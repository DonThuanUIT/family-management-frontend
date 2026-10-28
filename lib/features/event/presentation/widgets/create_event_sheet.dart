import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/event_models.dart';
import '../providers/event_providers.dart';

class CreateEventSheet extends ConsumerStatefulWidget {
  const CreateEventSheet({super.key});

  @override
  ConsumerState<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _lunarController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 14));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 30);

  String? _selectedHeadOfOrganizer;
  String? _selectedTreasurer;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _lunarController.dispose();
    _budgetController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
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

    final request = CreateEventRequestDto(
      eventName: _nameController.text.trim(),
      description: _descController.text.trim(),
      eventDatetime: eventDateTime,
      eventDateLunar: _lunarController.text.trim().isNotEmpty
          ? _lunarController.text.trim()
          : null,
      location: _locationController.text.trim(),
      estimatedBudget: budget,
      headOfOrganizerMemberId: _selectedHeadOfOrganizer,
      treasurerMemberId: _selectedTreasurer,
    );

    final success =
        await ref.read(eventListProvider.notifier).createEvent(request);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khởi tạo sự kiện mới thành công (Trạng thái: Draft)!'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo sự kiện. Vui lòng thử lại!'),
            backgroundColor: Color(0xFFB71C1C),
          ),
        );
      }
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
              // Thanh kéo drag handle
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

              // Tiêu đề Sheet
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
                      Icons.menu_book_outlined,
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
                          'Khởi Điển Kế Hoạch Tế Sự',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        Text(
                          'Khởi tạo sự kiện và thiết lập nhân sự ban tổ chức',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF7A6A60),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: const Color(0xFF8A7A70),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 1. Tên sự kiện
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên Điển Lễ / Sự Kiện *',
                  hintText: 'VD: Đại Lễ Giỗ Tiền Tổ Chi 2',
                  prefixIcon: Icon(Icons.celebration_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên sự kiện';
                  }
                  if (val.trim().length > 100) {
                    return 'Tên sự kiện tối đa 100 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Ngày Dương Lịch & Giờ
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

              // 3. Ngày Âm Lịch Đối Chiếu
              TextFormField(
                controller: _lunarController,
                decoration: const InputDecoration(
                  labelText: 'Ngày Âm Lịch Đối Chiếu',
                  hintText: 'VD: 10/03 Giáp Thìn',
                  prefixIcon: Icon(Icons.auto_stories_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Địa Điểm Tổ Chức
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa Điểm Tổ Chức *',
                  hintText: 'VD: Từ đường Chi 2, Xã Kim Liên',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập địa điểm tổ chức';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 5. Dự Toán Ngân Sách
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dự Toán Ngân Sách (VND)',
                  hintText: '50000000',
                  prefixIcon: Icon(Icons.payments_outlined, size: 20),
                  suffixText: 'đ',
                ),
              ),
              const SizedBox(height: 14),

              // 6. Contextual RBAC: Ban tổ chức & Thủ quỹ
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF5DCB7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Chỉ Định Nhân Sự (Contextual RBAC)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7A1518),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Trưởng tộc bổ nhiệm',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF8A7A70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedHeadOfOrganizer,
                      decoration: const InputDecoration(
                        labelText: 'Trưởng Ban Tổ Chức (Max 1)',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'MEM_001',
                          child: Text('Ông Vũ Văn Thịnh (Chi 1)'),
                        ),
                        DropdownMenuItem(
                          value: 'MEM_002',
                          child: Text('Ông Vũ Trọng Nghĩa (Chi 2)'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedHeadOfOrganizer = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTreasurer,
                      decoration: const InputDecoration(
                        labelText: 'Thủ Quỹ Sự Kiện (Max 1)',
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'MEM_003',
                          child: Text('Bà Vũ Thị Lan (Chi 1)'),
                        ),
                        DropdownMenuItem(
                          value: 'MEM_004',
                          child: Text('Ông Vũ Quốc Huy (Chi 3)'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedTreasurer = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 7. Ghi Chú & Kế Hoạch Chi Tiết
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi Chú / Nội Dung Kế Hoạch',
                  hintText: 'Nghi thức dâng hương, thứ tự đón rước...',
                ),
              ),
              const SizedBox(height: 20),

              // 8. Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A1518),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
                        'Ban Hành & Lưu Kế Hoạch',
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
