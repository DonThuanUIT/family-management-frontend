import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../invitation/presentation/widgets/position_link_quick_claim_card.dart';
import '../providers/auth_state_provider.dart';
import '../widgets/auth_editorial_panel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? initialInviteCode;
  final int initialTabIndex;

  const LoginScreen({
    super.key,
    this.initialInviteCode,
    this.initialTabIndex = 1,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _identifierController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    // Nếu có mã mời truyền vào thì mặc định mở tab "Gia Nhập Bằng Mã Mời" (index 0)
    _selectedTab = (widget.initialInviteCode?.isNotEmpty == true)
        ? 0
        : widget.initialTabIndex;

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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 20,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1040 : 480,
              ),
              child: isDesktop
                  ? _buildDesktopLayout(context, authState)
                  : _buildMobileLayout(context, authState),
            ),
          ),
        ),
      ),
    );
  }

  /// Layout chia 2 cột chuẩn Stitch Screen W1 trên Desktop
  Widget _buildDesktopLayout(BuildContext context, dynamic authState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột trái: Giới thiệu triết lý gia tộc & lời răn Trưởng tộc
          const Expanded(
            flex: 5,
            child: AuthEditorialPanel(),
          ),
          // Cột phải: Form tương tác 2 tab (Mã Mời vs Đăng Nhập)
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: _buildInteractionCard(context, authState),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout dạng thẻ đơn trên Mobile
  Widget _buildMobileLayout(BuildContext context, dynamic authState) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE6DFD8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _buildInteractionCard(context, authState),
      ),
    );
  }

  /// Card tương tác có Segmented Tab chuyển đổi giữa US-19 và Đăng Nhập
  Widget _buildInteractionCard(BuildContext context, dynamic authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        const Text(
          'Chào mừng con cháu',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1A),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Nhập mã mời để vào vị trí phả hệ hoặc đăng nhập tài khoản',
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF6B584E),
          ),
        ),
        const SizedBox(height: 20),

        // Segmented Tab Bar (Stitch Screen W1)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDEB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _selectedTab == 0
                          ? const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.vpn_key_outlined,
                            size: 16,
                            color: _selectedTab == 0
                                ? const Color(0xFF8F482F)
                                : const Color(0xFF54433E),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gia Nhập Bằng Mã Mời',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 0
                                  ? const Color(0xFF8F482F)
                                  : const Color(0xFF54433E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _selectedTab == 1
                          ? const [
                              BoxShadow(
                                color: Color(0x0C000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: _selectedTab == 1
                                ? const Color(0xFF8F482F)
                                : const Color(0xFF54433E),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Đăng Nhập Mật Khẩu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 1
                                  ? const Color(0xFF8F482F)
                                  : const Color(0xFF54433E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Nội dung từng Tab
        if (_selectedTab == 0)
          PositionLinkQuickClaimCard(
            initialCode: widget.initialInviteCode,
          )
        else
          _buildLoginForm(context, authState),

        const SizedBox(height: 24),

        // Footer Navigation Options
        _buildFooterOptions(context),
      ],
    );
  }

  /// Form đăng nhập mật khẩu truyền thống
  Widget _buildLoginForm(BuildContext context, dynamic authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Đăng Nhập Gia Tộc',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A1518),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Truy cập phả hệ & sổ vàng dòng họ của bạn',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B584E),
            ),
          ),
          const SizedBox(height: 16),

          // Error Message Banner
          if (authState.errorMessage != null) ...[
            _buildErrorBanner(context, authState.errorMessage!),
            const SizedBox(height: 14),
          ],

          // Input 1: SĐT hoặc Email
          const Text(
            'Số điện thoại hoặc Email *',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF2B1810),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'VD: 0901234567 hoặc email@domain.com',
              prefixIcon: const Icon(Icons.phone_android_outlined,
                  size: 18, color: Color(0xFF7A1518)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập số điện thoại hoặc email';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Input 2: Mật khẩu
          const Text(
            'Mật khẩu *',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF2B1810),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Nhập mật khẩu tài khoản',
              prefixIcon: const Icon(Icons.lock_outline,
                  size: 18, color: Color(0xFF7A1518)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF7D6E66),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Remember Me & Forgot Password
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: const Color(0xFF7A1518),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (val) {
                      setState(() {
                        _rememberMe = val ?? true;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Ghi nhớ',
                    style: TextStyle(
                      fontSize: 12.5,
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7A1518),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Submit Button
          ElevatedButton(
            onPressed: authState.isLoading ? null : _submitLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A1518),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Đăng Nhập Vào Dòng Họ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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
                color: Color(0xFF7A1518), size: 18),
            label: const Text(
              'Đăng nhập nhanh bằng Sinh trắc học',
              style: TextStyle(
                color: Color(0xFF7A1518),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFFD6C8BF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Quick-pick demo accounts
          const SizedBox(height: 16),
          const Text(
            'Chọn nhanh tài khoản kiểm thử (Mật khẩu chung: 123456):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B584E),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: kDemoAccounts.map((demo) {
              final isSelected =
                  _identifierController.text == demo.identifier;
              return ActionChip(
                avatar: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.account_circle_outlined,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF7A1518),
                ),
                label: Text(
                  demo.roleName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF7A1518),
                  ),
                ),
                backgroundColor: isSelected
                    ? const Color(0xFF7A1518)
                    : const Color(0xFFFAF6F0),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF7A1518)
                      : const Color(0xFFD6C8BF),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  setState(() {
                    _identifierController.text = demo.identifier;
                    _passwordController.text = demo.password;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Footer links
  Widget _buildFooterOptions(BuildContext context) {
    return Column(
      children: [
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
                    fontSize: 11,
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
        const SizedBox(height: 12),

        // Lựa chọn 1: Đăng ký Khởi lập Dòng họ mới (Dành cho Trưởng Tộc)
        OutlinedButton.icon(
          onPressed: () => context.push('/register-creator'),
          icon: const Icon(Icons.account_tree_outlined,
              color: Color(0xFF7A1518), size: 18),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Đăng Ký Khởi Lập Dòng Họ Mới (Trưởng Tộc)',
              style: TextStyle(
                color: Color(0xFF7A1518),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            side: const BorderSide(color: Color(0xFF7A1518), width: 1.1),
            backgroundColor: const Color(0xFF7A1518).withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Lựa chọn 2: Tham gia bằng Mã Thư Mời (Thành Viên / Con Cháu)
        OutlinedButton.icon(
          onPressed: () => context.push('/invite-code'),
          icon: const Icon(Icons.mail_outline,
              color: Color(0xFF6B584E), size: 18),
          label: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Gia Nhập Bằng Mã Mời Gia Tộc (Thành Viên)',
              style: TextStyle(
                color: Color(0xFF4A3831),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            side: const BorderSide(color: Color(0xFFD6C8BF), width: 1.1),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Liên kết quay về trang Chào mừng / Giới thiệu tổng quan
        Center(
          child: TextButton.icon(
            onPressed: () => context.go('/welcome'),
            icon: const Icon(Icons.info_outline,
                size: 15, color: Color(0xFF8C7A70)),
            label: const Text(
              'Xem trang giới thiệu & hướng dẫn đăng ký',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8C7A70),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, String rawError) {
    final isPending = rawError.contains('PendingApproval');
    final isDeactivated = rawError.contains('Deactivated');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPending
            ? const Color(0xFFFFF8E7)
            : isDeactivated
                ? const Color(0xFFFFF1F1)
                : const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(10),
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
                size: 18,
              ),
              const SizedBox(width: 8),
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
                    fontSize: 13,
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
              fontSize: 12,
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/pending-approval'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7A1518),
                  side: const BorderSide(color: Color(0xFF7A1518)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Xem quy trình & trạng thái phê duyệt',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
