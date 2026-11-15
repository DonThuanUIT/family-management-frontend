import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/branch_recursive_contribution_providers.dart';
import 'branch_contribution_breakdown_bottom_sheet.dart';

/// Widget hiển thị tóm tắt đóng góp đệ quy trên từng nút nhánh của Cây Phả Hệ (US-11).
/// - Mặc định ẩn, chỉ hiển thị khi người dùng bật công tắc "Xem công đức" trên Cây.
/// - Nếu số tiền = 0đ: hiển thị badge xám mờ "Chưa ghi nhận cúng tiến • 0đ".
/// - Nếu số tiền > 0đ: hiển thị tổng cúng tiến, thanh phân rã Tự thân vs Nhánh con, và mở Modal phân rã khi chạm vào.
class BranchContributionPill extends ConsumerWidget {
  final String branchId;
  final String branchName;
  final bool isRootBranch;

  const BranchContributionPill({
    super.key,
    required this.branchId,
    required this.branchName,
    this.isRootBranch = false,
  });

  static final _currencyFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Kiểm tra trạng thái bật/tắt chế độ xem công đức trên thanh công cụ
    final filterState = ref.watch(treeContributionFilterProvider);
    if (!filterState.isContributionViewEnabled) {
      return const SizedBox.shrink();
    }

    const kPrimaryMaroon = Color(0xFF8B1E1E); // Đỏ Huyết Dụ
    const kSecondaryGold = Color(0xFFD4AF37); // Vàng Hoàng Kim
    const kBorderColor = Color(0xFFE5E5E5);

    // 2. Tra cứu số liệu đệ quy từ Backend
    final queryParam = BranchContributionQueryParam(
      branchId: branchId,
      eventId: filterState.selectedEventId,
      year: filterState.selectedYear,
    );

    final contributionAsync =
        ref.watch(branchRecursiveContributionProvider(queryParam));

    return contributionAsync.when(
      loading: () => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryMaroon),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Đang tải công đức đệ quy...',
              style: TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontSize: 11,
                color: Color(0xFF58413F),
              ),
            ),
          ],
        ),
      ),
      error: (err, stack) => const SizedBox.shrink(),
      data: (summary) {
        // Trường hợp nhánh chưa có đóng góp nào (0đ) -> Badge mờ
        if (summary.totalRecursiveAmount <= 0) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5E5E5),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 13, color: Color(0xFF8B716E)),
                    SizedBox(width: 6),
                    Text(
                      'Chưa ghi nhận cúng tiến',
                      style: TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontSize: 11,
                        color: Color(0xFF8B716E),
                      ),
                    ),
                  ],
                ),
                Text(
                  '0đ',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B716E),
                  ),
                ),
              ],
            ),
          );
        }

        // Trường hợp nhánh có đóng góp > 0đ -> Card phân rã mini tương tác
        final directPercent = summary.directPercentage;
        final descendantsPercent = summary.descendantsPercentage;
        final eventLabel = filterState.selectedEventName != null &&
                filterState.selectedEventName!.isNotEmpty
            ? filterState.selectedEventName!
            : (filterState.selectedYear != null
                ? 'NĂM ${filterState.selectedYear}'
                : 'TOÀN BỘ NIÊN KHÓA');

        return Container(
          margin: const EdgeInsets.only(top: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                BranchContributionBreakdownBottomSheet.show(
                  context,
                  summary: summary,
                  eventId: filterState.selectedEventId,
                  year: filterState.selectedYear,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header của widget
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.stars,
                                  size: 14, color: kSecondaryGold),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'CÔNG ĐỨC ĐỆ QUY (${eventLabel.toUpperCase()})',
                                  style: const TextStyle(
                                    fontFamily: 'Be Vietnam Pro',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryMaroon,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Cơ cấu',
                              style: TextStyle(
                                fontFamily: 'Be Vietnam Pro',
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryMaroon,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                size: 9, color: kPrimaryMaroon),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Số tiền tổng cộng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          '∑ Tổng cúng tiến:',
                          style: TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 11.5,
                            color: Color(0xFF58413F),
                          ),
                        ),
                        Text(
                          _currencyFormatter.format(summary.totalRecursiveAmount),
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryMaroon,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Thanh mini split bar: Tự thân (Đỏ) vs Nhánh con (Vàng)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 5,
                        child: Row(
                          children: [
                            if (directPercent > 0)
                              Expanded(
                                flex: (directPercent * 10).round().clamp(1, 1000),
                                child: Container(color: kPrimaryMaroon),
                              ),
                            if (descendantsPercent > 0)
                              Expanded(
                                flex:
                                    (descendantsPercent * 10).round().clamp(1, 1000),
                                child: Container(color: kSecondaryGold),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Chi tiết 2 thành phần
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: kPrimaryMaroon,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tự thân: ${_formatCompact(summary.directTotalAmount)} (${directPercent.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                fontFamily: 'Be Vietnam Pro',
                                fontSize: 10,
                                color: Color(0xFF1A1C1A),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: kSecondaryGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Nhánh con: ${_formatCompact(summary.descendantsTotalAmount)} (${descendantsPercent.toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                fontFamily: 'Be Vietnam Pro',
                                fontSize: 10,
                                color: Color(0xFF1A1C1A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ';
    }
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} tr';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} k';
    }
    return '${amount.toStringAsFixed(0)} đ';
  }
}
