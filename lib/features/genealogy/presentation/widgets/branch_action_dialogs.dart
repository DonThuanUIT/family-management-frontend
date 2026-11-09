import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/branch_models.dart';

/// Màu sắc chủ đạo theo phong cách Stitch Warm Editorial Heritage
const Color _kPrimaryColor = Color(0xFF8F482F);
const Color _kBorderColor = Color(0xFFDAC1BA);
const Color _kTextColor = Color(0xFF1C1C1A);
const Color _kSubtextColor = Color(0xFF54433E);
const Color _kSurfaceColor = Color(0xFFFFFFFF);

/// 1. Dialog Thêm Thành Viên Mới Vào Chi (US-26 / US-23)
class AddMemberToBranchDialog extends ConsumerStatefulWidget {
  final BranchUiDetail branch;

  const AddMemberToBranchDialog({
    super.key,
    required this.branch,
  });

  static Future<bool?> show(BuildContext context, BranchUiDetail branch) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AddMemberToBranchDialog(branch: branch),
    );
  }

  @override
  ConsumerState<AddMemberToBranchDialog> createState() => _AddMemberToBranchDialogState();
}

class _AddMemberToBranchDialogState extends ConsumerState<AddMemberToBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _generationController;
  late TextEditingController _roleInBranchController;
  late TextEditingController _birthYearController;
  String _gender = 'male';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _generationController = TextEditingController(text: '2');
    _roleInBranchController = TextEditingController(text: 'Con trai cả');
    _birthYearController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _generationController.dispose();
    _roleInBranchController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      // Mô phỏng hoặc gọi API tạo thành viên
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đã thêm thành viên "${_fullNameController.text.trim()}" vào ${widget.branch.name}!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF006E2A),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: _kSurfaceColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_add_alt_1, color: _kPrimaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thêm Thành Viên Vào Chi',
                            style: TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _kTextColor,
                            ),
                          ),
                          Text(
                            widget.branch.name,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: _kSubtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: _kSubtextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: _kBorderColor),
                const SizedBox(height: 18),

                // Họ và tên
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên thành viên *',
                    hintText: 'Ví dụ: Nguyễn Văn Bảo',
                    prefixIcon: Icon(Icons.badge_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Giới tính & Đời thứ
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Giới tính',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Nam')),
                          DropdownMenuItem(value: 'female', child: Text('Nữ')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _gender = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _generationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Đời thứ *',
                          prefixIcon: Icon(Icons.timeline, size: 18),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          final numVal = int.tryParse(val ?? '');
                          if (numVal == null || numVal < 1) {
                            return 'Đời >= 1';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Vai vế trong chi
                TextFormField(
                  controller: _roleInBranchController,
                  decoration: const InputDecoration(
                    labelText: 'Vai vế / Quan hệ trong chi',
                    hintText: 'Ví dụ: Con trai thứ 2, Dâu trưởng...',
                    prefixIcon: Icon(Icons.family_restroom, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Năm sinh
                TextFormField(
                  controller: _birthYearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Năm sinh (tùy chọn)',
                    hintText: 'Ví dụ: 1995',
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Hủy bỏ'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(_isSubmitting ? 'Đang lưu...' : 'Thêm Thành Viên'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        foregroundColor: Colors.white,
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

/// 2. Dialog Chỉnh Sửa Thông Tin Chi Nhánh (US-02 / US-04 / US-23)
class EditBranchInfoDialog extends ConsumerStatefulWidget {
  final BranchUiDetail branch;

  const EditBranchInfoDialog({
    super.key,
    required this.branch,
  });

  static Future<bool?> show(BuildContext context, BranchUiDetail branch) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => EditBranchInfoDialog(branch: branch),
    );
  }

  @override
  ConsumerState<EditBranchInfoDialog> createState() => _EditBranchInfoDialogState();
}

class _EditBranchInfoDialogState extends ConsumerState<EditBranchInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _repNameController;
  late TextEditingController _descriptionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch.name);
    _repNameController = TextEditingController(text: widget.branch.representative);
    _descriptionController = TextEditingController(text: widget.branch.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Đã cập nhật thông tin "${_nameController.text.trim()}" thành công!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF006E2A),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: _kSurfaceColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_note, color: _kPrimaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chỉnh Sửa Thông Tin Chi',
                            style: TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _kTextColor,
                            ),
                          ),
                          Text(
                            'Cập nhật tên chi, người đại diện và phả ký',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: _kSubtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: _kSubtextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: _kBorderColor),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên chi nhánh *',
                    prefixIcon: Icon(Icons.account_tree_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Tên chi không được để trống' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _repNameController,
                  decoration: const InputDecoration(
                    labelText: 'Người đại diện chi / Trưởng chi *',
                    prefixIcon: Icon(Icons.person_pin_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Người đại diện không được để trống' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Lược sử & Phả ký chi nhánh',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.history_edu_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Hủy bỏ'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(_isSaving ? 'Đang lưu...' : 'Lưu Thay Đổi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        foregroundColor: Colors.white,
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

/// 3. Dialog Điều Chuyển Thành Viên / Chi Nhánh (US-28 / US-23)
class TransferBranchMemberDialog extends ConsumerStatefulWidget {
  final BranchUiDetail currentBranch;

  const TransferBranchMemberDialog({
    super.key,
    required this.currentBranch,
  });

  static Future<bool?> show(BuildContext context, BranchUiDetail currentBranch) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => TransferBranchMemberDialog(currentBranch: currentBranch),
    );
  }

  @override
  ConsumerState<TransferBranchMemberDialog> createState() => _TransferBranchMemberDialogState();
}

class _TransferBranchMemberDialogState extends ConsumerState<TransferBranchMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedMemberId;
  String? _targetBranchId;
  late TextEditingController _reasonController;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: 'Điều chuyển theo nguyện vọng gia phả');
    if (widget.currentBranch.members.isNotEmpty) {
      _selectedMemberId = widget.currentBranch.members.first.memberId;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberId == null || _targetBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thành viên và chi nhánh đích'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    setState(() => _isTransferring = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Điều chuyển thành viên thành công!')),
            ],
          ),
          backgroundColor: Color(0xFF006E2A),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: const Color(0xFFBA1A1A)),
      );
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.currentBranch.members;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: _kSurfaceColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.alt_route_rounded, color: _kPrimaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Điều Chuyển Thành Viên / Chi',
                            style: TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _kTextColor,
                            ),
                          ),
                          Text(
                            'Từ: ${widget.currentBranch.name}',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: _kSubtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: _kSubtextColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: _kBorderColor),
                const SizedBox(height: 18),

                // Chọn thành viên cần điều chuyển
                if (members.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: const Text(
                      'Chi nhánh này hiện chưa có thành viên nào để điều chuyển.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Chọn thành viên cần chuyển *',
                      prefixIcon: Icon(Icons.person_outline, size: 18),
                      border: OutlineInputBorder(),
                    ),
                    items: members.map((m) {
                      return DropdownMenuItem(
                        value: m.memberId,
                        child: Text('${m.fullName} (${m.roleInBranch})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMemberId = val),
                    validator: (val) => val == null ? 'Vui lòng chọn thành viên' : null,
                  ),
                const SizedBox(height: 14),

                // Chọn chi nhánh đích
                DropdownButtonFormField<String>(
                  initialValue: _targetBranchId,
                  decoration: const InputDecoration(
                    labelText: 'Chi nhánh tiếp nhận đích *',
                    prefixIcon: Icon(Icons.input_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Chọn chi nhánh đích đến'),
                  items: const [
                    DropdownMenuItem(value: 'BR_ROOT', child: Text('Chi Gốc (Đại Tôn)')),
                    DropdownMenuItem(value: 'BR_CHI_2', child: Text('Chi 2 - Nhánh Giáp')),
                    DropdownMenuItem(value: 'BR_CHI_3', child: Text('Chi 3 - Nhánh Ất')),
                  ],
                  onChanged: (val) => setState(() => _targetBranchId = val),
                  validator: (val) => val == null ? 'Vui lòng chọn chi nhánh đích' : null,
                ),
                const SizedBox(height: 14),

                // Lý do điều chuyển
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Lý do / Căn cứ điều chuyển *',
                    prefixIcon: Icon(Icons.description_outlined, size: 18),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập lý do' : null,
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isTransferring ? null : () => Navigator.of(context).pop(),
                      child: const Text('Hủy bỏ'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isTransferring ? null : _handleTransfer,
                      icon: _isTransferring
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_isTransferring ? 'Đang chuyển...' : 'Xác Nhận Điều Chuyển'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        foregroundColor: Colors.white,
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
