import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../task/data/models/task_models.dart';
import '../../data/models/advance_voucher_models.dart';
import '../providers/advance_voucher_providers.dart';

/// Giao diện Lập phiếu tạm ứng (LapTamUngUI - US-46).
/// Gắn trực tiếp với hạng mục công việc (TaskModel) và tự động điền sẵn
/// các thông số định mức ngân sách, người phụ trách, thời hạn đối soát.
class CreateAdvanceVoucherSheet extends ConsumerStatefulWidget {
  final TaskModel task;

  const CreateAdvanceVoucherSheet({
    super.key,
    required this.task,
  });

  static Future<AdvanceVoucherModel?> show(
    BuildContext context, {
    required TaskModel task,
  }) {
    return showModalBottomSheet<AdvanceVoucherModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateAdvanceVoucherSheet(task: task),
    );
  }

  @override
  ConsumerState<CreateAdvanceVoucherSheet> createState() =>
      _CreateAdvanceVoucherSheetState();
}

class _CreateAdvanceVoucherSheetState
    extends ConsumerState<CreateAdvanceVoucherSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _recipientNameController;
  late TextEditingController _recipientIdController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late int _amountInt;
  late DateTime _receivedDate;
  late DateTime _settlementDeadline;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final task = widget.task;
    final defaultRecipientName =
        task.assignedMemberName ?? (task.hasAssignee ? task.assigneeDisplayName : '');
    final defaultRecipientId = task.assignedMemberId ?? 'MEM_ASSIGNEE_001';

    _recipientNameController =
        TextEditingController(text: defaultRecipientName);
    _recipientIdController = TextEditingController(text: defaultRecipientId);

    _amountInt = task.advanceBudget > 0 ? task.advanceBudget : 1000000;
    _amountController = TextEditingController(
      text: AppFormatters.formatVnd(_amountInt),
    );

    _receivedDate = DateTime.now();
    _settlementDeadline = task.deadline.isAfter(DateTime.now())
        ? task.deadline
        : DateTime.now().add(const Duration(days: 3));

    _notesController = TextEditingController(
      text:
          'Tạm ứng kinh phí thực hiện hạng mục "${task.taskName}". Cam kết nộp hóa đơn/chứng từ đối soát trước ngày ${AppFormatters.formatDate(_settlementDeadline)}.',
    );
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientIdController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(clean) ?? 0;
    setState(() {
      _amountInt = parsed;
    });
  }

  Future<void> _pickReceivedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày nhận tiền tạm ứng',
    );
    if (picked != null) {
      setState(() => _receivedDate = picked);
    }
  }

  Future<void> _pickSettlementDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _settlementDeadline.isBefore(_receivedDate)
          ? _receivedDate
          : _settlementDeadline,
      firstDate: _receivedDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Hạn nộp chứng từ / quyết toán',
    );
    if (picked != null) {
      setState(() => _settlementDeadline = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amountInt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền tạm ứng phải lớn hơn 0 đ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final request = CreateAdvanceVoucherRequestDto(
      taskId: widget.task.taskId,
      recipientMemberId: _recipientIdController.text.trim().isNotEmpty
          ? _recipientIdController.text.trim()
          : (widget.task.assignedMemberId ?? 'MEM_ASSIGNEE_001'),
      advanceAmount: _amountInt,
      receivedDate: _receivedDate,
      settlementDeadline: _settlementDeadline,
      commitmentNotes: _notesController.text.trim(),
    );

    try {
      final created = await ref
          .read(taskAdvanceVouchersProvider(widget.task.taskId).notifier)
          .createVoucher(request);

      if (mounted) {
        Navigator.of(context).pop(created);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lập phiếu tạm ứng thành công cho "${widget.task.taskName}"!',
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lập phiếu tạm ứng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + keyboardPadding),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: isDesktop ? 600 : double.infinity,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Tiêu đề Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFFB45309),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lập Phiếu Tạm Ứng Kinh Phí',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1610),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hạng mục: ${widget.task.taskName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B5E55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Banner Thông Tin Hạng Mục Công Việc Gắn Kèm
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E4DF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 16,
                      color: AppTheme.primaryCrimson,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mã việc: ${widget.task.taskId} • Định mức: ${widget.task.formattedAdvanceBudget}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1610),
                            ),
                          ),
                          Text(
                            'Hạn chót công việc: ${widget.task.formattedDeadline}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B5E55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Người nhận tạm ứng
              const Text(
                'Người nhận tạm ứng *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1610),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _recipientNameController,
                decoration: InputDecoration(
                  hintText: 'Họ và tên người nhận kinh phí',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên người nhận tạm ứng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 4. Số tiền tạm ứng
              const Text(
                'Số tiền tạm ứng (VNĐ) *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1610),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _onAmountChanged,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền tạm ứng',
                  prefixIcon:
                      const Icon(Icons.payments_outlined, size: 20),
                  suffixText: '₫',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                ),
                validator: (val) {
                  if (_amountInt <= 0) {
                    return 'Số tiền tạm ứng phải lớn hơn 0 đ';
                  }
                  return null;
                },
              ),
              if (_amountInt > widget.task.advanceBudget &&
                  widget.task.advanceBudget > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Lưu ý: Số tiền tạm ứng (${AppFormatters.formatVnd(_amountInt)}) đang vượt định mức dự toán (${widget.task.formattedAdvanceBudget})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // 5. Ngày nhận tiền & Hạn nộp chứng từ
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày nhận tiền *',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1610),
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickReceivedDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFD1D5DB)),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 16, color: Color(0xFF6B5E55)),
                                const SizedBox(width: 8),
                                Text(
                                  AppFormatters.formatDate(_receivedDate),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hạn nộp chứng từ *',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F1610),
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickSettlementDeadline,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFD1D5DB)),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_outlined,
                                    size: 16, color: Color(0xFF6B5E55)),
                                const SizedBox(width: 8),
                                Text(
                                  AppFormatters.formatDate(_settlementDeadline),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6. Nội dung cam kết & Ghi chú
              const Text(
                'Nội dung cam kết & Ghi chú',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1610),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Nội dung cam kết sử dụng và nộp chứng từ...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 7. Action Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    _isSubmitting
                        ? 'Đang lập phiếu...'
                        : 'Xác Nhận & Lập Phiếu Tạm Ứng',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCrimson,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
