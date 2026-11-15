import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
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
                          Padding(padding: const EdgeInsets.only(top: 16),
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/members/${Uri.encodeComponent(state.profile!.memberId!)}'),
                              icon: const Icon(Icons.auto_stories_outlined),
                              label: const Text('Ảnh chân dung, tiểu sử và tư liệu gia sử'),
                            )),
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
