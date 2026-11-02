import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import 'package:familyfund_app/features/shared/presentation/widgets/heritage_nav_bar.dart';

/// Màn hình chính sau khi đăng nhập thành công.
/// Tích hợp thanh điều hướng HeritageNavBar chuẩn Stitch Warm Editorial.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dualRbacSessionProvider);
    final authState = ref.watch(authStateProvider);

    final fullName = authState.user?.fullName.isNotEmpty == true
        ? authState.user!.fullName
        : session.fullName;
    final accountId = authState.user?.accountId.isNotEmpty == true
        ? authState.user!.accountId
        : session.accountId;
    final memberId = authState.user?.memberId ?? session.memberId;
    final clanId = authState.user?.clanId ?? 'CLAN_DEFAULT';
    final roles = authState.user?.roles ??
        session.globalRoles.map((r) => r.code).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: const HeritageNavBar(currentRoute: '/home'),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/home'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card chào mừng & thông tin tài khoản
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE8DFD8)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7A1518),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFFE2AA36),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2B1810),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mã tài khoản: $accountId',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B584E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          _infoRow('Dòng họ:', clanId),
                          _infoRow('Mã thành viên:',
                              memberId.isNotEmpty ? memberId : '(Chưa liên kết)'),
                          _infoRow('Vai trò:', roles.join(', ')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card thông báo khu vực tự thiết kế
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD4A017),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4A017).withAlpha(25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.dashboard_customize_outlined,
                          size: 48,
                          color: Color(0xFF7A1518),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Khu Vực Thiết Kế Màn Hình Sau Đăng Nhập',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7A1518),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hệ thống quản trị tài chính & phả hệ dòng họ FamilyFund đã kết nối thành công. '
                          'Bạn có thể sử dụng thanh Navbar phía trên hoặc các nút nhanh bên dưới để chuyển đổi giữa các phân hệ.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF6B584E),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => context.go('/contributions'),
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('Sổ Cái Tài Chính (#71)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1E1E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/clan-assets'),
                              icon: const Icon(Icons.inventory_2),
                              label: const Text('Kho Bảo Vật Từ Đường (#74)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB36E1B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/events'),
                              icon: const Icon(Icons.celebration),
                              label: const Text('Sự Kiện Giỗ Tổ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E8B43),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/invite-code'),
                              icon: const Icon(Icons.qr_code_2),
                              label: const Text('Cấp Mã Mời Gia Tộc'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF7A1518),
                                side: const BorderSide(color: Color(0xFF7A1518)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref.read(authStateProvider.notifier).logout();
                                if (context.mounted) {
                                  context.go('/welcome');
                                }
                              },
                              icon: const Icon(Icons.logout, color: Color(0xFF7A1518)),
                              label: const Text('Đăng Xuất Tài Khoản'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF7A1518),
                                side: const BorderSide(color: Color(0xFFDAC1BA)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF54433E),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2B1810),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
