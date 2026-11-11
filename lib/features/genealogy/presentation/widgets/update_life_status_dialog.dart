import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/vietnamese_lunar_calendar.dart';
import '../../data/models/branch_models.dart';
import '../providers/genealogy_providers.dart';

/// Hộp thoại cập nhật tình trạng sinh/tử, tính ngày giỗ âm lịch (US-27).
class UpdateLifeStatusDialog extends ConsumerStatefulWidget {
  final BranchMemberItem member;
  final String? branchId;

  const UpdateLifeStatusDialog({
    super.key,
    required this.member,
    this.branchId,
  });

  @override
  ConsumerState<UpdateLifeStatusDialog> createState() => _UpdateLifeStatusDialogState();
}

class _UpdateLifeStatusDialogState extends ConsumerState<UpdateLifeStatusDialog> {
  late bool _isDeceased;
  DateTime? _selectedDeathDate;
  late final TextEditingController _burialPlaceController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isDeceased = widget.member.isDeceased;
    _selectedDeathDate = widget.member.deathDate ??
        (_isDeceased ? DateTime.now() : null);
    _burialPlaceController = TextEditingController(
      text: widget.member.burialPlace ?? '',
    );
  }

  @override
  void dispose() {
    _burialPlaceController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Chưa chọn';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickDeathDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = widget.member.dateOfBirth ?? DateTime(1800);
    final initialDate = _selectedDeathDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now)
          ? now
          : (initialDate.isBefore(firstDate) ? firstDate : initialDate),
      firstDate: firstDate,
      lastDate: now,
      helpText: 'CHỌN NGÀY MẤT (DƯƠNG LỊCH)',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryCrimson,
              onPrimary: Colors.white,
              surface: Color(0xFFFFFDF8),
              onSurface: Color(0xFF2B1810),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeathDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(lifeStatusActionProvider);
    final isLoading = actionState.isLoading;

    VietnameseLunarDate? lunarPreview;
    int? age;
    if (_isDeceased && _selectedDeathDate != null) {
      lunarPreview = VietnameseLunarCalendar.convertSolarToLunar(_selectedDeathDate!);
      age = VietnameseLunarCalendar.calculateAge(
        widget.member.dateOfBirth,
        _selectedDeathDate,
      );
    }

    return Dialog(
      backgroundColor: const Color(0xFFFFFDF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE6DFD8)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Dialog
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1E1E).withAlpha(16),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4A017), width: 1.2),
                      ),
                      child: const Icon(
                        Icons.auto_stories_outlined,
                        color: Color(0xFF8B1E1E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ghi Nhận Tình Trạng Sinh / Tử',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.member.fullName} • Đời ${widget.member.generation}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7D6E66),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF7D6E66)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Lựa chọn trạng thái: Còn sống vs Đã mất
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4ECE4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isDeceased = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isDeceased ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !_isDeceased
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x10000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_outline,
                                  size: 16,
                                  color: !_isDeceased
                                      ? const Color(0xFF006E2A)
                                      : const Color(0xFF6B584E),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Còn Sống',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: !_isDeceased
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: !_isDeceased
                                        ? const Color(0xFF006E2A)
                                        : const Color(0xFF6B584E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isDeceased = true;
                              _selectedDeathDate ??= DateTime.now();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isDeceased ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: _isDeceased
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x10000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  size: 16,
                                  color: _isDeceased
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF6B584E),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Đã Mất',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _isDeceased
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _isDeceased
                                        ? const Color(0xFF8B1E1E)
                                        : const Color(0xFF6B584E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Khi chọn "Đã Mất": Hiển thị các trường nhập ngày mất, âm lịch và an táng
                if (_isDeceased) ...[
                  // Bộ chọn ngày mất Dương lịch
                  InkWell(
                    onTap: () => _pickDeathDate(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDCD4CB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, size: 20, color: Color(0xFF8B1E1E)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ngày mất (Dương lịch) *',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7D6E66),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(_selectedDeathDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Color(0xFF7D6E66)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Thẻ Live Preview Ngày giỗ Âm lịch & Hưởng thọ
                  if (lunarPreview != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.brightness_3, size: 16, color: Color(0xFFB8860B)),
                              SizedBox(width: 6),
                              Text(
                                'Ngày Giỗ Tự Động (Âm Lịch):',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D4037),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lunarPreview.toFullAnniversaryString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B1E1E),
                            ),
                          ),
                          if (age != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Hưởng thọ: $age tuổi',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5D4037),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Nơi an táng / phần mộ
                  TextFormField(
                    controller: _burialPlaceController,
                    decoration: InputDecoration(
                      labelText: 'Nơi an táng / Phần mộ (Tùy chọn)',
                      hintText: 'Ví dụ: Khu lăng mộ tổ họ Nguyễn, nghĩa trang quê nhà...',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF8B1E1E)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDCD4CB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDCD4CB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF8B1E1E), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Lưu ý bảo mật & tính toàn vẹn phả hệ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F5F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2DCD5)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: Color(0xFF7D6E66)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chính sách phả hệ: Nút thành viên trên cây gia phả và toàn bộ lịch sử đóng góp quỹ dòng họ được bảo lưu vĩnh viễn. Tài khoản đăng nhập (nếu có) sẽ tự động bị khóa.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF6B584E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Khi chuyển về "Còn sống"
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBCE3C6)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Color(0xFF006E2A)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Khi chọn "Còn Sống", các thông tin ngày mất và ngày giỗ âm lịch sẽ được xóa. Tài khoản của thành viên sẽ được mở lại trạng thái hoạt động.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // Nút hành động
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(color: Color(0xFF6B584E)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (_isDeceased && _selectedDeathDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vui lòng chọn ngày mất của thành viên'),
                                    backgroundColor: Color(0xFF9B1C1C),
                                  ),
                                );
                                return;
                              }

                              final request = UpdateLifeStatusRequestDto(
                                status: _isDeceased ? 'Deceased' : 'Living',
                                deathDate: _isDeceased ? _selectedDeathDate : null,
                                burialPlace: _isDeceased &&
                                        _burialPlaceController.text.trim().isNotEmpty
                                    ? _burialPlaceController.text.trim()
                                    : null,
                              );

                              final success = await ref
                                  .read(lifeStatusActionProvider.notifier)
                                  .updateLifeStatus(
                                    memberId: widget.member.memberId,
                                    request: request,
                                    branchId: widget.branchId,
                                  );

                              if (context.mounted) {
                                if (success) {
                                  Navigator.of(context).pop(true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(child: Text('Cập nhật tình trạng thành viên thành công')),
                                        ],
                                      ),
                                      backgroundColor: Color(0xFF006E2A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  final error = ref.read(lifeStatusActionProvider).error;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              error?.toString().replaceFirst('Exception: ', '') ??
                                                  'Lỗi khi cập nhật tình trạng',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF9B1C1C),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                        isLoading ? 'Đang lưu...' : 'Lưu Cập Nhật',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryCrimson,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
