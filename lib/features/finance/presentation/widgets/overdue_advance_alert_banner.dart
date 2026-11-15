import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/overdue_advance_providers.dart';
import '../screens/overdue_advance_vouchers_screen.dart';

/// Banner cảnh báo khẩn cấp khi có các khoản tạm ứng quá hạn nộp chứng từ (US-48).
/// Hiển thị ở đầu Bảng điều khiển ngân sách sự kiện hoặc Danh sách công việc dành cho BTC & Thủ quỹ.
class OverdueAdvanceAlertBanner extends ConsumerWidget {
  final String? eventId;
  final String? eventName;

  const OverdueAdvanceAlertBanner({
    super.key,
    this.eventId,
    this.eventName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dualRbacSessionProvider);
    final canView = session.canViewOverdueAdvanceList(eventId: eventId);
    if (!canView) return const SizedBox.shrink();

    final state = ref.watch(overdueAdvanceListProvider(eventId));
    if (state.isLoading || state.vouchers.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = state.totalOverdueCount;
    final totalAmount = state.totalOverdueAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBA1A1A).withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFBA1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CẢNH BÁO TẠM ỨNG QUÁ HẠN NỘP CHỨNG TỪ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF410002),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Phát hiện $count khoản tạm ứng với tổng số tiền ${AppFormatters.formatVnd(totalAmount)} đã quá hạn quyết toán.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF93000A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  key: const Key('open_overdue_advances_button'),
                  onTap: () {
                    if (eventId != null && eventId!.trim().isNotEmpty) {
                      context.push('/events/$eventId/advances/overdue');
                    } else {
                      Navigator.of(context).push(
                        MaterialApp(
                          home: OverdueAdvanceVouchersScreen(
                            eventId: eventId,
                            eventName: eventName,
                          ),
                        ).onGenerateInitialRoutes!(
                          Navigator.defaultRouteName,
                        ).first,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem danh sách & Đôn đốc thu hồi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBA1A1A),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFFBA1A1A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
