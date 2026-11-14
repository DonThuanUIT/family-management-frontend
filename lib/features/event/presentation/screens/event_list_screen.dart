import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/widgets/adaptive_modal.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../data/models/event_models.dart';
import '../providers/event_providers.dart';
import '../widgets/assign_personnel_dialog.dart';
import '../widgets/create_event_sheet.dart';
import '../widgets/event_card.dart';
import '../widgets/event_detail_dialog.dart';
import '../widgets/event_notifications_dialog.dart';

/// Màn hình Quản lý & Khởi tạo Sự Kiện Dòng Họ (US-05, US-35, US-36, US-38).
/// Thích ứng đa nền tảng:
/// - Điện thoại (`< 900px`): Thẻ xếp chồng 1 cột + FloatingActionButton + BottomSheet.
/// - Máy tính (`>= 900px`): Khung `maxWidth: 1280`, lưới 2 cột + thanh công cụ mở rộng + Dialog.
class EventListScreen extends ConsumerStatefulWidget {
  const EventListScreen({super.key});

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  final _searchController = TextEditingController();
  bool _isClanCharterExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventListProvider.notifier).loadEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEventDetail(EventModel event) {
    showDialog(
      context: context,
      builder: (_) => EventDetailDialog(event: event),
    );
  }

  void _openCreateEventSheet() {
    showAdaptiveSheetOrDialog(
      context: context,
      maxDesktopWidth: 680,
      builder: (_) => const CreateEventSheet(),
    );
  }

  void _openAssignPersonnel(EventModel event) {
    showDialog(
      context: context,
      builder: (_) => AssignPersonnelDialog(event: event),
    );
  }

  void _openNotifications(String eventId) {
    showDialog(
      context: context,
      builder: (_) => EventNotificationsDialog(eventId: eventId),
    );
  }

  void _showStatusTransitionDialog(EventModel event) {
    String? nextStatus;
    switch (event.status) {
      case 'Draft':
        nextStatus = 'RegistrationOpen';
        break;
      case 'RegistrationOpen':
        nextStatus = 'RegistrationClosed';
        break;
      case 'RegistrationClosed':
        nextStatus = 'Ongoing';
        break;
      case 'Ongoing':
        nextStatus = 'Ended';
        break;
      case 'Ended':
        nextStatus = 'Closed';
        break;
      default:
        nextStatus = null;
    }

    if (nextStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sự kiện đã ở trạng thái Đóng Sổ (Closed), không thể chuyển tiếp!',
          ),
        ),
      );
      return;
    }

    final nextStatusName = EventLifecycleStatus.fromCode(nextStatus).displayName;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.swap_horiz, color: Color(0xFF7A1518)),
            SizedBox(width: 8),
            Text('Chuyển Vòng Đời Sự Kiện', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn chuyển trạng thái sự kiện "${event.eventName}" '
          'từ [${event.lifecycleStatus.displayName}] sang [$nextStatusName]?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A1518),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(eventListProvider.notifier)
                  .updateStatus(event.eventId, nextStatus!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Đã chuyển trạng thái sự kiện sang "$nextStatusName"!'
                          : 'Lỗi khi chuyển trạng thái!',
                    ),
                    backgroundColor:
                        success ? const Color(0xFF1B5E20) : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xác Nhận Chuyển'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventListProvider);
    final isDesktop = isDesktopViewport(context);
    const clanName = 'Vũ Tộc Tiên Lạc';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      appBar: const HeritageNavBar(currentRoute: '/events'),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/events'),
      body: RefreshIndicator(
        color: const Color(0xFF7A1518),
        onRefresh: () => ref.read(eventListProvider.notifier).loadEvents(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: isDesktop ? 40 : 90),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Sub-header & Hero Banner + KPI Bar
                  _buildHeroSection(
                    eventState: eventState,
                    clanName: clanName,
                    isDesktop: isDesktop,
                  ),

                  SizedBox(height: isDesktop ? 20 : 4),

                  // 2. Action & Filter Bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                    ),
                    child: _buildActionAndFilterBar(eventState, isDesktop),
                  ),

                  SizedBox(height: isDesktop ? 20 : 14),

                  // 3. Event Cards Feed (1 cột trên Mobile, Lưới 2 cột trên Desktop)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                    ),
                    child: _buildEventsContent(eventState, isDesktop),
                  ),

                  SizedBox(height: isDesktop ? 24 : 18),

                  // 4. Collapsible Tộc Ước Điều 7
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                    ),
                    child: _buildCharterCard(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateEventSheet,
              backgroundColor: const Color(0xFF7A1518),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Khởi Điển Sự Kiện',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
    );
  }

  Widget _buildHeroSection({
    required EventListState eventState,
    required String clanName,
    required bool isDesktop,
  }) {
    final headerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Clan Identity & Notification Trigger
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A017).withAlpha(45),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2AA36).withAlpha(140),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Text(
                  'Vũ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFE082),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'TỘC SỰ & TẾ LỄ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: Color(0xFFFFECB3),
                        ),
                      ),
                      Text(
                        '• Giáp Thìn 2024',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    clanName,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Thông báo sự kiện',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(22),
                foregroundColor: Colors.white,
              ),
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, size: 22),
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD54F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                if (eventState.events.isNotEmpty) {
                  _openNotifications(eventState.events.first.eventId);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Hero KPI Card
        Container(
          padding: EdgeInsets.all(isDesktop ? 18 : 14),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD54F).withAlpha(65),
              width: 1,
            ),
          ),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_stories,
                                size: 15,
                                color: Color(0xFFFFD54F),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Kế Hoạch Tế Sự Niên Khóa',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFECB3),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD54F).withAlpha(40),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${eventState.events.length} Điển Lễ Niên Vụ',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFE082),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '“Uống nước nhớ nguồn, giữ trọn cương thường. Tế tự trang nghiêm, muôn đời phúc ấm.”',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 48,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.white24,
                    ),
                    Expanded(
                      flex: 5,
                      child: _buildKpiRow(eventState, isDesktop: true),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_stories,
                                size: 14,
                                color: Color(0xFFFFD54F),
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Kế Hoạch Tế Sự Niên Khóa',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFFECB3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD54F).withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${eventState.events.length} Điển Lễ Niên Vụ',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFE082),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '“Uống nước nhớ nguồn, giữ trọn cương thường. Tế tự trang nghiêm, muôn đời phúc ấm.”',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const Divider(height: 18, color: Colors.white24),
                    _buildKpiRow(eventState, isDesktop: false),
                  ],
                ),
        ),
      ],
    );

    if (isDesktop) {
      return Container(
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A020A),
              Color(0xFF8B1E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A020A).withAlpha(35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: headerContent,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7A1719),
            Color(0xFF8B1E1E),
            Color(0xFFF9F7F4),
          ],
          stops: [0.0, 0.72, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: headerContent,
    );
  }

  Widget _buildKpiRow(EventListState eventState, {required bool isDesktop}) {
    final valueSize = isDesktop ? 16.0 : 13.5;
    final labelSize = isDesktop ? 11.0 : 10.0;
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                'Đang Mở',
                style: TextStyle(
                  fontSize: labelSize,
                  color: const Color(0xFFFFECB3),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '0${eventState.openEventsCount} sự kiện',
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD54F),
                ),
              ),
            ],
          ),
        ),
        Container(height: 24, width: 1, color: Colors.white24),
        Expanded(
          child: Column(
            children: [
              Text(
                'Dự Toán',
                style: TextStyle(
                  fontSize: labelSize,
                  color: const Color(0xFFFFECB3),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${eventState.totalBudgetMillions.toStringAsFixed(0)} Tr',
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(height: 24, width: 1, color: Colors.white24),
        Expanded(
          child: Column(
            children: [
              Text(
                'Tỷ Lệ Tự Tựu',
                style: TextStyle(
                  fontSize: labelSize,
                  color: const Color(0xFFFFECB3),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${eventState.averageAttendanceRate}%',
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFA5D6A7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionAndFilterBar(EventListState eventState, bool isDesktop) {
    final searchField = TextField(
      controller: _searchController,
      onChanged: (val) =>
          ref.read(eventListProvider.notifier).setSearchQuery(val),
      style: const TextStyle(fontSize: 12.5),
      decoration: InputDecoration(
        hintText: 'Tìm sự kiện, địa điểm, ngày âm...',
        prefixIcon: const Icon(Icons.search, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        filled: true,
        fillColor: const Color(0xFFF9F7F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5DDD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5DDD5)),
        ),
      ),
    );

    final createBtn = ElevatedButton.icon(
      onPressed: _openCreateEventSheet,
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Tạo Lễ Mới'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7A1518),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 18 : 12,
          vertical: isDesktop ? 14 : 10,
        ),
        textStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    final filterTabs = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterTab(
            'all',
            'Tất cả (${eventState.events.length})',
            eventState.selectedFilter,
          ),
          const SizedBox(width: 6),
          _buildFilterTab(
            'open',
            'Đang mở ghi danh',
            eventState.selectedFilter,
          ),
          const SizedBox(width: 6),
          _buildFilterTab(
            'ongoing',
            'Đang diễn ra',
            eventState.selectedFilter,
          ),
          const SizedBox(width: 6),
          _buildFilterTab(
            'completed',
            'Đã bế mạc',
            eventState.selectedFilter,
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(flex: 4, child: searchField),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: filterTabs),
                const SizedBox(width: 12),
                createBtn,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 8),
                    createBtn,
                  ],
                ),
                const SizedBox(height: 8),
                filterTabs,
              ],
            ),
    );
  }

  Widget _buildEventsContent(EventListState eventState, bool isDesktop) {
    if (eventState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF7A1518)),
        ),
      );
    }

    final events = eventState.filteredEvents;
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8DFD8)),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_busy, size: 40, color: Color(0xFFB0A298)),
            SizedBox(height: 8),
            Text(
              'Không tìm thấy sự kiện nào phù hợp.',
              style: TextStyle(fontSize: 13, color: Color(0xFF7A6A60)),
            ),
          ],
        ),
      );
    }

    Widget buildCard(EventModel event) {
      return EventCard(
        event: event,
        onTap: () => _openEventDetail(event),
        onAssignPersonnel: () => _openAssignPersonnel(event),
        onChangeStatus: () => _showStatusTransitionDialog(event),
      );
    }

    if (!isDesktop) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => buildCard(events[index]),
      );
    }

    // Desktop: Lưới 2 cột cân đối cho từng cặp EventCard
    final rows = <Widget>[];
    for (int i = 0; i < events.length; i += 2) {
      final first = events[i];
      final second = (i + 1 < events.length) ? events[i + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: buildCard(first)),
            const SizedBox(width: 16),
            Expanded(
              child: second != null
                  ? buildCard(second)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < events.length) {
        rows.add(const SizedBox(height: 16));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildCharterCard(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF9ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFF5DCB7)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isClanCharterExpanded,
          onExpansionChanged: (val) =>
              setState(() => _isClanCharterExpanded = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: const Icon(
            Icons.gavel_outlined,
            color: Color(0xFF7A1518),
            size: 20,
          ),
          title: const Text(
            'Tộc Ước Điều 7: Về Tế Lễ Tông Môn',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B1810),
            ),
          ),
          subtitle: const Text(
            'Quy chế phân công chấp sự & phụng tự',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF8A7A70)),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                '“Mọi con cháu nội ngoại đến ngày giỗ Tổ, tết thanh minh đều phải '
                'tề tựu hướng về phụng thờ tiên liệt. Ban Trị Sự cùng các Trưởng Chi '
                'có trách nhiệm phân công chấp sự minh bạch, dự toán công khai, kính cẩn chu toàn.”\n\n'
                '— Chấp bút: Hội Đồng Trị Sự & Tộc Biểu',
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF5C4A42),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String filterKey, String label, String currentFilter) {
    final isSelected = currentFilter == filterKey;
    return InkWell(
      onTap: () => ref.read(eventListProvider.notifier).setFilter(filterKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7A1518)
              : const Color(0xFFF5F0EB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF5C4A42),
          ),
        ),
      ),
    );
  }
}
