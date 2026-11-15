import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/auth_models.dart';
import 'join_request_detail_dialog.dart';
import 'reject_join_request_dialog.dart';

/// Bảng dữ liệu hiển thị danh sách đơn xin gia nhập cho màn hình Desktop (US-33).
class JoinRequestsTable extends ConsumerWidget {
  final List<JoinRequestResponseDto> requests;

  const JoinRequestsTable({
    super.key,
    required this.requests,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1000),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFFAF9F5)),
              headingTextStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF54433E),
              ),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 76,
              columnSpacing: 20,
              horizontalMargin: 20,
              columns: const [
                DataColumn(label: Text('MÃ ĐƠN')),
                DataColumn(label: Text('ỨNG VIÊN XIN GIA NHẬP')),
                DataColumn(label: Text('PHÂN NHÁNH ĐỀ XUẤT')),
                DataColumn(label: Text('LOẠI ĐỀ XUẤT')),
                DataColumn(label: Text('NGÀY NỘP')),
                DataColumn(label: Text('TRẠNG THÁI')),
                DataColumn(label: Text('THAO TÁC')),
              ],
              rows: requests.map((item) {
                final isPending = item.approvalStatus == JoinRequestApprovalStatus.pending;

                return DataRow(
                  cells: [
                    // 1. Mã đơn
                    DataCell(
                      InkWell(
                        onTap: () => JoinRequestDetailDialog.show(context, request: item),
                        child: Text(
                          item.requestId,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8F482F),
                          ),
                        ),
                      ),
                    ),

                    // 2. Ứng viên
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.fullName,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF1C1C1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                item.phoneNumber ?? '---',
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11.5,
                                  color: Color(0xFF54433E),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0EDEB),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.gender == 'Male' ? 'Nam' : (item.gender == 'Female' ? 'Nữ' : 'Khác'),
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF54433E)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3. Phân nhánh đề xuất
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.targetBranchName ?? item.targetBranchId,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đời thứ: Đời ${item.proposedGeneration}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              color: Color(0xFF6B584E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 4. Loại đề xuất
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.proposalType == ProposalType.newChildBranch
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF0EDEB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.proposalType == ProposalType.newChildBranch
                              ? 'Tách Chi Nhánh Mới'
                              : 'Gia Nhập Nhánh',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.proposalType == ProposalType.newChildBranch
                                ? const Color(0xFF006E2A)
                                : const Color(0xFF54433E),
                          ),
                        ),
                      ),
                    ),

                    // 5. Ngày nộp
                    DataCell(
                      Text(
                        _formatDate(item.createdAt),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          color: Color(0xFF54433E),
                        ),
                      ),
                    ),

                    // 6. Trạng thái
                    DataCell(_buildStatusBadge(item.approvalStatus)),

                    // 7. Thao tác
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Xem chi tiết
                          Tooltip(
                            message: 'Xem hồ sơ chi tiết và điều chỉnh nhánh',
                            child: OutlinedButton(
                              onPressed: () => JoinRequestDetailDialog.show(context, request: item),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                side: const BorderSide(color: Color(0xFFDAC1BA)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF54433E)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Chi Tiết',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF54433E)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (isPending) ...[
                            const SizedBox(width: 6),
                            // Nút Duyệt
                            Tooltip(
                              message: 'Phê duyệt gia nhập ngay',
                              child: ElevatedButton(
                                onPressed: () => JoinRequestDetailDialog.show(context, request: item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006E2A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 14),
                                    SizedBox(width: 4),
                                    Text('Duyệt', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Nút Từ chối
                            Tooltip(
                              message: 'Từ chối đơn gia nhập',
                              child: OutlinedButton(
                                onPressed: () => RejectJoinRequestDialog.show(context, request: item),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFBA1A1A)),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.close, size: 14, color: Color(0xFFBA1A1A)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Từ Chối',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFFBA1A1A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(JoinRequestApprovalStatus status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case JoinRequestApprovalStatus.pending:
        bg = const Color(0xFFFFF4D3);
        fg = const Color(0xFF7A5900);
        label = 'Chờ Duyệt';
        icon = Icons.hourglass_top_rounded;
        break;
      case JoinRequestApprovalStatus.approved:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF006E2A);
        label = 'Đã Phê Duyệt';
        icon = Icons.check_circle_outline;
        break;
      case JoinRequestApprovalStatus.rejected:
        bg = const Color(0xFFFFDAD6);
        fg = const Color(0xFFBA1A1A);
        label = 'Đã Từ Chối';
        icon = Icons.highlight_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF85736E)),
          SizedBox(height: 12),
          Text(
            'Không có yêu cầu gia nhập nào phù hợp',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B1810),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hãy kiểm tra lại bộ lọc trạng thái hoặc từ khóa tìm kiếm của quý vị.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF6B584E)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '---';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
