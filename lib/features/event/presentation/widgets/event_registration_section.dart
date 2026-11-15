import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/event_models.dart';
import '../providers/event_providers.dart';

/// Khu vực hiển thị, chỉnh sửa và hủy đăng ký tham dự của hộ gia đình (US-41).
/// Tự động khóa nút 'Chỉnh sửa đăng ký' & 'Hủy đăng ký' và hiển thị hướng dẫn
/// liên hệ trực tiếp Ban tổ chức khi sự kiện đã chuyển sang trạng thái chốt danh sách.
class EventRegistrationSection extends ConsumerWidget {
  final EventModel event;

  const EventRegistrationSection({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationAsync = ref.watch(myRegistrationProvider(event.eventId));
    final actionState = ref.watch(registrationActionProvider);
    final isSubmitting = actionState.isLoading;
    final isRegistrationOpen = event.status == 'RegistrationOpen';
    final isRegistrationClosed = event.status == 'RegistrationClosed';
    final isDeadlinePassed = event.isRegistrationDeadlinePassed;
    final isCapacityFull = event.isCapacityFull;
    final canRegisterNew =
        isRegistrationOpen && !isDeadlinePassed && !isCapacityFull;
    final canModifyExisting = isRegistrationOpen && !isDeadlinePassed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_reg, size: 17, color: Color(0xFF7A1518)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Đăng Ký Tham Dự Của Hộ Gia Đình',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1810),
                  ),
                ),
              ),
              if (isSubmitting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (event.registrationDeadline != null || event.maxCapacity != null) ...[
            const SizedBox(height: 8),
            _RegistrationDeadlineCapacityBanner(event: event),
          ],
          const SizedBox(height: 8),
          registrationAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text(
              'Không thể tải trạng thái đăng ký: $e',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
            data: (registration) {
              if (registration == null || registration.isCancelled) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      registration?.isCancelled == true
                          ? 'Lượt đăng ký trước đó của hộ gia đình đã được hủy.'
                          : 'Hộ gia đình bạn chưa có lượt đăng ký tham dự sự kiện này.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF54433E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isRegistrationOpen) ...[
                      if (isDeadlinePassed)
                        _buildWarningBanner(
                          'Đã hết hạn đăng ký tham dự sự kiện. Vui lòng liên hệ Ban tổ chức.',
                        )
                      else if (isCapacityFull)
                        _buildWarningBanner(
                          'Sự kiện đã hết chỗ trống (đạt sức chứa tối đa ${event.maxCapacity} người).',
                        ),
                      if (isDeadlinePassed || isCapacityFull)
                        const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: (canRegisterNew && !isSubmitting)
                            ? () => _openRegisterDialog(context, ref)
                            : null,
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: Text(
                          isDeadlinePassed
                              ? 'Đã Hết Hạn Đăng Ký'
                              : isCapacityFull
                                  ? 'Đã Hết Chỗ'
                                  : 'Đăng Ký Tham Dự',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A1518),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ]
                    else
                      _buildClosedNotice(isRegistrationClosed),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Số người tham dự: ${registration.totalAttendees} '
                    '(Chay: ${registration.vegetarianMeals}, Mặn: ${registration.savoryMeals})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B1810),
                    ),
                  ),
                  if (registration.transportationNotes != null &&
                      registration.transportationNotes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Phương tiện: ${registration.transportationNotes}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF54433E),
                      ),
                    ),
                  ],
                  if (!isRegistrationOpen) ...[
                    const SizedBox(height: 8),
                    _buildClosedNotice(isRegistrationClosed),
                  ] else if (isDeadlinePassed) ...[
                    const SizedBox(height: 8),
                    _buildWarningBanner(
                      'Đã hết hạn chỉnh sửa hoặc hủy đăng ký. Vui lòng liên hệ Ban tổ chức.',
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (canModifyExisting && !isSubmitting)
                              ? () => _openEditDialog(
                                    context,
                                    ref,
                                    registration,
                                  )
                              : null,
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text(
                            'Chỉnh sửa đăng ký',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7A1518),
                            side: BorderSide(
                              color: canModifyExisting
                                  ? const Color(0xFF7A1518)
                                  : Colors.grey.shade400,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (canModifyExisting && !isSubmitting)
                              ? () => _confirmCancel(
                                    context,
                                    ref,
                                    registration,
                                  )
                              : null,
                          icon: const Icon(Icons.cancel_outlined, size: 15),
                          label: const Text(
                            'Hủy đăng ký',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(
                              color: canModifyExisting
                                  ? Colors.red.shade400
                                  : Colors.grey.shade400,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_busy_outlined, size: 16, color: Colors.red.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.red.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedNotice(bool isRegistrationClosed) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_clock, size: 16, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isRegistrationClosed
                  ? 'Danh sách tham dự đã được Ban tổ chức chốt. Vui lòng liên hệ trực tiếp Ban tổ chức (BTC) nếu cần thay đổi hoặc hủy đăng ký.'
                  : 'Sự kiện hiện không ở trạng thái mở đăng ký. Vui lòng liên hệ trực tiếp Ban tổ chức (BTC) để được hỗ trợ.',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRegisterDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_RegistrationFormValue>(
      context: context,
      builder: (_) => const _RegistrationFormDialog(
        title: 'Đăng Ký Tham Dự Sự Kiện',
        confirmLabel: 'Xác Nhận Đăng Ký',
      ),
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(registrationActionProvider.notifier)
        .registerAttendees(
          eventId: event.eventId,
          request: RegisterAttendeesRequestDto(
            totalAttendees: result.totalAttendees,
            vegetarianMeals: result.vegetarianMeals,
            savoryMeals: result.savoryMeals,
            dietaryRequirements: result.dietaryRequirements,
            transportationNotes: result.transportationNotes,
          ),
        );
    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successMessage: 'Đăng ký tham dự sự kiện thành công',
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    WidgetRef ref,
    RegistrationModel registration,
  ) async {
    final result = await showDialog<_RegistrationFormValue>(
      context: context,
      builder: (_) => _RegistrationFormDialog(
        title: 'Chỉnh Sửa Đăng Ký Tham Dự',
        confirmLabel: 'Lưu Thay Đổi',
        initialTotal: registration.totalAttendees,
        initialVeg: registration.vegetarianMeals,
        initialSavory: registration.savoryMeals,
        initialDietary: registration.dietaryRequirements,
        initialTransport: registration.transportationNotes,
      ),
    );
    if (result == null || !context.mounted) return;

    final error = await ref
        .read(registrationActionProvider.notifier)
        .updateRegistration(
          eventId: event.eventId,
          registrationId: registration.registrationId,
          request: UpdateRegistrationRequestDto(
            totalAttendees: result.totalAttendees,
            vegetarianMeals: result.vegetarianMeals,
            savoryMeals: result.savoryMeals,
            dietaryRequirements: result.dietaryRequirements,
            transportationNotes: result.transportationNotes,
          ),
        );
    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successMessage: 'Cập nhật thông tin đăng ký thành công',
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    RegistrationModel registration,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đăng ký'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy lượt đăng ký tham dự sự kiện này của hộ gia đình không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(registrationActionProvider.notifier)
        .cancelRegistration(
          eventId: event.eventId,
          registrationId: registration.registrationId,
        );
    if (!context.mounted) return;
    _showResultSnackBar(
      context,
      error: error,
      successMessage: 'Đã hủy đăng ký tham dự thành công',
    );
  }

  static void _showResultSnackBar(
    BuildContext context, {
    required String? error,
    required String successMessage,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? successMessage),
        backgroundColor: error != null ? Colors.red.shade700 : Colors.green,
      ),
    );
  }
}

class _RegistrationFormValue {
  final int totalAttendees;
  final int vegetarianMeals;
  final int savoryMeals;
  final String? dietaryRequirements;
  final String? transportationNotes;

  const _RegistrationFormValue({
    required this.totalAttendees,
    required this.vegetarianMeals,
    required this.savoryMeals,
    this.dietaryRequirements,
    this.transportationNotes,
  });
}

class _RegistrationFormDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final int initialTotal;
  final int initialVeg;
  final int initialSavory;
  final String? initialDietary;
  final String? initialTransport;

  const _RegistrationFormDialog({
    required this.title,
    required this.confirmLabel,
    this.initialTotal = 1,
    this.initialVeg = 0,
    this.initialSavory = 1,
    this.initialDietary,
    this.initialTransport,
  });

  @override
  State<_RegistrationFormDialog> createState() =>
      _RegistrationFormDialogState();
}

class _RegistrationFormDialogState extends State<_RegistrationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _totalCtrl;
  late final TextEditingController _vegCtrl;
  late final TextEditingController _savoryCtrl;
  late final TextEditingController _dietaryCtrl;
  late final TextEditingController _transportCtrl;
  String? _mealError;

  @override
  void initState() {
    super.initState();
    _totalCtrl = TextEditingController(text: '${widget.initialTotal}');
    _vegCtrl = TextEditingController(text: '${widget.initialVeg}');
    _savoryCtrl = TextEditingController(text: '${widget.initialSavory}');
    _dietaryCtrl = TextEditingController(text: widget.initialDietary ?? '');
    _transportCtrl = TextEditingController(text: widget.initialTransport ?? '');
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _vegCtrl.dispose();
    _savoryCtrl.dispose();
    _dietaryCtrl.dispose();
    _transportCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final total = int.parse(_totalCtrl.text.trim());
    final veg = int.tryParse(_vegCtrl.text.trim()) ?? 0;
    final savory = int.tryParse(_savoryCtrl.text.trim()) ?? 0;
    if (veg + savory > total) {
      setState(() {
        _mealError = 'Tổng suất ăn chay + mặn ($veg + $savory) không được vượt quá tổng số người ($total)';
      });
      return;
    }
    Navigator.pop(
      context,
      _RegistrationFormValue(
        totalAttendees: total,
        vegetarianMeals: veg,
        savoryMeals: savory,
        dietaryRequirements: _dietaryCtrl.text,
        transportationNotes: _transportCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tổng số người tham dự *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1) {
                    return 'Vui lòng nhập số nguyên >= 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vegCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Suất ăn chay',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '0');
                        if (n == null || n < 0) return 'Số >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _savoryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Suất ăn mặn',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '0');
                        if (n == null || n < 0) return 'Số >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _transportCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phương tiện di chuyển',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dietaryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú khẩu phần / dị ứng',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_mealError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _mealError!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A1518),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Hiển thị bộ đếm ngược thời gian đến hạn chót đăng ký và số chỗ còn lại (US-43).
class _RegistrationDeadlineCapacityBanner extends StatefulWidget {
  final EventModel event;

  const _RegistrationDeadlineCapacityBanner({required this.event});

  @override
  State<_RegistrationDeadlineCapacityBanner> createState() =>
      _RegistrationDeadlineCapacityBannerState();
}

class _RegistrationDeadlineCapacityBannerState
    extends State<_RegistrationDeadlineCapacityBanner> {
  Timer? _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _syncRemainingTime();
    if (widget.event.registrationDeadline != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(_syncRemainingTime);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _RegistrationDeadlineCapacityBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.registrationDeadline !=
        widget.event.registrationDeadline) {
      _syncRemainingTime();
    }
  }

  void _syncRemainingTime() {
    final deadline = widget.event.registrationDeadline;
    if (deadline == null) {
      _remainingTime = Duration.zero;
      return;
    }
    final diff = deadline.difference(DateTime.now());
    _remainingTime = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    if (d <= Duration.zero) return 'Đã hết hạn đăng ký';
    final days = d.inDays;
    final hours = (d.inHours % 24).toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (days > 0) {
      return '$days ngày $hours:$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.event.registrationDeadline;
    final maxCap = widget.event.maxCapacity;
    final remainingSlots = widget.event.effectiveRemainingSlots;
    final isExpired = deadline != null && _remainingTime <= Duration.zero;
    final isFull = maxCap != null && (remainingSlots ?? 0) <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (isExpired || isFull)
            ? Colors.red.shade50
            : const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: (isExpired || isFull)
              ? Colors.red.shade200
              : const Color(0xFFF3D5A5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (deadline != null)
            Row(
              key: const Key('registration_countdown_row'),
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: isExpired
                      ? Colors.red.shade700
                      : const Color(0xFF7A1518),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isExpired
                        ? 'Đã hết hạn đăng ký'
                        : 'Còn lại: ${_formatCountdown(_remainingTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isExpired
                          ? Colors.red.shade800
                          : const Color(0xFF5D4037),
                    ),
                  ),
                ),
              ],
            ),
          if (deadline != null && maxCap != null) const SizedBox(height: 5),
          if (maxCap != null)
            Row(
              key: const Key('registration_remaining_slots_row'),
              children: [
                Icon(
                  Icons.event_seat_outlined,
                  size: 15,
                  color: isFull
                      ? Colors.red.shade700
                      : const Color(0xFF1B5E20),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isFull
                        ? 'Đã hết chỗ (0 / $maxCap chỗ)'
                        : 'Số chỗ còn lại: $remainingSlots / $maxCap chỗ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFull
                          ? Colors.red.shade800
                          : const Color(0xFF1B5E20),
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
