import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/event_budget_models.dart';
import '../providers/event_providers.dart';

/// Phần Phân Rã Ngân Sách Hạng Mục Công Việc Dạng Thu Gọn (Dense Accordion - US-37).
class TaskBudgetBreakdownSection extends ConsumerStatefulWidget {
  final String eventId;
  final List<TaskBudgetBreakdownModel> tasks;

  const TaskBudgetBreakdownSection({
    super.key,
    required this.eventId,
    required this.tasks,
  });

  @override
  ConsumerState<TaskBudgetBreakdownSection> createState() =>
      _TaskBudgetBreakdownSectionState();
}

class _TaskBudgetBreakdownSectionState
    extends ConsumerState<TaskBudgetBreakdownSection> {
  final Set<String> _expandedTaskIds = {};

  static const Color primaryColor = Color(0xFF8B1E1E);
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color criticalRed = Color(0xFFBA1A1A);
  static const Color safeGreen = Color(0xFF1B873F);
  static const Color subtextColor = Color(0xFF58413F);

  void _toggleExpand(String taskId) {
    setState(() {
      if (_expandedTaskIds.contains(taskId)) {
        _expandedTaskIds.remove(taskId);
      } else {
        _expandedTaskIds.add(taskId);
      }
    });
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000) {
      final inMillion = amount / 1000000;
      return '${inMillion.toStringAsFixed(inMillion.truncateToDouble() == inMillion ? 0 : 1)} Tr';
    }
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final filterCategory = ref.watch(taskBudgetFilterProvider);

    final warningTasks = widget.tasks
        .where((t) => t.alertCategory == 'CRITICAL' || t.alertCategory == 'WARNING')
        .toList();
    final safeTasks = widget.tasks.where((t) => t.alertCategory == 'SAFE').toList();

    List<TaskBudgetBreakdownModel> displayedTasks;
    switch (filterCategory) {
      case TaskBudgetFilterCategory.warning:
        displayedTasks = warningTasks;
        break;
      case TaskBudgetFilterCategory.safe:
        displayedTasks = safeTasks;
        break;
      case TaskBudgetFilterCategory.all:
        displayedTasks = widget.tasks;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tiêu đề mục & Số lượng
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                const Text(
                  'Phân Rã Hạng Mục Chi Tiêu',
                  style: TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${widget.tasks.length} hạng mục)',
                  style: const TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 11.5,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2. Bộ lọc Chip 3 chế độ
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Tất cả (${widget.tasks.length})',
                isSelected: filterCategory == TaskBudgetFilterCategory.all,
                onSelected: () => ref.read(taskBudgetFilterProvider.notifier).setFilter(
                    TaskBudgetFilterCategory.all),
                activeColor: primaryColor,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: '⚠️ Cần chú ý (${warningTasks.length})',
                isSelected: filterCategory == TaskBudgetFilterCategory.warning,
                onSelected: () => ref.read(taskBudgetFilterProvider.notifier).setFilter(
                    TaskBudgetFilterCategory.warning),
                activeColor: criticalRed,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: '✅ An toàn (${safeTasks.length})',
                isSelected: filterCategory == TaskBudgetFilterCategory.safe,
                onSelected: () => ref.read(taskBudgetFilterProvider.notifier).setFilter(
                    TaskBudgetFilterCategory.safe),
                activeColor: safeGreen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Danh sách công việc dạng Accordion
        if (displayedTasks.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5DDD5)),
            ),
            child: const Center(
              child: Text(
                'Không có hạng mục nào trong bộ lọc này.',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 12.5,
                  color: subtextColor,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedTasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = displayedTasks[index];
              return _buildTaskAccordionItem(task);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE0DCD7),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : subtextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskAccordionItem(TaskBudgetBreakdownModel task) {
    final isExpanded = _expandedTaskIds.contains(task.taskId);
    final percent = task.utilizationPercent;
    final isOver = task.isOverTaskBudget;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (isOver) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = criticalRed;
      badgeLabel = 'VƯỢT TRẦN ${percent.toStringAsFixed(1)}%';
    } else if (percent >= 90.0) {
      badgeBg = const Color(0xFFFFF8E1);
      badgeText = const Color(0xFFB8860B);
      badgeLabel = 'SÁT TRẦN ${percent.toStringAsFixed(1)}%';
    } else {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = safeGreen;
      badgeLabel = 'AN TOÀN ${percent.toStringAsFixed(1)}%';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOver
              ? criticalRed.withAlpha(120)
              : (percent >= 90 ? goldColor.withAlpha(140) : const Color(0xFFE5DDD5)),
          width: isOver ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _toggleExpand(task.taskId),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header của item
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    fontFamily: 'Be Vietnam Pro',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: badgeText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                task.taskId,
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 10,
                                  color: Color(0xFF8A7A70),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            task.taskName,
                            style: const TextStyle(
                              fontFamily: 'Be Vietnam Pro',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1C1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCompact(task.totalCommitted),
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isOver ? criticalRed : const Color(0xFF1A1C1A),
                          ),
                        ),
                        Text(
                          'Định mức: ${_formatCompact(task.advanceBudget)}',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            color: Color(0xFF8A7A70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18,
                      color: const Color(0xFF8A7A70),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Mini Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (percent / 100.0).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFF0EBE6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOver ? criticalRed : (percent >= 90 ? goldColor : safeGreen),
                    ),
                    minHeight: 4,
                  ),
                ),

                // Nội dung mở rộng chi tiết (Accordion Body)
                if (isExpanded) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFF0EBE6)),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    label: 'Tạm ứng đã cấp:',
                    value:
                        '${currencyFormatter.format(task.advanceAmount)} (${task.advanceVoucherCount} phiếu)',
                    valueColor: const Color(0xFFB8860B),
                  ),
                  const SizedBox(height: 4),
                  _buildDetailRow(
                    label: 'Thực chi đã lập:',
                    value:
                        '${currencyFormatter.format(task.actualExpenseAmount)} (${task.settlementVoucherCount} hóa đơn)',
                    valueColor: primaryColor,
                  ),
                  const SizedBox(height: 4),
                  _buildDetailRow(
                    label: isOver ? 'Bội chi định mức:' : 'Dư khả dụng còn lại:',
                    value: isOver
                        ? '-${currencyFormatter.format((task.totalCommitted - task.advanceBudget).abs())}'
                        : '+${currencyFormatter.format((task.advanceBudget - task.totalCommitted).clamp(0, double.infinity))}',
                    valueColor: isOver ? criticalRed : safeGreen,
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        context.push('/events/${widget.eventId}/tasks');
                      },
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: const Text(
                        'Xem chi tiết công việc (US-07)',
                        style: TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontSize: 11,
            color: subtextColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
