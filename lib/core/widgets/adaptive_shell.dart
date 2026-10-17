import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../security/rbac_models.dart';

/// Khung giao diện thích ứng đa nền tảng (Adaptive Responsive Shell):
/// - Tự động hiển thị Sidebar / NavigationRail trên Web & Tablet (>= 840px)
/// - Tự động hiển thị BottomNavigationBar + Drawer trên Mobile (< 840px)
/// - Hỗ trợ chuyển đổi trực tiếp giữa 2 phân hệ:
///   1. Phân hệ Thành viên / Con cháu (`PortalWorkspaceMode.memberPortal`)
///   2. Phân hệ Quản trị / Trưởng tộc & BTC (`PortalWorkspaceMode.managementPortal`)
///   trên CẢ Mobile App lẫn Web App.
class AdaptiveWorkspaceShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdaptiveWorkspaceShell({
    super.key,
    required this.navigationShell,
  });

  static const List<_NavDestinationItem> _destinations = [
    _NavDestinationItem(
      label: 'Gia phả',
      icon: Icons.account_tree_outlined,
      selectedIcon: Icons.account_tree,
    ),
    _NavDestinationItem(
      label: 'Sự kiện',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
    ),
    _NavDestinationItem(
      label: 'Công việc',
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt,
    ),
    _NavDestinationItem(
      label: 'Công đức',
      icon: Icons.volunteer_activism_outlined,
      selectedIcon: Icons.volunteer_activism,
    ),
    _NavDestinationItem(
      label: 'Quỹ & Sổ cái',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    _NavDestinationItem(
      label: 'Báo cáo',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dualRbacSessionProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWideScreen = width >= 840;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.temple_buddhist_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dòng Họ Nguyễn Trọng • FamilyFund',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${session.fullName} (${session.branchName})',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (session.canAccessManagementPortal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SegmentedButton<PortalWorkspaceMode>(
                segments: const [
                  ButtonSegment(
                    value: PortalWorkspaceMode.memberPortal,
                    icon: Icon(Icons.people_outline, size: 18),
                    label: Text('Thành viên'),
                  ),
                  ButtonSegment(
                    value: PortalWorkspaceMode.managementPortal,
                    icon: Icon(Icons.admin_panel_settings_outlined, size: 18),
                    label: Text('Quản trị / BTC'),
                  ),
                ],
                selected: {session.activePortalMode},
                onSelectionChanged: (selection) {
                  ref
                      .read(dualRbacSessionProvider.notifier)
                      .switchPortalMode(selection.first);
                },
              ),
            ),
          IconButton(
            tooltip: 'Đăng nhập / Hồ sơ định danh',
            onPressed: () => context.push('/auth'),
            icon: const Icon(Icons.verified_user_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isWideScreen)
            NavigationRail(
              extended: width >= 1180,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Chip(
                  avatar: Icon(
                    session.activePortalMode ==
                            PortalWorkspaceMode.managementPortal
                        ? Icons.security
                        : Icons.person_outline,
                    size: 16,
                  ),
                  label: Text(
                    session.activePortalMode.label,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
          if (isWideScreen) const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: _destinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _NavDestinationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavDestinationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
