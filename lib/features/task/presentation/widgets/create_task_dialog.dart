import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../event/data/models/event_models.dart';
import '../../data/models/task_models.dart';
import '../providers/task_providers.dart';
import 'assignee_picker_dialog.dart';

/// Hộp thoại / Bottom Sheet tạo mới một hạng mục công việc chuẩn bị cho sự kiện (US-07).
class CreateTaskDialog extends ConsumerStatefulWidget {
  final EventModel event;

  const CreateTaskDialog({
    super.key,
    required this.event,
  });

  /// Hiển thị thích ứng trên Web (Dialog) hoặc Mobile (ModalBottomSheet).
  static Future<bool?> show(BuildContext context, {required EventModel event}) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        builder: (_) => CreateTaskDialog(event: event),
      );
    } else {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: CreateTaskDialog(event: event),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController(text: '0 ₫');

  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 0);

  AssigneeSelection? _selectedAssignee;
  int _advanceBudgetInt = 0;
  bool _isSubmitting = false;
  String? _clientDeadlineError;

  @override
  void initState() {
    super.initState();
    // Khởi tạo hạn chót an toàn: Nếu sự kiện trong tương lai thì lấy trước sự kiện 1 ngày
    final eventTime = widget.event.eventDatetime;
    if (eventTime.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      _selectedDeadline = eventTime.subtract(const Duration(days: 1));
    } else {
      _selectedDeadline = DateTime.now().add(const Duration(hours: 12));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  DateTime get _combinedDeadline {
    return DateTime(
      _selectedDeadline.year,
      _selectedDeadline.month,
      _selectedDeadline.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  void _onBudgetChanged(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digitsOnly) ?? 0;
    _advanceBudgetInt = amount;
    final formatted = AppFormatters.formatVnd(amount);
    _budgetController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final eventDate = widget.event.eventDatetime;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline.isAfter(now) &&
              _selectedDeadline.isBefore(eventDate)
          ? _selectedDeadline
          : now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: eventDate,
      helpText: 'CHỌN HẠN CHÓT HOÀN THÀNH',
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _validateDeadlines();
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'CHỌN GIỜ HẠN CHÓT',
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _validateDeadlines();
      });
    }
  }

  void _validateDeadlines() {
    final deadline = _combinedDeadline;
    final now = DateTime.now();
    final eventTime = widget.event.eventDatetime;

    if (!deadline.isAfter(now)) {
      _clientDeadlineError = 'Hạn chót phải là thời điểm trong tương lai';
    } else if (!deadline.isBefore(eventTime)) {
      _clientDeadlineError =
          'Hạn chót phải trước ngày diễn ra sự kiện (${AppFormatters.formatDateTime(eventTime)})';
    } else {
      _clientDeadlineError = null;
    }
  }

  Future<void> _selectAssignee() async {
    final selection = await AssigneePickerDialog.show(
      context,
      event: widget.event,
      initialSelection: _selectedAssignee,
    );
    if (selection != null) {
      setState(() {
        _selectedAssignee = selection.isAssigned ? selection : null;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    _validateDeadlines();
    if (!_formKey.currentState!.validate() || _clientDeadlineError != null) {
      setState(() {});
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = CreateTaskRequestDto(
        taskName: _nameController.text.trim(),
        details: _detailsController.text.trim().isNotEmpty
            ? _detailsController.text.trim()
            : null,
        advanceBudget: _advanceBudgetInt,
        deadline: _combinedDeadline,
        assignedBranchId: _selectedAssignee?.branchId,
        assignedMemberId: _selectedAssignee?.memberId,
      );

      await ref
          .read(taskListProvider(widget.event.eventId).notifier)
          .createTask(request);

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Tạo hạng mục công việc thành công!'),
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
            content: Text('Lỗi khi lưu công việc: $e'),
            backgroundColor: AppTheme.primaryCrimson,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle for mobile
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCrimson.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_task,
                    color: AppTheme.primaryCrimson,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tạo Hạng Mục Phân Việc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1610),
                        ),
                      ),
                      Text(
                        'Phân hệ Ban tổ chức sự kiện (US-07)',
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
          ),
          const Divider(height: 1),

          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tên công việc
                    TextFormField(
                      controller: _nameController,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Tên công việc *',
                        hintText: 'Ví dụ: Mua hoa quả, chuẩn bị văn tế...',
                        prefixIcon: Icon(Icons.assignment_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Tên công việc không được để trống';
                        }
                        if (val.trim().length > 100) {
                          return 'Tên công việc tối đa 100 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Nội dung chi tiết
                    TextFormField(
                      controller: _detailsController,
                      maxLength: 4000,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung chi tiết (Tùy chọn)',
                        hintText: 'Mô tả số lượng mâm quả, yêu cầu chuẩn bị...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Ngân sách tạm ứng dự kiến (VNĐ - int)
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ngân sách tạm ứng dự kiến (VNĐ)',
                        prefixIcon: Icon(Icons.payments_outlined, size: 20),
                        helperText:
                            'Dự toán chuẩn bị; phiếu tạm ứng thực tế do Thủ quỹ duyệt',
                      ),
                      onChanged: _onBudgetChanged,
                    ),
                    const SizedBox(height: 14),

                    // Hạn chót
                    const Text(
                      'Hạn chót hoàn thành *',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F1610),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              AppFormatters.formatDate(_selectedDeadline),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(fontSize: 12.5),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_clientDeadlineError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _clientDeadlineError!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryCrimson,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Đối tượng nhận việc
                    const Text(
                      'Đối tượng nhận việc (Tùy chọn)',
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
                        color: const Color(0xFFF9F8F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8E4DF)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _selectedAssignee != null &&
                                    _selectedAssignee!.isAssigned
                                ? Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor: AppTheme.primaryCrimson,
                                      child: Text(
                                        _selectedAssignee!.displayName
                                                .isNotEmpty
                                            ? _selectedAssignee!
                                                .displayName.characters.first
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    label: Text(
                                      _selectedAssignee!.displayName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedAssignee = null;
                                      });
                                    },
                                    deleteIcon: const Icon(Icons.close, size: 14),
                                  )
                                : const Text(
                                    'Chưa chỉ định (Trạng thái: Chưa giao)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _selectAssignee,
                            icon: const Icon(Icons.person_search, size: 16),
                            label: const Text('Chọn',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryCrimson,
                              elevation: 0,
                              side: const BorderSide(
                                color: Color(0xFFD4C8BE),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F6),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Hủy bỏ'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCrimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
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
          ),
        ],
      ),
    );

    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
          child: content,
        ),
      );
    }

    return content;
  }
}

