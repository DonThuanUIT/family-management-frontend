import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

/// Màn hình chính sau khi đăng nhập thành công.
/// Đóng vai trò là placeholder trang trọng để nhóm phát triển tự xây dựng
/// các màn hình chức năng tiếp theo (Gia phả, Sự kiện, Tài chính...).
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
      appBar: AppBar(
        title: const Text(
          'Gia Tộc Việt Nam',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A1518),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: Color(0xFF7A1518)),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
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
                          'Phân hệ Xác thực & Phân quyền tĩnh đã hoàn tất kết nối với Backend API. '
                          'Các màn hình nghiệp vụ tiếp theo (Gia phả, Sự kiện, Thu chi, Quản lý chi...) '
                          'sẽ do nhóm của bạn tự do thiết kế và lắp ráp tại đây.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF6B584E),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/events'),
                          icon: const Icon(Icons.celebration_outlined),
                          label: const Text(
                            'Quản Lý Sự Kiện & Tế Lễ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7A1518),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ref.read(authStateProvider.notifier).logout();
                            if (context.mounted) {
                              context.go('/welcome');
                            }
                          },
                          icon: const Icon(Icons.logout, color: Color(0xFF7A1518)),
                          label: const Text(
                            'Đăng Xuất Tài Khoản',
                            style: TextStyle(
                              color: Color(0xFF7A1518),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF7A1518)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                fontSize: 13,
                color: Color(0xFF6B584E),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B1810),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
