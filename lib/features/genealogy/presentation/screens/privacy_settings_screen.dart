import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../providers/member_privacy_provider.dart';

/// Màn hình Cài đặt Quyền riêng tư Cá nhân của Thành viên (US-25).
/// Cho phép thành viên tự quyết định chia sẻ ngày sinh, số điện thoại và email.
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memberPrivacyProvider);
    final notifier = ref.read(memberPrivacyProvider.notifier);
    final authUser = ref.watch(authStateProvider).user;

    // Lắng nghe thay đổi để hiển thị thông báo
    ref.listen<MemberPrivacyState>(memberPrivacyProvider, (prev, next) {
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
        currentRoute: '/privacy-settings',
        customTitle: 'Quyền Riêng Tư Cá Nhân',
      ),
      bottomNavigationBar:
          const HeritageBottomNavBar(currentRoute: '/privacy-settings'),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryCrimson),
            )
          : RefreshIndicator(
              color: AppTheme.primaryCrimson,
              onRefresh: () => notifier.loadSettings(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoBanner(context),
                        const SizedBox(height: 20),
                        _buildSettingsCard(context, state, notifier),
                        const SizedBox(height: 20),
                        _buildLivePreviewCard(context, state, authUser?.fullName),
                        const SizedBox(height: 24),
                        _buildActionButtons(context, state, notifier),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.secondaryGold, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quy tắc Bảo mật Dữ liệu Dòng họ',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1810),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mặc định, ngày sinh, số điện thoại và email của bạn được giữ kín đối với các thành viên khác. Nếu bật chia sẻ, toàn thể người trong họ có thể tra cứu thông tin này. Riêng Trưởng tộc và Trưởng nhánh vẫn có quyền xem để phục vụ điều hành phả hệ.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Color(0xFF54433E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    MemberPrivacyState state,
    MemberPrivacyNotifier notifier,
  ) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE6DFD8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Text(
                'Tùy chọn chia sẻ thông tin',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B1810),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0EBE5)),
            _buildSwitchItem(
              title: 'Chia sẻ ngày sinh & tuổi tác',
              subtitle:
                  'Cho phép các thành viên khác xem ngày, tháng, năm sinh trên cây phả hệ.',
              icon: Icons.cake_outlined,
              value: state.draftShareDateOfBirth,
              onChanged: notifier.toggleShareDateOfBirth,
            ),
            const Divider(height: 1, color: Color(0xFFF0EBE5), indent: 56),
            _buildSwitchItem(
              title: 'Chia sẻ số điện thoại liên lạc',
              subtitle:
                  'Cho phép hiển thị số điện thoại trên danh bạ liên lạc họ tộc.',
              icon: Icons.phone_outlined,
              value: state.draftSharePhoneNumber,
              onChanged: notifier.toggleSharePhoneNumber,
            ),
            const Divider(height: 1, color: Color(0xFFF0EBE5), indent: 56),
            _buildSwitchItem(
              title: 'Chia sẻ hòm thư điện tử (Email)',
              subtitle:
                  'Cho phép thành viên gửi email trao đổi hoặc nhận thông báo việc họ.',
              icon: Icons.email_outlined,
              value: state.draftShareEmail,
              onChanged: notifier.toggleShareEmail,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppTheme.primaryCrimson,
      activeThumbColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value
              ? AppTheme.primaryCrimson.withAlpha(20)
              : const Color(0xFFF2ECE6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: value ? AppTheme.primaryCrimson : const Color(0xFF7D6E66),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2B1810),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF7D6E66)),
      ),
    );
  }

  Widget _buildLivePreviewCard(
    BuildContext context,
    MemberPrivacyState state,
    String? userName,
  ) {
    final name = userName?.isNotEmpty == true ? userName! : 'Thành viên gia tộc';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFD7CE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF54433E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Xem trước: Hiển thị với thành viên thông thường',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8E2DA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryCrimson.withAlpha(20),
                      child: Text(
                        name.trim().split(' ').last[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryCrimson,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildPreviewRow(
                  icon: Icons.cake_outlined,
                  label: 'Ngày sinh',
                  isVisible: state.draftShareDateOfBirth,
                  visibleText: '15/08/1990',
                  restrictedText: 'Ngày sinh riêng tư',
                ),
                const SizedBox(height: 6),
                _buildPreviewRow(
                  icon: Icons.phone_outlined,
                  label: 'Số điện thoại',
                  isVisible: state.draftSharePhoneNumber,
                  visibleText: '0912 345 678',
                  restrictedText: 'Số điện thoại riêng tư',
                ),
                const SizedBox(height: 6),
                _buildPreviewRow(
                  icon: Icons.email_outlined,
                  label: 'Hòm thư email',
                  isVisible: state.draftShareEmail,
                  visibleText: 'thanhvien@familyfund.vn',
                  restrictedText: 'Email riêng tư',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow({
    required IconData icon,
    required String label,
    required bool isVisible,
    required String visibleText,
    required String restrictedText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF7D6E66)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF7D6E66)),
        ),
        if (isVisible)
          Text(
            visibleText,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B1810),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBE5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 11, color: Color(0xFF8F482F)),
                const SizedBox(width: 4),
                Text(
                  restrictedText,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8F482F),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    MemberPrivacyState state,
    MemberPrivacyNotifier notifier,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (state.hasChanges) ...[
          OutlinedButton(
            onPressed: state.isSaving ? null : notifier.resetChanges,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              side: const BorderSide(color: Color(0xFFD4C8BC)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Khôi phục',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF54433E),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed:
              (state.hasChanges && !state.isSaving) ? notifier.saveSettings : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryCrimson,
            disabledBackgroundColor: const Color(0xFFD8D2CB),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 1,
          ),
          child: state.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}
