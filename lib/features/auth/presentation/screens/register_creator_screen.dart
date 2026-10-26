import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/auth_models.dart';
import '../providers/auth_state_provider.dart';

class RegisterCreatorScreen extends ConsumerStatefulWidget {
  const RegisterCreatorScreen({super.key});

  @override
  ConsumerState<RegisterCreatorScreen> createState() =>
      _RegisterCreatorScreenState();
}

class _RegisterCreatorScreenState extends ConsumerState<RegisterCreatorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Clan Controllers
  final _clanNameController = TextEditingController();
  final _ancestorNameController = TextEditingController();
  final _originLocationController = TextEditingController();
  final _establishedYearController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Creator Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _gender = 'Male';
  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _agreedToTerms = true;

  @override
  void dispose() {
    _clanNameController.dispose();
    _ancestorNameController.dispose();
    _originLocationController.dispose();
    _establishedYearController.dispose();
    _descriptionController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với cam kết trách nhiệm gia tộc'),
          backgroundColor: Color(0xFF9B1C1C),
        ),
      );
      return;
    }

    final year = int.tryParse(_establishedYearController.text.trim());
    final dobStr = _selectedDob != null
        ? "${_selectedDob!.year.toString().padLeft(4, '0')}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}"
        : null;

    final request = RegisterCreatorRequestDto(
      clanName: _clanNameController.text.trim(),
      ancestorName: _ancestorNameController.text.trim(),
      originLocation: _originLocationController.text.trim(),
      establishedYear: year,
      description: _descriptionController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      gender: _gender,
      dateOfBirth: dobStr,
      generation: 1,
    );

    try {
      await ref.read(authStateProvider.notifier).registerCreator(request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khởi lập dòng họ thành công! Chào mừng Trưởng tộc.'),
            backgroundColor: Color(0xFF0F766E),
          ),
        );
        context.go('/home');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text(
          'Khởi Lập Dòng Họ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A1518),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF7A1518)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A1518),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7A1518).withAlpha(50),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.workspace_premium_outlined,
                              color: Color(0xFFE2AA36), size: 36),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quyền Hạn Trưởng Tộc (Clan Head)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Khởi tạo cây phả hệ gốc, phát hành mã mời và quản trị toàn bộ dòng họ.',
                                  style: TextStyle(
                                    color: Color(0xFFE5D5D0),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Thông tin dòng họ
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE8DFD8)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_tree,
                                    color: Color(0xFF7A1518), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '1. Thông Tin Dòng Họ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7A1518),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _clanNameController,
                              decoration: const InputDecoration(
                                labelText: 'Tên Dòng Họ *',
                                hintText: 'VD: Nguyễn Tộc, Trần Tộc, Lê Đại Gia',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Vui lòng nhập tên dòng họ'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _ancestorNameController,
                              decoration: const InputDecoration(
                                labelText: 'Danh tính Thủy Tổ (nếu rõ)',
                                hintText: 'VD: Cụ Thủy Tổ Nguyễn Quý Công',
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _originLocationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Quê quán / Gốc tích',
                                      hintText: 'VD: Thái Bình',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _establishedYearController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Năm khởi lập',
                                      hintText: '1820',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả / Lời răn dạy của dòng họ',
                                hintText: 'Tộc ước, phương châm gia phong...',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Thông tin Trưởng tộc
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE8DFD8)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person,
                                    color: Color(0xFF7A1518), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '2. Thông Tin Trưởng Tộc',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7A1518),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Họ và tên Trưởng tộc *',
                                hintText: 'VD: Nguyễn Trọng Hoàng',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Vui lòng nhập họ và tên'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại đăng nhập *',
                                hintText: '0901234567',
                              ),
                              validator: (v) => v == null || v.trim().length < 8
                                  ? 'SĐT phải từ 8-15 ký tự'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email nhận thông báo',
                                hintText: 'truongtoc@example.com',
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Gender Selection
                            const Text(
                              'Giới tính *',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.male, size: 18),
                                          SizedBox(width: 4),
                                          Text('Nam'),
                                        ],
                                      ),
                                    ),
                                    selected: _gender == 'Male',
                                    selectedColor: const Color(0xFF7A1518),
                                    labelStyle: TextStyle(
                                      color: _gender == 'Male'
                                          ? Colors.white
                                          : const Color(0xFF2B1810),
                                    ),
                                    onSelected: (val) {
                                      if (val) setState(() => _gender = 'Male');
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.female, size: 18),
                                          SizedBox(width: 4),
                                          Text('Nữ'),
                                        ],
                                      ),
                                    ),
                                    selected: _gender == 'Female',
                                    selectedColor: const Color(0xFF7A1518),
                                    labelStyle: TextStyle(
                                      color: _gender == 'Female'
                                          ? Colors.white
                                          : const Color(0xFF2B1810),
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() => _gender = 'Female');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Date of birth picker
                            InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(now.year - 40),
                                  firstDate: DateTime(1900),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  setState(() => _selectedDob = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Ngày tháng năm sinh',
                                  suffixIcon: Icon(Icons.calendar_month),
                                ),
                                child: Text(
                                  _selectedDob != null
                                      ? "${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}"
                                      : 'Chọn ngày sinh',
                                  style: TextStyle(
                                    color: _selectedDob != null
                                        ? const Color(0xFF2B1810)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu bảo vệ *',
                                hintText: 'Tối thiểu 6 ký tự',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().length < 6
                                  ? 'Mật khẩu tối thiểu 6 ký tự'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePassword,
                              decoration: const InputDecoration(
                                labelText: 'Nhập lại mật khẩu *',
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Mật khẩu nhập lại không khớp';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Agreement
                    CheckboxListTile(
                      value: _agreedToTerms,
                      activeColor: const Color(0xFF7A1518),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Tôi cam kết là đại diện có thẩm quyền của dòng họ và chịu trách nhiệm về tính trung thực của gia phả.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      onChanged: (val) =>
                          setState(() => _agreedToTerms = val ?? true),
                    ),
                    const SizedBox(height: 16),

                    // Submit button
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _submitRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A1518),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Khởi Lập Dòng Họ & Mở Cây Gia Phả',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
