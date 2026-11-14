import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/invitation_management_models.dart';
import '../../data/models/position_link_models.dart';
import '../providers/position_link_providers.dart';
import 'extend_invite_dialog.dart';
import 'revoke_invite_dialog.dart';

/// Danh sách mã mời dạng thẻ trên thiết bị di động (US-34 & AC-06)
class IssuedCodesMobileList extends ConsumerWidget {
  final List<PositionLinkItemModel> items;

  const IssuedCodesMobileList({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.search_off, size: 36, color: Color(0xFFDAC1BA)),
            SizedBox(height: 8),
            Text(
              'Không tìm thấy mã mời nào phù hợp.',
              style: TextStyle(fontSize: 13, color: Color(0xFF54433E)),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final status = item.status;
        final isGeneral = item.inviteType == 'GeneralInviteCode';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6DFD8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top row: Code + Status Badge (Wrap prevents overflow)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F6F0),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF8F482F).withAlpha(50)),
                        ),
                        child: Text(
                          item.code,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8F482F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        tooltip: 'Sao chép mã',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        color: const Color(0xFF8F482F),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã sao chép mã mời: ${item.code}'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF8F482F),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: status.bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: status.textColor.withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.icon, size: 11, color: status.textColor),
                            const SizedBox(width: 4),
                            Text(
                              status.label,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: status.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.isActivated ? '✓ Đã Kích Hoạt' : 'Chờ Kích Hoạt',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: item.isActivated
                              ? const Color(0xFF006E2A)
                              : const Color(0xFF874E00),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Middle Row: Tên + Loại mã & Phân nhánh
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    item.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isGeneral
                          ? const Color(0xFFE0F2FE)
                          : const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isGeneral ? 'Mã Chung' : 'Đích Danh',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isGeneral
                            ? const Color(0xFF0369A1)
                            : const Color(0xFF6B21A8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined,
                      size: 13, color: Color(0xFF756864)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${item.branchName} ${item.generation > 0 ? "• Đời ${item.generation}" : ""}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF54433E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 3. Usage count progress bar (used_count / max_uses)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF0EDEB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        const Text(
                          'Số lượt đã dùng:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF54433E)),
                        ),
                        Text(
                          '${item.usedCount} / ${item.maxUses} lượt',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: item.isUsedUp
                                ? const Color(0xFF4A148C)
                                : const Color(0xFF1C1C1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: item.maxUses > 0
                          ? (item.usedCount / item.maxUses).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: const Color(0xFFE6DFD8),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item.isUsedUp
                            ? const Color(0xFF4A148C)
                            : const Color(0xFF006E2A),
                      ),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 4. Validity Row (Wrap prevents overflow on narrow screens)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: Color(0xFF756864)),
                      const SizedBox(width: 4),
                      Text(
                        item.expiresAt != null
                            ? 'Hạn: ${dateFormat.format(item.expiresAt!)}'
                            : 'Không thời hạn',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF54433E),
                        ),
                      ),
                    ],
                  ),
                  _buildRemainingDaysBadge(item),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Action Buttons (Wrap prevents overflow on 390px screens)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Nút Gia hạn
                  OutlinedButton.icon(
                    onPressed: () => ExtendInviteDialog.show(
                      context,
                      item: item,
                    ),
                    icon: const Icon(Icons.more_time_rounded,
                        size: 13, color: Color(0xFF006E2A)),
                    label: const Text(
                      'Gia Hạn',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006E2A),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF81C784)),
                      backgroundColor: const Color(0xFFF1F8E9),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),

                  // Nút Thu hồi (nếu còn Active)
                  if (status == InvitationCodeStatus.active)
                    OutlinedButton.icon(
                      onPressed: () => RevokeInviteDialog.show(
                        context,
                        item: item,
                      ),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 13, color: Color(0xFFBA1A1A)),
                      label: const Text(
                        'Thu Hồi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFFCDD2)),
                        backgroundColor: const Color(0xFFFFEBEE),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),

                  // Sao chép link
                  IconButton.outlined(
                    tooltip: 'Sao chép link',
                    icon: const Icon(Icons.link, size: 14, color: Color(0xFF8F482F)),
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDAC1BA)),
                      backgroundColor: const Color(0xFFF6F3F1),
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.shareableUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã sao chép link mời: ${item.shareableUrl}'),
                          backgroundColor: const Color(0xFF8F482F),
                        ),
                      );
                    },
                  ),

                  // Tái tạo mã
                  IconButton.outlined(
                    tooltip: 'Tái tạo mã mới',
                    icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF0369A1)),
                    style: IconButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBAE6FD)),
                      backgroundColor: const Color(0xFFE0F2FE),
                      padding: const EdgeInsets.all(6),
                      minimumSize: const Size(32, 32),
                    ),
                    onPressed: () {
                      ref
                          .read(clanInvitesProvider.notifier)
                          .regenerateInvite(item.code);
                    },
                  ),

                  if (item.isActivated)
                    IconButton.outlined(
                      tooltip: 'Xem trên cây',
                      icon: const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF54433E)),
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDAC1BA)),
                        backgroundColor: const Color(0xFFF6F3F1),
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                      onPressed: () => context.go('/home'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemainingDaysBadge(PositionLinkItemModel item) {
    if (item.expiresAt == null) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now();
    final diff = item.expiresAt!.difference(now).inDays;

    if (diff < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDAD6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Đã hết hạn',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFFBA1A1A),
          ),
        ),
      );
    } else if (diff == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE0B2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Hết hạn hôm nay',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE65100),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Còn $diff ngày',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF006E2A),
          ),
        ),
      );
    }
  }
}
