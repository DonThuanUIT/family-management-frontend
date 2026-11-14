import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_state_provider.dart';
import '../widgets/heritage_auth_split_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _identifierController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    // Mặc định điền sẵn thông tin tài khoản đăng nhập (0901234567 / 123456)
    _identifierController = TextEditingController(text: '0901234567');
    _passwordController = TextEditingController(text: '123456');
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authStateProvider.notifier).login(
            _identifierController.text.trim(),
            _passwordController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công vào dòng họ!'),
            backgroundColor: Color(0xFF0F766E),
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/home');
      }
    } catch (_) {
      // Error is stored in authStateProvider and displayed on UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF7A1518)),
          tooltip: Navigator.of(context).canPop()
              ? 'Quay lại'
              : 'Về trang chào mừng & đăng ký',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/welcome'),
            icon: const Icon(Icons.app_registration,
                size: 18, color: Color(0xFF7A1518)),
            label: const Text(
              'Đăng Ký',
              style: TextStyle(
                color: Color(0xFF7A1518),
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: HeritageAuthSplitShell(
          maxMobileWidth: 440,
          badgeLabel: 'CỔNG ĐĂNG NHẬP GIA PHẢ',
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                    // Small logo header
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7A1518).withAlpha(30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo_gtvn.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: const Color(0xFF7A1518),
                              child: const Icon(
                                Icons.account_balance,
                                color: Color(0xFFD4A017),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đăng Nhập Gia Tộc',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7A1518),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Truy cập phả hệ & sổ vàng dòng họ của bạn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF6B584E),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Error Message Banner (Shows real backend error message)
                    if (authState.errorMessage != null) ...[
                      _buildErrorBanner(context, authState.errorMessage!),
                      const SizedBox(height: 16),
                    ],

                    // Input 1: SĐT hoặc Email
                    const Text(
                      'Số điện thoại hoặc Email *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'VD: 0901234567 hoặc email@domain.com',
                        prefixIcon: const Icon(Icons.phone_android_outlined,
                            color: Color(0xFF7A1518)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại hoặc email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Input 2: Mật khẩu
                    const Text(
                      'Mật khẩu *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu tài khoản',
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF7A1518)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF7D6E66),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: const Color(0xFF7A1518),
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? true;
                                });
                              },
                            ),
                            const Text(
                              'Ghi nhớ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2B1810),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push('/forgot-password'),
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7A1518),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button (Calls online backend REST API)
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A1518),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
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
                              'Đăng Nhập Vào Dòng Họ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Demo Account Picker (V6 seed accounts)
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8DFD8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chọn nhanh tài khoản kiểm thử (Mật khẩu chung):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B584E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: kDemoAccounts.map((account) {
                              final isSelected =
                                  _identifierController.text.trim() ==
                                      account.identifier;
                              return ActionChip(
                                avatar: Icon(
                                  account.roles.contains('ROLE_CLAN_HEAD')
                                      ? Icons.workspace_premium_outlined
                                      : account.roles
                                              .contains('ROLE_BRANCH_HEAD')
                                          ? Icons.account_tree_outlined
                                          : Icons.person_outline,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF7A1518),
                                ),
                                label: Text(
                                  account.roleName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF2B1810),
                                  ),
                                ),
                                backgroundColor: isSelected
                                    ? const Color(0xFF7A1518)
                                    : Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF7A1518)
                                      : const Color(0xFFD6C8BF),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _identifierController.text =
                                        account.identifier;
                                    _passwordController.text = account.password;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Biometrics Mockup Option
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Tính năng Sinh trắc học (Vân tay/Face ID) sẵn sàng khi thiết bị hỗ trợ.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.fingerprint,
                          color: Color(0xFF7A1518)),
                      label: const Text(
                        'Đăng nhập nhanh bằng Sinh trắc học',
                        style: TextStyle(
                          color: Color(0xFF7A1518),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFD6C8BF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 24),

                    // Phân tách & Tiêu đề khu vực Đăng ký
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color(0xFFD6C8BF).withValues(alpha: 0.8),
                          ),
                        ),
                        const Flexible(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'CHƯA CÓ TÀI KHOẢN GIA TỘC?',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Color(0xFF8C7A70),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: const Color(0xFFD6C8BF).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lựa chọn 1: Đăng ký Khởi lập Dòng họ mới (Dành cho Trưởng Tộc)
                    OutlinedButton.icon(
                      onPressed: () => context.push('/register-creator'),
                      icon: const Icon(Icons.account_tree_outlined,
                          color: Color(0xFF7A1518), size: 20),
                      label: const Text(
                        'Đăng Ký Khởi Lập Dòng Họ Mới (Trưởng Tộc)',
                        style: TextStyle(
                          color: Color(0xFF7A1518),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        side: const BorderSide(
                            color: Color(0xFF7A1518), width: 1.2),
                        backgroundColor:
                            const Color(0xFF7A1518).withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Lựa chọn 2: Tham gia bằng Mã Thư Mời (Thành Viên / Con Cháu)
                    OutlinedButton.icon(
                      onPressed: () => context.push('/invite-code'),
                      icon: const Icon(Icons.mail_outline,
                          color: Color(0xFF6B584E), size: 20),
                      label: const Text(
                        'Gia Nhập Bằng Mã Mời Gia Tộc (Thành Viên)',
                        style: TextStyle(
                          color: Color(0xFF4A3831),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        side: const BorderSide(
                            color: Color(0xFFD6C8BF), width: 1.2),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Liên kết quay về trang Chào mừng / Giới thiệu tổng quan
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.go('/welcome'),
                        icon: const Icon(Icons.info_outline,
                            size: 16, color: Color(0xFF8C7A70)),
                        label: const Text(
                          'Xem trang giới thiệu & hướng dẫn đăng ký',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8C7A70),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String rawError) {
    final isPending = rawError.contains('PendingApproval');
    final isDeactivated = rawError.contains('Deactivated');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending
            ? const Color(0xFFFFF8E7)
            : isDeactivated
                ? const Color(0xFFFFF1F1)
                : const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? const Color(0xFFE2AA36)
              : const Color(0xFFF8B4B4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPending
                    ? Icons.hourglass_top_rounded
                    : Icons.error_outline,
                color: isPending
                    ? const Color(0xFF8B6B23)
                    : const Color(0xFF9B1C1C),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPending
                      ? 'Tài khoản đang chờ duyệt'
                      : isDeactivated
                          ? 'Tài khoản chưa được kích hoạt'
                          : 'Đăng nhập không thành công',
                  style: TextStyle(
                    color: isPending
                        ? const Color(0xFF8B6B23)
                        : const Color(0xFF9B1C1C),
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isPending
                ? 'Hồ sơ đề xuất gia nhập dòng họ của bạn đang được Trưởng tộc / Trưởng chi xem xét đối soát.'
                : isDeactivated
                    ? 'Tài khoản đã bị từ chối hoặc tạm khóa. Vui lòng liên hệ Ban quản trị dòng họ để được hỗ trợ.'
                    : rawError,
            style: TextStyle(
              color: isPending
                  ? const Color(0xFF6B584E)
                  : const Color(0xFF9B1C1C),
              fontSize: 12.5,
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/pending-approval'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7A1518),
                  side: const BorderSide(color: Color(0xFF7A1518)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Xem quy trình & trạng thái phê duyệt',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
