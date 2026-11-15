import 'package:flutter/material.dart';

import '../../data/models/member_import_models.dart';

/// Bảng xem trước danh sách thành viên nhập từ Excel/CSV (US-31).
/// Tô đỏ nổi bật các dòng bị lỗi kèm danh sách nguyên nhân cụ thể.
class MemberImportPreviewTable extends StatelessWidget {
  final List<ImportMemberPreviewRowDto> rows;

  const MemberImportPreviewTable({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDAC1BA)),
        ),
        child: const Text(
          'Không có dòng dữ liệu nào phù hợp với bộ lọc hiện tại.',
          style: TextStyle(color: Color(0xFF54433E)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDAC1BA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF5ECE6)),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 110,
          columnSpacing: 18,
          columns: const [
            DataColumn(label: Text('Dòng', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Mã TV', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Ngày sinh', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Đời', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Mã nhánh', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Tình trạng', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Ngày mất / Giỗ ÂL', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nguyên nhân lỗi', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: rows.map((row) {
            final isError = !row.valid;
            final rowColor = isError
                ? WidgetStateProperty.all(Colors.red.shade50)
                : WidgetStateProperty.all(Colors.white);

            final dobText = row.dateOfBirth ?? row.rawDateOfBirth ?? '—';
            final deathText = row.status == 'Deceased'
                ? '${row.deathDate ?? row.rawDeathDate ?? '—'}'
                    '${row.deathDateLunar != null ? '\n(${row.deathDateLunar})' : ''}'
                : '—';

            return DataRow(
              color: rowColor,
              cells: [
                DataCell(Text('#${row.rowNumber}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isError ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isError ? Colors.red.shade400 : Colors.green.shade400,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isError ? Icons.error_outline : Icons.check_circle_outline,
                          size: 14,
                          color: isError ? Colors.red.shade800 : Colors.green.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isError ? 'Lỗi' : 'Hợp lệ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isError ? Colors.red.shade900 : Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(Text(row.memberId ?? '(Tự sinh)')),
                DataCell(
                  Text(
                    row.fullName ?? '—',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isError ? Colors.red.shade900 : const Color(0xFF1C1C1A),
                    ),
                  ),
                ),
                DataCell(Text(dobText)),
                DataCell(Text(_formatGender(row.gender))),
                DataCell(Text(row.generation?.toString() ?? '—')),
                DataCell(
                  Text(
                    row.branchName != null
                        ? '${row.branchId ?? ''}\n(${row.branchName})'
                        : (row.branchId ?? '—'),
                  ),
                ),
                DataCell(Text(row.status == 'Deceased' ? 'Đã mất' : 'Còn sống')),
                DataCell(Text(deathText)),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: isError
                        ? Text(
                            row.errors.map((e) => '• $e').join('\n'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : const Text(
                            'Không có lỗi',
                            style: TextStyle(fontSize: 12, color: Colors.green),
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

  static String _formatGender(String? gender) {
    return switch (gender) {
      'Male' => 'Nam',
      'Female' => 'Nữ',
      'Other' => 'Khác',
      _ => gender ?? '—',
    };
  }
}
