import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../providers/join_requests_provider.dart';
import '../widgets/join_requests_mobile_list.dart';
import '../widgets/join_requests_table.dart';

/// Màn hình Quản lý Yêu cầu Gia nhập cho Trưởng tộc / Trưởng chi nhánh (US-33 & US-17).
class JoinRequestsManagementScreen extends ConsumerStatefulWidget {
  final String? initialBranchId;

  const JoinRequestsManagementScreen({
    super.key,
    this.initialBranchId,
  });

  @override
  ConsumerState<JoinRequestsManagementScreen> createState() =>
      _JoinRequestsManagementScreenState();
}

class _JoinRequestsManagementScreenState
    extends ConsumerState<JoinRequestsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(joinRequestsProvider.notifier)
          .loadInitialData(initialBranchId: widget.initialBranchId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(joinRequestsProvider);
    final notifier = ref.read(joinRequestsProvider.notifier);
    final isDesktop = MediaQuery.of(context).size.width >= 860;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      appBar: const HeritageNavBar(currentRoute: '/join-requests'),
      bottomNavigationBar:
          const HeritageBottomNavBar(currentRoute: '/join-requests'),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Success & Error Feedback Banners
                if (state.errorMessage != null)
                  _buildFeedbackBanner(
                    message: state.errorMessage!,
                    isError: true,
                    onClose: notifier.clearMessages,
                  ),
                if (state.successMessage != null)
                  _buildFeedbackBanner(
                    message: state.successMessage!,
                    isError: false,
                    onClose: notifier.clearMessages,
                  ),

                // 2. Top Archival Context Notice
                _buildTopNotice(isDesktop),
                const SizedBox(height: 20),

                // 3. Page Header
                _buildPageHeader(notifier),
                const SizedBox(height: 20),

                // 4. KPI Summary Cards
                _buildKpiCards(state, notifier, isDesktop),
                const SizedBox(height: 24),

                // 5. Search & Filters Bar
                _buildSearchAndFilters(state, notifier, isDesktop),
                const SizedBox(height: 20),

                // 6. Request List / Table Content
                if (state.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: CircularProgressIndicator(color: Color(0xFF8F482F)),
                    ),
                  )
                else if (isDesktop)
                  JoinRequestsTable(requests: state.requests)
                else
                  JoinRequestsMobileList(requests: state.requests),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner({
    required String message,
    required bool isError,
    required VoidCallback onClose,
  }) {
    final bgColor = isError ? const Color(0xFFFFDAD6) : const Color(0xFFE8F5E9);
    final borderColor =
        isError ? const Color(0xFFBA1A1A) : const Color(0xFF006E2A);
    final textColor =
        isError ? const Color(0xFF93000A) : const Color(0xFF00531E);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: borderColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: textColor),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNotice(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE6E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF8F482F).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined,
                color: Color(0xFF8F482F), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HỆ THỐNG PHÊ CHUẨN GIA NHẬP PHẢ HỆ • DUAL-RBAC BẢO MẬT',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF8F482F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Trưởng tộc và Trưởng chi nhánh có thẩm quyền xem xét hồ sơ, điều chỉnh lại vị trí nhánh phả hệ nếu ứng viên chọn nhầm trước khi phê duyệt (AC-08), hoặc từ chối kèm lý do chính thức (AC-06).',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12.5,
                    color: Color(0xFF54433E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(JoinRequestsNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản Lý Đơn Xin Gia Nhập',
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1A),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tiếp nhận, thẩm định và phê duyệt thành viên mới vào cây gia phả dòng họ',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Color(0xFF6B584E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Tải lại danh sách',
          onPressed: () =>
              notifier.loadInitialData(initialBranchId: widget.initialBranchId),
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF8F482F)),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFDAC1BA)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCards(
    JoinRequestsState state,
    JoinRequestsNotifier notifier,
    bool isDesktop,
  ) {
    final cards = [
      _KpiCardItem(
        label: 'Chờ Phê Duyệt',
        count: state.pendingCount,
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFF7A5900),
        bgColor: const Color(0xFFFFF4D3),
        isSelected: state.statusFilter == JoinRequestApprovalStatus.pending,
        onTap: () => notifier.setStatusFilter(
          state.statusFilter == JoinRequestApprovalStatus.pending
              ? null
              : JoinRequestApprovalStatus.pending,
        ),
      ),
      _KpiCardItem(
        label: 'Đã Phê Duyệt',
        count: state.approvedCount,
        icon: Icons.check_circle_outline,
        color: const Color(0xFF006E2A),
        bgColor: const Color(0xFFE8F5E9),
        isSelected: state.statusFilter == JoinRequestApprovalStatus.approved,
        onTap: () => notifier.setStatusFilter(
          state.statusFilter == JoinRequestApprovalStatus.approved
              ? null
              : JoinRequestApprovalStatus.approved,
        ),
      ),
      _KpiCardItem(
        label: 'Đã Từ Chối',
        count: state.rejectedCount,
        icon: Icons.highlight_off_rounded,
        color: const Color(0xFFBA1A1A),
        bgColor: const Color(0xFFFFDAD6),
        isSelected: state.statusFilter == JoinRequestApprovalStatus.rejected,
        onTap: () => notifier.setStatusFilter(
          state.statusFilter == JoinRequestApprovalStatus.rejected
              ? null
              : JoinRequestApprovalStatus.rejected,
        ),
      ),
      _KpiCardItem(
        label: 'Tổng Đơn Toàn Tộc',
        count: state.totalCount,
        icon: Icons.format_list_bulleted,
        color: const Color(0xFF8F482F),
        bgColor: const Color(0xFFF6F3F1),
        isSelected: state.statusFilter == null,
        onTap: () => notifier.setStatusFilter(null),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards.map((c) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildSingleKpiCard(c),
        ))).toList(),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards.map((c) => _buildSingleKpiCard(c)).toList(),
      );
    }
  }

  Widget _buildSingleKpiCard(_KpiCardItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isSelected ? item.color : const Color(0xFFE6DFD8),
            width: item.isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (item.isSelected)
              BoxShadow(
                color: item.color.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      fontWeight:
                          item.isSelected ? FontWeight.bold : FontWeight.w500,
                      color: const Color(0xFF54433E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.count}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(
    JoinRequestsState state,
    JoinRequestsNotifier notifier,
    bool isDesktop,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        children: [
          // Search input
          TextField(
            controller: _searchController,
            onChanged: notifier.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo họ tên, số điện thoại, mã đơn...',
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFF85736E)),
              prefixIcon:
                  const Icon(Icons.search, size: 20, color: Color(0xFF85736E)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        notifier.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFFCF9F6),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFDAC1BA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF8F482F), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filters Row
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Status tabs
              Wrap(
                spacing: 6,
                children: [
                  _buildFilterChip(
                    label: 'Tất cả (${state.totalCount})',
                    isSelected: state.statusFilter == null,
                    onTap: () => notifier.setStatusFilter(null),
                  ),
                  _buildFilterChip(
                    label: 'Chờ duyệt (${state.pendingCount})',
                    isSelected:
                        state.statusFilter == JoinRequestApprovalStatus.pending,
                    selectedColor: const Color(0xFF7A5900),
                    onTap: () => notifier
                        .setStatusFilter(JoinRequestApprovalStatus.pending),
                  ),
                  _buildFilterChip(
                    label: 'Đã duyệt (${state.approvedCount})',
                    isSelected:
                        state.statusFilter == JoinRequestApprovalStatus.approved,
                    selectedColor: const Color(0xFF006E2A),
                    onTap: () => notifier
                        .setStatusFilter(JoinRequestApprovalStatus.approved),
                  ),
                  _buildFilterChip(
                    label: 'Đã từ chối (${state.rejectedCount})',
                    isSelected:
                        state.statusFilter == JoinRequestApprovalStatus.rejected,
                    selectedColor: const Color(0xFFBA1A1A),
                    onTap: () => notifier
                        .setStatusFilter(JoinRequestApprovalStatus.rejected),
                  ),
                ],
              ),

              // Branch dropdown filter
              if (state.branchOptions.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: DropdownButtonFormField<String?>(
                    initialValue: state.branchFilter,
                    isDense: true,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFFCF9F6),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDAC1BA)),
                      ),
                    ),
                    hint: const Text('Tất cả chi nhánh',
                        style: TextStyle(fontSize: 12)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tất cả chi nhánh',
                            style: TextStyle(fontSize: 12)),
                      ),
                      ...state.branchOptions.map((b) => DropdownMenuItem<String?>(
                            value: b.branchId,
                            child: Text(
                              b.displayName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (val) => notifier.setBranchFilter(val),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final activeColor = selectedColor ?? const Color(0xFF8F482F);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(25) : const Color(0xFFF6F3F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFDAC1BA),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : const Color(0xFF54433E),
          ),
        ),
      ),
    );
  }
}

class _KpiCardItem {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _KpiCardItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });
}
