import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../../genealogy/presentation/providers/genealogy_providers.dart';
import '../../../genealogy/presentation/widgets/branch_detail_sidebar.dart';
import '../../../genealogy/presentation/widgets/transfer_node_dialog.dart';
import '../../../genealogy/data/models/branch_models.dart';
import '../../../genealogy/data/repositories/genealogy_repository_impl.dart';
import '../../../contribution/presentation/providers/branch_recursive_contribution_providers.dart';
import '../../../contribution/presentation/widgets/branch_contribution_pill.dart';
import '../../../event/presentation/providers/event_providers.dart';

/// Họa sĩ vẽ nhánh chẽ chữ T chuẩn hình học phả hệ (pixel-perfect)
class TreeForkPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const TreeForkPainter({
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final midY = size.height / 2;

    // Đường đứng từ trên xuống điểm giữa (center stem up)
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, midY), paint);
    // Thanh ngang nối từ mép trái sang mép phải (crossbar)
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    // Đường đứng mép trái xuống tâm Chi 1 (left drop)
    canvas.drawLine(Offset(0, midY), Offset(0, size.height), paint);
    // Đường đứng mép phải xuống tâm Chi 2 (right drop)
    canvas.drawLine(Offset(size.width, midY), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant TreeForkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Màn hình Cây Phả Hệ Trực Quan Đa Chi Phái (Stitch Warm Editorial Heritage)
/// Hỗ trợ Pan & Zoom, Đóng/Mở nhánh con, Popover tóm tắt (US-29, Task #110)
/// Thanh tìm kiếm thông minh kèm bộ lọc thế hệ, auto-pan/focus & highlight (US-30, Task #112)
/// Điều chuyển nhánh/thành viên kèm cảnh báo lỗi đệ quy (US-28, Task #108)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Bộ điều khiển Pan & Zoom (InteractiveViewer) (US-29, Task #110)
  final TransformationController _transformationController = TransformationController();

  // Danh sách các chi nhánh đang bị thu gọn (Collapse/Expand theo từng nhánh) (US-29, Task #110)
  final Set<String> _collapsedBranchIds = {};

  // Trạng thái hiển thị mở rộng toàn bộ các đời phả hệ
  bool _isFullTreeExpanded = true;

  // ID của chi/nhánh đang được chọn
  String? _selectedBranchId;

  // Thành viên cụ thể đang được chọn (nếu click vào thẻ thành viên)
  BranchMemberItem? _selectedMember;

  // Trạng thái hiển thị Sidebar chi tiết (trên màn hình rộng)
  bool _isSidebarOpen = true;

  // ID thành viên & chi nhánh đang được highlight do tìm kiếm (US-30, Task #112)
  String? _highlightedMemberId;
  String? _highlightedBranchId;

  // Bộ điều khiển tìm kiếm thông minh (US-30, Task #112)
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<MemberSearchDto> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchOverlay = false;
  int? _selectedGenerationFilter;
  String? _selectedBranchFilter;

  @override
  void dispose() {
    _transformationController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Thu phóng Pan & Zoom
  void _zoomIn() {
    final matrix = _transformationController.value.clone();
    matrix.scale(1.25);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformationController.value.clone();
    matrix.scale(0.8);
    _transformationController.value = matrix;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  // Đóng/mở từng nhánh con (US-29, Task #110)
  void _toggleBranchCollapse(String branchId) {
    setState(() {
      if (_collapsedBranchIds.contains(branchId)) {
        _collapsedBranchIds.remove(branchId);
      } else {
        _collapsedBranchIds.add(branchId);
      }
    });
  }

  // Tìm kiếm thông minh nối API thực tế `GET /api/v1/members/search` (US-30, Task #112)
  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty && _selectedGenerationFilter == null && _selectedBranchFilter == null) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showSearchOverlay = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      try {
        final repo = ref.read(genealogyRepositoryProvider);
        final results = await repo.searchMembers(
          keyword: query.trim().isNotEmpty ? query.trim() : null,
          generation: _selectedGenerationFilter,
          branchId: _selectedBranchFilter,
        );
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
            _showSearchOverlay = results.isNotEmpty;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchResults = [];
          });
        }
      }
    });
  }

  // Khi chọn một kết quả tìm kiếm: auto-expand, auto-focus & highlight (US-30, Task #112)
  void _selectSearchResult(MemberSearchDto member, BranchTreeNodeDto tree, bool isWide) {
    setState(() {
      _showSearchOverlay = false;
      _highlightedMemberId = member.memberId;
      _highlightedBranchId = member.branchId;

      // Mở rộng tất cả các nhánh để hiện thành viên này
      if (member.branchId != null) {
        _collapsedBranchIds.remove(member.branchId!);
      }
      _isFullTreeExpanded = true;

      // Tự động cuộn & focus lại trung tâm khung nhìn
      _transformationController.value = Matrix4.identity();

      // Cập nhật selected member
      _selectedMember = BranchMemberItem(
        memberId: member.memberId,
        fullName: member.fullName,
        generation: member.generation,
        birthDeathInfo: member.dateOfBirth != null ? 'Sinh ${member.dateOfBirth!.split('-').first}' : null,
        roleInBranch: 'Đời ${member.generation}',
        isActivated: !member.isPlaceholder,
      );
      if (member.branchId != null) {
        _selectedBranchId = member.branchId;
      }
      _isSidebarOpen = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã định vị & làm nổi bật: ${member.fullName} (Đời ${member.generation})'),
        backgroundColor: const Color(0xFF006E2A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Mở hộp thoại Popover xem tóm tắt khi click nút (US-29, Task #110)
  void _showNodePopover(BuildContext context, BranchUiDetail detail, BranchTreeNodeDto rootTree) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDFB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDAC1BA)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8F482F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_tree, color: Color(0xFF8F482F), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.name,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1A),
                    ),
                  ),
                  Text(
                    detail.badge,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8F482F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _popoverRow(Icons.person, 'Người đại diện', detail.representative),
            const SizedBox(height: 8),
            _popoverRow(Icons.groups, 'Tổng thành viên', '${detail.memberCount} thành viên (${detail.activatedMemberCount} đã kích hoạt)'),
            const SizedBox(height: 8),
            _popoverRow(Icons.qr_code, 'Mã chi phái', detail.code),
            const SizedBox(height: 8),
            _popoverRow(Icons.info_outline, 'Mô tả', detail.description),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showTransferDialog(rootTree, initialBranchId: detail.id);
            },
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Điều Chuyển Nhánh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8F482F),
              side: const BorderSide(color: Color(0xFF8F482F)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _selectedBranchId = detail.id;
                _selectedMember = null;
                _isSidebarOpen = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8F482F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xem Danh Sách'),
          ),
        ],
      ),
    );
  }

  Widget _popoverRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8F482F)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: Color(0xFF1C1C1A)),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Mở hộp thoại điều chuyển (US-28, Task #108)
  void _showTransferDialog(BranchTreeNodeDto rootTree, {String? initialBranchId, BranchMemberItem? initialMember}) {
    showDialog(
      context: context,
      builder: (_) => TransferNodeDialog(
        rootTree: rootTree,
        initialBranchId: initialBranchId,
        initialMember: initialMember,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(branchTreeProvider);
    final rootBranchState = ref.watch(rootBranchProvider);
    final authState = ref.watch(authStateProvider);
    final session = ref.watch(dualRbacSessionProvider);

    final currentUserName = authState.user?.fullName.isNotEmpty == true
        ? authState.user!.fullName
        : (session.fullName.isNotEmpty ? session.fullName : '');
    final currentMemberId = authState.user?.memberId ?? session.memberId;
    final isClanHead = authState.user?.roles.contains('ROLE_CLAN_HEAD') == true ||
        session.globalRoles.contains(SystemRole.roleClanHead);

    const kPrimaryColor = Color(0xFF8F482F);
    const kBgColor = Color(0xFFFCF9F6);
    const kBorderColor = Color(0xFFDAC1BA);

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: const HeritageNavBar(currentRoute: '/home'),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/home'),
      body: treeAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_top_outlined, color: kPrimaryColor, size: 28),
                SizedBox(height: 12),
                Text(
                  'Đang tải cấu trúc cây phả hệ dòng họ...',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFBA1A1A)),
                const SizedBox(height: 12),
                Text(
                  'Lỗi tải cây phả hệ: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(branchTreeProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
        data: (tree) {
          // Khởi tạo nhánh chọn mặc định là Nhánh Gốc nếu chưa chọn
          final activeBranchId = _selectedBranchId ?? tree.branchId;
          final activeBranchMembersAsync = ref.watch(branchMembersProvider(activeBranchId));
          final activeBranchMembers = activeBranchMembersAsync.value ?? [];

          final rootMembersAsync = ref.watch(branchMembersProvider(tree.branchId));
          final rootMembers = rootMembersAsync.value ?? [];

          // Tự động phân giải tên Khởi Tổ thông minh nếu backend chưa set representativeName
          final effectiveRootRepresentative = (tree.representativeName != null && tree.representativeName!.trim().isNotEmpty)
              ? tree.representativeName!
              : (rootMembers.firstWhereOrNull((m) => m.generation == 1)?.fullName ??
                  (rootMembers.isNotEmpty ? rootMembers.first.fullName : 'Chưa cập nhật'));

          // Xác định nhánh được chọn để hiển thị ở Sidebar
          final BranchUiDetail selectedDetail;
          if (_selectedMember != null) {
            selectedDetail = BranchUiDetail(
              id: _selectedMember!.memberId,
              name: 'Hồ Sơ: ${_selectedMember!.fullName}',
              badge: 'ĐỜI ${_selectedMember!.generation}',
              code: _selectedMember!.memberId,
              representative: _selectedMember!.fullName,
              representativeSubtext: _selectedMember!.birthDeathInfo ?? 'Thành viên Đời ${_selectedMember!.generation}',
              memberCount: 1,
              activatedMemberCount: _selectedMember!.isActivated ? 1 : 0,
              fundAmount: '0 đ',
              description: 'Hồ sơ thành viên chính thức thuộc phả hệ dòng họ ${tree.clanName}.',
              members: [_selectedMember!],
              isRoot: false,
            );
          } else if (activeBranchId == tree.branchId) {
            final isRootCurrentUser = isClanHead ||
                currentMemberId == tree.representativeId ||
                currentUserName == tree.representativeName ||
                currentUserName == effectiveRootRepresentative;
            selectedDetail = BranchUiDetail(
              id: tree.branchId,
              name: tree.branchName,
              badge: isRootCurrentUser ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC' : 'CỤ KHỞI TỔ • ĐỜI 1',
              code: tree.branchId,
              representative: effectiveRootRepresentative,
              representativeSubtext: 'Trưởng Tộc • Đại diện Dòng họ',
              representativeId: tree.representativeId,
              memberCount: tree.memberCount,
              activatedMemberCount: rootMembers.where((m) => m.isActivated).isNotEmpty
                  ? rootMembers.where((m) => m.isActivated).length
                  : tree.memberCount,
              fundAmount: '0 đ',
              description: rootBranchState.branch?.description ??
                  'Chi nhánh gốc khởi lập gia phả dòng họ, nơi quy tụ toàn thể con cháu.',
              successionChain: [effectiveRootRepresentative],
              members: rootMembers,
              isRoot: true,
            );
          } else {
            // Nhánh phụ được chọn
            BranchTreeNodeDto? foundChild;
            void searchNode(BranchTreeNodeDto n) {
              if (n.branchId == activeBranchId) {
                foundChild = n;
                return;
              }
              for (final c in n.children) {
                searchNode(c);
              }
            }
            searchNode(tree);

            final childNode = foundChild ?? (tree.children.isNotEmpty ? tree.children.first : tree);
            final childMembersAsync = ref.watch(branchMembersProvider(childNode.branchId));
            final childMembers = childMembersAsync.value ?? [];
            final effectiveChildRep = (childNode.representativeName != null && childNode.representativeName!.trim().isNotEmpty)
                ? childNode.representativeName!
                : (childMembers.firstWhereOrNull((m) => m.roleInBranch.contains('Trưởng') || m.generation == childNode.generationLevel)?.fullName ??
                    (childMembers.isNotEmpty ? childMembers.first.fullName : 'Chưa cập nhật'));

            final isChildCurrentUser = currentMemberId == childNode.representativeId ||
                currentUserName == childNode.representativeName ||
                currentUserName == effectiveChildRep;

            selectedDetail = BranchUiDetail(
              id: childNode.branchId,
              name: childNode.branchName,
              badge: isChildCurrentUser
                  ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG CHI'
                  : 'Chi ${childNode.branchName} • Đời ${childNode.generationLevel}',
              code: childNode.branchId,
              representative: effectiveChildRep,
              representativeSubtext: 'Đại diện Chi • Đời ${childNode.generationLevel}',
              representativeId: childNode.representativeId,
              memberCount: childNode.memberCount,
              activatedMemberCount: activeBranchMembers.where((m) => m.isActivated).isNotEmpty
                  ? activeBranchMembers.where((m) => m.isActivated).length
                  : childNode.memberCount,
              fundAmount: '0 đ',
              description: 'Chi nhánh trực thuộc phả hệ dòng họ ${tree.clanName}.',
              successionChain: [effectiveRootRepresentative, effectiveChildRep],
              members: activeBranchMembers,
              isRoot: false,
            );
          }

          final isRootCurrentUser = isClanHead ||
              currentMemberId == tree.representativeId ||
              currentUserName == tree.representativeName ||
              currentUserName == effectiveRootRepresentative;

          final rootUiDetail = BranchUiDetail(
            id: tree.branchId,
            name: tree.branchName,
            badge: isRootCurrentUser ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC' : 'CỤ KHỞI TỔ • ĐỜI 1',
            code: tree.branchId,
            representative: effectiveRootRepresentative,
            representativeSubtext: 'Trưởng Tộc • Đại diện Dòng họ',
            representativeId: tree.representativeId,
            memberCount: tree.memberCount,
            activatedMemberCount: rootMembers.where((m) => m.isActivated).length > 0
                ? rootMembers.where((m) => m.isActivated).length
                : tree.memberCount,
            fundAmount: '0 đ',
            description: rootBranchState.branch?.description ??
                'Chi nhánh gốc khởi lập gia phả dòng họ, nơi quy tụ toàn thể con cháu.',
            members: rootMembers,
            isRoot: true,
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // VÙNG CANVAS HIỂN THỊ CÂY PHẢ HỆ
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        // THANH TÌM KIẾM THÔNG MINH KÈM BỘ LỌC (US-30, Task #112)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: kBorderColor, width: 1)),
                          ),
                          child: Column(
                            children: [
                              // Dòng 1: Tên Dòng Họ + Các Nút Action (Thu gọn/Mở rộng, US-11 Công đức đệ quy, Online badge)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.account_tree_outlined, color: kPrimaryColor, size: 20),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          tree.clanName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Merriweather',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF1C1C1A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      // NÚT CHUYỂN ĐỔI: THU GỌN / HIỆN ĐẦY ĐỦ CÂY
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _isFullTreeExpanded = !_isFullTreeExpanded;
                                          });
                                        },
                                        icon: Icon(
                                          _isFullTreeExpanded ? Icons.unfold_less : Icons.unfold_more,
                                          size: 16,
                                          color: kPrimaryColor,
                                        ),
                                        label: Text(
                                          _isFullTreeExpanded ? 'Thu Gọn Sơ Đồ' : 'Hiện Đầy Đủ Cây (Tất Cả Đời)',
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimaryColor,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: kPrimaryColor),
                                          backgroundColor: _isFullTreeExpanded
                                              ? kPrimaryColor.withValues(alpha: 0.08)
                                              : Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // [US-11] NÚT CHUYỂN ĐỔI CHẾ ĐỘ XEM CÔNG ĐỨC ĐỆ QUY
                                      Builder(
                                        builder: (context) {
                                          final treeContribFilter = ref.watch(treeContributionFilterProvider);
                                          final treeContribNotifier = ref.read(treeContributionFilterProvider.notifier);
                                          final isEnabled = treeContribFilter.isContributionViewEnabled;

                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () => treeContribNotifier.toggleContributionView(),
                                                icon: Icon(
                                                  isEnabled ? Icons.visibility_off : Icons.stars,
                                                  size: 16,
                                                  color: isEnabled ? const Color(0xFFD4AF37) : const Color(0xFF8B1E1E),
                                                ),
                                                label: Text(
                                                  isEnabled ? 'Ẩn Công Đức' : 'Xem Công Đức Đệ Quy',
                                                  style: TextStyle(
                                                    fontFamily: 'Be Vietnam Pro',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isEnabled ? Colors.white : const Color(0xFF8B1E1E),
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor: isEnabled
                                                      ? const Color(0xFF8B1E1E)
                                                      : Colors.white,
                                                  side: const BorderSide(
                                                    color: Color(0xFF8B1E1E),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                ),
                                              ),
                                              if (isEnabled) ...[
                                                const SizedBox(width: 8),
                                                Consumer(
                                                  builder: (context, ref, _) {
                                                    final eventList = ref.watch(eventListProvider);
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFAF9F6),
                                                        borderRadius: BorderRadius.circular(20),
                                                        border: Border.all(color: const Color(0xFFE5E5E5)),
                                                      ),
                                                      child: DropdownButtonHideUnderline(
                                                        child: DropdownButton<String?>(
                                                          value: treeContribFilter.selectedEventId,
                                                          isDense: true,
                                                          hint: const Text(
                                                            'Tất cả sự kiện',
                                                            style: TextStyle(
                                                              fontFamily: 'Be Vietnam Pro',
                                                              fontSize: 11,
                                                              color: Color(0xFF58413F),
                                                            ),
                                                          ),
                                                          items: [
                                                            const DropdownMenuItem<String?>(
                                                              value: null,
                                                              child: Text(
                                                                'Tất cả sự kiện',
                                                                style: TextStyle(
                                                                  fontFamily: 'Be Vietnam Pro',
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                            ),
                                                            ...eventList.events.map((e) => DropdownMenuItem<String?>(
                                                                  value: e.eventId,
                                                                  child: Text(
                                                                    e.eventName,
                                                                    style: const TextStyle(
                                                                      fontFamily: 'Be Vietnam Pro',
                                                                      fontSize: 11,
                                                                    ),
                                                                  ),
                                                                )),
                                                          ],
                                                          onChanged: (val) {
                                                            final ev = eventList.events.where((e) => e.eventId == val).firstOrNull;
                                                            treeContribNotifier.setEventFilter(eventId: val, eventName: ev?.eventName);
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      // Badge trạng thái kết nối API
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF99F8A2).withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '● Trực tuyến ${tree.children.length + 1} chi',
                                          style: const TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF006E2A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),


                              // Dòng 3: THANH TÌM KIẾM THÀNH VIÊN VÀ ĐIỀU CHUYỂN
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: _onSearchChanged,
                                      decoration: InputDecoration(
                                        hintText: 'Tìm kiếm thành viên theo tên, mã thành viên, đời thứ...',
                                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                                        prefixIcon: _isSearching
                                            ? const Padding(
                                                padding: EdgeInsets.all(12),
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              )
                                            : const Icon(Icons.search, color: kPrimaryColor, size: 20),
                                        suffixIcon: _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 18),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  _onSearchChanged('');
                                                },
                                              )
                                            : null,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: kBorderColor),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFFAF9F6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Bộ lọc Thế Hệ / Đời
                                  DropdownButton<int?>(
                                    value: _selectedGenerationFilter,
                                    hint: const Text('Tất cả đời', style: TextStyle(fontSize: 12.5)),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Tất cả đời')),
                                      for (int g = 1; g <= 10; g++)
                                        DropdownMenuItem(value: g, child: Text('Đời $g')),
                                    ],
                                    onChanged: (val) {
                                      setState(() => _selectedGenerationFilter = val);
                                      _onSearchChanged(_searchController.text);
                                    },
                                  ),
                                  const SizedBox(width: 8),

                                  // Nút điều chuyển nhanh (US-28)
                                  ElevatedButton.icon(
                                    onPressed: () => _showTransferDialog(tree),
                                    icon: const Icon(Icons.swap_horiz, size: 16),
                                    label: const Text('Điều Chuyển'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // CANVAS INTERACTIVE VIEWER HỖ TRỢ PAN & ZOOM (US-29, Task #110)
                        Expanded(
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            boundaryMargin: const EdgeInsets.all(1200),
                            minScale: 0.25,
                            maxScale: 2.5,
                            constrained: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ROOT ANCESTOR NODE
                                  _buildRootAncestorCard(
                                    context: context,
                                    detail: rootUiDetail,
                                    isSelected: activeBranchId == tree.branchId && _selectedMember == null,
                                    isCurrentUser: isRootCurrentUser,
                                    isHighlighted: _highlightedBranchId == tree.branchId,
                                    onTap: () => _handleSelectBranch(tree.branchId, selectedDetail, isWide),
                                    onShowPopover: () => _showNodePopover(context, rootUiDetail, tree),
                                  ),


                                  // HIỂN THỊ CÁC CHI NHÁNH CON
                                  if (tree.children.isNotEmpty) ...[
                                    if (tree.children.length == 1) ...[
                                      Container(width: 2, height: 28, color: kPrimaryColor),
                                      _buildChildBranchColumn(
                                        context: context,
                                        child: tree.children.first,
                                        isWide: isWide,
                                        currentMemberId: currentMemberId,
                                        currentUserName: currentUserName,
                                        activeBranchId: activeBranchId,
                                        rootTree: tree,
                                      ),
                                    ] else ...[
                                      SizedBox(
                                        width: (tree.children.length * 360.0) / 1.8,
                                        height: 36,
                                        child: const CustomPaint(
                                          painter: TreeForkPainter(color: kPrimaryColor, strokeWidth: 2),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for (int i = 0; i < tree.children.length; i++) ...[
                                            if (i > 0) const SizedBox(width: 32),
                                            _buildChildBranchColumn(
                                              context: context,
                                              child: tree.children[i],
                                              isWide: isWide,
                                              currentMemberId: currentMemberId,
                                              currentUserName: currentUserName,
                                              activeBranchId: activeBranchId,
                                              rootTree: tree,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // OVERLAY KẾT QUẢ TÌM KIẾM THÔNG MINH (US-30, Task #112)
                    if (_showSearchOverlay && _searchResults.isNotEmpty)
                      Positioned(
                        top: 60,
                        left: 16,
                        right: 16,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 320),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kPrimaryColor),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final m = _searchResults[i];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: kPrimaryColor.withValues(alpha: 0.1),
                                    child: Text(
                                      '${m.generation}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                                    ),
                                  ),
                                  title: Text(
                                    m.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  subtitle: Text(
                                    'Mã: ${m.memberId} • Đời ${m.generation} • Chi: ${m.branchName ?? 'Chưa gán'}',
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: kPrimaryColor),
                                  onTap: () => _selectSearchResult(m, tree, isWide),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // THANH ĐIỀU KHIỂN PAN & ZOOM (US-29, Task #110)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: kBorderColor),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _zoomIn,
                              tooltip: 'Phóng to (+)',
                              icon: const Icon(Icons.add, size: 20, color: kPrimaryColor),
                            ),
                            IconButton(
                              onPressed: _zoomOut,
                              tooltip: 'Thu nhỏ (-)',
                              icon: const Icon(Icons.remove, size: 20, color: kPrimaryColor),
                            ),
                            IconButton(
                              onPressed: _resetZoom,
                              tooltip: 'Khôi phục tỷ lệ (1:1)',
                              icon: const Icon(Icons.center_focus_strong, size: 20, color: kPrimaryColor),
                            ),
                            if (isWide)
                              IconButton(
                                onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                                tooltip: _isSidebarOpen ? 'Thu gọn bảng chi tiết' : 'Mở bảng chi tiết',
                                icon: Icon(
                                  _isSidebarOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                                  size: 20,
                                  color: kPrimaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Nút mở nhanh bảng chi tiết chi khi đang đóng trên màn hình rộng
                    if (isWide && !_isSidebarOpen)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Material(
                          elevation: 3,
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => setState(() => _isSidebarOpen = true),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.view_sidebar_outlined, size: 18, color: kPrimaryColor),
                                  SizedBox(width: 6),
                                  Text(
                                    'Mở bảng chi tiết chi',
                                    style: TextStyle(
                                      fontFamily: 'Be Vietnam Pro',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // BẢNG SIDEBAR BÊN PHẢI (HIỂN THỊ TRÊN MÀN HÌNH RỘNG >= 900px)
              if (isWide && _isSidebarOpen)
                BranchDetailSidebar(
                  branch: selectedDetail,
                  onClose: () => setState(() {
                    _isSidebarOpen = false;
                    _selectedMember = null;
                  }),
                  onEdit: selectedDetail.isRoot
                      ? () => context.push('/branches/root/edit')
                      : () => _showTransferDialog(tree, initialBranchId: selectedDetail.id),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleSelectBranch(String branchId, BranchUiDetail detail, bool isWide) {
    setState(() {
      _selectedBranchId = branchId;
      _selectedMember = null;
      _isSidebarOpen = true;
    });

    if (!isWide) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: BranchDetailSidebar(
              branch: detail,
              onClose: () => Navigator.of(ctx).pop(),
              onEdit: detail.isRoot ? () => context.push('/branches/root/edit') : null,
            ),
          ),
        ),
      );
    }
  }

  // 1. Thẻ Nhánh Gốc (Root Ancestor Node)
  Widget _buildRootAncestorCard({
    required BuildContext context,
    required BranchUiDetail detail,
    required bool isSelected,
    required bool isCurrentUser,
    required VoidCallback onTap,
    required VoidCallback onShowPopover,
    bool isHighlighted = false,
  }) {
    const kPrimaryColor = Color(0xFF8F482F);

    return InkWell(
      onTap: onTap,
      onDoubleTap: onShowPopover,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1E1A), Color(0xFF4A342E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFFFD700)
                : (isCurrentUser ? const Color(0xFF006E2A) : const Color(0xFFD4A017)),
            width: isHighlighted ? 3 : (isCurrentUser || isSelected ? 2.5 : 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: isHighlighted ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A017),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          detail.badge,
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C1E1A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onShowPopover,
                        icon: const Icon(Icons.info_outline, color: Color(0xFFFFB59D), size: 18),
                        tooltip: 'Xem tóm tắt (Popover)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFD4A017),
                        child: const Icon(Icons.account_balance, color: Color(0xFF2C1E1A), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.representative,
                              style: const TextStyle(
                                fontFamily: 'Merriweather',
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              detail.name,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12.5,
                                color: Color(0xFFFFB59D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // [US-11] Thống kê đóng góp đệ quy trên Nhánh Gốc (Thủy Tổ)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: BranchContributionPill(
                branchId: detail.id,
                branchName: detail.name,
                isRootBranch: true,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${detail.memberCount} Thành viên',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFFFB59D), fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: onShowPopover,
                        icon: const Icon(Icons.visibility, size: 14, color: Colors.white),
                        label: const Text('Tóm tắt', style: TextStyle(fontSize: 11, color: Colors.white)),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/branches/root/edit'),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Thẻ Chi Nhánh Con Hỗ Trợ Thu Gọn / Mở Rộng (Collapse/Expand) (US-29, Task #110)
  Widget _buildChildBranchColumn({
    required BuildContext context,
    required BranchTreeNodeDto child,
    required bool isWide,
    required String currentMemberId,
    required String currentUserName,
    required String activeBranchId,
    required BranchTreeNodeDto rootTree,
  }) {
    const kPrimaryColor = Color(0xFF8F482F);
    final isCollapsed = _collapsedBranchIds.contains(child.branchId);

    final childMembersAsync = ref.watch(branchMembersProvider(child.branchId));
    final childMembers = childMembersAsync.value ?? [];

    final effectiveRepresentative = (child.representativeName != null && child.representativeName!.trim().isNotEmpty)
        ? child.representativeName!
        : (childMembers.firstWhereOrNull((m) => m.roleInBranch.contains('Trưởng') || m.generation == child.generationLevel)?.fullName ??
            (childMembers.isNotEmpty ? childMembers.first.fullName : 'Chưa cập nhật'));

    final isChildCurrentUser = currentMemberId == child.representativeId ||
        currentUserName == child.representativeName ||
        currentUserName == effectiveRepresentative;

    final subMembers = childMembers.where((m) => m.memberId != child.representativeId && m.fullName != effectiveRepresentative).toList()
      ..sort((a, b) => a.generation.compareTo(b.generation));

    final childUiDetail = BranchUiDetail(
      id: child.branchId,
      name: child.branchName,
      badge: isChildCurrentUser
          ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG CHI'
          : 'Chi ${child.branchName} • Đời ${child.generationLevel}',
      code: child.branchId,
      representative: effectiveRepresentative,
      representativeSubtext: 'Đại diện Chi • Đời ${child.generationLevel}',
      representativeId: child.representativeId,
      memberCount: child.memberCount,
      activatedMemberCount: childMembers.where((m) => m.isActivated).isNotEmpty
          ? childMembers.where((m) => m.isActivated).length
          : child.memberCount,
      fundAmount: '0 đ',
      description: 'Chi nhánh trực thuộc phả hệ dòng họ.',
      members: childMembers,
      isRoot: false,
    );

    return SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBranchNodeCard(
            context: context,
            detail: childUiDetail,
            isSelected: activeBranchId == child.branchId && _selectedMember == null,
            isWide: isWide,
            isCurrentUser: isChildCurrentUser,
            isCollapsed: isCollapsed,
            isHighlighted: _highlightedBranchId == child.branchId,
            onSelect: () => _handleSelectBranch(child.branchId, childUiDetail, isWide),
            onToggleCollapse: () => _toggleBranchCollapse(child.branchId),
            onShowPopover: () => _showNodePopover(context, childUiDetail, rootTree),
            onTransfer: () => _showTransferDialog(rootTree, initialBranchId: child.branchId),
          ),

          // Render nhánh con và thành viên nếu KHÔNG bị thu gọn (Collapse/Expand)
          if (!isCollapsed && _isFullTreeExpanded) ...[
            if (subMembers.isNotEmpty) ...[
              for (final member in subMembers) ...[
                Container(width: 2, height: 16, color: kPrimaryColor),
                _buildSubGenerationCard(
                  generation: 'Đời ${member.generation}',
                  title: member.fullName,
                  subtitle: member.birthDeathInfo ?? 'Thành viên phả hệ',
                  color: kPrimaryColor,
                  isSelected: _selectedMember?.memberId == member.memberId,
                  isHighlighted: _highlightedMemberId == member.memberId,
                  onTap: () {
                    setState(() {
                      _selectedMember = member;
                      _selectedBranchId = child.branchId;
                      _isSidebarOpen = true;
                    });
                  },
                ),
              ],
            ],

            // Đệ quy nhánh cháu chắt nếu có
            if (child.children.isNotEmpty) ...[
              Container(width: 2, height: 20, color: kPrimaryColor),
              for (final grandChild in child.children)
                _buildChildBranchColumn(
                  context: context,
                  child: grandChild,
                  isWide: isWide,
                  currentMemberId: currentMemberId,
                  currentUserName: currentUserName,
                  activeBranchId: activeBranchId,
                  rootTree: rootTree,
                ),
            ],
          ],
        ],
      ),
    );
  }

  // 2. Branch Node Card (Chi 1, Chi 2, ...)
  Widget _buildBranchNodeCard({
    required BuildContext context,
    required BranchUiDetail detail,
    required bool isSelected,
    required bool isWide,
    required bool isCollapsed,
    required VoidCallback onSelect,
    required VoidCallback onToggleCollapse,
    required VoidCallback onShowPopover,
    required VoidCallback onTransfer,
    bool isCurrentUser = false,
    bool isHighlighted = false,
  }) {
    const kPrimaryColor = Color(0xFF8F482F);
    const kBorderColor = Color(0xFFDAC1BA);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFFCF6F3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFFFD700)
              : (isCurrentUser
                  ? const Color(0xFF006E2A)
                  : (isSelected ? kPrimaryColor : kBorderColor)),
          width: isHighlighted ? 3 : (isCurrentUser || isSelected ? 2 : 1),
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isHighlighted ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    detail.badge,
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Nút Collapse/Expand theo từng nhánh (US-29, Task #110)
                InkWell(
                  onTap: onToggleCollapse,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCollapsed ? const Color(0xFFE8DEF8) : const Color(0xFFF0EDEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCollapsed ? Icons.add_circle_outline : Icons.remove_circle_outline,
                          size: 13,
                          color: kPrimaryColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isCollapsed ? 'Mở nhánh' : 'Thu gọn',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Info
          InkWell(
            onTap: onSelect,
            onDoubleTap: onShowPopover,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF0EDEB),
                    child: const Icon(Icons.person, color: kPrimaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.representative,
                          style: const TextStyle(
                            fontFamily: 'Merriweather',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                        Text(
                          detail.name,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: Color(0xFF6B584E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Member stats & Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0EDEB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${detail.memberCount} thành viên',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF54433E)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 16, color: kPrimaryColor),
                      onPressed: onShowPopover,
                      tooltip: 'Xem tóm tắt (Popover)',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz, size: 17, color: kPrimaryColor),
                      onPressed: onTransfer,
                      tooltip: 'Điều chuyển nhánh',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // [US-11] Thống kê đóng góp đệ quy trên Nút Nhánh Chi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: BranchContributionPill(
              branchId: detail.id,
              branchName: detail.name,
              isRootBranch: false,
            ),
          ),

          // Footer Button
          InkWell(
            onTap: onSelect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0EDEB))),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Xem bảng chi tiết',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 14, color: kPrimaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Sub-Generation Cards
  Widget _buildSubGenerationCard({
    required String generation,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? const Color(0xFFFFF9E6)
              : (isSelected ? const Color(0xFFFCF6F3) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFFFD700)
                : (isSelected ? color : const Color(0xFFDAC1BA)),
            width: isHighlighted ? 2.5 : (isSelected ? 2 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isHighlighted ? 12 : 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                generation,
                style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B584E)),
                  ),
                ],
              ),
            ),
            if (isHighlighted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Tìm kiếm', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              )
            else if (isSelected)
              const Icon(Icons.check_circle, size: 16, color: Color(0xFF006E2A)),
          ],
        ),
      ),
    );
  }

}
