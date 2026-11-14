import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/event_models.dart';
import '../providers/event_providers.dart';

class EditEventSheet extends ConsumerStatefulWidget {
  final EventModel event;

  const EditEventSheet({super.key, required this.event});

  @override
  ConsumerState<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends ConsumerState<EditEventSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _lunarController;
  late final TextEditingController _budgetController;
  late final TextEditingController _descController;
  late final TextEditingController _maxCapacityController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  DateTime? _registrationDeadline;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.eventName);
    _locationController = TextEditingController(text: widget.event.location);
    _lunarController =
        TextEditingController(text: widget.event.eventDateLunar ?? '');
    _budgetController = TextEditingController(
        text: widget.event.estimatedBudget.toStringAsFixed(0));
    _descController =
        TextEditingController(text: widget.event.description ?? '');
    _maxCapacityController = TextEditingController(
        text: widget.event.maxCapacity?.toString() ?? '');

    _selectedDate = widget.event.eventDatetime;
    _selectedTime = TimeOfDay.fromDateTime(widget.event.eventDatetime);
    _registrationDeadline = widget.event.registrationDeadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _lunarController.dispose();
    _budgetController.dispose();
    _descController.dispose();
    _maxCapacityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initialDate = _registrationDeadline ?? now.add(const Duration(days: 7));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _registrationDeadline != null
          ? TimeOfDay.fromDateTime(_registrationDeadline!)
          : const TimeOfDay(hour: 23, minute: 59),
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _registrationDeadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final budget = double.tryParse(
          _budgetController.text.replaceAll(',', '').replaceAll('.', '').trim(),
        ) ??
        0.0;

    final maxCapacityText = _maxCapacityController.text.trim();
    final maxCapacity =
        maxCapacityText.isNotEmpty ? int.tryParse(maxCapacityText) : null;

    final request = UpdateEventRequestDto(
      eventName: _nameController.text.trim(),
      description: _descController.text.trim(),
      eventDatetime: eventDateTime,
      eventDateLunar: _lunarController.text.trim().isNotEmpty
          ? _lunarController.text.trim()
          : null,
      location: _locationController.text.trim(),
      estimatedBudget: budget,
      registrationDeadline: _registrationDeadline,
      maxCapacity: maxCapacity,
    );

    final success = await ref
        .read(eventListProvider.notifier)
        .updateEvent(widget.event.eventId, request);

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Đã cập nhật sự kiện thành công! Nếu có thay đổi lịch trình, thông báo đã được phát (US-22).'
              : 'Lỗi khi cập nhật sự kiện!'),
          backgroundColor:
              success ? const Color(0xFF1B5E20) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4C8BE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBEBEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_outlined,
                      color: Color(0xFF7A1518),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cập Nhật Sự Kiện & Lịch Trình',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        Text(
                          'API PUT /api/v1/events/{id} • Tự động phát thông báo khi đổi ngày/giờ/địa điểm (US-22)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7A6A60),
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
              const Divider(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên Điển Lễ / Sự Kiện *',
                  prefixIcon: Icon(Icons.celebration_outlined, size: 20),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Nhập tên sự kiện' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày Dương *',
                          prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Giờ Khai Lễ *',
                          prefixIcon: Icon(Icons.access_time, size: 18),
                        ),
                        child: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _lunarController,
                decoration: const InputDecoration(
                  labelText: 'Ngày Âm Lịch',
                  prefixIcon: Icon(Icons.auto_stories_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa Điểm Tổ Chức *',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Nhập địa điểm tổ chức'
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dự Toán Ngân Sách (VND)',
                  prefixIcon: Icon(Icons.payments_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      key: const Key('edit_event_deadline_picker'),
                      onTap: _pickDeadline,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hạn Chót Đăng Ký',
                          prefixIcon: const Icon(Icons.timer_outlined, size: 18),
                          suffixIcon: _registrationDeadline != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => setState(
                                      () => _registrationDeadline = null),
                                )
                              : null,
                        ),
                        child: Text(
                          _registrationDeadline != null
                              ? DateFormat('dd/MM/yyyy HH:mm')
                                  .format(_registrationDeadline!)
                              : 'Không giới hạn',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _registrationDeadline != null
                                ? const Color(0xFF2B1810)
                                : const Color(0xFF8A7A70),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: const Key('edit_event_max_capacity_input'),
                      controller: _maxCapacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sức Chứa Tối Đa',
                        hintText: 'VD: 150',
                        prefixIcon: Icon(Icons.groups_outlined, size: 18),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final parsed = int.tryParse(val.trim());
                        if (parsed == null || parsed < 1) {
                          return 'Phải >= 1';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi Chú Kế Hoạch',
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A1518),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lưu Cập Nhật & Phát Thông Báo (US-22)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
