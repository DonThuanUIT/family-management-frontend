import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../data/models/join_request_management_models.dart';
import '../providers/join_requests_provider.dart';
import 'reject_join_request_dialog.dart';

/// Modal xem chi tiết đơn gia nhập dòng họ & điều chỉnh vị trí nhánh trước khi phê duyệt (US-33 & AC-08).
class JoinRequestDetailDialog extends ConsumerStatefulWidget {
  final JoinRequestResponseDto request;
  final VoidCallback? onProcessed;

  const JoinRequestDetailDialog({
    super.key,
    required this.request,
    this.onProcessed,
  });

  static Future<void> show(
    BuildContext context, {
    required JoinRequestResponseDto request,
    VoidCallback? onProcessed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => JoinRequestDetailDialog(
        request: request,
        onProcessed: onProcessed,
      ),
    );
  }

  @override
  ConsumerState<JoinRequestDetailDialog> createState() => _JoinRequestDetailDialogState();
}

class _JoinRequestDetailDialogState extends ConsumerState<JoinRequestDetailDialog> {
  late String _selectedTargetBranchId;
  late TextEditingController _branchNameController;

  @override
  void initState() {
    super.initState();
    _selectedTargetBranchId = widget.request.targetBranchId;
    _branchNameController = TextEditingController(
      text: widget.request.proposedNewBranchName ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(joinRequestsProvider).branchOptions.isEmpty) {
        ref.read(joinRequestsProvider.notifier).loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    super.dispose();
  }

  bool get _isPending => widget.request.approvalStatus == JoinRequestApprovalStatus.pending;
  bool get _isBranchChanged => _selectedTargetBranchId != widget.request.targetBranchId;

  Future<void> _handleApprove() async {
    final notifier = ref.read(joinRequestsProvider.notifier);
    final isNewChild = widget.request.proposalType == ProposalType.newChildBranch;

    final success = await notifier.approveRequest(
      widget.request.requestId,
      targetBranchId: _selectedTargetBranchId,
      proposedNewBranchName: isNewChild ? _branchNameController.text.trim() : null,
    );

    if (mounted && success) {
      widget.onProcessed?.call();
      Navigator.of(context).pop();
    }
  }

  void _handleOpenReject() {
    RejectJoinRequestDialog.show(
      context,
      request: widget.request,
      onRejected: () {
        widget.onProcessed?.call();
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(joinRequestsProvider);
    final isLoading = state.isActionLoading && state.actionRequestId == widget.request.requestId;
    final branchOptions = state.branchOptions;

    // Ensure selected branch ID exists in branchOptions
    final hasMatchingBranch = branchOptions.any((b) => b.branchId == _selectedTargetBranchId);
    if (!hasMatchingBranch && branchOptions.isNotEmpty) {
      _selectedTargetBranchId = branchOptions.first.branchId;
    }

    return Dialog(
      backgroundColor: const Color(0xFFFCF9F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 850),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE6DFD8))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8F482F).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_ind_outlined, color: Color(0xFF8F482F), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'Đơn Xin Gia Nhập: ${widget.request.requestId}',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1C1C1A),
                              ),
                            ),
                            _buildStatusBadge(widget.request.approvalStatus),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mã mời: ${widget.request.inviteCode} • Nộp ngày: ${_formatDateTime(widget.request.createdAt)}',
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11.5,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: const Color(0xFF54433E),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reviewed info banner if already processed
                    if (!_isPending) _buildProcessedNotice(),

                    // 1. Candidate Info Section
                    _buildSectionCard(
                      title: '1. Thông Tin Ứng Viên Xin Gia Nhập',
                      icon: Icons.person_outline,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: Icons.badge_outlined,
                            label: 'Họ và tên:',
                            value: widget.request.fullName,
                            isBold: true,
                          ),
                          const Divider(height: 16, color: Color(0xFFF0EDEB)),
                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Số điện thoại:',
                            value: widget.request.phoneNumber ?? 'Chưa cập nhật',
                            isMono: true,
                          ),
                          const Divider(height: 16, color: Color(0xFFF0EDEB)),
                          _buildInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email liên hệ:',
                            value: widget.request.email ?? 'Không có',
                          ),
                          const Divider(height: 16, color: Color(0xFFF0EDEB)),
                          _buildInfoRow(
                            icon: Icons.cake_outlined,
                            label: 'Ngày sinh:',
                            value: widget.request.dateOfBirth ?? 'Chưa rõ',
                            isMono: true,
                          ),
                          const Divider(height: 16, color: Color(0xFFF0EDEB)),
                          _buildInfoRow(
                            icon: Icons.wc_outlined,
                            label: 'Giới tính:',
                            value: _formatGender(widget.request.gender),
                          ),
                          if (widget.request.relationshipNote != null &&
                              widget.request.relationshipNote!.trim().isNotEmpty) ...[
                            const Divider(height: 16, color: Color(0xFFF0EDEB)),
                            _buildInfoRow(
                              icon: Icons.family_restroom_outlined,
                              label: 'Ghi chú liên kết họ hàng:',
                              value: widget.request.relationshipNote!,
                              valueColor: const Color(0xFF8F482F),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Proposed Position & Branch Override Card (US-33 & AC-08)
                    _buildSectionCard(
                      title: '2. Vị Trí Cây Phả Hệ & Điều Chỉnh Chi Nhánh Tiếp Nhận',
                      icon: Icons.account_tree_outlined,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: Icons.merge_type_outlined,
                            label: 'Loại đề xuất:',
                            value: widget.request.proposalType == ProposalType.newChildBranch
                                ? 'Đề xuất tách chi nhánh con mới'
                                : 'Gia nhập nhánh đã có sẵn',
                            valueColor: const Color(0xFF006E2A),
                            isBold: true,
                          ),
                          const Divider(height: 16, color: Color(0xFFF0EDEB)),
                          _buildInfoRow(
                            icon: Icons.format_list_numbered,
                            label: 'Đời thứ đề xuất:',
                            value: 'Đời ${widget.request.proposedGeneration}',
                            isMono: true,
                            isBold: true,
                          ),
                          const SizedBox(height: 16),

                          // Dropdown đổi chi nhánh nếu ứng viên chọn nhầm
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF9F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isBranchChanged ? const Color(0xFF006E2A) : const Color(0xFFDAC1BA),
                                width: _isBranchChanged ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.edit_location_alt_outlined, size: 18, color: Color(0xFF8F482F)),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Chi nhánh tiếp nhận chính thức (Trưởng tộc/nhánh có thể điều chỉnh):',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1C1C1A),
                                        ),
                                      ),
                                    ),
                                    if (_isBranchChanged)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF006E2A).withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF006E2A)),
                                        ),
                                        child: const Text(
                                          'Đã đổi nhánh',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF006E2A),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                if (_isPending)
                                  DropdownButtonFormField<String>(
                                    key: const ValueKey('branch_override_dropdown'),
                                    value: _selectedTargetBranchId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFDAC1BA)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF8F482F), width: 1.5),
                                      ),
                                    ),
                                    items: branchOptions.map((b) {
                                      return DropdownMenuItem<String>(
                                        value: b.branchId,
                                        child: Text(
                                          b.displayName,
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 13,
                                            fontWeight: b.branchId == widget.request.targetBranchId
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedTargetBranchId = val;
                                        });
                                      }
                                    },
                                  )
                                else
                                  Text(
                                    '${widget.request.targetBranchName ?? widget.request.targetBranchId} (Mã: ${widget.request.targetBranchId})',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1C1C1A),
                                    ),
                                  ),

                                const SizedBox(height: 8),
                                const Text(
                                  'Gợi ý AC-08: Nếu người nộp đơn chọn nhầm chi nhánh, quý vị hãy chọn lại nhánh chính xác trước khi bấm Phê duyệt. Thành viên sẽ được thêm vào đúng nhánh đã chọn.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B584E),
                                    height: 1.35,
                                  ),
                                ),

                                // Custom branch name input if NewChildBranch
                                if (widget.request.proposalType == ProposalType.newChildBranch) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tên chi nhánh con mới đề xuất:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1C1C1A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: _branchNameController,
                                    enabled: _isPending,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFFDAC1BA)),
                                      ),
                                      hintText: 'Nhập tên chi nhánh con mới...',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error feedback
            if (state.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                color: const Color(0xFFFFDAD6),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFBA1A1A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Footer Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF9F5),
                border: Border(top: BorderSide(color: Color(0xFFE6DFD8))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      side: const BorderSide(color: Color(0xFFDAC1BA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(color: Color(0xFF54433E), fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),

                  if (_isPending) ...[
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _handleOpenReject,
                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFBA1A1A)),
                      label: const Text(
                        'Từ Chối',
                        style: TextStyle(
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFBA1A1A)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _handleApprove,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        isLoading ? 'Đang xử lý...' : (_isBranchChanged ? 'Duyệt Vào Nhánh Mới' : 'Phê Duyệt Đơn'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006E2A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 1,
                      ),
                    ),
                  ] else ...[
                    Text(
                      widget.request.approvalStatus == JoinRequestApprovalStatus.approved
                          ? 'Đơn này đã được phê duyệt'
                          : 'Đơn này đã bị từ chối',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.request.approvalStatus == JoinRequestApprovalStatus.approved
                            ? const Color(0xFF006E2A)
                            : const Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF8F482F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
    bool isMono = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF85736E)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12.5,
            color: Color(0xFF54433E),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: isMono ? 'JetBrains Mono' : 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? const Color(0xFF1C1C1A),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  Widget _buildProcessedNotice() {
    final isApproved = widget.request.approvalStatus == JoinRequestApprovalStatus.approved;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isApproved ? const Color(0xFFF1F8F3) : const Color(0xFFFFF1EF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isApproved ? const Color(0xFF006E2A) : const Color(0xFFBA1A1A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApproved ? Icons.verified : Icons.cancel_outlined,
                size: 18,
                color: isApproved ? const Color(0xFF006E2A) : const Color(0xFFBA1A1A),
              ),
              const SizedBox(width: 8),
              Text(
                isApproved ? 'Đơn Đã Được Phê Chuẩn Chính Thức' : 'Đơn Bị Từ Chối Gia Nhập',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isApproved ? const Color(0xFF006E2A) : const Color(0xFFBA1A1A),
                ),
              ),
            ],
          ),
          if (widget.request.reviewedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Thời gian duyệt: ${_formatDateTime(widget.request.reviewedAt)} • Người duyệt: ${widget.request.reviewedByAccountId ?? "Hệ thống"}',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF54433E)),
            ),
          ],
          if (!isApproved && widget.request.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Text(
              'Lý do từ chối: "${widget.request.rejectionReason}"',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF93000A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatGender(String g) {
    if (g == 'Male') return 'Nam';
    if (g == 'Female') return 'Nữ';
    return 'Khác';
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '---';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
