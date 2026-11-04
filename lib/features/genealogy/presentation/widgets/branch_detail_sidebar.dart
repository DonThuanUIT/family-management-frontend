import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/branch_models.dart';

/// Bảng hiển thị thông tin chi tiết và danh sách thành viên của một Chi/Nhánh.
/// Có thể hiển thị ở dạng Sidebar bên phải (trên Web/Tablet) hoặc Modal Bottom Sheet (trên Mobile).
class BranchDetailSidebar extends StatefulWidget {
  final BranchUiDetail branch;
  final VoidCallback onClose;
  final VoidCallback? onEdit;
  final bool isMobileSheet;

  const BranchDetailSidebar({
    super.key,
    required this.branch,
    required this.onClose,
    this.onEdit,
    this.isMobileSheet = false,
  });

  @override
  State<BranchDetailSidebar> createState() => _BranchDetailSidebarState();
}

class _BranchDetailSidebarState extends State<BranchDetailSidebar> {
  static const Color primaryColor = Color(0xFF8F482F); // Đỏ son trầm gia phả
  static const Color bgColor = Color(0xFFFCF9F6);      // Nền ngà ấm
  static const Color borderColor = Color(0xFFDAC1BA);
  static const Color textColor = Color(0xFF1C1C1A);
  static const Color subtextColor = Color(0xFF54433E);

  int _selectedTab = 0; // 0: Tổng quan, 1: Danh sách thành viên
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = widget.branch.members.where((m) {
      if (_searchKeyword.isEmpty) return true;
      final query = _searchKeyword.toLowerCase();
      return m.fullName.toLowerCase().contains(query) ||
          m.roleInBranch.toLowerCase().contains(query) ||
          'đời ${m.generation}'.contains(query);
    }).toList();

    return Container(
      width: widget.isMobileSheet ? double.infinity : 400,
      decoration: BoxDecoration(
        color: bgColor,
        border: widget.isMobileSheet
            ? null
            : const Border(
                left: BorderSide(color: borderColor, width: 1),
              ),
        boxShadow: widget.isMobileSheet
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(-4, 0),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Sidebar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.branch.code,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.branch.name,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: subtextColor),
                  tooltip: 'Đóng bảng chi tiết',
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Tab Selector (Tổng quan vs Danh sách thành viên)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    title: 'Tổng Quan Chi',
                    icon: Icons.info_outline,
                    activeColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    title: 'Thành Viên (${widget.branch.memberCount})',
                    icon: Icons.group_outlined,
                    activeColor: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: borderColor),

          // Body Content
          Expanded(
            child: _selectedTab == 0
                ? _buildOverviewTab(context)
                : _buildMembersListTab(context, filteredMembers),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : const Color(0xFF6B584E),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF6B584E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Representative Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDEB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.branch.badge,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.branch.representative,
                        style: const TextStyle(
                          fontFamily: 'Merriweather',
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        widget.branch.representativeSubtext,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11.5,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2 Metrics Pills (Thành viên kích hoạt & Quỹ tích lũy chi)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = 1),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thành viên',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: subtextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${widget.branch.memberCount}',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const Text(
                              ' người',
                              style: TextStyle(fontSize: 12, color: subtextColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Text(
                              'Xem danh sách',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006E2A),
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_ios, size: 10, color: primaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quỹ tích lũy chi',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.branch.fundAmount,
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006E2A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.branch.kycStatus,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          color: Color(0xFF006E2A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Succession Chain (Chuỗi kế thừa trực hệ)
          if (widget.branch.successionChain.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHUỖI KẾ THỪA TRỰC HỆ:',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final item in widget.branch.successionChain)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.subdirectory_arrow_right, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Description & Genealogy Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_edu_outlined, size: 16, color: primaryColor),
                    SizedBox(width: 6),
                    Text(
                      'Lược Sử & Phả Ký',
                      style: TextStyle(
                        fontFamily: 'Merriweather',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.branch.description.isNotEmpty
                      ? widget.branch.description
                      : 'Hồ sơ nhánh chi phái được lập và số hóa từ niên khóa 2026. Mọi con cháu thuộc chi phái đều được liên kết trực tiếp trên cây gia phả số.',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: subtextColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          if (widget.branch.isRoot && widget.onEdit != null) ...[
            ElevatedButton.icon(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_note, size: 18, color: Colors.white),
              label: const Text(
                'Chỉnh Sửa Nhánh Gốc (Ticket #16)',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () {
              context.push('/clan-invites');
            },
            icon: const Icon(Icons.qr_code_2, size: 18, color: primaryColor),
            label: const Text(
              'Xuất Mã Mời Gia Phả Cho Chi Này',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersListTab(
    BuildContext context,
    List<BranchMemberItem> members,
  ) {
    return Column(
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm thành viên theo tên, vai vế...',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
              suffixIcon: _searchKeyword.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchKeyword = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: borderColor),
              ),
            ),
            onChanged: (val) => setState(() => _searchKeyword = val),
          ),
        ),

        // List of Members
        Expanded(
          child: members.isEmpty
              ? Center(
                  child: Text(
                    _searchKeyword.isEmpty
                        ? 'Chưa có thành viên nào được đăng ký'
                        : 'Không tìm thấy thành viên khớp từ khóa',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: members.length,
                  separatorBuilder: (context, index) => const Divider(height: 8, color: Color(0xFFEFECE8)),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEAE5E0)),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: member.gender == 'female'
                                ? const Color(0xFFFFD8E4)
                                : const Color(0xFFDBE7FF),
                            child: Icon(
                              member.gender == 'female' ? Icons.face_3 : Icons.face,
                              size: 20,
                              color: member.gender == 'female'
                                  ? const Color(0xFFB3261E)
                                  : const Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      member.fullName,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1C1C1A),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Đời ${member.generation}',
                                        style: const TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${member.roleInBranch}${member.birthDeathInfo != null ? " • ${member.birthDeathInfo}" : ""}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B584E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: member.isActivated
                                  ? const Color(0xFF99F8A2).withValues(alpha: 0.25)
                                  : const Color(0xFFFFDCBE).withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              member.isActivated ? 'Đã KYC' : 'Chờ liên kết',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: member.isActivated
                                    ? const Color(0xFF006E2A)
                                    : const Color(0xFF874E00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Thanh đếm số lượng & Add Member Button Bottom
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFEAE5E0))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hiển thị: ${members.length} / ${widget.branch.memberCount} thành viên',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        color: Color(0xFF6B584E),
                      ),
                    ),
                    Text(
                      '${widget.branch.activatedMemberCount} đã kích hoạt',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006E2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/clan-invites');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Cấp Mã Mời Thành Viên',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ],
    );
  }
}
