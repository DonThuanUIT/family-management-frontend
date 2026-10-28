import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/models/event_models.dart';
import '../providers/event_providers.dart';
import '../widgets/assign_personnel_dialog.dart';
import '../widgets/create_event_sheet.dart';
import '../widgets/event_card.dart';
import '../widgets/event_detail_dialog.dart';
import '../widgets/event_notifications_dialog.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
          content: Text('Sự kiện đã ở trạng thái Đóng Sổ (Closed), không thể chuyển tiếp!'),
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
    final session = ref.watch(dualRbacSessionProvider);
    final authState = ref.watch(authStateProvider);

    final fullName = authState.user?.fullName.isNotEmpty == true
        ? authState.user!.fullName
        : session.fullName;
    final clanName = 'Vũ Tộc Tiên Lạc';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F4),
      // 1. App Bar
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A1719),
        foregroundColor: Colors.white,
        elevation: 2,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A017).withAlpha(40),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE2AA36).withAlpha(120),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Text(
                  'Vũ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFE082),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Text(
                        'TỘC SỰ & TẾ LỄ',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: Color(0xFFFFECB3),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '• Giáp Thìn 2024',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    clanName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Nút chuông thông báo (US-22)
          IconButton(
            tooltip: 'Thông báo sự kiện',
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 24),
                Positioned(
                  right: 2,
                  top: 2,
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
          // User Avatar với vai trò
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFB8860B),
              child: Text(
                fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),

      // 2. Body: Single Scrollable View with Pull-to-refresh
      body: RefreshIndicator(
        color: const Color(0xFF7A1518),
        onRefresh: () => ref.read(eventListProvider.notifier).loadEvents(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 2.1. Compact Hero Banner & KPI Bar
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF7A1719),
                      Color(0xFF8B1E1E),
                      Color(0xFFF9F7F4),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD54F).withAlpha(60),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_stories, size: 14, color: Color(0xFFFFD54F)),
                              SizedBox(width: 6),
                              Text(
                                'Kế Hoạch Tế Sự Niên Khóa',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFECB3),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

                      // Dải KPI 3 Cột (Thu gọn thay vì 4 khối to chiếm chỗ)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Đang Mở',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFFFECB3),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '0${eventState.openEventsCount} sự kiện',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFD54F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 20, width: 1, color: Colors.white24),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Dự Toán',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFFFECB3),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${eventState.totalBudgetMillions.toStringAsFixed(0)} Tr',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 20, width: 1, color: Colors.white24),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Tỷ Lệ Tự Tựu',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFFFECB3),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${eventState.averageAttendanceRate}%',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFA5D6A7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2.2. Sticky Action & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(10),
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
                  child: Column(
                    children: [
                      // Search & New Event Button
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => ref
                                  .read(eventListProvider.notifier)
                                  .setSearchQuery(val),
                              style: const TextStyle(fontSize: 12.5),
                              decoration: InputDecoration(
                                hintText: 'Tìm sự kiện, địa điểm, ngày âm...',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9F7F4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5DDD5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5DDD5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _openCreateEventSheet,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tạo Lễ Mới'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7A1518),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Lifecycle Status Tabs
                      SingleChildScrollView(
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
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2.3. Event Cards Feed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: eventState.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: Color(0xFF7A1518),
                          ),
                        ),
                      )
                    : eventState.filteredEvents.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: const Column(
                              children: [
                                Icon(Icons.event_busy,
                                    size: 40, color: Color(0xFFB0A298)),
                                SizedBox(height: 8),
                                Text(
                                  'Không tìm thấy sự kiện nào phù hợp.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7A6A60),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: eventState.filteredEvents.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final event = eventState.filteredEvents[index];
                              return EventCard(
                                event: event,
                                onTap: () => _openEventDetail(event),
                                onAssignPersonnel: () =>
                                    _openAssignPersonnel(event),
                                onChangeStatus: () =>
                                    _showStatusTransitionDialog(event),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 18),

              // 2.4. Collapsible Tộc Ước Điều 7 (Gọn gàng, không choán diện tích)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: const Color(0xFFFFF9ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFF5DCB7)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: _isClanCharterExpanded,
                      onExpansionChanged: (val) =>
                          setState(() => _isClanCharterExpanded = val),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
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
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF8A7A70),
                        ),
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
                ),
              ),
            ],
          ),
        ),
      ),

      // 3. Floating Action Center Button (Native feel)
      floatingActionButton: FloatingActionButton.extended(
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

  Widget _buildFilterTab(String filterKey, String label, String currentFilter) {
    final isSelected = currentFilter == filterKey;
    return InkWell(
      onTap: () =>
          ref.read(eventListProvider.notifier).setFilter(filterKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7A1518)
              : const Color(0xFFF5F0EB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF5C4A42),
          ),
        ),
      ),
    );
  }
}
