import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/common_fund_disbursement_models.dart';
import '../providers/ledger_adjustment_providers.dart';

const List<String> _kApproveDisbursementChips = [
  'Phê duyệt chi Quỹ chung theo đúng dự toán và biên bản thẩm định.',
  'Đồng ý xuất quỹ thực hiện việc lớn của dòng họ.',
];

const List<String> _kRejectDisbursementChips = [
  'Thiếu hóa đơn, dự toán hoặc biên bản nghiệm thu đính kèm.',
  'Số liệu dự toán chưa hợp lý; đề nghị điều chỉnh lại định mức.',
  'Cần hoàn thiện thêm hồ sơ người thụ hưởng trước khi trình ký lại.',
];

typedef DisbursementReviewSubmitCallback
    = Future<ReviewCommonFundDisbursementResponseModel> Function({
  String? confirmPassword,
  String? rejectionReason,
  String? description,
});

/// Hộp thoại Ký duyệt chi Quỹ chung kèm xác thực lớp 2 bằng Mật khẩu Trưởng tộc (US-60).
class ApproveDisbursementPasswordDialog extends StatefulWidget {
  final CommonFundDisbursementModel request;
  final double availableBalance;
  final DisbursementReviewSubmitCallback onConfirm;

  const ApproveDisbursementPasswordDialog({
    super.key,
    required this.request,
    required this.availableBalance,
    required this.onConfirm,
  });

  static Future<ReviewCommonFundDisbursementResponseModel?> show(
    BuildContext context, {
    required CommonFundDisbursementModel request,
    required double availableBalance,
    required DisbursementReviewSubmitCallback onConfirm,
  }) {
    return showDialog<ReviewCommonFundDisbursementResponseModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ApproveDisbursementPasswordDialog(
        request: request,
        availableBalance: availableBalance,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ApproveDisbursementPasswordDialog> createState() =>
      _ApproveDisbursementPasswordDialogState();
}

class _ApproveDisbursementPasswordDialogState
    extends State<ApproveDisbursementPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pwd = _passwordController.text.trim();
    if (pwd.isEmpty) {
      setState(() {
        _errorMessage =
            'Mật khẩu xác nhận không được để trống khi phê duyệt chi Quỹ chung.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final desc = _descController.text.trim();
      final result = await widget.onConfirm(
        confirmPassword: pwd,
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
    final projected = widget.availableBalance - widget.request.amount;
    final hasPassword = _passwordController.text.trim().isNotEmpty;

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
              Icons.lock_outline_rounded,
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
                  'Ký Duyệt Chi & Xác Thực Mật Khẩu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                Text(
                  'Trưởng tộc nhập mật khẩu tài khoản để xuất Quỹ chung & ghi Sổ cái SHA-256',
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
                    _DialogSummaryLine(
                      label: 'Mã phiếu chi:',
                      value: widget.request.requestId,
                      isMonospace: true,
                    ),
                    const SizedBox(height: 6),
                    _DialogSummaryLine(
                      label: 'Số tiền xuất Quỹ chung:',
                      value: '−${AppFormatters.formatVnd(widget.request.amount)}',
                      valueColor: const Color(0xFFBA1A1A),
                      isMonospace: true,
                    ),
                    const Divider(height: 18, color: Color(0xFFE6DFD8)),
                    _DialogSummaryLine(
                      label: 'Số dư Quỹ mới sau chi:',
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
                  'Xác thực lớp 2 bắt buộc: Sau khi xác nhận mật khẩu đúng, hệ thống sẽ ghi bút toán chi bất biến vào Sổ cái (SHA-256) và không thể hoàn tác.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF58413F),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Mật khẩu tài khoản Trưởng tộc *',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1A),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const Key('approve_disbursement_password_input'),
                controller: _passwordController,
                enabled: !_submitting,
                obscureText: _obscurePassword,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  } else {
                    setState(() {});
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Nhập mật khẩu tài khoản để ký duyệt...',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF8B716E),
                  ),
                  prefixIcon: const Icon(
                    Icons.key_outlined,
                    size: 19,
                    color: Color(0xFF58413F),
                  ),
                  suffixIcon: IconButton(
                    key: const Key('toggle_approve_password_visibility'),
                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 19,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryCrimson,
                      width: 1.8,
                    ),
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
                children: _kApproveDisbursementChips
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
                key: const Key('approve_disbursement_description_input'),
                controller: _descController,
                enabled: !_submitting,
                maxLines: 2,
                maxLength: 2000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'Bỏ trống nếu muốn hệ thống tự động ghép diễn giải từ tiêu đề và mục đích phiếu chi...',
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
                  key: const Key('approve_disbursement_error_box'),
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
                'Quay lại',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              key: const Key('confirm_approve_disbursement_button'),
              onPressed: (!_submitting && hasPassword) ? _submit : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: AppTheme.primaryCrimson,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE3E2E0),
                disabledForegroundColor: const Color(0xFF8B716E),
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
                  : const Icon(Icons.verified_user_outlined, size: 18),
              label: Text(
                _submitting
                    ? 'Đang xác thực...'
                    : 'Xác Thực & Phê Duyệt Chi',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Hộp thoại Từ chối Đề xuất Chi Quỹ chung (bắt buộc nhập `rejectionReason`, US-60).
class RejectDisbursementDialog extends StatefulWidget {
  final CommonFundDisbursementModel request;
  final DisbursementReviewSubmitCallback onConfirm;

  const RejectDisbursementDialog({
    super.key,
    required this.request,
    required this.onConfirm,
  });

  static Future<ReviewCommonFundDisbursementResponseModel?> show(
    BuildContext context, {
    required CommonFundDisbursementModel request,
    required DisbursementReviewSubmitCallback onConfirm,
  }) {
    return showDialog<ReviewCommonFundDisbursementResponseModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RejectDisbursementDialog(
        request: request,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<RejectDisbursementDialog> createState() =>
      _RejectDisbursementDialogState();
}

class _RejectDisbursementDialogState extends State<RejectDisbursementDialog> {
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
                  'Từ Chối Đề Xuất Chi Quỹ Chung',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                Text(
                  'Bắt buộc ghi rõ lý do để người lập hoàn thiện hoặc đối chiếu',
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
                child: _DialogSummaryLine(
                  label: 'Phiếu bị từ chối:',
                  value:
                      '${widget.request.requestId} (−${AppFormatters.formatVnd(widget.request.amount)})',
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
                children: _kRejectDisbursementChips
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
                key: const Key('reject_disbursement_reason_input'),
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
              key: const Key('confirm_reject_disbursement_button'),
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

class _DialogSummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isMonospace;
  final bool boldLabel;

  const _DialogSummaryLine({
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
