import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../providers/ledger_adjustment_providers.dart';

const List<String> _kApproveDescriptionChips = [
  'Phê duyệt theo biên bản đối soát thực tế của Ban Tổ Chức.',
  'Đồng ý ghi nhận bút toán bù trừ vào Sổ cái Quỹ chung.',
];

const List<String> _kRejectReasonChips = [
  'Thiếu biên bản hoặc hóa đơn chứng từ gốc kèm theo.',
  'Số liệu đối chiếu chưa khớp với sao kê ngân hàng.',
  'Cần họp Ban Thường Trực dòng họ thống nhất trước khi điều chỉnh.',
];

typedef ReviewSubmitCallback = Future<ReviewLedgerAdjustmentResponseModel>
    Function({
  String? description,
  String? rejectionReason,
});

/// Hộp thoại Xác nhận Phê duyệt & Ghi bút toán Sổ cái bất biến (US-59).
class ApproveLedgerAdjustmentDialog extends StatefulWidget {
  final LedgerAdjustmentRequestModel request;
  final double currentFundBalance;
  final ReviewSubmitCallback onConfirm;

  const ApproveLedgerAdjustmentDialog({
    super.key,
    required this.request,
    required this.currentFundBalance,
    required this.onConfirm,
  });

  static Future<ReviewLedgerAdjustmentResponseModel?> show(
    BuildContext context, {
    required LedgerAdjustmentRequestModel request,
    required double currentFundBalance,
    required ReviewSubmitCallback onConfirm,
  }) {
    return showDialog<ReviewLedgerAdjustmentResponseModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ApproveLedgerAdjustmentDialog(
        request: request,
        currentFundBalance: currentFundBalance,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ApproveLedgerAdjustmentDialog> createState() =>
      _ApproveLedgerAdjustmentDialogState();
}

class _ApproveLedgerAdjustmentDialogState
    extends State<ApproveLedgerAdjustmentDialog> {
  final TextEditingController _descController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final desc = _descController.text.trim();
      final result = await widget.onConfirm(
        description: desc.isEmpty ? null : desc,
      );
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = formatLedgerFailure(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projected =
        widget.currentFundBalance + widget.request.proposedAdjustmentAmount;
    final amtColor = widget.request.proposedAdjustmentAmount >= 0
        ? AppTheme.immutableLedgerTeal
        : const Color(0xFFBA1A1A);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppTheme.immutableLedgerTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xác Nhận Phê Duyệt & Ghi Sổ Cái',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                Text(
                  'Bút toán sau khi ghi vào Sổ cái bất biến không thể sửa hay xóa',
                  style: TextStyle(fontSize: 12, color: Color(0xFF58413F)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                  children: [
                    _DialogSummaryRow(
                      label: 'Mã đề xuất:',
                      value: widget.request.requestId,
                      isMonospace: true,
                    ),
                    const SizedBox(height: 6),
                    _DialogSummaryRow(
                      label: 'Khoản bù trừ:',
                      value: formatSignedLedgerVnd(
                        widget.request.proposedAdjustmentAmount,
                      ),
                      valueColor: amtColor,
                      isMonospace: true,
                    ),
                    const Divider(height: 18, color: Color(0xFFE6DFD8)),
                    _DialogSummaryRow(
                      label: 'Số dư Quỹ mới sau ghi sổ:',
                      value: AppFormatters.formatVnd(projected),
                      valueColor: AppTheme.immutableLedgerTeal,
                      isMonospace: true,
                      boldLabel: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'Lưu ý bảo mật Sổ cái bất biến (SHA-256): Hệ thống sẽ tạo một bút toán mới và nối vào chuỗi băm của dòng họ. Sau khi xác nhận không thể hủy bỏ.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF58413F),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Diễn giải bút toán Sổ cái (Tùy chọn)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                  ),
                  Text(
                    '${_descController.text.length} / 2000',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF58413F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _kApproveDescriptionChips
                    .map(
                      (chip) => ActionChip(
                        label: Text(
                          chip,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF58413F),
                          ),
                        ),
                        backgroundColor: const Color(0xFFFAF9F6),
                        side: const BorderSide(color: Color(0xFFE6DFD8)),
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                  _descController.value = TextEditingValue(
                                    text: chip,
                                    selection: TextSelection.collapsed(
                                      offset: chip.length,
                                    ),
                                  );
                                }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),

              TextField(
                key: const Key('approve_description_input'),
                controller: _descController,
                enabled: !_submitting,
                maxLines: 3,
                maxLength: 2000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'Bỏ trống nếu muốn hệ thống tự động ghép diễn giải từ lý do của Thủ quỹ...',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF8B716E),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                  ),
                ),
              ),

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
            OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: const Color(0xFF1A1C1A),
                side: const BorderSide(color: Color(0xFFDFD8D0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Quay lại kiểm tra',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              key: const Key('confirm_approve_adjustment_button'),
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: AppTheme.primaryCrimson,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _submitting
                    ? 'Đang niêm phong...'
                    : 'Xác Nhận Phê Duyệt & Ghi Sổ Cái',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Hộp thoại Từ chối Đề xuất Bù trừ (bắt buộc nhập `rejectionReason`, US-59).
class RejectLedgerAdjustmentDialog extends StatefulWidget {
  final LedgerAdjustmentRequestModel request;
  final ReviewSubmitCallback onConfirm;

  const RejectLedgerAdjustmentDialog({
    super.key,
    required this.request,
    required this.onConfirm,
  });

  static Future<ReviewLedgerAdjustmentResponseModel?> show(
    BuildContext context, {
    required LedgerAdjustmentRequestModel request,
    required ReviewSubmitCallback onConfirm,
  }) {
    return showDialog<ReviewLedgerAdjustmentResponseModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RejectLedgerAdjustmentDialog(
        request: request,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<RejectLedgerAdjustmentDialog> createState() =>
      _RejectLedgerAdjustmentDialogState();
}

class _RejectLedgerAdjustmentDialogState
    extends State<RejectLedgerAdjustmentDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _appendChip(String chip) {
    final current = _reasonController.text.trim();
    String next;
    if (current.isEmpty) {
      next = chip;
    } else if (current.contains(chip)) {
      return;
    } else {
      next = '$current $chip';
    }
    if (next.length > 2000) {
      next = next.substring(0, 2000);
    }
    setState(() {
      _reasonController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.length < 5) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.onConfirm(rejectionReason: reason);
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = formatLedgerFailure(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmedLen = _reasonController.text.trim().length;
    final isValid = trimmedLen >= 5 && trimmedLen <= 2000;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Icon(
              Icons.highlight_off_rounded,
              color: Color(0xFFBA1A1A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Từ Chối Đề Xuất Bù Trừ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                Text(
                  'Bắt buộc ghi rõ lý do để Thủ quỹ đối chiếu hoặc lập lại đề xuất',
                  style: TextStyle(fontSize: 12, color: Color(0xFF58413F)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: _DialogSummaryRow(
                  label: 'Đề xuất bị từ chối:',
                  value:
                      '${widget.request.requestId} (${formatSignedLedgerVnd(widget.request.proposedAdjustmentAmount)})',
                  isMonospace: true,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lý do từ chối *',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                  ),
                  Text(
                    '${_reasonController.text.length} / 2000',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF58413F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _kRejectReasonChips
                    .map(
                      (chip) => ActionChip(
                        label: Text(
                          chip,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF58413F),
                          ),
                        ),
                        backgroundColor: const Color(0xFFFAF9F6),
                        side: const BorderSide(color: Color(0xFFE6DFD8)),
                        onPressed:
                            _submitting ? null : () => _appendChip(chip),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),

              TextField(
                key: const Key('reject_reason_input'),
                controller: _reasonController,
                enabled: !_submitting,
                maxLines: 3,
                maxLength: 2000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'Nhập tối thiểu 5 ký tự giải thích rõ lý do từ chối...',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF8B716E),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFBA1A1A),
                      width: 1.6,
                    ),
                  ),
                ),
              ),

              if (!isValid) ...[
                const SizedBox(height: 6),
                const Text(
                  'Bắt buộc nhập lý do từ chối (tối thiểu 5 ký tự).',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBA1A1A),
                  ),
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
            OutlinedButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: const Color(0xFF1A1C1A),
                side: const BorderSide(color: Color(0xFFDFD8D0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hủy bỏ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              key: const Key('confirm_reject_adjustment_button'),
              onPressed: (!_submitting && isValid) ? _submit : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE3E2E0),
                disabledForegroundColor: const Color(0xFF8B716E),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.close_rounded, size: 18),
              label: Text(
                _submitting ? 'Đang xử lý...' : 'Xác Nhận Từ Chối',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DialogSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isMonospace;
  final bool boldLabel;

  const _DialogSummaryRow({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF1A1C1A),
    this.isMonospace = false,
    this.boldLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: boldLabel ? FontWeight.bold : FontWeight.normal,
              color: boldLabel
                  ? const Color(0xFF1A1C1A)
                  : const Color(0xFF58413F),
            ),
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
