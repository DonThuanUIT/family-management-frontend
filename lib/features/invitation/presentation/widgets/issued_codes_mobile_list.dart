import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/position_link_models.dart';
import '../providers/position_link_providers.dart';

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
              'Không tìm thấy mã liên kết nào phù hợp.',
              style: TextStyle(fontSize: 13, color: Color(0xFF54433E)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
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
              // 1. Top row: Code + Status (Wrap prevents overflow)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
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
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8F482F),
                      ),
                    ),
                  ),
                  item.isActivated
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF99F8A2).withAlpha(120),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 12, color: Color(0xFF006E2A)),
                              SizedBox(width: 4),
                              Text(
                                '✓ Đã Kích Hoạt',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006E2A),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDCBE).withAlpha(160),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_top,
                                  size: 12, color: Color(0xFF874E00)),
                              SizedBox(width: 4),
                              Text(
                                'Chờ Kích Hoạt',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF874E00),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. Middle Row: Tên + Vị trí phả hệ (Wrap prevents overflow)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    item.fullName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1A),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDEB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.branchName,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(Icons.chevron_right,
                            size: 12, color: Color(0xFF87736D)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDEB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Đời ${item.generation}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 3. Lower Row: Người cấp + Ngày tạo
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: Color(0xFF756864)),
                      const SizedBox(width: 4),
                      Text(
                        item.issuedBy,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF54433E),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(item.createdAt),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: Color(0xFF756864),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 4. Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.isActivated)
                    OutlinedButton.icon(
                      onPressed: () {
                        context.go('/home');
                      },
                      icon: const Icon(Icons.visibility_outlined,
                          size: 13, color: Color(0xFF8F482F)),
                      label: const Text(
                        'Xem Vị Trí Cây',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E0DA)),
                        backgroundColor: const Color(0xFFF6F3F1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(clanInvitesProvider.notifier)
                            .copyShareableLink();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Đã sao chép link gửi lại mã: ${item.shareableUrl}'),
                            backgroundColor: const Color(0xFF874E00),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_outlined,
                          size: 13, color: Color(0xFF874E00)),
                      label: const Text(
                        'Gửi Lại Mã',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF874E00),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E0DA)),
                        backgroundColor: const Color(0xFFF6F3F1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
