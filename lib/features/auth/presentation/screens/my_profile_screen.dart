import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../../contribution/data/models/contribution_models.dart';
import '../../../contribution/presentation/providers/contribution_ui_provider.dart';
import '../providers/auth_state_provider.dart';
import '../providers/profile_provider.dart';

/// Màn hình Hồ sơ cá nhân của thành viên (US-22).
/// Cho phép:
/// 1. Xem thông tin phả hệ cố định ở chế độ Read-only (Họ tên, ngày sinh, đời thứ, chi tộc).
/// 2. Cập nhật các trường thông tin liên lạc (Số điện thoại, email, địa chỉ thường trú).
/// 3. Đổi mật khẩu tài khoản tự phục vụ an toàn.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  // Form liên lạc
  final _contactFormKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  // Form đổi mật khẩu
  final _passwordFormKey = GlobalKey<FormState>();
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool _isContactInitialized = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _populateContactFields(ProfileState state) {
    if (state.profile != null && !_isContactInitialized) {
      _phoneController.text = state.profile!.phoneNumber;
      _emailController.text = state.profile!.email ?? '';
      _addressController.text = state.profile!.address ?? '';
      _isContactInitialized = true;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Chưa cập nhật';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day/$month/$year';
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'Chưa rõ';
    switch (gender.toUpperCase()) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }

  String _formatRole(String role) {
    switch (role.toUpperCase()) {
      case 'TRUONG_TOC':
        return 'Trưởng tộc';
      case 'TRUONG_NHANH':
        return 'Trưởng nhánh';
      case 'THU_QUY':
        return 'Thủ quỹ';
      case 'THANH_VIEN':
        return 'Thành viên';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    // Điền dữ liệu liên lạc vào controller khi tải xong hồ sơ lần đầu
    _populateContactFields(state);

    // Lắng nghe sự kiện thông báo lỗi hoặc thành công
    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: const Color(0xFF9B1C1C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(next.successMessage!)),
              ],
            ),
            backgroundColor: const Color(0xFF006E2A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: const HeritageNavBar(
        currentRoute: '/profile',
        customTitle: 'Hồ Sơ Cá Nhân',
      ),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/profile'),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryCrimson),
            )
          : RefreshIndicator(
              color: AppTheme.primaryCrimson,
              onRefresh: () async {
                _isContactInitialized = false;
                ref.invalidate(clanBankingInfoProvider);
                await notifier.loadProfile();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderCard(context, state),
                        const SizedBox(height: 20),
                        _buildGenealogyImmutableCard(context, state),
                        if (state.profile?.memberId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/members/${Uri.encodeComponent(state.profile!.memberId!)}'),
                              icon: const Icon(Icons.auto_stories_outlined),
                              label: const Text('Ảnh chân dung, tiểu sử và tư liệu gia sử'),
                            ),
                          ),
                        const SizedBox(height: 20),
                        _buildClanBankingCard(context, state),
                        const SizedBox(height: 20),
                        _buildContactEditableCard(context, state, notifier),
                        const SizedBox(height: 20),
                        _buildPasswordChangeCard(context, state, notifier),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // Header thông tin đại diện tóm tắt
  Widget _buildHeaderCard(BuildContext context, ProfileState state) {
    final profile = state.profile;
    final fullName = profile?.fullName ?? 'Thành viên Dòng họ';
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim().split(' ').last[0].toUpperCase()
        : 'T';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1E1E), Color(0xFF5A1212)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4A017), width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1810),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chi tộc: ${profile?.branchName ?? "Chưa gán nhánh"} • Đời thứ: ${profile?.generation ?? "Chưa rõ"}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7D6E66),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (profile?.roles != null && profile!.roles.isNotEmpty)
                      ...profile.roles.map(
                        (r) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B1E1E).withAlpha(16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF8B1E1E).withAlpha(40),
                            ),
                          ),
                          child: Text(
                            _formatRole(r),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B1E1E),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1E1E).withAlpha(16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Thành viên',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B1E1E),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006E2A).withAlpha(16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF006E2A).withAlpha(40),
                        ),
                      ),
                      child: Text(
                        profile?.accountStatus == 'ACTIVE' ? 'Đã kích hoạt' : 'Hợp lệ',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF006E2A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Khối 1: Thông tin phả hệ & nhân khẩu cố định (Read-Only)
  Widget _buildGenealogyImmutableCard(BuildContext context, ProfileState state) {
    final p = state.profile;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8860B).withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFFB8860B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông Tin Phả Hệ Nhân Khẩu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    Text(
                      'Bảo vệ tính toàn vẹn lịch sử dòng họ (Chỉ xem)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7D6E66),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFEA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDCD4CB)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 13, color: Color(0xFF7D6E66)),
                    SizedBox(width: 4),
                    Text(
                      'Read-only',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7D6E66),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Banner giải thích lý do Read-Only
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xFFB8860B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Các trường nhân khẩu và phả hệ (Họ tên, Ngày sinh, Giới tính, Đời thứ, Chi tộc) được niêm phong để đảm bảo tính chuẩn xác của gia phả. Nếu phát hiện sai sót, vui lòng liên hệ Trưởng tộc hoặc Trưởng nhánh để được hiệu đính.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5D4037),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Grid hiển thị các trường cố định
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              _buildReadOnlyField(
                label: 'Họ và tên',
                value: p?.fullName ?? 'Chưa cập nhật',
                icon: Icons.person_outline,
                widthFactor: 0.47,
              ),
              _buildReadOnlyField(
                label: 'Ngày sinh',
                value: _formatDate(p?.dateOfBirth),
                icon: Icons.cake_outlined,
                widthFactor: 0.47,
              ),
              _buildReadOnlyField(
                label: 'Giới tính',
                value: _formatGender(p?.gender),
                icon: Icons.wc_outlined,
                widthFactor: 0.47,
              ),
              _buildReadOnlyField(
                label: 'Đời thứ (Thế hệ)',
                value: p?.generation != null ? 'Đời thứ ${p!.generation}' : 'Chưa gán',
                icon: Icons.account_tree_outlined,
                widthFactor: 0.47,
              ),
              _buildReadOnlyField(
                label: 'Chi nhánh / Phân chi',
                value: p?.branchName ?? 'Chưa phân nhánh',
                icon: Icons.holiday_village_outlined,
                widthFactor: 0.97,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required double widthFactor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 600
            ? constraints.maxWidth
            : (constraints.maxWidth * widthFactor);

        return SizedBox(
          width: itemWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFECE6DF)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF8C7E77)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8C7E77),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B1810),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.lock, size: 14, color: Color(0xFFBDB4AC)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Khối: Tài khoản thụ hưởng & Cấu hình VietQR của Dòng họ
  Widget _buildClanBankingCard(BuildContext context, ProfileState state) {
    final authState = ref.watch(authStateProvider);
    final isClanHead = authState.user?.roles.any((r) =>
            r.toUpperCase() == 'ROLE_CLAN_HEAD' ||
            r.toUpperCase() == 'TRUONG_TOC' ||
            r.toUpperCase() == 'ROLE_ADMIN' ||
            r.toUpperCase() == 'ADMIN') == true ||
        (state.profile?.roles.any((r) =>
            r.toUpperCase() == 'ROLE_CLAN_HEAD' ||
            r.toUpperCase() == 'TRUONG_TOC' ||
            r.toUpperCase() == 'ROLE_ADMIN' ||
            r.toUpperCase() == 'ADMIN') == true);

    final clanBankingAsync = ref.watch(clanBankingInfoProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E1E).withAlpha(16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Color(0xFF8B1E1E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tài Khoản Thụ Hưởng Quỹ Dòng Họ (VietQR)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    Text(
                      'Thông tin tài khoản nhận công đức, cúng tiến để tự động sinh mã VietQR',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7D6E66),
                      ),
                    ),
                  ],
                ),
              ),
              if (isClanHead)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 13, color: Color(0xFFB8860B)),
                      SizedBox(width: 4),
                      Text(
                        'Trưởng tộc',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB8860B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          clanBankingAsync.when(
            data: (banking) => _buildClanBankingContent(context, banking, isClanHead),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppTheme.primaryCrimson),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEDED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF5C2C7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFF842029), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không thể tải thông tin tài khoản: $err',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF842029)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(clanBankingInfoProvider),
                    child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClanBankingContent(
    BuildContext context,
    ClanBankingInfoDto banking,
    bool isClanHead,
  ) {
    final qrData = _buildPreviewVietQrPayload(
      bankBin: banking.bankBin,
      accountNumber: banking.bankAccountNumber,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 560;

            final infoColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBankingField(
                  label: 'Dòng họ thụ hưởng',
                  value: banking.clanName ?? 'Dòng họ',
                  icon: Icons.temple_buddhist_outlined,
                ),
                const SizedBox(height: 10),
                _buildBankingField(
                  label: 'Ngân hàng thụ hưởng',
                  value: '${banking.bankName ?? "Napas"} (BIN: ${banking.bankBin})',
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 10),
                _buildBankingField(
                  label: 'Số tài khoản nhận tiền',
                  value: banking.bankAccountNumber.isNotEmpty
                      ? banking.bankAccountNumber
                      : 'Chưa cấu hình',
                  icon: Icons.credit_card_outlined,
                  onCopy: banking.bankAccountNumber.isNotEmpty
                      ? () {
                          Clipboard.setData(ClipboardData(text: banking.bankAccountNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép số tài khoản vào bộ nhớ tạm'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 10),
                _buildBankingField(
                  label: 'Tên chủ tài khoản (Người đại diện quỹ)',
                  value: banking.bankAccountName.isNotEmpty
                      ? banking.bankAccountName
                      : 'Chưa cấu hình',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 10),
                _buildBankingField(
                  label: 'Mẫu mã QR chuẩn',
                  value: banking.qrTemplate == 'compact2'
                      ? 'Khung thông minh (compact2)'
                      : banking.qrTemplate == 'compact'
                          ? 'Rút gọn (compact)'
                          : 'Mã QR thuần (qr_only)',
                  icon: Icons.qr_code_2_outlined,
                ),
              ],
            );

            final qrColumn = Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEADBCE)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (banking.bankAccountNumber.isNotEmpty && banking.bankBin.isNotEmpty)
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 150,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF8B1E1E),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF2B1810),
                      ),
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    )
                  else
                    Container(
                      width: 150,
                      height: 150,
                      alignment: Alignment.center,
                      child: const Text(
                        'Chưa có mã QR\nVui lòng cập nhật STK',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF7D6E66)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mã QR Thử Nghiệm',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B1810),
                    ),
                  ),
                  const Text(
                    'Quét bằng app ngân hàng',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7D6E66),
                    ),
                  ),
                ],
              ),
            );

            if (isNarrow) {
              return Column(
                children: [
                  infoColumn,
                  const SizedBox(height: 16),
                  Center(child: qrColumn),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: infoColumn),
                  const SizedBox(width: 20),
                  qrColumn,
                ],
              );
            }
          },
        ),
        const SizedBox(height: 18),
        if (isClanHead)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showEditClanBankingDialog(context, banking),
              icon: const Icon(Icons.edit_note, size: 20),
              label: const Text(
                'Cập Nhật Tài Khoản Ngân Hàng Dòng Họ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E1E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF7D6E66)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chỉ Trưởng tộc hoặc Quản trị viên mới có quyền cập nhật tài khoản ngân hàng chính thức của dòng họ.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7D6E66)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBankingField({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECE6DF)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8B1E1E)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8C7E77),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B1810),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 16, color: Color(0xFF8B1E1E)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Sao chép',
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Future<void> _showEditClanBankingDialog(
    BuildContext context,
    ClanBankingInfoDto currentBanking,
  ) async {
    final formKey = GlobalKey<FormState>();

    BankInfoItem selectedBank = kSupportedBanks.firstWhere(
      (b) => b.bin == currentBanking.bankBin,
      orElse: () => kSupportedBanks.first,
    );

    final accountCtrl = TextEditingController(text: currentBanking.bankAccountNumber);
    final holderCtrl = TextEditingController(text: currentBanking.bankAccountName);
    String selectedTemplate = currentBanking.qrTemplate.isNotEmpty ? currentBanking.qrTemplate : 'compact2';
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFFDF8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E1E).withAlpha(16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance, color: Color(0xFF8B1E1E), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cập Nhật Tài Khoản Dòng Họ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        Text(
                          'Đồng bộ với hệ thống VietQR tự động',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF7D6E66)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chọn Ngân hàng
                        const Text(
                          'Ngân hàng thụ hưởng *',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2B1810)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<BankInfoItem>(
                          initialValue: selectedBank,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.account_balance_outlined, color: Color(0xFF8B1E1E), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFFCFAF7),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: kSupportedBanks.map((bank) {
                            return DropdownMenuItem<BankInfoItem>(
                              value: bank,
                              child: Text(
                                bank.name,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF2B1810)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: isSubmitting
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      selectedBank = val;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 14),

                        // Số tài khoản ngân hàng
                        const Text(
                          'Số tài khoản ngân hàng *',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2B1810)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: accountCtrl,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Nhập số tài khoản ngân hàng chính thức',
                            prefixIcon: const Icon(Icons.credit_card_outlined, color: Color(0xFF8B1E1E), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFFCFAF7),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Vui lòng nhập số tài khoản ngân hàng';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Tên chủ tài khoản
                        const Text(
                          'Tên chủ tài khoản (Viết hoa không dấu hoặc có dấu) *',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2B1810)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: holderCtrl,
                          enabled: !isSubmitting,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                              (oldVal, newVal) => TextEditingValue(
                                text: newVal.text.toUpperCase(),
                                selection: newVal.selection,
                              ),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Ví dụ: NGUYEN TRONG HOANG',
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF8B1E1E), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFFCFAF7),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Vui lòng nhập tên chủ tài khoản';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Mẫu hiển thị mã VietQR
                        const Text(
                          'Kiểu mẫu hiển thị VietQR',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2B1810)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedTemplate,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.qr_code_2_outlined, color: Color(0xFF8B1E1E), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFFCFAF7),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'compact2',
                              child: Text('Khung thông minh (compact2 - Khuyên dùng)'),
                            ),
                            DropdownMenuItem(
                              value: 'compact',
                              child: Text('Khung rút gọn (compact)'),
                            ),
                            DropdownMenuItem(
                              value: 'qr_only',
                              child: Text('Chỉ mã QR thuần (qr_only)'),
                            ),
                          ],
                          onChanged: isSubmitting
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setDialogState(() {
                                      selectedTemplate = val;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Color(0xFFB8860B)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sau khi lưu, mọi mã QR cúng tiến trên toàn hệ thống sẽ tự động cập nhật ngay lập tức theo số tài khoản mới này.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy Bỏ', style: TextStyle(color: Color(0xFF7D6E66))),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setDialogState(() {
                              isSubmitting = true;
                            });
                            try {
                              final request = UpdateClanBankingRequestDto(
                                bankBin: selectedBank.bin,
                                bankAccountNumber: accountCtrl.text.trim(),
                                bankAccountName: holderCtrl.text.trim(),
                                qrTemplate: selectedTemplate,
                              );

                              await ref.read(contributionUiProvider.notifier).updateClanBankingInfo(request);

                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Expanded(child: Text('Cập nhật tài khoản ngân hàng dòng họ thành công!')),
                                      ],
                                    ),
                                    backgroundColor: Color(0xFF006E2A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text('Lỗi khi cập nhật tài khoản: $e')),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF9B1C1C),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    isSubmitting ? 'Đang lưu...' : 'Lưu Cập Nhật',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCrimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _buildPreviewVietQrPayload({
    required String bankBin,
    required String accountNumber,
  }) {
    if (bankBin.isEmpty || accountNumber.isEmpty) {
      return 'vietqr://$bankBin/$accountNumber';
    }

    String tlv(String tag, String value) {
      final len = value.length.toString().padLeft(2, '0');
      return '$tag$len$value';
    }

    String calcCrc16(String str) {
      int crc = 0xFFFF;
      for (int i = 0; i < str.length; i++) {
        int c = str.codeUnitAt(i);
        crc ^= (c << 8);
        for (int j = 0; j < 8; j++) {
          if ((crc & 0x8000) != 0) {
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
          } else {
            crc = (crc << 1) & 0xFFFF;
          }
        }
      }
      return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
    }

    final f00 = tlv('00', '01');
    final f01 = tlv('01', '11');

    final guid = tlv('00', 'A000000727');
    final beneficiary = tlv('00', bankBin) + tlv('01', accountNumber);
    final sub38_01 = tlv('01', beneficiary);
    final serviceCode = tlv('02', 'QRIBFTTA');
    final f38 = tlv('38', guid + sub38_01 + serviceCode);

    final f53 = tlv('53', '704');
    final f58 = tlv('58', 'VN');

    final rawWithoutCrc = '$f00$f01$f38$f53$f58' '6304';
    final crc = calcCrc16(rawWithoutCrc);
    return '$rawWithoutCrc$crc';
  }

  // Khối 2: Cập nhật thông tin liên lạc (Chỉnh sửa được)
  Widget _buildContactEditableCard(
    BuildContext context,
    ProfileState state,
    ProfileNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Form(
        key: _contactFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E1E).withAlpha(16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.contact_phone_outlined,
                    color: Color(0xFF8B1E1E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông Tin Liên Lạc Cá Nhân',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                      Text(
                        'Thành viên được tự do cập nhật địa chỉ, SĐT và Email',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7D6E66),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Số điện thoại (bắt buộc, 10 chữ số)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại liên lạc *',
                hintText: 'Ví dụ: 0912345678',
                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF8B1E1E)),
                filled: true,
                fillColor: const Color(0xFFFCFAF7),
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
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập số điện thoại liên lạc';
                }
                final cleaned = val.trim();
                final phoneRegex = RegExp(r'^0[0-9]{9}$');
                if (!phoneRegex.hasMatch(cleaned)) {
                  return 'Số điện thoại không hợp lệ (cần 10 chữ số, bắt đầu bằng 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Email (tùy chọn)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Địa chỉ Email (Tùy chọn)',
                hintText: 'thanhvien@dongho.vn',
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8B1E1E)),
                filled: true,
                fillColor: const Color(0xFFFCFAF7),
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
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final emailRegex =
                      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Định dạng email không hợp lệ';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Địa chỉ thường trú (tùy chọn)
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Địa chỉ thường trú (Tùy chọn)',
                hintText: 'Số nhà, ngõ/xóm, xã/phường, quận/huyện, tỉnh/thành phố...',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.location_on_outlined, color: Color(0xFF8B1E1E)),
                ),
                filled: true,
                fillColor: const Color(0xFFFCFAF7),
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
            const SizedBox(height: 20),
            // Nút Lưu thông tin liên lạc
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: state.isUpdatingContact
                    ? null
                    : () async {
                        if (_contactFormKey.currentState?.validate() ?? false) {
                          await notifier.updateContactProfile(
                            phoneNumber: _phoneController.text.trim(),
                            email: _emailController.text.trim().isEmpty
                                ? null
                                : _emailController.text.trim(),
                            address: _addressController.text.trim().isEmpty
                                ? null
                                : _addressController.text.trim(),
                          );
                        }
                      },
                icon: state.isUpdatingContact
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(
                  state.isUpdatingContact
                      ? 'Đang lưu...'
                      : 'Lưu Thông Tin Liên Lạc',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCrimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Khối 3: Đổi mật khẩu tài khoản (Tự phục vụ)
  Widget _buildPasswordChangeCard(
    BuildContext context,
    ProfileState state,
    ProfileNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006E2A).withAlpha(16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.password_rounded,
                    color: Color(0xFF006E2A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đổi Mật Khẩu Đăng Nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                      Text(
                        'Tự phục vụ bảo mật tài khoản cá nhân',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7D6E66),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Mật khẩu hiện tại
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu hiện tại *',
                hintText: 'Nhập mật khẩu bạn đang dùng',
                prefixIcon: const Icon(Icons.lock_open_outlined, color: Color(0xFF7D6E66)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF7D6E66),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFFCFAF7),
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
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Vui lòng nhập mật khẩu hiện tại';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Mật khẩu mới
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới * (Tối thiểu 6 ký tự)',
                hintText: 'Nhập mật khẩu mới an toàn',
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF7D6E66)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF7D6E66),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFFCFAF7),
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
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Vui lòng nhập mật khẩu mới';
                }
                if (val.length < 6) {
                  return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                }
                if (val == _currentPasswordController.text) {
                  return 'Mật khẩu mới không được trùng với mật khẩu hiện tại';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Xác nhận mật khẩu mới
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Xác nhận lại mật khẩu mới *',
                hintText: 'Nhập lại chính xác mật khẩu mới',
                prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF7D6E66)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF7D6E66),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                filled: true,
                fillColor: const Color(0xFFFCFAF7),
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
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Vui lòng xác nhận lại mật khẩu mới';
                }
                if (val != _newPasswordController.text) {
                  return 'Mật khẩu xác nhận không khớp với mật khẩu mới';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Nút Xác nhận đổi mật khẩu
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: state.isChangingPassword
                    ? null
                    : () async {
                        if (_passwordFormKey.currentState?.validate() ?? false) {
                          final success = await notifier.changePassword(
                            currentPassword: _currentPasswordController.text,
                            newPassword: _newPasswordController.text,
                            confirmPassword: _confirmPasswordController.text,
                          );
                          if (success) {
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                          }
                        }
                      },
                icon: state.isChangingPassword
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.vpn_key_outlined, size: 18),
                label: Text(
                  state.isChangingPassword ? 'Đang xử lý...' : 'Cập Nhật Mật Khẩu',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B1810),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thông tin định danh ngân hàng hỗ trợ chuẩn Napas / VietQR
class BankInfoItem {
  final String bin;
  final String shortName;
  final String name;

  const BankInfoItem({
    required this.bin,
    required this.shortName,
    required this.name,
  });
}

const List<BankInfoItem> kSupportedBanks = [
  BankInfoItem(bin: '970422', shortName: 'MBBank', name: 'MBBank - Ngân hàng TMCP Quân Đội'),
  BankInfoItem(bin: '970436', shortName: 'Vietcombank', name: 'Vietcombank - Ngân hàng TMCP Ngoại Thương VN'),
  BankInfoItem(bin: '970407', shortName: 'Techcombank', name: 'Techcombank - Ngân hàng TMCP Kỹ Thương VN'),
  BankInfoItem(bin: '970415', shortName: 'VietinBank', name: 'VietinBank - Ngân hàng TMCP Công Thương VN'),
  BankInfoItem(bin: '970418', shortName: 'BIDV', name: 'BIDV - Ngân hàng TMCP Đầu Tư & Phát Triển VN'),
  BankInfoItem(bin: '970423', shortName: 'TPBank', name: 'TPBank - Ngân hàng TMCP Tiên Phong'),
  BankInfoItem(bin: '970432', shortName: 'VPBank', name: 'VPBank - Ngân hàng TMCP Việt Nam Thịnh Vượng'),
  BankInfoItem(bin: '970416', shortName: 'ACB', name: 'ACB - Ngân hàng TMCP Á Châu'),
  BankInfoItem(bin: '970405', shortName: 'Agribank', name: 'Agribank - Ngân hàng Nông Nghiệp & PTNT VN'),
  BankInfoItem(bin: '970441', shortName: 'VIB', name: 'VIB - Ngân Hàng Quốc Tế'),
  BankInfoItem(bin: '970448', shortName: 'OCB', name: 'OCB - Ngân hàng TMCP Phương Đông'),
  BankInfoItem(bin: '970443', shortName: 'SHB', name: 'SHB - Ngân hàng TMCP Sài Gòn - Hà Nội'),
  BankInfoItem(bin: '970428', shortName: 'NamABank', name: 'NamABank - Ngân hàng TMCP Nam Á'),
  BankInfoItem(bin: '970454', shortName: 'VietCapitalBank', name: 'BVBank - Ngân hàng Bản Việt'),
];
