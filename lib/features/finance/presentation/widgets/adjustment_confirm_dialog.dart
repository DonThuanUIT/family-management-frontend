import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../providers/ledger_adjustment_providers.dart';

/// Hộp thoại Xác nhận trước khi upload biên bản và gửi Đề xuất bù trừ (US-15).
class AdjustmentConfirmDialog extends ConsumerStatefulWidget {
  final LedgerHistoryItemModel transaction;
  final double signedAmount;
  final double projectedFundBalance;
  final String adjustmentReason;
  final SelectedEvidenceFile? selectedFile;
  final String? externalEvidenceUrl;

  const AdjustmentConfirmDialog({
    super.key,
    required this.transaction,
    required this.signedAmount,
    required this.projectedFundBalance,
    required this.adjustmentReason,
    this.selectedFile,
    this.externalEvidenceUrl,
  });

  static Future<LedgerAdjustmentRequestModel?> show(
    BuildContext context, {
    required LedgerHistoryItemModel transaction,
    required double signedAmount,
    required double projectedFundBalance,
    required String adjustmentReason,
    SelectedEvidenceFile? selectedFile,
    String? externalEvidenceUrl,
  }) {
    return showDialog<LedgerAdjustmentRequestModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdjustmentConfirmDialog(
        transaction: transaction,
        signedAmount: signedAmount,
        projectedFundBalance: projectedFundBalance,
        adjustmentReason: adjustmentReason,
        selectedFile: selectedFile,
        externalEvidenceUrl: externalEvidenceUrl,
      ),
    );
  }

  @override
  ConsumerState<AdjustmentConfirmDialog> createState() =>
      _AdjustmentConfirmDialogState();
}

class _AdjustmentConfirmDialogState
    extends ConsumerState<AdjustmentConfirmDialog> {
  bool _isSubmitting = false;
  String _statusText = '';
  String? _errorMessage;

  String _spokenWords(double signedAmount) {
    final absWords = VietnameseMoneyConverter.toWords(signedAmount.abs());
    final cleanAbs = absWords.isNotEmpty
        ? '${absWords[0].toLowerCase()}${absWords.substring(1)}'
        : 'không đồng chẵn';
    return signedAmount > 0
        ? 'Cộng (tăng quỹ) $cleanAbs'
        : 'Trừ (giảm quỹ) $cleanAbs';
  }

  Future<void> _confirmAndSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(ledgerRepositoryProvider);
      String? resolvedEvidenceUrl = widget.externalEvidenceUrl?.trim();

      if (widget.selectedFile != null) {
        if (mounted) {
          setState(() => _statusText = 'Đang tải lên biên bản chứng từ...');
        }
        final uploaded = await repo.uploadEvidence(
          bytes: widget.selectedFile!.bytes,
          filename: widget.selectedFile!.name,
          originalTransactionId: widget.transaction.transactionId,
        );
        resolvedEvidenceUrl = uploaded.evidenceUrl;
      }

      if (mounted) {
        setState(() => _statusText = 'Đang gửi đề xuất bù trừ...');
      }

      final created = await repo.proposeAdjustment(
        ProposeLedgerAdjustmentRequestDto(
          originalTransactionId: widget.transaction.transactionId,
          proposedAdjustmentAmount: widget.signedAmount,
          adjustmentReason: widget.adjustmentReason.trim(),
          evidenceAttachmentUrl:
              resolvedEvidenceUrl != null && resolvedEvidenceUrl.isNotEmpty
                  ? resolvedEvidenceUrl
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
    final hasUrl = widget.externalEvidenceUrl != null &&
        widget.externalEvidenceUrl!.trim().isNotEmpty;
    final hasEvidence = hasFile || hasUrl;

    final evidenceText = hasFile
        ? '${widget.selectedFile!.name} (${widget.selectedFile!.formattedSize})'
        : (hasUrl ? widget.externalEvidenceUrl!.trim() : 'Không đính kèm');

    final amtColor = widget.signedAmount >= 0
        ? AppTheme.immutableLedgerTeal
        : const Color(0xFFBA1A1A);

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
              Icons.fact_check_outlined,
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
                  'Xác Nhận Gửi Đề Xuất Bù Trừ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                Text(
                  'Kiểm tra kỹ số liệu trước khi trình Trưởng tộc phê duyệt',
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
                    _ConfirmRow(
                      label: 'Mã giao dịch gốc:',
                      value: widget.transaction.transactionId,
                      isMonospace: true,
                    ),
                    const SizedBox(height: 8),
                    _ConfirmRow(
                      label: 'Số tiền bù trừ:',
                      value: formatSignedLedgerVnd(widget.signedAmount),
                      valueColor: amtColor,
                      isMonospace: true,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '(${_spokenWords(widget.signedAmount)})',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF58413F),
                      ),
                    ),
                    const Divider(height: 18, color: Color(0xFFE6DFD8)),
                    _ConfirmRow(
                      label: 'Số dư Quỹ sau duyệt:',
                      value:
                          AppFormatters.formatVnd(widget.projectedFundBalance),
                      valueColor: AppTheme.immutableLedgerTeal,
                      isMonospace: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'NỘI DUNG GIẢI TRÌNH',
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
                  widget.adjustmentReason.trim(),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'BIÊN BẢN ĐÍNH KÈM',
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
                  evidenceText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
              ),

              if (!hasEvidence) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppTheme.secondaryGold,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chưa có biên bản đính kèm — Trưởng tộc có thể yêu cầu bổ sung chứng từ đối chiếu trước khi duyệt.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF58413F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
          key: const Key('confirm_submit_adjustment_button'),
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
            _isSubmitting ? 'Đang gửi...' : 'Xác Nhận & Gửi Đề Xuất',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isMonospace;

  const _ConfirmRow({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF1A1C1A),
    this.isMonospace = false,
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
        Text(
          value,
          style: TextStyle(
            fontFamily: isMonospace ? 'monospace' : null,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
