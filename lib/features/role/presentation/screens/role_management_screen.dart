import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/adaptive_modal.dart';
import '../../../event/presentation/providers/event_providers.dart';
import '../providers/role_providers.dart';
import '../widgets/assign_role_bottom_sheet.dart';
import '../widgets/audit_log_tab.dart';
import '../widgets/branch_roles_tab.dart';
import '../widgets/event_roles_tab.dart';

class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() =>
      _RoleManagementScreenState();
}

class _RoleManagementScreenState extends ConsumerState<RoleManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roleManagementProvider.notifier).loadData();
      ref.read(eventListProvider.notifier).loadEvents();
    });
  }

  void _openAssignBottomSheet() {
    showAdaptiveSheetOrDialog(
      context: context,
      maxDesktopWidth: 600,
      builder: (_) => const AssignRoleBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleState = ref.watch(roleManagementProvider);
    final eventState = ref.watch(eventListProvider);

    final branchCount = roleState.branchCount;
    final totalPersonnelCount = eventState.events.fold<int>(
      0,
      (sum, e) => sum + e.personnel.length,
    );
    final auditCount = roleState.auditLogs.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6A020A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BAN TRỊ SỰ TÔNG MÔN',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF735C00),
                    ),
                  ),
                  Text(
                    'Phân Quyền & Chức Sự',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A020A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF58413F)),
            onPressed: () {
              ref.read(roleManagementProvider.notifier).loadData();
              ref.read(eventListProvider.notifier).loadEvents();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEEEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentTab(
                          tab: RoleManagementTab.branches,
                          label: 'Trưởng Chi',
                          count: branchCount,
                          icon: Icons.account_tree_outlined,
                          currentTab: roleState.selectedTab,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildSegmentTab(
                          tab: RoleManagementTab.events,
                          label: 'BTC Sự Kiện',
                          count: totalPersonnelCount,
                          icon: Icons.festival_outlined,
                          currentTab: roleState.selectedTab,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildSegmentTab(
                          tab: RoleManagementTab.audit,
                          label: 'Nhật Ký',
                          count: auditCount,
                          icon: Icons.receipt_long_outlined,
                          currentTab: roleState.selectedTab,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF6A020A),
        onRefresh: () async {
          await ref.read(roleManagementProvider.notifier).loadData();
          await ref.read(eventListProvider.notifier).loadEvents();
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildTabContent(roleState.selectedTab),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE9E8E5)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF1B873F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'RBAC 2.0 • Ghi log tự động',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF58413F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _openAssignBottomSheet,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Chỉ Định Quyền Mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A020A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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

  Widget _buildSegmentTab({
    required RoleManagementTab tab,
    required String label,
    required int count,
    required IconData icon,
    required RoleManagementTab currentTab,
  }) {
    final isSelected = tab == currentTab;
    return InkWell(
      onTap: () =>
          ref.read(roleManagementProvider.notifier).switchTab(tab),
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? const Color(0xFF6A020A)
                  : const Color(0xFF58413F),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF6A020A)
                      : const Color(0xFF58413F),
                ),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFDAD6)
                      : const Color(0xFFE3E2E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF6A020A)
                        : const Color(0xFF58413F),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(RoleManagementTab tab) {
    switch (tab) {
      case RoleManagementTab.branches:
        return const BranchRolesTab(key: ValueKey('branches'));
      case RoleManagementTab.events:
        return const EventRolesTab(key: ValueKey('events'));
      case RoleManagementTab.audit:
        return const AuditLogTab(key: ValueKey('audit'));
    }
  }
}
