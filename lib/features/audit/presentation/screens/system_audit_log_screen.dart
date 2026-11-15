import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/audit_log_models.dart';
import '../providers/audit_providers.dart';
import '../widgets/diff_viewer_dialog.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';

/// Màn hình Nhật Ký Thao Tác Hệ Thống (System Audit Log & Diff Viewer)
/// Thiết kế chuẩn mực theo DESIGN.md (Warm Editorial Heritage):
/// - Thích ứng đa nền tảng: Bảng dữ liệu chuẩn mực trên Desktop & Thẻ sự kiện trên Mobile.
/// - Kết nối trực tiếp API Backend Spring Boot (/api/v1/audit-logs).
class SystemAuditLogScreen extends ConsumerStatefulWidget {
  const SystemAuditLogScreen({super.key});

  @override
  ConsumerState<SystemAuditLogScreen> createState() => _SystemAuditLogScreenState();
}

class _SystemAuditLogScreenState extends ConsumerState<SystemAuditLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(auditFilterProvider);
    final auditLogsAsync = ref.watch(auditLogsProvider);
    final stats = ref.watch(auditStatsProvider);

    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // Warm Ivory Canvas
      appBar: const HeritageNavBar(currentRoute: '/audit-logs'),
      bottomNavigationBar: isDesktop ? null : const HeritageBottomNavBar(currentRoute: '/audit-logs'),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: isDesktop ? 24 : 16,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Breadcrumb
                _buildBreadcrumb(context),
                const SizedBox(height: 16),

                // 2. Tiêu đề trang & Các nút tác vụ nhanh
                _buildPageHeader(context, isDesktop),
                const SizedBox(height: 20),

                // 3. Thanh Interactive Demo Bar (Xem nhanh 4 kịch bản Diff theo yêu cầu)
                _buildInteractiveDemoBar(context),
                const SizedBox(height: 24),

                // 4. Thống kê nhanh 4 chỉ số (Stat Cards)
                _buildStatCards(stats, isDesktop),
                const SizedBox(height: 24),

                // 5. Bộ lọc & Tìm kiếm nhật ký (Filter Panel)
                _buildFilterPanel(context, filter),
                const SizedBox(height: 24),

                // 6. Danh sách nhật ký (Bảng Desktop hoặc Card Stack Mobile)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D2A2A2A),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header của Card danh sách
                      _buildListHeader(auditLogsAsync, isDesktop),
                      const Divider(height: 1, color: Color(0xFFE5E5E5)),

                      // Danh sách dữ liệu
                      auditLogsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF8B1E1E))),
                        ),
                        error: (err, stack) => Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 40),
                              const SizedBox(height: 10),
                              Text('Lỗi kết nối máy chủ API: $err', style: const TextStyle(color: Color(0xFF58413F))),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => ref.invalidate(auditLogsProvider),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                        data: (pageData) {
                          if (pageData.items.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(48.0),
                              child: Center(
                                child: Text('Không tìm thấy bản ghi nhật ký phù hợp với bộ lọc.',
                                    style: TextStyle(color: Color(0xFF58413F), fontSize: 14)),
                              ),
                            );
                          }

                          if (isDesktop) {
                            return _buildDesktopAuditTable(pageData.items);
                          } else {
                            return _buildMobileAuditCardStack(pageData.items);
                          }
                        },
                      ),

                      const Divider(height: 1, color: Color(0xFFE5E5E5)),
                      // Phân trang
                      _buildPaginationBar(auditLogsAsync),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Breadcrumb
  Widget _buildBreadcrumb(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          Text('Trang chủ', style: TextStyle(color: Color(0xFF58413F), fontSize: 13.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('/', style: TextStyle(color: Color(0xFF58413F), fontSize: 12)),
          ),
          Text('Quản trị hệ thống', style: TextStyle(color: Color(0xFF58413F), fontSize: 13.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('/', style: TextStyle(color: Color(0xFF58413F), fontSize: 12)),
          ),
          Text(
            'Nhật ký thao tác (Audit Log)',
            style: TextStyle(color: Color(0xFF1A1C1A), fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  // 2. Tiêu đề trang & Nút hành động
  Widget _buildPageHeader(BuildContext context, bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.history_edu, color: Color(0xFF8B1E1E), size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nhật Ký Thao Tác Quan Trọng',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Ghi nhận minh bạch mọi hành động phân quyền, duyệt gia nhập, sửa cây gia phả và điều chỉnh sự kiện',
                style: TextStyle(fontSize: 14.5, color: Color(0xFF58413F)),
              ),
            ],
          ),
        ),
        if (isDesktop)
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang xuất báo cáo kiểm toán PDF...')),
                  );
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Xuất Báo Cáo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1E1E),
                  side: const BorderSide(color: Color(0xFF8B1E1E), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(140, 48),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(auditLogsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Làm Mới Dữ Liệu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E1E),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(150, 48),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // 3. Interactive Demo Selector Bar
  Widget _buildInteractiveDemoBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4AF37).withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: Color(0xFF735C00), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bản xem thử tương tác - Xem nhanh 4 kịch bản so sánh dữ liệu Cũ - Mới (Diff):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF735C00)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _demoPill('1. Phân quyền Trưởng chi', 'AUD_01HZX87K91'),
              _demoPill('2. Duyệt đơn gia nhập', 'AUD_01HZX78J42'),
              _demoPill('3. Sửa cây gia phả', 'AUD_01HZX65G33'),
              _demoPill('4. Đổi trạng thái sự kiện', 'AUD_01HZX54D19'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoPill(String label, String auditId) {
    return InkWell(
      onTap: () => showDiffViewer(context: context, auditId: auditId),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD4AF37).withAlpha(120)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF735C00)),
        ),
      ),
    );
  }

  // 4. Stat Cards
  Widget _buildStatCards(AuditStatsSummary stats, bool isDesktop) {
    final cards = [
      _statCard('Tổng Thao Tác', '${stats.totalCount}', Icons.assignment_outlined, const Color(0xFF0F766E)),
      _statCard('Phân Quyền / Thu Hồi', '${stats.assignCount}', Icons.key_outlined, const Color(0xFF1B873F)),
      _statCard('Duyệt Gia Nhập', '${stats.joinCount}', Icons.person_add_alt_1_outlined, const Color(0xFF7C3AED)),
      _statCard('Biến Động Cây Gia Phả', '${stats.genealogyCount}', Icons.park_outlined, const Color(0xFFE67E22)),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: cards,
      );
    }
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A2A2A2A), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF58413F)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1A)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  // 5. Filter Panel
  Widget _buildFilterPanel(BuildContext context, AuditLogFilter filter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A2A2A2A), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.filter_alt_outlined, color: Color(0xFF8B1E1E), size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Bộ Lọc & Tìm Kiếm Nhật Ký',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1C1A)),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(auditFilterProvider.notifier).reset();
                },
                child: const Text('Đặt lại bộ lọc', style: TextStyle(color: Color(0xFF8B1E1E), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ô tìm kiếm
          TextField(
            controller: _searchController,
            onChanged: (val) {
              ref.read(auditFilterProvider.notifier).setFilter(filter.copyWith(keyword: val.trim()));
            },
            decoration: InputDecoration(
              hintText: 'Tìm theo tên thành viên, ID đối tượng, mô tả hành động...',
              hintStyle: const TextStyle(color: Color(0xFF58413F), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF8B1E1E), size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(auditFilterProvider.notifier).setFilter(filter.copyWith(keyword: ''));
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFFAF9F6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E5E5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E5E5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF8B1E1E), width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AuditCategory.values.map((cat) {
                final isSelected = filter.category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF58413F)),
                        const SizedBox(width: 6),
                        Text(cat.label),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(auditFilterProvider.notifier).setFilter(filter.copyWith(category: cat, page: 0));
                    },
                    selectedColor: const Color(0xFF8B1E1E),
                    backgroundColor: const Color(0xFFFAF9F6),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : const Color(0xFF58413F),
                    ),
                    side: BorderSide(color: isSelected ? const Color(0xFF8B1E1E) : const Color(0xFFE5E5E5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Header của khối danh sách
  Widget _buildListHeader(AsyncValue<AuditLogPageResponse> asyncValue, bool isDesktop) {
    final count = asyncValue.value?.items.length ?? 0;
    final total = asyncValue.value?.totalElements ?? 0;

    if (!isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiển thị $count / $total bản ghi kiểm toán gần nhất',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1A1C1A)),
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.shield_outlined, color: Color(0xFF1B873F), size: 15),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Dữ liệu bất biến chống sửa đổi (Append-only)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B873F)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Hiển thị $count / $total bản ghi kiểm toán gần nhất',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1C1A)),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFF1B873F), size: 16),
              SizedBox(width: 6),
              Text(
                'Dữ liệu bất biến chống sửa đổi (Append-only)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1B873F)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6A. Bảng Desktop (Data Table)
  Widget _buildDesktopAuditTable(List<AuditLogItemModel> items) {
    return Column(
      children: [
        // Table Header
        Container(
          color: const Color(0xFFF4F3F1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: const Row(
            children: [
              SizedBox(width: 150, child: Text('THỜI ĐIỂM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF58413F)))),
              SizedBox(width: 200, child: Text('NGƯỜI THỰC HIỆN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF58413F)))),
              SizedBox(width: 140, child: Text('HÀNH ĐỘNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF58413F)))),
              SizedBox(width: 150, child: Text('ĐỐI TƯỢNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF58413F)))),
              Expanded(child: Text('NỘI DUNG TÓM TẮT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF58413F)))),
              SizedBox(width: 110, child: Text('SO SÁNH', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF58413F)))),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E5E5)),

        // Table Rows
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE5E5E5)),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: () => showDiffViewer(context: context, auditId: item.auditId),
              hoverColor: const Color(0xFF8B1E1E).withAlpha(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Thời điểm
                    SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getRelativeTime(item.createdAt),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1A1C1A)),
                          ),
                          Text(
                            _dateFormat.format(item.createdAt),
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF58413F)),
                          ),
                        ],
                      ),
                    ),

                    // Người thực hiện
                    SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF8B1E1E),
                            child: Text(
                              _getInitials(item.actorFullName ?? 'Hệ thống'),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.actorFullName ?? item.actorAccountId ?? 'Hệ thống',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1A1C1A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.actorAccountId ?? 'Tộc biểu',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF58413F), fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hành động Badge
                    SizedBox(
                      width: 140,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.actionColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: item.actionColor.withAlpha(60)),
                          ),
                          child: Text(
                            item.actionDisplayName,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: item.actionColor,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Đối tượng Chip
                    SizedBox(
                      width: 150,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F3F1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                          ),
                          child: Text(
                            '${item.entityTypeDisplayName} • ${item.entityId ?? "-"}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1C1A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),

                    // Nội dung tóm tắt
                    Expanded(
                      child: Text(
                        item.description ?? '',
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF1A1C1A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Nút Xem Diff
                    SizedBox(
                      width: 110,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => showDiffViewer(context: context, auditId: item.auditId),
                          icon: const Icon(Icons.compare_arrows, size: 14),
                          label: const Text('Xem Diff'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B1E1E),
                            side: const BorderSide(color: Color(0xFF8B1E1E)),
                            minimumSize: const Size(96, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 6B. Thẻ Mobile (Card Stack)
  Widget _buildMobileAuditCardStack(List<AuditLogItemModel> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
            boxShadow: const [
              BoxShadow(color: Color(0x082A2A2A), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card: Avatar + Tên + Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF8B1E1E),
                          child: Text(
                            _getInitials(item.actorFullName ?? 'Hệ thống'),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.actorFullName ?? item.actorAccountId ?? 'Hệ thống',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1C1A)),
                              ),
                              Text(
                                item.actorAccountId ?? 'Tộc biểu',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF58413F), fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.actionColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: item.actionColor.withAlpha(60)),
                    ),
                    child: Text(
                      item.actionDisplayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.actionColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Thân Card: Mô tả
              Text(
                item.description ?? '',
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1C1A), height: 1.4),
              ),
              const SizedBox(height: 12),

              // Footer Card: Chip đối tượng & Thời gian
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F3F1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: Text(
                        '${item.entityTypeDisplayName} • ${item.entityId ?? "-"}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getRelativeTime(item.createdAt),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Nút Xem Diff lớn chuẩn 48px trên Mobile
              OutlinedButton.icon(
                onPressed: () => showDiffViewer(context: context, auditId: item.auditId),
                icon: const Icon(Icons.compare_arrows, size: 18),
                label: const Text('Xem So Sánh Chi Tiết (Diff)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1E1E),
                  side: const BorderSide(color: Color(0xFF8B1E1E), width: 1.5),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 7. Phân trang
  Widget _buildPaginationBar(AsyncValue<AuditLogPageResponse> asyncValue) {
    final page = asyncValue.value?.page ?? 0;
    final totalPages = asyncValue.value?.totalPages ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Trang ${page + 1} / $totalPages', style: const TextStyle(fontSize: 13.5, color: Color(0xFF58413F))),
          Row(
            children: [
              IconButton(
                onPressed: page > 0
                    ? () {
                        final filter = ref.read(auditFilterProvider);
                        ref.read(auditFilterProvider.notifier).setFilter(filter.copyWith(page: page - 1));
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
                splashRadius: 18,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E1E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${page + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              IconButton(
                onPressed: page < totalPages - 1
                    ? () {
                        final filter = ref.read(auditFilterProvider);
                        ref.read(auditFilterProvider.notifier).setFilter(filter.copyWith(page: page + 1));
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'NT';
  }
}
