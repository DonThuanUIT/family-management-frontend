import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../event/data/models/event_models.dart';
import '../../data/models/task_models.dart';
import '../providers/task_providers.dart';
import 'assignee_picker_dialog.dart';

/// Hộp thoại phân công hoặc điều chuyển người nhận việc (US-07: `POST /assign`).
class AssignTaskDialog extends ConsumerStatefulWidget {
  final EventModel event;
  final TaskModel task;

  const AssignTaskDialog({
    super.key,
    required this.event,
    required this.task,
  });

  static Future<bool?> show(
    BuildContext context, {
    required EventModel event,
    required TaskModel task,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AssignTaskDialog(event: event, task: task),
    );
  }

  @override
  ConsumerState<AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends ConsumerState<AssignTaskDialog> {
  AssigneeSelection? _selection;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selection = AssigneeSelection(
      memberId: widget.task.assignedMemberId,
      memberName: widget.task.assignedMemberName,
      branchId: widget.task.assignedBranchId,
      branchName: widget.task.assignedBranchName,
    );
  }

  Future<void> _chooseAssignee() async {
    final result = await AssigneePickerDialog.show(
      context,
      event: widget.event,
      initialSelection: _selection,
    );
    if (result != null) {
      setState(() {
        _selection = result;
      });
    }
  }

  Future<void> _submitAssignment() async {
    if (_selection == null || !_selection!.isAssigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chỉ định ít nhất cá nhân hoặc chi nhánh phụ trách'),
          backgroundColor: AppTheme.primaryCrimson,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = AssignTaskRequestDto(
        assignedBranchId: _selection?.branchId,
        assignedMemberId: _selection?.memberId,
      );

      await ref
          .read(taskListProvider(widget.event.eventId).notifier)
          .assignTask(widget.task.taskId, request);

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Phân công công việc thành công!'),
              ],
            ),
            backgroundColor: Color(0xFF047857),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể phân công: $e'),
            backgroundColor: AppTheme.primaryCrimson,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCrimson.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sync_alt,
                    color: AppTheme.primaryCrimson,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân Công / Điều Chuyển Việc',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1610),
                        ),
                      ),
                      Text(
                        'Chuyển trạng thái sang Đang thực hiện & gửi thông báo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B5E55),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const Divider(height: 20),

            // Task Name Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFEBE6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.taskName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1610),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã việc: ${widget.task.taskId} • Hạn chót: ${widget.task.formattedDeadline}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A7A70),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Target Assignee Preview Box
            const Text(
              'Đối tượng nhận việc mới *',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F1610),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4C8BE)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _selection != null && _selection!.isAssigned
                        ? Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppTheme.primaryCrimson,
                                child: Text(
                                  _selection!.displayName.isNotEmpty
                                      ? _selection!.displayName.characters.first
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _selection!.displayName,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Chưa chọn người hoặc chi nhánh',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  ElevatedButton(
                    onPressed: _chooseAssignee,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9F8F6),
                      foregroundColor: AppTheme.primaryCrimson,
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFD4C8BE)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Chọn lại',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Hủy bỏ'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCrimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu Phân Công',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

