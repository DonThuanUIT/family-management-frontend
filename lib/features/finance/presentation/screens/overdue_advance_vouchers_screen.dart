import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/overdue_advance_providers.dart';
import '../widgets/overdue_advance_card.dart';

/// Màn hình theo dõi các khoản tạm ứng quá hạn nộp chứng từ dành cho BTC và Thủ quỹ (US-48).
class OverdueAdvanceVouchersScreen extends ConsumerStatefulWidget {
  final String? eventId;
  final String? eventName;
  final bool isClosed;

  const OverdueAdvanceVouchersScreen({
    super.key,
    this.eventId,
    this.eventName,
    this.isClosed = false,
  });

  @override
  ConsumerState<OverdueAdvanceVouchersScreen> createState() =>
      _OverdueAdvanceVouchersScreenState();
}

class _OverdueAdvanceVouchersScreenState
    extends ConsumerState<OverdueAdvanceVouchersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref
        .read(overdueAdvanceListProvider(widget.eventId).notifier)
        .setSearchQuery(value);
  }

  Future<void> _manualScan() async {
    try {
      final summary = await ref
          .read(overdueAdvanceListProvider(widget.eventId).notifier)
          .scanOverdue();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quét hoàn tất: ${summary.scannedCount} phiếu được rà soát, ${summary.overdueTransitionedCount} phiếu chuyển sang quá hạn, ${summary.notificationsSentCount} thông báo đã phát.',
            ),
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể quét quá hạn: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(dualRbacSessionProvider);
    final canScan = session.canTriggerManualOverdueScan(
      isClosed: widget.isClosed,
    );

    final state = ref.watch(overdueAdvanceListProvider(widget.eventId));
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: Color(0xFF1F1610)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theo Dõi Tạm Ứng Quá Hạn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1610),
              ),
            ),
            Text(
              widget.eventName != null && widget.eventName!.isNotEmpty
                  ? widget.eventName!
                  : 'Đôn đốc thu hồi chứng từ & hoàn ứng',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B5E55)),
            ),
          ],
        ),
        actions: [
          if (canScan)
            IconButton(
              key: const Key('manual_scan_button'),
              tooltip: 'Quét phiếu quá hạn thủ công',
              onPressed: state.isScanning ? null : _manualScan,
              icon: state.isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.radar_outlined,
                      color: AppTheme.primaryCrimson,
                    ),
            ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () {
              ref
                  .read(overdueAdvanceListProvider(widget.eventId).notifier)
                  .loadOverdueVouchers(showLoading: true);
            },
            icon: const Icon(Icons.refresh, color: Color(0xFF6B5E55)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 960 : double.infinity,
          ),
          child: Column(
            children: [
              // 1. KPI Overview Box
              _buildKpiSection(state),

              // 2. Search & Filter Bar
              _buildFilterSection(state),

              // 3. Danh sách phiếu
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.filteredVouchers.isEmpty
                        ? _buildEmptyState(state)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: state.filteredVouchers.length,
                            itemBuilder: (context, index) {
                              final voucher = state.filteredVouchers[index];
                              return OverdueAdvanceCard(
                                voucher: voucher,
                                isClosed: widget.isClosed,
                                eventId: widget.eventId,
                                onReminderSent: () {
                                  ref
                                      .read(overdueAdvanceListProvider(
                                              widget.eventId)
                                          .notifier)
                                      .loadOverdueVouchers(showLoading: false);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection(OverdueAdvanceListState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // KPI 1: Tổng tiền nợ quá hạn
          _buildKpiItem(
            label: 'Tổng tiền quá hạn',
            value: AppFormatters.formatVnd(state.totalOverdueAmount),
            valueColor: const Color(0xFFBA1A1A),
            isMonospace: true,
          ),
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFFCA5A5).withAlpha(120),
          ),
          // KPI 2: Số phiếu quá hạn
          _buildKpiItem(
            label: 'Số phiếu trễ',
            value: '${state.totalOverdueCount} phiếu',
            valueColor: const Color(0xFFBA1A1A),
          ),
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFFCA5A5).withAlpha(120),
          ),
          // KPI 3: Trễ nhiều nhất
          _buildKpiItem(
            label: 'Trễ dài nhất',
            value: state.maxOverdueDays > 0
                ? '${state.maxOverdueDays} ngày'
                : '0 ngày',
            valueColor: const Color(0xFF93000A),
          ),
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFFCA5A5).withAlpha(120),
          ),
          // KPI 4: Số người chưa nộp
          _buildKpiItem(
            label: 'Người nhận chưa nộp',
            value: '${state.debtorCount} người',
            valueColor: const Color(0xFF1F1610),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    required Color valueColor,
    bool isMonospace = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B5E55)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: isMonospace ? 'monospace' : null,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(OverdueAdvanceListState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search TextField
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm theo họ tên người nhận, công việc, mã phiếu...',
              hintStyle:
                  const TextStyle(fontSize: 12.5, color: Color(0xFF8A7A70)),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8E4DF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8E4DF)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OverdueDaysFilter.values.map((filter) {
                final isSelected = state.daysFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1F1610),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(overdueAdvanceListProvider(widget.eventId)
                              .notifier)
                          .setDaysFilter(filter);
                    },
                    selectedColor: AppTheme.primaryCrimson,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryCrimson
                          : const Color(0xFFE8E4DF),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(OverdueAdvanceListState state) {
    final hasSearchOrFilter = state.searchQuery.isNotEmpty ||
        state.daysFilter != OverdueDaysFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearchOrFilter
                  ? Icons.search_off_rounded
                  : Icons.verified_outlined,
              size: 56,
              color: hasSearchOrFilter
                  ? Colors.grey.shade400
                  : const Color(0xFF047857),
            ),
            const SizedBox(height: 12),
            Text(
              hasSearchOrFilter
                  ? 'Không tìm thấy khoản tạm ứng nào khớp bộ lọc'
                  : 'Ngân sách minh bạch & đúng hạn',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1610),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearchOrFilter
                  ? 'Vui lòng thử tìm với từ khóa hoặc mốc ngày khác'
                  : 'Hiện không có khoản tạm ứng nào quá hạn nộp chứng từ đối soát.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B5E55)),
            ),
          ],
        ),
      ),
    );
  }
}
