import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/advance_voucher_models.dart';
import '../providers/overdue_advance_providers.dart';

/// Hộp thoại đôn đốc thu hồi khoản tạm ứng quá hạn nộp chứng từ (US-48).
/// Cung cấp mẫu thông điệp trang trọng, đúng mực gia tộc để Thủ quỹ và BTC gửi nhắc nhở.
class UrgeSettlementDialog extends ConsumerStatefulWidget {
  final AdvanceVoucherModel voucher;
  final String? eventId;
  final VoidCallback? onSent;

  const UrgeSettlementDialog({
    super.key,
    required this.voucher,
    this.eventId,
    this.onSent,
  });

  static Future<bool?> show(
    BuildContext context, {
    required AdvanceVoucherModel voucher,
    String? eventId,
    VoidCallback? onSent,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => UrgeSettlementDialog(
        voucher: voucher,
        eventId: eventId,
        onSent: onSent,
      ),
    );
  }

  @override
  ConsumerState<UrgeSettlementDialog> createState() =>
      _UrgeSettlementDialogState();
}

class _UrgeSettlementDialogState extends ConsumerState<UrgeSettlementDialog> {
  late final TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;
    final recipientName = v.recipientMemberName ?? v.recipientMemberId;
    final taskTitle = v.taskName ?? v.taskId;
    final overdueText = v.overdueDays > 0 ? '${v.overdueDays} ngày' : 'hôm nay';

    _messageController = TextEditingController(
      text:
          'Kính gửi anh/chị $recipientName, khoản tạm ứng kinh phí ${v.formattedAdvanceAmount} cho hạng mục "$taskTitle" đã quá hạn nộp chứng từ đối soát $overdueText (hạn chót: ${v.formattedSettlementDeadline}). Ban Tổ Chức và Thủ quỹ trân trọng đề nghị anh/chị khẩn trương nộp hóa đơn/biên lai đối soát hoặc hoàn trả kinh phí còn dư để hoàn tất quyết toán sự kiện.',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendReminder() async {
    setState(() => _isSending = true);
    final text = _messageController.text.trim();

    try {
      await ref
          .read(overdueAdvanceListProvider(widget.eventId).notifier)
          .sendReminder(
            widget.voucher.advanceVoucherId,
            customMessage: text.isNotEmpty ? text : null,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onSent?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã gửi thông báo đôn đốc thu hồi tới ${widget.voucher.recipientMemberName ?? widget.voucher.recipientMemberId} thành công!',
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
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi đôn đốc: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.voucher;
    final recipientName = v.recipientMemberName ?? v.recipientMemberId;

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
              color: const Color(0xFFFFDAD6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Icon(
              Icons.notification_important_rounded,
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
                  'Đôn Đốc Quyết Toán Tạm Ứng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1610),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gửi lời nhắc thu hồi chứng từ và hoàn ứng',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B5E55),
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
            // Tóm tắt khoản nợ tạm ứng
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Người nhận:',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF6B5E55)),
                      ),
                      Flexible(
                        child: Text(
                          recipientName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1610),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số tiền tạm ứng:',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF6B5E55)),
                      ),
                      Text(
                        v.formattedAdvanceAmount,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hạn quyết toán:',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF6B5E55)),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            v.formattedSettlementDeadline,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1610),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBA1A1A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              v.overdueDurationText,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Nội dung tin nhắn đôn đốc
            const Text(
              'Nội dung thông điệp đôn đốc:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1610),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung nhắc nhở...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
              ),
              style: const TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy Bỏ', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _sendReminder,
          icon: _isSending
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 15),
          label: Text(_isSending ? 'Đang gửi...' : 'Gửi Đôn Đốc Ngay'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryCrimson,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
