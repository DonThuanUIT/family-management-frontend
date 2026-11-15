import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/advance_voucher_models.dart';
import '../providers/advance_voucher_providers.dart';

/// Hộp thoại xác nhận đã giải ngân kinh phí dành riêng cho Thủ quỹ sự kiện (US-46).
class ConfirmDisbursementDialog extends ConsumerStatefulWidget {
  final AdvanceVoucherModel voucher;

  const ConfirmDisbursementDialog({
    super.key,
    required this.voucher,
  });

  static Future<AdvanceVoucherModel?> show(
    BuildContext context, {
    required AdvanceVoucherModel voucher,
  }) {
    return showDialog<AdvanceVoucherModel>(
      context: context,
      builder: (_) => ConfirmDisbursementDialog(voucher: voucher),
    );
  }

  @override
  ConsumerState<ConfirmDisbursementDialog> createState() =>
      _ConfirmDisbursementDialogState();
}

class _ConfirmDisbursementDialogState
    extends ConsumerState<ConfirmDisbursementDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notesController.text =
        'Đã hoàn tất bàn giao tiền tạm ứng cho ${widget.voucher.recipientMemberName ?? widget.voucher.recipientMemberId}.';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _isSubmitting = true);
    final notes = _notesController.text.trim();

    try {
      final updated = await ref
          .read(taskAdvanceVouchersProvider(widget.voucher.taskId).notifier)
          .confirmDisbursement(
            widget.voucher.advanceVoucherId,
            notes: notes.isNotEmpty ? notes : null,
          );

      if (mounted) {
        Navigator.of(context).pop(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Thủ quỹ đã xác nhận giải ngân thành công ${AppFormatters.formatVnd(widget.voucher.advanceAmount)}!',
            ),
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xác nhận giải ngân: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voucher = widget.voucher;
    final recipientName =
        voucher.recipientMemberName ?? voucher.recipientMemberId;

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
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6EE7B7)),
            ),
            child: const Icon(
              Icons.paid_outlined,
              color: Color(0xFF047857),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xác Nhận Đã Giải Ngân',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1610),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Thủ quỹ sự kiện xác nhận giao tiền',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin phiếu tạm ứng
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E4DF)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mã phiếu:',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5E55)),
                      ),
                      Text(
                        voucher.advanceVoucherId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Người nhận:',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5E55)),
                      ),
                      Text(
                        recipientName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1610),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số tiền giải ngân:',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5E55)),
                      ),
                      Text(
                        AppFormatters.formatVnd(voucher.advanceAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Ghi chú giải ngân (VietQR / Tiền mặt)
            const Text(
              'Ghi chú giải ngân (Hình thức giao tiền):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1610),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    'Ví dụ: Đã chuyển khoản VietQR / Giao tiền mặt tại từ đường...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Hủy',
            style: TextStyle(color: Color(0xFF6B5E55)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _confirm,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_rounded, size: 16),
          label: Text(_isSubmitting ? 'Đang xử lý...' : 'Xác Nhận Đã Giải Ngân'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF047857),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
