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

/// Bảng danh sách các mã mời đã phát hành kèm trạng thái, số lượt đã dùng,
/// nút Thu hồi mã, Gia hạn hoặc Tạo mã mới (US-34 & AC-06).
class IssuedCodesTable extends ConsumerWidget {
  final List<PositionLinkItemModel> items;

  const IssuedCodesTable({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.search_off, size: 44, color: Color(0xFFDAC1BA)),
            SizedBox(height: 12),
            Text(
              'Không tìm thấy mã mời nào phù hợp với bộ lọc hiện tại.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF54433E)),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width >= 1200
              ? MediaQuery.of(context).size.width - 64
              : 1100,
        ),
        child: DataTable(
          horizontalMargin: 16,
          columnSpacing: 18,
          headingRowHeight: 46,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF0EDEB)),
          columns: const [
            DataColumn(
              label: Text(
                'MÃ MỜI',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF54433E),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'LOẠI MÃ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF54433E),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'ĐỐI TƯỢNG / PHÂN NHÁNH',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF54433E),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'SỐ LƯỢT DÙNG (USED / MAX)',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF54433E),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'HẠN HIỆU LỰC',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF54433E),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'TRẠNG THÁI',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF54433E),
                ),
              ),
            ),
            DataColumn(
              numeric: true,
              label: Text(
                'THAO TÁC',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: Color(0xFF54433E),
                ),
              ),
            ),
          ],
          rows: items.map((item) {
            final status = item.status;
            final isGeneral = item.inviteType == 'GeneralInviteCode';

            return DataRow(
              cells: [
                // 1. Mã mời (monospace + copy button)
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SelectableText(
                        item.code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8F482F),
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
                ),

                // 2. Loại mã (General vs PositionLink)
                DataCell(
                  isGeneral
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.diversity_3, size: 12, color: Color(0xFF0369A1)),
                              SizedBox(width: 4),
                              Text(
                                'Mã Chung Gia Phả',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_pin_circle_outlined,
                                  size: 12, color: Color(0xFF6B21A8)),
                              SizedBox(width: 4),
                              Text(
                                'Vị Trí Đích Danh',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B21A8),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // 3. Đối tượng / Phân nhánh
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.branchName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF54433E),
                            ),
                          ),
                          if (item.generation > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0EDEB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Đời ${item.generation}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF54433E),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 4. Số lượt đã dùng (used_count / max_uses)
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.isUsedUp
                              ? const Color(0xFFF3E5F5)
                              : const Color(0xFFF0EDEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.isUsedUp
                                ? const Color(0xFFCE93D8)
                                : const Color(0xFFDAC1BA),
                          ),
                        ),
                        child: Text(
                          '${item.usedCount} / ${item.maxUses} lượt',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.isUsedUp
                                ? const Color(0xFF4A148C)
                                : const Color(0xFF1C1C1A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: 90,
                        child: LinearProgressIndicator(
                          value: item.maxUses > 0
                              ? (item.usedCount / item.maxUses).clamp(0.0, 1.0)
                              : 0.0,
                          backgroundColor: const Color(0xFFE6DFD8),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            item.isUsedUp
                                ? const Color(0xFF4A148C)
                                : const Color(0xFF006E2A),
                          ),
                          minHeight: 3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Hạn hiệu lực
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.expiresAt != null
                            ? dateFormat.format(item.expiresAt!)
                            : 'Vô thời hạn',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.isExpired
                              ? const Color(0xFFBA1A1A)
                              : const Color(0xFF1C1C1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _buildRemainingDaysText(item),
                    ],
                  ),
                ),

                // 6. Trạng thái (Hoạt Động, Đã Dùng Hết, Hết Hạn, Đã Thu Hồi & Trạng thái kích hoạt)
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: status.bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: status.textColor.withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.icon, size: 12, color: status.textColor),
                            const SizedBox(width: 4),
                            Text(
                              status.label,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: status.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.isActivated ? '✓ Đã Kích Hoạt' : 'Chờ Kích Hoạt',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.isActivated
                              ? const Color(0xFF006E2A)
                              : const Color(0xFF874E00),
                        ),
                      ),
                    ],
                  ),
                ),

                // 7. Thao tác: Thu hồi, Gia hạn, Cấp lại, Sao chép link
                DataCell(
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),

                      // Nút Thu hồi mã (khi còn đang Active)
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),

                      // Menu thêm (Sao chép link, Cấp lại / Tái tạo mã, Xem cây)
                      PopupMenuButton<String>(
                        tooltip: 'Thao tác khác',
                        icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF54433E)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onSelected: (val) {
                          if (val == 'copy') {
                            Clipboard.setData(ClipboardData(text: item.shareableUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã sao chép liên kết mời: ${item.shareableUrl}'),
                                backgroundColor: const Color(0xFF8F482F),
                              ),
                            );
                          } else if (val == 'regenerate') {
                            ref
                                .read(clanInvitesProvider.notifier)
                                .regenerateInvite(item.code);
                          } else if (val == 'view_tree') {
                            context.go('/home');
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'copy',
                            child: Row(
                              children: [
                                Icon(Icons.link, size: 15, color: Color(0xFF8F482F)),
                                SizedBox(width: 8),
                                Text('Sao chép liên kết', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'regenerate',
                            child: Row(
                              children: [
                                Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF0369A1)),
                                SizedBox(width: 8),
                                Text('Tái tạo mã mới', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          if (item.isActivated)
                            const PopupMenuItem(
                              value: 'view_tree',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF54433E)),
                                  SizedBox(width: 8),
                                  Text('Xem vị trí cây', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRemainingDaysText(PositionLinkItemModel item) {
    if (item.expiresAt == null) {
      return const Text(
        'Không giới hạn',
        style: TextStyle(fontSize: 10, color: Color(0xFF756864)),
      );
    }
    final now = DateTime.now();
    final diff = item.expiresAt!.difference(now).inDays;

    if (diff < 0) {
      return const Text(
        'Đã hết hạn',
        style: TextStyle(fontSize: 10, color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold),
      );
    } else if (diff == 0) {
      return const Text(
        'Hết hạn hôm nay',
        style: TextStyle(fontSize: 10, color: Color(0xFFE65100), fontWeight: FontWeight.bold),
      );
    } else {
      return Text(
        'Còn $diff ngày',
        style: const TextStyle(fontSize: 10, color: Color(0xFF006E2A)),
      );
    }
  }
}
