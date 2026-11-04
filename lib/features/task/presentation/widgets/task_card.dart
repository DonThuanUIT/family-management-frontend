import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/task_models.dart';

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

  @override
  Widget build(BuildContext context) {
    final status = task.status;
    final isCompleted = status == TaskStatusEnum.completed;
    final isOverdue = task.isOverdue;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue
              ? Colors.red.shade200
              : const Color(0xFFE8E4DF),
          width: isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
            ],
          ),

          const SizedBox(height: 12),

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
    );
  }
}
