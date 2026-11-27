import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/files/member_file_actions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../../../core/widgets/adaptive_modal.dart';
import '../../data/datasources/ledger_remote_datasource.dart';
import '../../data/models/common_fund_disbursement_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/common_fund_disbursement_repository_impl.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../providers/common_fund_disbursement_providers.dart';
import '../providers/ledger_adjustment_providers.dart';

/// Thẻ đối chiếu Số dư Quỹ chung theo thời gian thực (`GET /api/v1/ledger/balance`, US-60).
class DisbursementBalanceImpactCard extends StatelessWidget {
  final CommonFundBalanceModel balance;
  final double proposedAmount;

  const DisbursementBalanceImpactCard({
    super.key,
    required this.balance,
    required this.proposedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final available = balance.availableBalance;
    final pendingSum = balance.pendingDisbursementAmount;
    final projected = available - proposedAmount;
    final freeAfterPending = available - pendingSum;

    final isOverAvailable = projected < 0;
    final isExceedPendingBuffer = !isOverAvailable &&
        pendingSum > 0 &&
        proposedAmount > 0 &&
        proposedAmount > freeAfterPending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverAvailable ? const Color(0xFFFFF8F8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverAvailable
              ? const Color(0xFFBA1A1A)
              : const Color(0xFFE6DFD8),
          width: isOverAvailable ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Đối Chiếu Quỹ Chung Hiện Có',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: const Text(
                  'Chính xác từng đồng',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF58413F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _MetricLine(
            label: 'Số dư Quỹ khả dụng:',
            value: AppFormatters.formatVnd(available),
            valueColor: const Color(0xFF1A1C1A),
          ),
          const SizedBox(height: 8),
          _MetricLine(
            label: 'Các phiếu khác đang chờ duyệt:',
            value: AppFormatters.formatVnd(pendingSum),
            valueColor: AppTheme.secondaryGold,
          ),
          const SizedBox(height: 8),
          _MetricLine(
            label: 'Đề xuất chi lần này:',
            value: proposedAmount > 0
                ? '−${AppFormatters.formatVnd(proposedAmount)}'
                : AppFormatters.formatVnd(0),
            valueColor: proposedAmount > 0
                ? const Color(0xFFBA1A1A)
                : const Color(0xFF58413F),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isOverAvailable
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOverAvailable
                    ? const Color(0xFFFECACA)
                    : const Color(0xFF99F6E4),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Số dư dự kiến sau chi:',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppFormatters.formatVnd(projected),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: isOverAvailable
                          ? const Color(0xFFBA1A1A)
                          : AppTheme.immutableLedgerTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isOverAvailable) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('disbursement_overdraft_warning'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBA1A1A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFBA1A1A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không thể lập phiếu: Số tiền đề xuất (${AppFormatters.formatVnd(proposedAmount)}) vượt quá Số dư Quỹ khả dụng (${AppFormatters.formatVnd(available)}).',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF93000A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isExceedPendingBuffer) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('disbursement_pending_buffer_warning'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.secondaryGold,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lưu ý: Nếu các phiếu đang chờ (${AppFormatters.formatVnd(pendingSum)}) được duyệt hết trước, số dư còn lại (${AppFormatters.formatVnd(freeAfterPending)}) sẽ không đủ cho phiếu này.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF58413F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hộp thoại xác nhận trước khi tải lên chứng từ (Deferred Upload) & gửi Đề xuất chi Quỹ chung (US-60).
class ProposeDisbursementConfirmDialog extends ConsumerStatefulWidget {
  final String title;
  final CommonFundExpenseCategoryEnum category;
  final double amount;
  final String? beneficiaryName;
  final String? beneficiaryMemberId;
  final String beneficiaryDisplay;
  final String purpose;
  final double projectedBalance;
  final SelectedEvidenceFile? selectedFile;
  final String? externalAttachmentUrl;

  const ProposeDisbursementConfirmDialog({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    this.beneficiaryName,
    this.beneficiaryMemberId,
    required this.beneficiaryDisplay,
    required this.purpose,
    required this.projectedBalance,
    this.selectedFile,
    this.externalAttachmentUrl,
  });

  static Future<CommonFundDisbursementModel?> show(
    BuildContext context, {
    required String title,
    required CommonFundExpenseCategoryEnum category,
    required double amount,
    String? beneficiaryName,
    String? beneficiaryMemberId,
    required String beneficiaryDisplay,
    required String purpose,
    required double projectedBalance,
    SelectedEvidenceFile? selectedFile,
    String? externalAttachmentUrl,
  }) {
    return showDialog<CommonFundDisbursementModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProposeDisbursementConfirmDialog(
        title: title,
        category: category,
        amount: amount,
        beneficiaryName: beneficiaryName,
        beneficiaryMemberId: beneficiaryMemberId,
        beneficiaryDisplay: beneficiaryDisplay,
        purpose: purpose,
        projectedBalance: projectedBalance,
        selectedFile: selectedFile,
        externalAttachmentUrl: externalAttachmentUrl,
      ),
    );
  }

  @override
  ConsumerState<ProposeDisbursementConfirmDialog> createState() =>
      _ProposeDisbursementConfirmDialogState();
}

class _ProposeDisbursementConfirmDialogState
    extends ConsumerState<ProposeDisbursementConfirmDialog> {
  bool _isSubmitting = false;
  String _statusText = '';
  String? _errorMessage;

  Future<void> _confirmAndSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      String? resolvedAttachmentUrl = widget.externalAttachmentUrl?.trim();
      if (widget.selectedFile != null) {
        if (mounted) {
          setState(() => _statusText = 'Đang tải lên tài liệu chứng từ...');
        }
        final uploaded = await ref.read(ledgerRepositoryProvider).uploadEvidence(
              bytes: widget.selectedFile!.bytes,
              filename: widget.selectedFile!.name,
            );
        resolvedAttachmentUrl = uploaded.evidenceUrl;
      }

      if (mounted) {
        setState(() => _statusText = 'Đang gửi đề xuất chi Quỹ chung...');
      }

      final created = await ref
          .read(commonFundDisbursementRepositoryProvider)
          .proposeDisbursement(
            ProposeCommonFundDisbursementRequestDto(
              title: widget.title.trim(),
              category: widget.category,
              amount: widget.amount,
              beneficiaryName: widget.beneficiaryName,
              beneficiaryMemberId: widget.beneficiaryMemberId,
              purpose: widget.purpose.trim(),
              attachmentUrl:
                  resolvedAttachmentUrl != null && resolvedAttachmentUrl.isNotEmpty
                      ? resolvedAttachmentUrl
                      : null,
            ),
          );

      if (mounted) {
        Navigator.of(context).pop(created);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _statusText = '';
          _errorMessage = formatLedgerFailure(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.selectedFile != null;
    final hasUrl = widget.externalAttachmentUrl != null &&
        widget.externalAttachmentUrl!.trim().isNotEmpty;
    final evidenceLabel = hasFile
        ? '${widget.selectedFile!.name} (${widget.selectedFile!.formattedSize})'
        : (hasUrl ? widget.externalAttachmentUrl!.trim() : 'Không đính kèm');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Icon(
              Icons.request_quote_outlined,
              color: AppTheme.primaryCrimson,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xác Nhận Gửi Đề Xuất Chi Quỹ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                Text(
                  'Kiểm tra kỹ thông tin trước khi trình Trưởng tộc ký duyệt',
                  style: TextStyle(fontSize: 12, color: Color(0xFF58413F)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MetricLine(
                      label: 'Danh mục:',
                      value: widget.category.displayName,
                      valueColor: const Color(0xFF1A1C1A),
                      isMonospace: false,
                    ),
                    const SizedBox(height: 6),
                    _MetricLine(
                      label: 'Tiêu đề:',
                      value: widget.title.trim(),
                      valueColor: const Color(0xFF1A1C1A),
                      isMonospace: false,
                    ),
                    const SizedBox(height: 6),
                    _MetricLine(
                      label: 'Thụ hưởng:',
                      value: widget.beneficiaryDisplay,
                      valueColor: const Color(0xFF1A1C1A),
                      isMonospace: false,
                    ),
                    const Divider(height: 18, color: Color(0xFFE6DFD8)),
                    _MetricLine(
                      label: 'Số tiền xin chi:',
                      value: '−${AppFormatters.formatVnd(widget.amount)}',
                      valueColor: const Color(0xFFBA1A1A),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '(${VietnameseMoneyConverter.toWords(widget.amount)})',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF58413F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MetricLine(
                      label: 'Quỹ dự kiến sau chi:',
                      value: AppFormatters.formatVnd(widget.projectedBalance),
                      valueColor: AppTheme.immutableLedgerTeal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'MỤC ĐÍCH CHI QUỸ CHUNG',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF58413F),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Text(
                  widget.purpose.trim(),
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF1A1C1A)),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'CHỨNG TỪ ĐÍNH KÈM',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF58413F),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Text(
                  evidenceLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
              ),

              if (_isSubmitting && _statusText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryCrimson,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryCrimson,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBA1A1A),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text(
                'Kiểm tra lại',
                style: TextStyle(
                  color: Color(0xFF58413F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              key: const Key('confirm_submit_disbursement_button'),
              onPressed: _isSubmitting ? null : _confirmAndSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: AppTheme.primaryCrimson,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 17),
              label: Text(
                _isSubmitting ? 'Đang gửi...' : 'Xác Nhận Gửi Phiếu Chi',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Modal / Sheet xem lịch sử các Đề xuất chi Quỹ chung (`GET /api/v1/ledger/disbursements`).
class DisbursementHistorySheet extends ConsumerWidget {
  const DisbursementHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showAdaptiveSheetOrDialog<void>(
      context: context,
      maxDesktopWidth: 780,
      maxDesktopHeightFactor: 0.88,
      builder: (_) => const DisbursementHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commonFundOverviewProvider);
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
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE6DFD8))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lịch Sử Đề Xuất Chi Quỹ Chung',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Theo dõi trạng thái ký duyệt của Trưởng tộc',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF58413F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => ref
                        .read(commonFundOverviewProvider.notifier)
                        .loadOverview(showLoading: true),
                    icon: const Icon(Icons.refresh, color: Color(0xFF58413F)),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF1A1C1A)),
                  ),
                ],
              ),
            ),

            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildFilterChip(
                    label: 'Tất cả (${state.items.length})',
                    selected: state.statusFilter == null,
                    onTap: () => ref
                        .read(commonFundOverviewProvider.notifier)
                        .setStatusFilter(null),
                  ),
                  ...CommonFundDisbursementStatusEnum.values.map((status) {
                    final count = state.items
                        .where((e) => e.approvalStatus == status)
                        .length;
                    final shortLabel = switch (status) {
                      CommonFundDisbursementStatusEnum.pending => 'Chờ duyệt',
                      CommonFundDisbursementStatusEnum.approved => 'Đã duyệt',
                      CommonFundDisbursementStatusEnum.rejected => 'Từ chối',
                    };
                    return _buildFilterChip(
                      label: '$shortLabel ($count)',
                      selected: state.statusFilter == status,
                      onTap: () => ref
                          .read(commonFundOverviewProvider.notifier)
                          .setStatusFilter(status),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE6DFD8)),

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
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              state.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFBA1A1A)),
                            ),
                          ),
                        )
                      : state.filteredItems.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'Chưa có đề xuất chi Quỹ chung nào trong danh sách.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF58413F),
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.filteredItems.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, idx) => _DisbursementHistoryCard(
                                item: state.filteredItems[idx],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF58413F),
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppTheme.primaryCrimson,
      backgroundColor: const Color(0xFFFAF9F6),
      side: BorderSide(
        color: selected ? AppTheme.primaryCrimson : const Color(0xFFE6DFD8),
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _DisbursementHistoryCard extends ConsumerStatefulWidget {
  final CommonFundDisbursementModel item;
  const _DisbursementHistoryCard({required this.item});

  @override
  ConsumerState<_DisbursementHistoryCard> createState() =>
      _DisbursementHistoryCardState();
}

class _DisbursementHistoryCardState
    extends ConsumerState<_DisbursementHistoryCard> {
  bool _downloading = false;

  Future<void> _downloadAttachment(String url, String fileName) async {
    setState(() => _downloading = true);
    try {
      final bytes =
          await ref.read(ledgerRepositoryProvider).downloadEvidenceBytes(url);
      if (!mounted) return;
      final lower = fileName.toLowerCase();
      final mime = lower.endsWith('.pdf')
          ? 'application/pdf'
          : (lower.endsWith('.png') ? 'image/png' : 'image/jpeg');
      final saved =
          await ref.read(memberFileActionsProvider).save(bytes, fileName, mime);
      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tải xuống chứng từ $fileName'),
            backgroundColor: AppTheme.immutableLedgerTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở chứng từ: ${formatLedgerFailure(e)}'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final internalName = LedgerRemoteDataSourceImpl
        .extractInternalEvidenceFilename(item.attachmentUrl);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE6DFD8)),
                    ),
                    child: Text(
                      item.requestId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item.category.badgeBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: item.category.badgeBorderColor),
                    ),
                    child: Text(
                      item.category.displayName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: item.category.badgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.approvalStatus.badgeBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: item.approvalStatus.badgeBorderColor),
                ),
                child: Text(
                  item.approvalStatus.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.approvalStatus.badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '−${AppFormatters.formatVnd(item.amount)}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBA1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Thụ hưởng: ${item.beneficiaryName ?? '—'} • ${item.formattedCreatedAt}',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
          ),

          if (internalName != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _downloading
                  ? null
                  : () =>
                      _downloadAttachment(item.attachmentUrl!, internalName),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 42),
                foregroundColor: AppTheme.primaryCrimson,
                side: const BorderSide(color: Color(0xFFE6DFD8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _downloading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attachment_rounded, size: 17),
              label: Text(
                _downloading ? 'Đang tải...' : 'Tải chứng từ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          if (item.rejectionReason != null &&
              item.rejectionReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'Lý do từ chối: ${item.rejectionReason}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF93000A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isMonospace;

  const _MetricLine({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isMonospace = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF58413F)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: isMonospace ? 'monospace' : null,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
