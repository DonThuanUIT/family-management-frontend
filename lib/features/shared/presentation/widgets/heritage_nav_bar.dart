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

    final isWide = MediaQuery.of(context).size.width >= 860;

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
                InkWell(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'FamilyFund',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B1810),
                                letterSpacing: -0.3,
                              ),
                            ),
                            Container(
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
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF8B1E1E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 2. Navigation items (Horizontal scrollable row on wide screens)
                if (isWide)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: kHeritageNavItems.map((item) {
                            final isActive = currentRoute == item.route;
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
                                      horizontal: 9, vertical: 7),
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
                                        size: 16,
                                        color: isActive
                                            ? const Color(0xFF8B1E1E)
                                            : const Color(0xFF54433E),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          fontSize: 12.5,
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
                  )
                else
                  const Spacer(),

                // 3. Status Pill & User Profile
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Verified Pill
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

                    const SizedBox(width: 10),
                    Container(
                        width: 1, height: 26, color: const Color(0xFFE6DFD8)),
                    const SizedBox(width: 10),

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
                          if (isWide) ...[
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
