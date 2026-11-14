import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/auth_models.dart';
import 'join_request_detail_dialog.dart';
import 'reject_join_request_dialog.dart';

/// Danh sách thẻ hiển thị yêu cầu gia nhập tối ưu cho màn hình Mobile (US-33).
class JoinRequestsMobileList extends ConsumerWidget {
  final List<JoinRequestResponseDto> requests;

  const JoinRequestsMobileList({
    super.key,
    required this.requests,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = requests[index];
        final isPending = item.approvalStatus == JoinRequestApprovalStatus.pending;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6DFD8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Name & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fullName,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              item.phoneNumber ?? '---',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 12,
                                color: Color(0xFF54433E),
                              ),
                            ),
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
                  _buildStatusBadge(item.approvalStatus),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0EDEB)),
              const SizedBox(height: 12),

              // 2. Body Details
              Row(
                children: [
                  const Icon(Icons.account_tree_outlined, size: 15, color: Color(0xFF8F482F)),
                  const SizedBox(width: 6),
                  const Text(
                    'Nhánh đề xuất: ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                  ),
                  Expanded(
                    child: Text(
                      '${item.targetBranchName ?? item.targetBranchId} (Đời ${item.proposedGeneration})',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF1C1C1A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag, size: 15, color: Color(0xFF85736E)),
                      const SizedBox(width: 6),
                      const Text(
                        'Mã đơn: ',
                        style: TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                      ),
                      Text(
                        item.requestId,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8F482F),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.proposalType == ProposalType.newChildBranch
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF0EDEB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.proposalType == ProposalType.newChildBranch ? 'Tách nhánh mới' : 'Gia nhập nhánh',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: item.proposalType == ProposalType.newChildBranch
                            ? const Color(0xFF006E2A)
                            : const Color(0xFF54433E),
                      ),
                    ),
                  ),
                ],
              ),

              if (item.relationshipNote != null && item.relationshipNote!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, size: 15, color: Color(0xFF85736E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Quan hệ: "${item.relationshipNote}"',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF6B584E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // 3. Action Buttons Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => JoinRequestDetailDialog.show(context, request: item),
                    icon: const Icon(Icons.edit_note_outlined, size: 16, color: Color(0xFF54433E)),
                    label: const Text(
                      'Chi Tiết & Đổi Nhánh',
                      style: TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: const BorderSide(color: Color(0xFFDAC1BA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  if (isPending) ...[
                    OutlinedButton.icon(
                      onPressed: () => RejectJoinRequestDialog.show(context, request: item),
                      icon: const Icon(Icons.close, size: 15, color: Color(0xFFBA1A1A)),
                      label: const Text(
                        'Từ Chối',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBA1A1A)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => JoinRequestDetailDialog.show(context, request: item),
                      icon: const Icon(Icons.check, size: 15),
                      label: const Text(
                        'Duyệt Đơn',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006E2A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10.5,
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
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF85736E)),
          SizedBox(height: 10),
          Text(
            'Không có yêu cầu gia nhập nào',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B1810),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy kiểm tra lại bộ lọc hoặc tìm kiếm.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B584E)),
          ),
        ],
      ),
    );
  }
}
