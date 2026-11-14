import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/adaptive_modal.dart';
import '../../../event/data/models/event_models.dart';
import '../../../event/presentation/providers/event_providers.dart';
import '../../data/models/role_models.dart';
import '../providers/role_providers.dart';
import 'assign_role_bottom_sheet.dart';
import 'revoke_role_dialog.dart';

class EventRolesTab extends ConsumerWidget {
  const EventRolesTab({super.key});

  void _openAssign(
    BuildContext context,
    String eventId,
    AssignableRoleCode role,
  ) {
    showAdaptiveSheetOrDialog(
      context: context,
      maxDesktopWidth: 600,
      builder: (_) => AssignRoleBottomSheet(
        initialScope: RoleScopeType.event,
        initialTargetId: eventId,
        initialRole: role,
      ),
    );
  }

  void _openRevoke(
    BuildContext context,
    EventPersonnelModel personnel,
    EventModel event,
  ) {
    final roleEnum = AssignableRoleCode.fromCode(personnel.eventRole);
    showDialog(
      context: context,
      builder: (_) => RevokeRoleDialog(
        memberId: personnel.memberId,
        memberName: personnel.memberName ?? 'Thành viên',
        roleCode: roleEnum.code,
        roleDisplayName: roleEnum.displayName,
        scopeType: RoleScopeType.event,
        scopeId: event.eventId,
        scopeName: event.eventName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventState = ref.watch(eventListProvider);
    final roleState = ref.watch(roleManagementProvider);
    final events = eventState.events;

    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Chưa có sự kiện nào trong hệ thống.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8B716E)),
          ),
        ),
      );
    }

    final selectedEventId =
        roleState.selectedEventId ?? events.first.eventId;
    final currentEvent = events.firstWhere(
      (e) => e.eventId == selectedEventId,
      orElse: () => events.first,
    );

    final headOfOrg = currentEvent.headOfOrganizer;
    final treasurer = currentEvent.eventTreasurer;
    final otherMembers = currentEvent.personnel
        .where((p) =>
            p.eventRole != 'HeadOfOrganizer' && p.eventRole != 'EventTreasurer')
        .toList();

    final isDesktop = isDesktopViewport(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: isDesktop ? 16 : 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
        // Event Picker Selector Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFEEEB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHỌN SỰ KIỆN PHÂN BỔ NHÂN SỰ:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Color(0xFF735C00),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedEventId,
                isExpanded: true,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1A),
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F3F1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE9E8E5)),
                  ),
                ),
                items: events
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.eventId,
                        child: Text(
                          '${e.eventName} (${e.eventDateLunar ?? "Sắp tới"})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(roleManagementProvider.notifier).selectEvent(val);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 1. Trưởng Ban Tổ Chức (HeadOfOrganizer)
        _buildSectionCard(
          context: context,
          title: 'Trưởng Ban Tổ Chức (Head)',
          icon: Icons.gavel,
          iconColor: const Color(0xFF6A020A),
          actionWidget: headOfOrg == null
              ? TextButton.icon(
                  onPressed: () => _openAssign(
                    context,
                    currentEvent.eventId,
                    AssignableRoleCode.headOfOrganizer,
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Bổ Nhiệm'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6A020A),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          child: headOfOrg != null
              ? _buildPersonnelItem(
                  context,
                  headOfOrg,
                  'Toàn quyền điều phối đại lễ & phê duyệt chi phí',
                  const Color(0xFF6A020A),
                  () => _openRevoke(context, headOfOrg, currentEvent),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Chưa chỉ định Trưởng Ban Tổ Chức cho sự kiện này.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF8B716E),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 10),

        // 2. Thủ Quỹ Sự Kiện (EventTreasurer)
        _buildSectionCard(
          context: context,
          title: 'Thủ Quỹ Sự Kiện (Treasurer)',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFF735C00),
          actionWidget: TextButton.icon(
            onPressed: () => _openAssign(
              context,
              currentEvent.eventId,
              AssignableRoleCode.eventTreasurer,
            ),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Thêm Thủ Quỹ'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6A020A),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child: treasurer != null
              ? _buildPersonnelItem(
                  context,
                  treasurer,
                  'Thu cúng tiến, ghi sổ công đức, giải ngân mâm cỗ',
                  const Color(0xFF735C00),
                  () => _openRevoke(context, treasurer, currentEvent),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Chưa chỉ định Thủ Quỹ cho sự kiện này.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF8B716E),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 10),

        // 3. Thành Viên Ban Tổ Chức (OrganizerMember)
        _buildSectionCard(
          context: context,
          title: 'Thành Viên Ban Tổ Chức',
          icon: Icons.group_outlined,
          iconColor: const Color(0xFF6A020A),
          actionWidget: TextButton.icon(
            onPressed: () => _openAssign(
              context,
              currentEvent.eventId,
              AssignableRoleCode.organizerMember,
            ),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Thêm Thành Viên'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6A020A),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child: otherMembers.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Chưa bổ sung thành viên ban tổ chức.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF8B716E),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: otherMembers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, idx) {
                    final member = otherMembers[idx];
                    return _buildPersonnelItem(
                      context,
                      member,
                      'Phụ trách điều phối & hậu cần sự kiện',
                      const Color(0xFF58413F),
                      () => _openRevoke(context, member, currentEvent),
                    );
                  },
                ),
        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    Widget? actionWidget,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEEEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ?actionWidget,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPersonnelItem(
    BuildContext context,
    EventPersonnelModel personnel,
    String dutyDescription,
    Color avatarColor,
    VoidCallback onRevoke,
  ) {
    final name = personnel.memberName ?? 'Thành viên';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: avatarColor.withAlpha(40),
            foregroundColor: avatarColor,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                Text(
                  dutyDescription,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF58413F),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Thu hồi quyền hạn',
            onPressed: onRevoke,
            icon: const Icon(Icons.remove_moderator, size: 16),
            color: const Color(0xFFBA1A1A),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFFDAD6),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(28, 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
