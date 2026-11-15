import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/task_models.dart';

/// Thẻ cảnh báo khẩn cấp màu đỏ gửi riêng cho Trưởng chi / Trưởng nhánh (US-47).
/// Hiển thị danh sách các công việc trễ hạn từ 12 giờ trở lên thuộc chi mình phụ trách,
/// kèm huy hiệu `⚠️ Trễ [X]h` và nút bấm nhanh "Đôn đốc ngay" chuẩn Stitch W4.
class BranchOverdueEscalationCard extends StatelessWidget {
  final List<TaskModel> overdueTasks;
  final String branchName;
  final void Function(TaskModel task)? onTaskTap;
  final void Function(TaskModel task)? onNudge;

  const BranchOverdueEscalationCard({
    super.key,
    required this.overdueTasks,
    required this.branchName,
    this.onTaskTap,
    this.onNudge,
  });

  void _showNudgeDialog(BuildContext context, TaskModel task) {
    final assigneeName = task.assignedMemberName ?? task.assigneeDisplayName;
    final overdueHours = task.overdueHours;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              ),
              child: const Icon(
                Icons.campaign_outlined,
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
                    'Đôn Đốc Tiến Độ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1610),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Gửi nhắc nhở khẩn tới người phụ trách',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7F1D1D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.taskName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF410002),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBA1A1A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Trễ ${overdueHours}h',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Phụ trách: $assigneeName',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7F1D1D),
                    ),
                  ),
                  Text(
                    'Hạn chót: ${task.formattedDeadline}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B5E55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nội dung tin nhắn đôn đốc:',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1610),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8E4DF)),
              ),
              child: Text(
                'Kính gửi $assigneeName, hạng mục "${task.taskName}" đã quá hạn $overdueHours giờ. Đề nghị đồng chí khẩn trương hoàn tất và báo cáo tiến độ tới Trưởng chi.',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF4B5563),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Đóng',
              style: TextStyle(color: Color(0xFF6B5E55)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              onNudge?.call(task);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã gửi thông báo đôn đốc thành công tới $assigneeName!',
                  ),
                  backgroundColor: const Color(0xFFBA1A1A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.send_rounded, size: 15),
            label: const Text('Gửi Đôn Đốc'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (overdueTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0), // bg-error-container/20
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBA1A1A).withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Dải viền đỏ đậm bên trái (Stitch W4)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                color: const Color(0xFFBA1A1A),
              ),
            ),

            // Nội dung chính
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.crisis_alert_rounded,
                          color: Color(0xFFBA1A1A),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBA1A1A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.warning_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'BÁO ĐỘNG VƯỢT CẤP (12H)',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFDAD6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${overdueTasks.length} việc trễ',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFBA1A1A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Cảnh Báo Quá Hạn Thuộc $branchName',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF410002),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 2. Banner giải thích cơ chế leo thang
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Color(0xFFBA1A1A),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Hệ thống đã tự động ghi vết cảnh báo và gửi báo động tới Trưởng chi. Đề nghị Trưởng chi đôn đốc các thành viên phụ trách.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7F1D1D),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Danh sách các công việc trễ hạn
                  Column(
                    children: overdueTasks.map((task) {
                      final overdueHours = task.overdueHours;
                      final assigneeName =
                          task.assignedMemberName ?? task.assigneeDisplayName;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên việc + badge trễ
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => onTaskTap?.call(task),
                                    child: Text(
                                      task.taskName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F1610),
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBA1A1A),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Trễ ${overdueHours}h',
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
                            const SizedBox(height: 6),

                            // Meta row: Phụ trách & Hạn chót
                            Row(
                              children: [
                                const Icon(
                                  Icons.assignment_ind_outlined,
                                  size: 13,
                                  color: Color(0xFFBA1A1A),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Phụ trách: $assigneeName',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF7F1D1D),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: Color(0xFF8A7A70),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    task.formattedDeadline,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B5E55),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Button Đôn đốc ngay
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (task.advanceBudget > 0)
                                  Text(
                                    'Tạm ứng: ${task.formattedAdvanceBudget}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryCrimson,
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showNudgeDialog(context, task),
                                  icon: const Icon(Icons.campaign_outlined,
                                      size: 14),
                                  label: const Text('Đôn đốc ngay'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFBA1A1A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    minimumSize: const Size(0, 30),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
