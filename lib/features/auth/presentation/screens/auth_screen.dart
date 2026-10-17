import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';

/// Màn hình Xác thực, Kích hoạt hồ sơ ảo (`PositionLinkCode`) & Cấu hình Dual-RBAC.
class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(dualRbacSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Định danh Tài khoản & Phân quyền Kép (Dual-RBAC)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hồ sơ & Tài khoản hiện tại',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Họ tên: ${session.fullName}'),
                        Text('Mã thành viên (MEMBER): ${session.memberId}'),
                        Text('Mã tài khoản (USER_ACCOUNT): ${session.accountId}'),
                        Text('Chi nhánh: ${session.branchName}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Phân quyền Tĩnh Toàn cục (SYSTEM_ROLE & ACCOUNT_ROLE)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: SystemRole.values.map((role) {
                            final selected = session.globalRoles.contains(role);
                            return FilterChip(
                              label: Text('${role.displayName} (${role.code})'),
                              selected: selected,
                              onSelected: (_) {
                                ref
                                    .read(dualRbacSessionProvider.notifier)
                                    .toggleSimulationRole(role);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2. Phân quyền Động Theo Sự kiện (EVENT_PERSONNEL)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...session.eventRolesByEventId.values.map(
                          (ctx) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_available),
                            title: Text(
                              'Sự kiện: ${ctx.eventId} • ${ctx.role.displayName}',
                            ),
                            subtitle: Text(
                              'Trạng thái: ${ctx.eventStatus.displayName} | '
                              'Chế độ chỉ đọc (is_read_only): ${ctx.isEffectiveReadOnly ? "BẬT" : "TẮT"}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
