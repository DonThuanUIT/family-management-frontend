import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/position_link_models.dart';
import '../providers/position_link_providers.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.search_off, size: 40, color: Color(0xFFDAC1BA)),
            SizedBox(height: 10),
            Text(
              'Không tìm thấy mã liên kết nào phù hợp với bộ lọc.',
              style: TextStyle(fontSize: 13, color: Color(0xFF54433E)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width >= 1100
              ? MediaQuery.of(context).size.width - 64
              : 960,
        ),
        child: DataTable(
          horizontalMargin: 16,
          columnSpacing: 20,
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 56,
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
                'VỊ TRÍ CÂY PHẢ HỆ',
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
                'TÊN CON CHÁU',
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
                'NGƯỜI CẤP QUYỀN',
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
                'NGÀY TẠO',
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
            return DataRow(
              cells: [
                // 1. Mã mời
                DataCell(
                  SelectableText(
                    item.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8F482F),
                    ),
                  ),
                ),
                // 2. Vị trí cây phả hệ
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDEB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.branchName,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.chevron_right,
                            size: 14, color: Color(0xFF87736D)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDEB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Đời ${item.generation}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 3. Tên con cháu
                DataCell(
                  Text(
                    item.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1A),
                    ),
                  ),
                ),
                // 4. Người cấp quyền
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline,
                          size: 15, color: Color(0xFF756864)),
                      const SizedBox(width: 5),
                      Text(
                        item.issuedBy,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF54433E),
                        ),
                      ),
                    ],
                  ),
                ),
                // 5. Ngày tạo
                DataCell(
                  Text(
                    DateFormat('dd/MM/yyyy').format(item.createdAt),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: Color(0xFF54433E),
                    ),
                  ),
                ),
                // 6. Trạng thái
                DataCell(
                  item.isActivated
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF99F8A2).withAlpha(120),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 13, color: Color(0xFF006E2A)),
                              SizedBox(width: 4),
                              Text(
                                '✓ Đã Kích Hoạt',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006E2A),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDCBE).withAlpha(160),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_top,
                                  size: 13, color: Color(0xFF874E00)),
                              SizedBox(width: 4),
                              Text(
                                'Chờ Kích Hoạt',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF874E00),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                // 7. Thao tác
                DataCell(
                  item.isActivated
                      ? OutlinedButton.icon(
                          onPressed: () {
                            context.go('/home');
                          },
                          icon: const Icon(Icons.visibility_outlined,
                              size: 14, color: Color(0xFF8F482F)),
                          label: const Text(
                            'Xem Vị Trí Cây',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1A),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E0DA)),
                            backgroundColor: const Color(0xFFF6F3F1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
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
                              size: 14, color: Color(0xFF874E00)),
                          label: const Text(
                            'Gửi Lại Mã',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF874E00),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E0DA)),
                            backgroundColor: const Color(0xFFF6F3F1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
