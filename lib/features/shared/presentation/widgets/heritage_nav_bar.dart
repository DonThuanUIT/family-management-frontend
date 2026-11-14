import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

/// Item trong thanh điều hướng Stitch FamilyFund
class HeritageNavItem {
  final String label;
  final String shortLabel;
  final String route;
  final IconData icon;
  final IconData activeIcon;

  const HeritageNavItem({
    required this.label,
    required this.shortLabel,
    required this.route,
    required this.icon,
    required this.activeIcon,
  });
}

/// Danh sách 5 phân hệ điều hướng cốt lõi theo thiết kế Stitch
const List<HeritageNavItem> kHeritageNavItems = [
  HeritageNavItem(
    label: 'Sổ Cái Tài Chính',
    shortLabel: 'Sổ Cái',
    route: '/contributions',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
  ),
  HeritageNavItem(
    label: 'Kho Bảo Vật',
    shortLabel: 'Bảo Vật',
    route: '/clan-assets',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2,
  ),
  HeritageNavItem(
    label: 'Sự Kiện Giỗ Tổ',
    shortLabel: 'Sự Kiện',
    route: '/events',
    icon: Icons.celebration_outlined,
    activeIcon: Icons.celebration,
  ),
  HeritageNavItem(
    label: 'Cây Phả Hệ',
    shortLabel: 'Phả Hệ',
    route: '/home',
    icon: Icons.account_tree_outlined,
    activeIcon: Icons.account_tree,
  ),
  HeritageNavItem(
    label: 'Cấp Mã Mời',
    shortLabel: 'Mã Mời',
    route: '/clan-invites',
    icon: Icons.qr_code_2_outlined,
    activeIcon: Icons.qr_code_2,
  ),
];

/// Thanh Navbar điều hướng phía trên chuẩn Stitch Warm Editorial Heritage (h-[68px])
class HeritageNavBar extends ConsumerWidget implements PreferredSizeWidget {
  final String currentRoute;
  final String? customTitle;

  const HeritageNavBar({
    super.key,
    required this.currentRoute,
    this.customTitle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dualRbacSessionProvider);
    final authState = ref.watch(authStateProvider);

    final fullName = authState.user?.fullName.isNotEmpty == true
        ? authState.user!.fullName
        : (session.fullName.isNotEmpty ? session.fullName : 'Lê Hữu Tuấn');
    final branchRole = authState.user?.roles.contains('ROLE_CLAN_HEAD') == true
        ? 'Trưởng Tộc • Chi Gốc'
        : (session.branchName.isNotEmpty ? session.branchName : 'Chi 2 (Đời 5)');

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 860;
    final isUltraWide = screenWidth >= 1280;
    final isMediumWide = screenWidth >= 1100;

    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6DFD8), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1360),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 1. Brand Logo & Name
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 280 : MediaQuery.sizeOf(context).width - 116,
                  ),
                  child: InkWell(
                    onTap: () => context.go('/home'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B1E1E), Color(0xFF6B1414)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFD4A017), width: 1.2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.account_balance,
                                color: Color(0xFFD4A017),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  customTitle ?? 'FamilyFund',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B1810),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (isUltraWide)
                                  Container(
                                    margin: const EdgeInsets.only(top: 1.5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0EDEB),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: const Color(0xFFDAC1BA), width: 0.8),
                                    ),
                                    child: Text(
                                      fullName.startsWith('Nguyễn')
                                          ? 'DÒNG HỌ NGUYỄN VIỆT NAM'
                                          : (fullName.startsWith('Lê')
                                              ? 'DÒNG HỌ LÊ VIỆT NAM'
                                              : 'GIA TỘC VIỆT NAM'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 9.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF8B1E1E),
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

                const SizedBox(width: 8),

                // 2. Navigation items (FittedBox with scaleDown to never overlap or clip behind right actions)
                if (isWide)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: kHeritageNavItems.map((item) {
                              final isActive = currentRoute == item.route;
                              final displayLabel =
                                  isMediumWide ? item.label : item.shortLabel;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: InkWell(
                                  onTap: () {
                                    if (!isActive) {
                                      context.go(item.route);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7.5, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFFF5EBE6)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isActive
                                          ? Border.all(
                                              color: const Color(0xFF8B1E1E)
                                                  .withAlpha(60),
                                              width: 1)
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isActive ? item.activeIcon : item.icon,
                                          size: 15,
                                          color: isActive
                                              ? const Color(0xFF8B1E1E)
                                              : const Color(0xFF54433E),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          displayLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isActive
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isActive
                                                ? const Color(0xFF8B1E1E)
                                                : const Color(0xFF54433E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(width: 6),

                // 3. Status Pill & User Profile
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Verified Pill
                    if (isWide) ...[
                      if (screenWidth >= 1180) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006E2A).withAlpha(18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFF006E2A).withAlpha(40),
                                width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  size: 14, color: Color(0xFF006E2A)),
                              SizedBox(width: 4),
                              Text(
                                'Niêm Phong 2026',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006E2A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (screenWidth >= 960) ...[
                        Tooltip(
                          message:
                              'Sổ cái & Hồ sơ gia phả đã được niêm phong số 2026',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006E2A).withAlpha(18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF006E2A).withAlpha(40),
                                  width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    size: 13, color: Color(0xFF006E2A)),
                                SizedBox(width: 3),
                                Text(
                                  '2026',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF006E2A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                          width: 1, height: 24, color: const Color(0xFFE6DFD8)),
                      const SizedBox(width: 8),
                    ],

                    // User Profile & Logout Popover
                    PopupMenuButton<String>(
                      tooltip: 'Tài khoản & Điều hướng',
                      onSelected: (val) async {
                        if (val == 'logout') {
                          await ref.read(authStateProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        } else if (val == 'home') {
                          context.go('/home');
                        } else {
                          context.go(val);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B1810))),
                              Text(branchRole,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF6B584E))),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        ...kHeritageNavItems.map(
                          (nav) => PopupMenuItem(
                            value: nav.route,
                            child: Row(
                              children: [
                                Icon(nav.icon,
                                    size: 18,
                                    color: currentRoute == nav.route
                                        ? const Color(0xFF8B1E1E)
                                        : const Color(0xFF54433E)),
                                const SizedBox(width: 10),
                                Text(nav.label,
                                    style: TextStyle(
                                      fontWeight: currentRoute == nav.route
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: currentRoute == nav.route
                                          ? const Color(0xFF8B1E1E)
                                          : const Color(0xFF2B1810),
                                    )),
                              ],
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: '/roles',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings_outlined,
                                  size: 18,
                                  color: currentRoute == '/roles'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF54433E)),
                              const SizedBox(width: 10),
                              Text(
                                'Phân Quyền Vai Trò',
                                style: TextStyle(
                                  fontWeight: currentRoute == '/roles'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: currentRoute == '/roles'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF2B1810),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: '/join-requests',
                          child: Row(
                            children: [
                              Icon(Icons.how_to_reg_outlined,
                                  size: 18,
                                  color: currentRoute == '/join-requests'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF54433E)),
                              const SizedBox(width: 10),
                              Text(
                                'Quản Lý Đơn Gia Nhập',
                                style: TextStyle(
                                  fontWeight: currentRoute == '/join-requests'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: currentRoute == '/join-requests'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF2B1810),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: '/audit-logs',
                          child: Row(
                            children: [
                              Icon(Icons.history_edu_outlined,
                                  size: 18,
                                  color: currentRoute == '/audit-logs'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF54433E)),
                              const SizedBox(width: 10),
                              Text(
                                'Nhật Ký Thao Tác (Audit Log)',
                                style: TextStyle(
                                  fontWeight: currentRoute == '/audit-logs'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: currentRoute == '/audit-logs'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF2B1810),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: '/profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 18,
                                  color: currentRoute == '/profile'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF54433E)),
                              const SizedBox(width: 10),
                              Text(
                                'Hồ Sơ Cá Nhân',
                                style: TextStyle(
                                  fontWeight: currentRoute == '/profile'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: currentRoute == '/profile'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF2B1810),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: '/privacy-settings',
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  size: 18,
                                  color: currentRoute == '/privacy-settings'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF54433E)),
                              const SizedBox(width: 10),
                              Text(
                                'Quyền Riêng Tư Cá Nhân',
                                style: TextStyle(
                                  fontWeight: currentRoute == '/privacy-settings'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: currentRoute == '/privacy-settings'
                                      ? const Color(0xFF8B1E1E)
                                      : const Color(0xFF2B1810),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout,
                                  size: 18, color: Color(0xFF9B1C1C)),
                              SizedBox(width: 10),
                              Text('Đăng Xuất Dòng Họ',
                                  style: TextStyle(color: Color(0xFF9B1C1C))),
                            ],
                          ),
                        ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isWide && screenWidth >= 1060) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                                if (isUltraWide)
                                  Text(
                                    branchRole,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF6B584E),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A1518),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFD4A017), width: 1.2),
                            ),
                            child: Center(
                              child: Text(
                                fullName.isNotEmpty
                                    ? fullName.trim().split(' ').last[0].toUpperCase()
                                    : 'T',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down,
                              color: Color(0xFF54433E), size: 18),
                        ],
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

/// Thanh Bottom Navigation Bar trên thiết bị di động (Mobile / Narrow Screens)
class HeritageBottomNavBar extends StatelessWidget {
  final String currentRoute;

  const HeritageBottomNavBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 860;
    if (!isMobile) return const SizedBox.shrink();

    int currentIndex = kHeritageNavItems.indexWhere((i) => i.route == currentRoute);
    if (currentIndex < 0) currentIndex = 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE6DFD8), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index != currentIndex) {
            context.go(kHeritageNavItems[index].route);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF8B1E1E),
        unselectedItemColor: const Color(0xFF7D6E66),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 8,
        items: kHeritageNavItems.map((item) {
          final isSelected = currentRoute == item.route;
          return BottomNavigationBarItem(
            icon: Icon(isSelected ? item.activeIcon : item.icon, size: 22),
            label: item.shortLabel,
          );
        }).toList(),
      ),
    );
  }
}
