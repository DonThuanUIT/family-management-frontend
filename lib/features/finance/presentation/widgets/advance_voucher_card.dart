import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../data/models/advance_voucher_models.dart';
import 'confirm_disbursement_dialog.dart';

/// Thẻ hiển thị một phiếu tạm ứng sự kiện (US-46).
/// Tích hợp nút "Xác nhận đã giải ngân" dành riêng cho Thủ quỹ sự kiện.
class AdvanceVoucherCard extends ConsumerWidget {
  final AdvanceVoucherModel voucher;
  final bool isClosed;
  final List<dynamic>? personnel;
  final String? eventId;
  final VoidCallback? onDisbursed;

  const AdvanceVoucherCard({
    super.key,
    required this.voucher,
    this.isClosed = false,
    this.personnel,
    this.eventId,
    this.onDisbursed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dualRbacSessionProvider);
    final canDisburse = session.canDisburseAdvanceVoucher(
      isClosed: isClosed,
      personnel: personnel,
      eventId: eventId,
    );

    final status = voucher.status;
    final recipientName =
        voucher.recipientMemberName ?? voucher.recipientMemberId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: status.badgeBorderColor.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Mã phiếu + Huy hiệu trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_outlined,
                    size: 15,
                    color: Color(0xFF8A7A70),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    voucher.advanceVoucherId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1610),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status.badgeBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: status.badgeBorderColor, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 12, color: status.badgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      status.displayName,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: status.badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Số tiền tạm ứng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Số tiền tạm ứng:',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B5E55),
                ),
              ),
              Text(
                voucher.formattedAdvanceAmount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 3. Người nhận
          Row(
            children: [
              const Icon(
                Icons.person_pin_outlined,
                size: 14,
                color: Color(0xFF8A7A70),
              ),
              const SizedBox(width: 5),
              const Text(
                'Người nhận: ',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5E55)),
              ),
              Text(
                recipientName,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1610),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 4. Hạn nộp chứng từ
          Row(
            children: [
              const Icon(
                Icons.event_available_outlined,
                size: 14,
                color: Color(0xFF8A7A70),
              ),
              const SizedBox(width: 5),
              Text(
                'Hạn nộp chứng từ: ${voucher.formattedSettlementDeadline}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B5E55),
                ),
              ),
            ],
          ),

          // 5. Ghi chú giao tiền nếu có
          if (voucher.disbursementNotes != null &&
              voucher.disbursementNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8E4DF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 13,
                    color: Color(0xFF047857),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Giao tiền: ${voucher.disbursementNotes!}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF4B5563),
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 6. Action: Nút giải ngân dành riêng cho Thủ quỹ
          if (voucher.isPendingDisbursement) ...[
            const SizedBox(height: 10),
            if (canDisburse)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await ConfirmDisbursementDialog.show(
                      context,
                      voucher: voucher,
                    );
                    if (res != null) {
                      onDisbursed?.call();
                    }
                  },
                  icon: const Icon(Icons.paid_outlined, size: 15),
                  label: const Text(
                    'Xác Nhận Đã Giải Ngân',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else
              const Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 13,
                    color: Color(0xFFB45309),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Đang chờ Thủ quỹ xác nhận giao tiền...',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
