import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/event_budget_models.dart';

/// Thẻ Hero Tổng Quan Ngân Sách Tích Hợp (Compact Executive Hero Card - US-37).
/// Tích hợp cảnh báo vượt trần, 3 chỉ số tài chính cốt lõi và thanh tiến độ phân đoạn đa màu.
class EventBudgetHeroCard extends StatelessWidget {
  final EventBudgetSummaryModel budget;

  const EventBudgetHeroCard({super.key, required this.budget});

  static const Color primaryColor = Color(0xFF8B1E1E); // Đỏ huyết dụ
  static const Color goldColor = Color(0xFFD4AF37); // Vàng hoàng kim
  static const Color criticalRed = Color(0xFFBA1A1A); // Đỏ cảnh báo
  static const Color safeGreen = Color(0xFF1B873F); // Xanh an toàn
  static const Color subtextColor = Color(0xFF58413F);

  String _formatCompact(double amount) {
    if (amount >= 1000000) {
      final inMillion = amount / 1000000;
      return '${inMillion.toStringAsFixed(inMillion.truncateToDouble() == inMillion ? 0 : 1)} Tr';
    }
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isOver = budget.isOverBudget;
    final percent = budget.totalUtilizationPercent;

    return Container(
      decoration: BoxDecoration(
        color: isOver ? const Color(0xFFFBEBEB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOver ? criticalRed : goldColor,
          width: isOver ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOver ? criticalRed : primaryColor).withAlpha(isOver ? 20 : 12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header cảnh báo & Độ lệch
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOver ? criticalRed : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOver ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                            size: 14,
                            color: isOver ? Colors.white : safeGreen,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isOver
                                  ? 'VƯỢT DỰ TOÁN • ${budget.warningLevel}'
                                  : 'TRONG NGÂN SÁCH AN TOÀN',
                              style: TextStyle(
                                fontFamily: 'Be Vietnam Pro',
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isOver ? Colors.white : safeGreen,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isOver
                          ? 'Tổng tạm ứng & thực chi đã vượt trần định mức'
                          : 'Tiến độ giải ngân đang nằm trong tầm kiểm soát',
                      style: const TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontSize: 11.5,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOver ? 'Vượt trần' : 'Dư khả dụng',
                    style: TextStyle(
                      fontFamily: 'Be Vietnam Pro',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOver ? subtextColor : safeGreen,
                    ),
                  ),
                  Text(
                    isOver
                        ? '+${currencyFormatter.format(budget.overrunAmount)}'
                        : '+${currencyFormatter.format(budget.netRemainingBudget > 0 ? budget.netRemainingBudget : 0)}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOver ? criticalRed : safeGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. 3 Cột Chỉ Số Tài Chính Cốt Lõi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(isOver ? 200 : 255),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5DDD5), width: 0.8),
            ),
            child: Row(
              children: [
                _buildMetricCol(
                  label: 'Dự Toán Ban Đầu',
                  value: _formatCompact(budget.estimatedBudget),
                  color: const Color(0xFF1A1C1A),
                ),
                _buildDivider(),
                _buildMetricCol(
                  label: 'Tạm Ứng Lưu Động',
                  value: _formatCompact(budget.totalAdvanceAmount),
                  color: const Color(0xFFB8860B),
                ),
                _buildDivider(),
                _buildMetricCol(
                  label: 'Thực Chi Đã Lập',
                  value: _formatCompact(budget.totalActualExpenseAmount),
                  color: primaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Thanh Tiến Độ Phân Đoạn (Segmented Progress Bar)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Tiến độ tiêu dùng',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: subtextColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${percent.toStringAsFixed(1)}%${isOver ? ' (Vượt trần ${(percent - 100).toStringAsFixed(1)}%)' : ''}',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOver ? criticalRed : safeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          _buildSegmentedProgressBar(
            estimated: budget.estimatedBudget,
            actual: budget.totalActualExpenseAmount,
            advance: budget.totalAdvanceAmount,
            overrun: budget.overrunAmount,
            isOver: isOver,
          ),

          const SizedBox(height: 6),

          // Chú thích ngang 1 dòng gọn gàng
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildLegendItem(primaryColor, 'Thực chi: ${_formatCompact(budget.totalActualExpenseAmount)}'),
              _buildLegendItem(goldColor, 'Tạm ứng: ${_formatCompact(budget.totalAdvanceAmount)}'),
              if (isOver)
                _buildLegendItem(criticalRed, 'Vượt: ${_formatCompact(budget.overrunAmount)}')
              else
                _buildLegendItem(safeGreen, 'Khả dụng: ${_formatCompact(budget.netRemainingBudget > 0 ? budget.netRemainingBudget : 0)}'),
            ],
          ),

          // 4. Thông điệp cảnh báo ngắn gọn (nếu có)
          if (budget.warningMessages.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isOver ? criticalRed.withAlpha(15) : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOver ? criticalRed.withAlpha(60) : const Color(0xFFFFD54F),
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: isOver ? criticalRed : const Color(0xFFF57F17),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      budget.warningMessages.first,
                      style: TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontSize: 11,
                        color: isOver ? criticalRed : const Color(0xFF795548),
                        height: 1.35,
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

  Widget _buildMetricCol({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Be Vietnam Pro',
              fontSize: 10,
              color: subtextColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE5DDD5),
    );
  }

  Widget _buildSegmentedProgressBar({
    required double estimated,
    required double actual,
    required double advance,
    required double overrun,
    required bool isOver,
  }) {
    final denom = isOver ? (actual + advance) : (estimated > 0 ? estimated : 1.0);
    final actualFlex = denom > 0 ? (actual / denom * 1000).toInt() : 0;
    final advanceFlex = denom > 0 ? (advance / denom * 1000).toInt() : 0;
    final remainingAmount = estimated - actual - advance;
    final remainingFlex = (!isOver && remainingAmount > 0 && denom > 0)
        ? (remainingAmount / denom * 1000).toInt()
        : 0;

    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFE5DDD5),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (actualFlex > 0)
            Expanded(
              flex: actualFlex,
              child: Container(color: primaryColor),
            ),
          if (advanceFlex > 0)
            Expanded(
              flex: advanceFlex,
              child: Container(color: goldColor),
            ),
          if (remainingFlex > 0)
            Expanded(
              flex: remainingFlex,
              child: Container(color: safeGreen),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontSize: 10.5,
            color: subtextColor,
          ),
        ),
      ],
    );
  }
}
