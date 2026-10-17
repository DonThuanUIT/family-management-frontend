import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/rbac_models.dart';

/// Khung hiển thị chuẩn cho từng phân hệ, tự động điều chỉnh các tính năng hiển thị
/// dựa trên chế độ Phân hệ (`Thành viên / Con cháu` hoặc `Quản trị / Trưởng tộc & BTC`)
/// trên cả Mobile App và Web App.
class ModulePortalScaffold extends ConsumerWidget {
  final String moduleCode;
  final String title;
  final String subtitle;
  final List<String> databaseTables;
  final List<String> memberFeatures;
  final List<String> managementFeatures;
  final String businessRuleNote;

  const ModulePortalScaffold({
    super.key,
    required this.moduleCode,
    required this.title,
    required this.subtitle,
    required this.databaseTables,
    required this.memberFeatures,
    required this.managementFeatures,
    required this.businessRuleNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dualRbacSessionProvider);
    final isManagementMode =
        session.activePortalMode == PortalWorkspaceMode.managementPortal;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(
                    label: Text(moduleCode),
                    backgroundColor: colorScheme.primaryContainer,
                  ),
                  Chip(
                    avatar: Icon(
                      isManagementMode
                          ? Icons.admin_panel_settings
                          : Icons.people,
                      size: 16,
                    ),
                    label: Text(
                      'Đang xem: ${session.activePortalMode.label}',
                    ),
                  ),
                  ...session.globalRoles.map(
                    (r) => Chip(
                      label: Text(
                        r.displayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isTwoColumn = constraints.maxWidth >= 720;
                  final memberCard = _FeatureListCard(
                    title: 'Phân hệ Thành viên / Con cháu (Web & Mobile)',
                    icon: Icons.family_restroom_outlined,
                    isHighlighted: !isManagementMode,
                    items: memberFeatures,
                  );
                  final managementCard = _FeatureListCard(
                    title: 'Phân hệ Quản trị / Trưởng tộc & BTC (Web & Mobile)',
                    icon: Icons.gavel_outlined,
                    isHighlighted: isManagementMode,
                    items: managementFeatures,
                  );

                  if (isTwoColumn) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: memberCard),
                        const SizedBox(width: 16),
                        Expanded(child: managementCard),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      memberCard,
                      const SizedBox(height: 16),
                      managementCard,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ràng buộc Nghiệp vụ & Bảng CSDL ánh xạ',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(businessRuleNote),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: databaseTables
                            .map(
                              (table) => Chip(
                                avatar: const Icon(
                                  Icons.storage_outlined,
                                  size: 14,
                                ),
                                label: Text(
                                  table,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isHighlighted;
  final List<String> items;

  const _FeatureListCard({
    required this.title,
    required this.icon,
    required this.isHighlighted,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isHighlighted
              ? colorScheme.primary
              : colorScheme.outlineVariant.withAlpha(120),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isHighlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Đang kích hoạt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
