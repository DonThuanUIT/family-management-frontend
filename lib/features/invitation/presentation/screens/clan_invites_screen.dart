import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../data/models/invitation_management_models.dart';
import '../providers/position_link_providers.dart';
import '../widgets/create_general_invite_dialog.dart';
import '../widgets/invitation_generator_card.dart';
import '../widgets/issued_codes_mobile_list.dart';
import '../widgets/issued_codes_table.dart';
import '../widgets/pedigree_structure_card.dart';

class ClanInvitesScreen extends ConsumerStatefulWidget {
  final String? initialBranchId;

  const ClanInvitesScreen({
    super.key,
    this.initialBranchId,
  });

  @override
  ConsumerState<ClanInvitesScreen> createState() => _ClanInvitesScreenState();
}

class _ClanInvitesScreenState extends ConsumerState<ClanInvitesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clanInvitesProvider.notifier).loadInitialData(widget.initialBranchId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clanInvitesProvider);
    final notifier = ref.read(clanInvitesProvider.notifier);
    final isDesktop = MediaQuery.of(context).size.width >= 860;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      appBar: const HeritageNavBar(currentRoute: '/clan-invites'),
      bottomNavigationBar:
          const HeritageBottomNavBar(currentRoute: '/clan-invites'),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Success / Error Feedback Snackbars / Banners
                if (state.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBA1A1A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFBA1A1A), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFF93000A),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state.successMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF99F8A2).withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF006E2A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Color(0xFF006E2A), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.successMessage!,
                            style: const TextStyle(
                              color: Color(0xFF00531E),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Top Archival Context Notice
                _buildTopNotice(isDesktop),
                const SizedBox(height: 24),

                // 3. Page Header
                _buildPageHeader(),
                const SizedBox(height: 24),

                // 4. Generator Card & Pedigree Side Panel Grid
                if (isDesktop)
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: InvitationGeneratorCard()),
                      SizedBox(width: 20),
                      Expanded(flex: 5, child: PedigreeStructureCard()),
                    ],
                  )
                else ...[
                  const InvitationGeneratorCard(),
                  const SizedBox(height: 16),
                  const PedigreeStructureCard(),
                ],
                const SizedBox(height: 32),

                // 5. Active Invites Table Section
                _buildTableSection(context, state, notifier, isDesktop),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Archival Context Notice
  Widget _buildTopNotice(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE6E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                _noticeIcon(),
                const SizedBox(width: 14),
                Expanded(child: _noticeContent()),
                const SizedBox(width: 16),
                _noticeBadges(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _noticeIcon(),
                    const SizedBox(width: 12),
                    Expanded(child: _noticeContent()),
                  ],
                ),
                const SizedBox(height: 12),
                _noticeBadges(),
              ],
            ),
    );
  }

  Widget _noticeIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF8F482F).withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.account_tree_outlined,
        color: Color(0xFF8F482F),
        size: 22,
      ),
    );
  }

  Widget _noticeContent() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cơ Chế Phân Cấp Hồ Sơ & Mật Khóa Nhánh Tộc',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1A),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tất cả mã phát hành được ràng buộc trực tiếp với tọa độ phả hệ niên khóa 2026. Con cháu sau khi mở liên kết sẽ kế thừa đúng chi phái mà không cần hội đồng duyệt lại.',
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Color(0xFF54433E),
          ),
        ),
      ],
    );
  }

  Widget _noticeBadges() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDEB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                color: Color(0xFF54433E),
              ),
              children: [
                TextSpan(text: 'Mã Tộc: '),
                TextSpan(
                  text: 'VN-LE-2026',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8F482F),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF99F8A2).withAlpha(80),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF006E2A).withAlpha(50)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_reset, size: 14, color: Color(0xFF006E2A)),
              SizedBox(width: 4),
              Text(
                'Xác thực mật mã',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006E2A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Page Header
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDEB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.badge_outlined, size: 14, color: Color(0xFF8F482F)),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Quản Trị Thành Viên & Phân Cấp',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8F482F),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cấp Mã Mời & Khởi Tạo Hồ Sơ Gia Phả',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1A),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Định vị trước vị trí con cháu trên cây phả hệ, xuất mã liên kết để con cháu tự nhập vị trí không cần duyệt thủ công.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF54433E),
          ),
        ),
      ],
    );
  }

  /// Active Invites Table Section
  Widget _buildTableSection(BuildContext context, ClanInvitesState state,
      ClanInvitesNotifier notifier, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Table Toolbar
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _tableTitleBadge(state),
                          _tableActions(notifier, state),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tableTitleBadge(state),
                          const SizedBox(height: 12),
                          _tableActions(notifier, state),
                        ],
                      ),
                const SizedBox(height: 14),
                _statusFilterChips(notifier, state),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEBE6E0)),

          // 2. Data Content: Table on Desktop, Cards on Mobile
          if (isDesktop)
            IssuedCodesTable(items: state.paginatedCodes)
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: IssuedCodesMobileList(items: state.paginatedCodes),
            ),

          // 3. Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F7F4),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Color(0xFFEBE6E0))),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Hiển thị ${state.paginatedCodes.length} trong tổng số ${state.filteredCodes.length} mã đã cấp phát',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: Color(0xFF756864),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: state.currentPage > 1
                          ? () => notifier.setPage(state.currentPage - 1)
                          : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(50, 30),
                      ),
                      child: const Text('Trước', style: TextStyle(fontSize: 12)),
                    ),
                    for (int p = 1; p <= state.totalPages; p++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: () => notifier.setPage(p),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p == state.currentPage
                                  ? const Color(0xFF8F482F)
                                  : const Color(0xFFF0EDEB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$p',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: p == state.currentPage
                                    ? Colors.white
                                    : const Color(0xFF1C1C1A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: state.currentPage < state.totalPages
                          ? () => notifier.setPage(state.currentPage + 1)
                          : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(50, 30),
                      ),
                      child: const Text('Sau', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableTitleBadge(ClanInvitesState state) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        const Text(
          'Danh Sách Mã Liên Kết Đã Phát Hành',
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1A),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF0EDEB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${state.issuedCodes.length} mã',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF54433E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusFilterChips(ClanInvitesNotifier notifier, ClanInvitesState state) {
    final current = state.codeStatusFilter;

    Widget chip({
      required String label,
      required int count,
      required bool isSelected,
      required VoidCallback onTap,
      Color? activeColor,
    }) {
      final color = activeColor ?? const Color(0xFF8F482F);
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? color : const Color(0xFFF0EDEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE5E0DA),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF54433E),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withAlpha(50) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF54433E),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip(
          label: 'Tất cả',
          count: state.issuedCodes.length,
          isSelected: current == null,
          onTap: () => notifier.setCodeStatusFilter(null),
        ),
        chip(
          label: 'Hoạt Động',
          count: state.activeCount,
          isSelected: current == InvitationCodeStatus.active,
          activeColor: const Color(0xFF006E2A),
          onTap: () => notifier.setCodeStatusFilter(InvitationCodeStatus.active),
        ),
        chip(
          label: 'Đã Dùng Hết',
          count: state.usedUpCount,
          isSelected: current == InvitationCodeStatus.usedUp,
          activeColor: const Color(0xFF4A148C),
          onTap: () => notifier.setCodeStatusFilter(InvitationCodeStatus.usedUp),
        ),
        chip(
          label: 'Hết Hạn',
          count: state.expiredCount,
          isSelected: current == InvitationCodeStatus.expired,
          activeColor: const Color(0xFF7A5900),
          onTap: () => notifier.setCodeStatusFilter(InvitationCodeStatus.expired),
        ),
        chip(
          label: 'Đã Thu Hồi',
          count: state.revokedCount,
          isSelected: current == InvitationCodeStatus.revoked,
          activeColor: const Color(0xFFBA1A1A),
          onTap: () => notifier.setCodeStatusFilter(InvitationCodeStatus.revoked),
        ),
      ],
    );
  }

  Widget _tableActions(ClanInvitesNotifier notifier, ClanInvitesState state) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        // Nút Tạo Mã Mới (US-34 & US-16)
        ElevatedButton.icon(
          onPressed: () => CreateGeneralInviteDialog.show(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text(
            'Tạo Mã Mới',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8F482F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Ô tìm kiếm
        SizedBox(
          width: 200,
          height: 36,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9E928E)),
              prefixIcon:
                  const Icon(Icons.search, size: 16, color: Color(0xFF756864)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: const Color(0xFFF6F3F1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
              ),
            ),
            onChanged: (val) => notifier.setSearchQuery(val),
          ),
        ),

        // Popup filter trạng thái
        PopupMenuButton<InvitationCodeStatus?>(
          tooltip: 'Lọc trạng thái mã',
          initialValue: state.codeStatusFilter,
          onSelected: (val) => notifier.setCodeStatusFilter(val),
          itemBuilder: (context) => const [
            PopupMenuItem(value: null, child: Text('Tất cả trạng thái')),
            PopupMenuItem(value: InvitationCodeStatus.active, child: Text('🟢 Hoạt Động')),
            PopupMenuItem(value: InvitationCodeStatus.usedUp, child: Text('🟣 Đã Dùng Hết')),
            PopupMenuItem(value: InvitationCodeStatus.expired, child: Text('🟡 Hết Hạn')),
            PopupMenuItem(value: InvitationCodeStatus.revoked, child: Text('🔴 Đã Thu Hồi')),
          ],
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDEB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.filter_list,
                size: 20, color: Color(0xFF54433E)),
          ),
        ),

        // Xuất file CSV
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đang trích xuất danh sách mã liên kết ra file CSV...'),
                backgroundColor: Color(0xFF8F482F),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDEB),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.download, size: 20, color: Color(0xFF54433E)),
          ),
        ),
      ],
    );
  }
}
