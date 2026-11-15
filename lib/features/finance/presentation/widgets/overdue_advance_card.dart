import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/advance_voucher_models.dart';
import 'urge_settlement_dialog.dart';

/// Thẻ hiển thị một khoản tạm ứng quá hạn nộp chứng từ đối soát (US-48).
/// Cho phép BTC và Thủ quỹ xem chi tiết và kích hoạt hành động đôn đốc thu hồi.
class OverdueAdvanceCard extends ConsumerWidget {
  final AdvanceVoucherModel voucher;
  final bool isClosed;
  final String? eventId;
  final VoidCallback? onReminderSent;

  const OverdueAdvanceCard({
    super.key,
    required this.voucher,
    this.isClosed = false,
    this.eventId,
    this.onReminderSent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dualRbacSessionProvider);
    final canUrge = session.canUrgeAdvanceSettlement(
      isClosed: isClosed,
      eventId: voucher.eventId ?? eventId,
    );

    final recipientName =
        voucher.recipientMemberName ?? voucher.recipientMemberId;
    final taskTitle = voucher.taskName ?? 'Hạng mục: ${voucher.taskId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBA1A1A).withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Dải màu đỏ cảnh báo bên trái
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                color: const Color(0xFFBA1A1A),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header: Mã phiếu & Badge Quá hạn
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8A7A70),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              voucher.overdueDurationText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2. Thông tin người nhận tiền & Số tiền tạm ứng
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppTheme.primaryCrimson.withAlpha(20),
                        child: Text(
                          recipientName.isNotEmpty
                              ? recipientName.characters.first
                              : '?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryCrimson,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipientName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F1610),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              taskTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B5E55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Chưa quyết toán',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF93000A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            voucher.formattedAdvanceAmount,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Color(0xFFBA1A1A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3. Mốc thời gian đối soát & Hạn chót
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: Color(0xFF8A7A70),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Nhận tiền: ${voucher.formattedReceivedDate}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B5E55),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.event_busy_outlined,
                              size: 13,
                              color: Color(0xFFBA1A1A),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Hạn nộp: ${voucher.formattedSettlementDeadline}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBA1A1A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Cam kết ban đầu (nếu có)
                  if (voucher.commitmentNotes != null &&
                      voucher.commitmentNotes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          size: 14,
                          color: Color(0xFF8A7A70),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            voucher.commitmentNotes!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF6B5E55),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // 5. Action Bar: Nút Đôn Đốc Thu Hồi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (canUrge)
                        ElevatedButton.icon(
                          key: Key('urge_button_${voucher.advanceVoucherId}'),
                          onPressed: () {
                            UrgeSettlementDialog.show(
                              context,
                              voucher: voucher,
                              eventId: eventId,
                              onSent: onReminderSent,
                            );
                          },
                          icon: const Icon(
                            Icons.notification_important_rounded,
                            size: 14,
                          ),
                          label: const Text(
                            'Đôn Đốc Thu Hồi',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryCrimson,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            minimumSize: const Size(0, 34),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      else
                        const Text(
                          'Chờ Ban tổ chức và Thủ quỹ xử lý',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF8A7A70),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
