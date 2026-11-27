import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/adaptive_modal.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../providers/ledger_adjustment_providers.dart';

/// Bảng / Modal chọn giao dịch gốc từ Sổ cái Quỹ chung bất biến (GET /api/v1/ledger).
class LedgerTransactionPickerSheet extends ConsumerStatefulWidget {
  final String? selectedTransactionId;

  const LedgerTransactionPickerSheet({
    super.key,
    this.selectedTransactionId,
  });

  static Future<LedgerHistoryItemModel?> show(
    BuildContext context, {
    String? selectedTransactionId,
  }) {
    return showAdaptiveSheetOrDialog<LedgerHistoryItemModel>(
      context: context,
      maxDesktopWidth: 920,
      maxDesktopHeightFactor: 0.88,
      builder: (_) => LedgerTransactionPickerSheet(
        selectedTransactionId: selectedTransactionId,
      ),
    );
  }

  @override
  ConsumerState<LedgerTransactionPickerSheet> createState() =>
      _LedgerTransactionPickerSheetState();
}

class _LedgerTransactionPickerSheetState
    extends ConsumerState<LedgerTransactionPickerSheet> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final initialKeyword = ref.read(ledgerPickerProvider).keyword;
    _searchController = TextEditingController(text: initialKeyword);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) {
        ref.read(ledgerPickerProvider.notifier).setKeyword(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerPickerProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 820;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: isWide
              ? BorderRadius.circular(24)
              : const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE6DFD8)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chọn Giao Dịch Gốc Từ Sổ Cái',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Số dư Quỹ chung hiện tại: ${AppFormatters.formatVnd(state.currentFundBalance)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.immutableLedgerTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => ref
                        .read(ledgerPickerProvider.notifier)
                        .loadLedger(showLoading: true),
                    icon: const Icon(Icons.refresh, color: Color(0xFF58413F)),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF1A1C1A)),
                  ),
                ],
              ),
            ),

            // Search & Filter Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('ledger_picker_search_input'),
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText:
                          'Tìm theo mã giao dịch (LDG...), nội dung, sự kiện...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B716E),
                      ),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(ledgerPickerProvider.notifier)
                                    .setKeyword('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFFAF9F6),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE6DFD8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE6DFD8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Tất cả',
                          isSelected: state.selectedType == null,
                          onTap: () => ref
                              .read(ledgerPickerProvider.notifier)
                              .setTypeFilter(null),
                        ),
                        ...LedgerTransactionTypeEnum.values.map(
                          (type) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _buildFilterChip(
                              label: type.displayName,
                              isSelected: state.selectedType == type,
                              onTap: () => ref
                                  .read(ledgerPickerProvider.notifier)
                                  .setTypeFilter(type),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE6DFD8)),

            // List / Table Body
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryCrimson,
                        ),
                      ),
                    )
                  : state.errorMessage != null
                      ? _buildErrorState(state.errorMessage!)
                      : state.items.isEmpty
                          ? _buildEmptyState()
                          : isWide
                              ? _buildDesktopTable(state.items)
                              : _buildMobileList(state.items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF58413F),
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryCrimson,
      backgroundColor: const Color(0xFFFAF9F6),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryCrimson : const Color(0xFFE6DFD8),
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildDesktopTable(List<LedgerHistoryItemModel> items) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(bottom: BorderSide(color: Color(0xFFE6DFD8))),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 175,
                      child: Text(
                        'MÃ GD / NGÀY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF58413F),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'LOẠI & NỘI DUNG',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF58413F),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 155,
                      child: Text(
                        'SỐ TIỀN GD',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF58413F),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    SizedBox(
                      width: 145,
                      child: Text(
                        'THAO TÁC',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF58413F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...items.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == items.length - 1;
                return _buildDesktopRow(item, isLast);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopRow(LedgerHistoryItemModel item, bool isLast) {
    final isLocked = item.isLockedByPendingAdjustment;
    final isSelected = widget.selectedTransactionId == item.transactionId;
    final amountColor = item.amount > 0
        ? AppTheme.immutableLedgerTeal
        : (item.amount < 0 ? const Color(0xFFBA1A1A) : const Color(0xFF58413F));

    return Opacity(
      opacity: isLocked ? 0.72 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFEFECE6))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 175,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.transactionId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.formattedSolarDate,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF58413F),
                    ),
                  ),
                  Text(
                    item.formattedLunarDate,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF8B716E),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeBadge(type: item.transactionType),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 6),
                    _LockedPendingBadge(),
                  ] else if (item.hasAdjustments) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Đã có ${item.adjustmentCount} bù trừ • Ròng: ${formatSignedLedgerVnd(item.netAdjustedAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryGold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 155,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatSignedLedgerVnd(item.amount),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Số dư: ${AppFormatters.formatVnd(item.runningBalance)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: Color(0xFF58413F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 145,
              child: Align(
                alignment: Alignment.topRight,
                child: _buildSelectButton(item, isLocked, isSelected),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(List<LedgerHistoryItemModel> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isLocked = item.isLockedByPendingAdjustment;
        final isSelected = widget.selectedTransactionId == item.transactionId;
        final amountColor = item.amount > 0
            ? AppTheme.immutableLedgerTeal
            : (item.amount < 0
                ? const Color(0xFFBA1A1A)
                : const Color(0xFF58413F));

        return Opacity(
          opacity: isLocked ? 0.78 : 1,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryCrimson
                    : const Color(0xFFE6DFD8),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.transactionId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _TypeBadge(type: item.transactionType),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.formattedSolarDate} • ${item.formattedLunarDate}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF58413F),
                        ),
                      ),
                    ),
                    Text(
                      formatSignedLedgerVnd(item.amount),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                  ],
                ),
                if (isLocked) ...[
                  const SizedBox(height: 8),
                  _LockedPendingBadge(),
                ] else if (item.hasAdjustments) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Đã có ${item.adjustmentCount} bù trừ • Ròng: ${formatSignedLedgerVnd(item.netAdjustedAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryGold,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildSelectButton(item, isLocked, isSelected),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectButton(
    LedgerHistoryItemModel item,
    bool isLocked,
    bool isSelected,
  ) {
    if (isLocked) {
      return OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Giao dịch ${item.transactionId} đang có đề xuất chờ Trưởng tộc xử lý. Vui lòng chờ hoàn tất trước khi lập đề xuất mới.',
              ),
              backgroundColor: AppTheme.secondaryGold,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: const Color(0xFF8B716E),
          side: const BorderSide(color: Color(0xFFE6DFD8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Đang chờ duyệt',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (isSelected) {
      return OutlinedButton(
        onPressed: () => Navigator.of(context).pop(item),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppTheme.immutableLedgerTeal,
          backgroundColor: const Color(0xFFECFDF5),
          side: const BorderSide(color: Color(0xFF99F6E4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Đang chọn',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(item),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppTheme.primaryCrimson,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Chọn giao dịch',
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 40),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFFBA1A1A)),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(ledgerPickerProvider.notifier)
                  .loadLedger(showLoading: true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: AppTheme.primaryCrimson,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tải lại Sổ cái'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 42, color: Color(0xFF8B716E)),
            SizedBox(height: 10),
            Text(
              'Không tìm thấy giao dịch Sổ cái phù hợp',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Hãy thử xóa từ khóa tìm kiếm hoặc chọn bộ lọc "Tất cả".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF58413F)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final LedgerTransactionTypeEnum type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: type.badgeBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: type.badgeBorderColor),
      ),
      child: Text(
        type.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: type.badgeTextColor,
        ),
      ),
    );
  }
}

class _LockedPendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_clock_outlined, size: 14, color: Color(0xFFB8860B)),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              'Đang có đề xuất chờ duyệt (Khóa chọn)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB8860B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
