import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/auth_models.dart';
import '../providers/auth_state_provider.dart';

class RegisterMemberScreen extends ConsumerStatefulWidget {
  final String? initialInviteCode;

  const RegisterMemberScreen({super.key, this.initialInviteCode});

  @override
  ConsumerState<RegisterMemberScreen> createState() =>
      _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends ConsumerState<RegisterMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _inviteCodeController;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _gender = 'Female'; // Default matching Image 3 (Nữ checked)
  DateTime _dateOfBirth = DateTime(1992, 10, 22); // Matching Image 3
  bool _obscurePassword = true;
  bool _agreedToTerms = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inviteCodeController = TextEditingController(
      text: widget.initialInviteCode ?? 'DK-CHI2-NHA-A-05',
    );
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatDateVietnamese(DateTime dt) {
    return '${dt.day} tháng ${dt.month}, ${dt.year}';
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với cam kết gia phong'),
          backgroundColor: Color(0xFF9B1C1C),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dobStr =
        "${_dateOfBirth.year.toString().padLeft(4, '0')}-${_dateOfBirth.month.toString().padLeft(2, '0')}-${_dateOfBirth.day.toString().padLeft(2, '0')}";

    final request = RegisterMemberRequestDto(
      inviteCode: _inviteCodeController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      gender: _gender == 'Female' ? 'Female' : 'Male',
      dateOfBirth: dobStr,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    );

    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);
      await dataSource.registerMember(request);

      // Attempt automatic login
      try {
        await ref.read(authStateProvider.notifier).login(
              request.phoneNumber,
              request.password,
            );
        if (mounted) {
          context.go('/home');
        }
      } catch (_) {
        // If account requires approval, navigate to pending approval screen
        if (mounted) {
          context.push('/pending-approval');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFF9B1C1C),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text(
          'Ghi Tên Vào Gia Phả',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner (Image 3 design)
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5A0E10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_stories,
                                    color: Color(0xFFE2AA36), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'SỔ VÀNG GIA TỘC',
                                  style: TextStyle(
                                    color: Color(0xFFE2AA36),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ghi Tên Vào Gia Phả',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nối tiếp tiền nhân • Giữ gìn gia phong muôn thuở',
                            style: TextStyle(
                              color: Color(0xFFE5D5D0),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 1: Mã Gia Tộc
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.qr_code,
                                        color: Color(0xFF7A1518), size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Mã Gia Tộc',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2B1810),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Bắt buộc',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8B6B23),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Mã gia tộc đã được xác nhận để liên kết vào cây phả hệ.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7D6E66),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _inviteCodeController,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF9F6F0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Vui lòng có mã gia tộc'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Thông Tin Thành Viên Mới
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
                                Icon(Icons.person_add_alt_1,
                                    color: Color(0xFF7A1518), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Thông Tin Thành Viên Mới',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 22),

                            // Họ và tên khai sinh *
                            const Text(
                              'Họ và tên khai sinh *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                hintText: 'VD: Nguyễn Thị Mai Anh',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Vui lòng nhập họ và tên'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // Số điện thoại liên lạc *
                            const Text(
                              'Số điện thoại liên lạc *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: 'VD: 0903 888 999',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().length < 8
                                  ? 'SĐT phải từ 8-15 số'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // Giới tính * (Matching Image 3 chips)
                            const Text(
                              'Giới tính *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _gender = 'Male'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _gender == 'Male'
                                            ? const Color(0xFF7A1518)
                                            : const Color(0xFFF7F1EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.male,
                                            size: 20,
                                            color: _gender == 'Male'
                                                ? Colors.white
                                                : const Color(0xFF2B1810),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Nam',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _gender == 'Male'
                                                  ? Colors.white
                                                  : const Color(0xFF2B1810),
                                            ),
                                          ),
                                          if (_gender == 'Male') ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.check_circle,
                                                size: 16, color: Colors.white),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _gender = 'Female'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _gender == 'Female'
                                            ? const Color(0xFF7A1518)
                                            : const Color(0xFFF7F1EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.female,
                                            size: 20,
                                            color: _gender == 'Female'
                                                ? Colors.white
                                                : const Color(0xFF2B1810),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Nữ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _gender == 'Female'
                                                  ? Colors.white
                                                  : const Color(0xFF2B1810),
                                            ),
                                          ),
                                          if (_gender == 'Female') ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.check_circle,
                                                size: 16, color: Colors.white),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Ngày tháng năm sinh (Dương lịch) * (Matching Image 3)
                            const Text(
                              'Ngày tháng năm sinh (Dương lịch) *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateOfBirth,
                                  firstDate: DateTime(1900),
                                  lastDate: now,
                                );
                                if (picked != null) {
                                  setState(() => _dateOfBirth = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F1EB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE8DFD8)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        color: Color(0xFF7A1518), size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      _formatDateVietnamese(_dateOfBirth),
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2B1810),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Email (tùy chọn)
                            const Text(
                              'Email nhận tin dòng họ (tùy chọn)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'VD: maianh@domain.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // CRITICAL SECURITY FIELDS: Mật khẩu & Nhập lại mật khẩu
                            const Text(
                              'Mật khẩu bảo vệ tài khoản *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7A1518),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Tối thiểu 6 ký tự để đăng nhập sau này',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null || v.trim().length < 6
                                  ? 'Mật khẩu tối thiểu 6 ký tự'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Nhập lại mật khẩu *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Nhập lại chính xác mật khẩu trên',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                    const SizedBox(height: 12),

                    // Cam kết gia tộc
                    CheckboxListTile(
                      value: _agreedToTerms,
                      activeColor: const Color(0xFF7A1518),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Tôi cam kết thông tin khai báo là chính xác và đồng ý tuân thủ Tộc ước dòng họ.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      onChanged: (val) =>
                          setState(() => _agreedToTerms = val ?? true),
                    ),
                    const SizedBox(height: 14),

                    // Submit Button (Image 3 design)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitRegistration,
                      icon: const Icon(Icons.how_to_reg, color: Colors.white),
                      label: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Hoàn tất đăng ký & Vào dòng họ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A1518),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Footer security assurance (Image 3)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 16, color: Color(0xFFD4A017)),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Quyền bảo vệ danh dự & sự minh bạch của dòng họ được đảm bảo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7D6E66),
                            ),
                          ),
                        ),
                      ],
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
