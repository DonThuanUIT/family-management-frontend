import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/task_models.dart';
import 'task_deadline_countdown_card.dart';

/// Thẻ hiển thị một hạng mục công việc chuẩn bị cho sự kiện (US-07).
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool canManage;
  final bool isClosed;
  final VoidCallback onReassign;

  const TaskCard({
    super.key,
    required this.task,
    required this.canManage,
    required this.isClosed,
    required this.onReassign,
  });

  void _showCountdownDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TaskDeadlineCountdownCard(task: task),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = task.status;
    final isCompleted = status == TaskStatusEnum.completed;
    final isOverdue = task.isOverdue;
    final isOverdue12H = task.isOverdue12Hours;

    return Container(
      decoration: BoxDecoration(
        color: isOverdue12H ? const Color(0xFFFFF1F0) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue12H
              ? const Color(0xFFFCA5A5)
              : (isOverdue ? Colors.red.shade200 : const Color(0xFFE8E4DF)),
          width: (isOverdue12H || isOverdue) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdue12H
                ? const Color(0xFFBA1A1A).withAlpha(15)
                : Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (isOverdue12H)
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
              padding: EdgeInsets.fromLTRB(
                isOverdue12H ? 16 : 14,
                12,
                14,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header: Tên việc + Huy hiệu trạng thái
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.taskName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F1610),
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (task.isOverdue12Hours) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3.5),
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
                                  const SizedBox(width: 3),
                                  Text(
                                    task.overdueDurationText,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            if (task.isWithin24Hours) ...[
                              InkWell(
                                onTap: () => _showCountdownDialog(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 13,
                                        color: Color(0xFFB45309),
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Còn 24h',
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: isOverdue
                                    ? const Color(0xFFFEF2F2)
                                    : status.badgeBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOverdue
                                      ? Colors.red.shade300
                                      : status.badgeTextColor.withAlpha(60),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOverdue
                                        ? Icons.warning_amber_rounded
                                        : status.icon,
                                    size: 13,
                                    color: isOverdue
                                        ? AppTheme.primaryCrimson
                                        : status.badgeTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOverdue ? 'Quá hạn' : status.displayName,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isOverdue
                                          ? AppTheme.primaryCrimson
                                          : status.badgeTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

              if (task.details != null && task.details!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.details!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B5E55),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Thông số chi tiết (Hạn chót, Tạm ứng, Phụ trách)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEFEBE6)),
                ),
                child: Column(
                  children: [
                    // Hạn chót
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule,
                                size: 14, color: Color(0xFF8A7A70)),
                            SizedBox(width: 5),
                            Text(
                              'Hạn chót:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B5E55),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            task.formattedDeadline,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isOverdue
                                  ? AppTheme.primaryCrimson
                                  : const Color(0xFF1F1610),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Tạm ứng dự kiến
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.request_quote_outlined,
                                size: 14, color: Color(0xFF8A7A70)),
                            SizedBox(width: 5),
                            Text(
                              'Tạm ứng:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B5E55),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            task.formattedAdvanceBudget,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryCrimson,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1, thickness: 0.5),
                    ),

                    // Người nhận việc
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_pin_outlined,
                                size: 14, color: Color(0xFF8A7A70)),
                            SizedBox(width: 5),
                            Text(
                              'Phụ trách:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B5E55),
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: task.hasAssignee
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 9,
                                      backgroundColor: AppTheme.primaryCrimson
                                          .withAlpha(25),
                                      child: Text(
                                        task.assigneeDisplayName.isNotEmpty
                                            ? task.assigneeDisplayName
                                                .characters.first
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryCrimson,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        task.assigneeDisplayName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1F1610),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Chưa chỉ định',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // [US-47] Stitch W4 Alert Notice Box: Báo động vượt cấp lên Trưởng chi
              if (task.isOverdue12Hours) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFCA5A5),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.report_problem_rounded,
                        color: Color(0xFFBA1A1A),
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ĐÃ BÁO ĐỘNG VƯỢT CẤP LÊN TRƯỞNG CHI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF410002),
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              'Hệ thống đã tự động ghi vết cảnh báo và gửi thông báo khẩn cấp tới Trưởng chi.',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF7F1D1D),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Footer Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã: ${task.taskId}',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Color(0xFF8A7A70),
                ),
              ),

              // Action button
              if (isCompleted)
                const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Color(0xFF047857), size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Đã nghiệm thu',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                )
              else if (canManage)
                OutlinedButton.icon(
                  onPressed: isClosed ? null : onReassign,
                  icon: Icon(
                    task.hasAssignee ? Icons.sync_alt : Icons.person_add_alt,
                    size: 14,
                  ),
                  label: Text(
                    task.hasAssignee ? 'Phân công lại' : 'Gán người nhận',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryCrimson,
                    side: BorderSide(
                      color: isClosed
                          ? Colors.grey.shade300
                          : AppTheme.primaryCrimson.withAlpha(120),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
