import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../../genealogy/presentation/providers/genealogy_providers.dart';
import '../../../genealogy/presentation/widgets/branch_detail_sidebar.dart';
import '../../../genealogy/data/models/branch_models.dart';
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
/// Nối 100% Full API Backend thực tế (GET /api/v1/branches/tree, GET /api/v1/branches/{id}/members)
/// Tuyệt đối không dùng dữ liệu cứng / seed data giả lập.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Trạng thái hiển thị mở rộng toàn bộ các đời phả hệ
  bool _isFullTreeExpanded = false;

  // ID của chi/nhánh đang được chọn
  String? _selectedBranchId;

  // Thành viên cụ thể đang được chọn (nếu click vào thẻ thành viên)
  BranchMemberItem? _selectedMember;

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
    const kSurfaceColor = Color(0xFFFFFFFF);
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
                currentUserName == tree.representativeName;
            selectedDetail = BranchUiDetail(
              id: tree.branchId,
              name: tree.branchName,
              badge: isRootCurrentUser ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC' : 'CỤ KHỞI TỔ • ĐỜI 1',
              code: tree.branchId,
              representative: tree.representativeName ?? 'Chưa cập nhật',
              representativeSubtext: 'Trưởng Tộc • Đại diện Dòng họ',
              representativeId: tree.representativeId,
              memberCount: tree.memberCount,
              activatedMemberCount: activeBranchMembers.where((m) => m.isActivated).isNotEmpty
                  ? activeBranchMembers.where((m) => m.isActivated).length
                  : tree.memberCount,
              fundAmount: '0 đ',
              description: rootBranchState.branch?.description ??
                  'Chi nhánh gốc khởi lập gia phả dòng họ, nơi quy tụ toàn thể con cháu.',
              successionChain: [tree.representativeName ?? 'Khởi Tổ'],
              members: activeBranchMembers,
              isRoot: true,
            );
          } else {
            // Nhánh phụ được chọn
            BranchTreeNodeDto? foundChild;
            for (final c in tree.children) {
              if (c.branchId == activeBranchId) {
                foundChild = c;
                break;
              }
            }
            final childNode = foundChild ?? (tree.children.isNotEmpty ? tree.children.first : tree);
            final isChildCurrentUser = currentMemberId == childNode.representativeId ||
                currentUserName == childNode.representativeName;

            selectedDetail = BranchUiDetail(
              id: childNode.branchId,
              name: childNode.branchName,
              badge: isChildCurrentUser
                  ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG CHI'
                  : 'Chi ${childNode.branchName} • Đời ${childNode.generationLevel}',
              code: childNode.branchId,
              representative: childNode.representativeName ?? 'Chưa cập nhật',
              representativeSubtext: 'Đại diện Chi • Đời ${childNode.generationLevel}',
              representativeId: childNode.representativeId,
              memberCount: childNode.memberCount,
              activatedMemberCount: activeBranchMembers.where((m) => m.isActivated).isNotEmpty
                  ? activeBranchMembers.where((m) => m.isActivated).length
                  : childNode.memberCount,
              fundAmount: '0 đ',
              description: 'Chi nhánh trực thuộc phả hệ dòng họ ${tree.clanName}.',
              successionChain: [tree.representativeName ?? 'Khởi Tổ', childNode.representativeName ?? 'Trưởng Chi'],
              members: activeBranchMembers,
              isRoot: false,
            );
          }

          // Kiểm tra xem người dùng hiện tại có phải là Trưởng tộc tại nhánh gốc không
          final isRootCurrentUser = isClanHead ||
              currentMemberId == tree.representativeId ||
              currentUserName == tree.representativeName;

          final rootUiDetail = BranchUiDetail(
            id: tree.branchId,
            name: tree.branchName,
            badge: isRootCurrentUser ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC' : 'CỤ KHỞI TỔ • ĐỜI 1',
            code: tree.branchId,
            representative: tree.representativeName ?? 'Chưa cập nhật',
            representativeSubtext: 'Trưởng Tộc • Đại diện Dòng họ',
            representativeId: tree.representativeId,
            memberCount: tree.memberCount,
            activatedMemberCount: tree.memberCount,
            fundAmount: '0 đ',
            description: rootBranchState.branch?.description ??
                'Chi nhánh gốc khởi lập gia phả dòng họ, nơi quy tụ toàn thể con cháu.',
            members: activeBranchId == tree.branchId ? activeBranchMembers : const [],
            isRoot: true,
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. VÙNG CANVAS CHÍNH HIỂN THỊ CÂY PHẢ HỆ
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          children: [
                            // Thanh công cụ: Thông tin xuất xứ + Nút Toggle [Thu gọn / Hiện đầy đủ]
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: kSurfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorderColor),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 8,
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
                                                  side: BorderSide(
                                                    color: isEnabled
                                                        ? const Color(0xFF8B1E1E)
                                                        : const Color(0xFF8B1E1E),
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
                            ),
                            const SizedBox(height: 12),

                            // [US-23] Demo Bar: Kiểm thử phân quyền phạm vi chi nhánh (Branch Scope Guard)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kBorderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.security, size: 18, color: kPrimaryColor),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'GIẢ LẬP VAI TRÒ (US-23):',
                                    style: TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          _buildPersonaChip(
                                            ref: ref,
                                            label: 'Trưởng Tộc (Toàn quyền)',
                                            personaKey: 'CLAN_HEAD',
                                            isSelected: session.isClanHead,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildPersonaChip(
                                            ref: ref,
                                            label: 'Trưởng Chi 2 (Chỉ quản lý Chi 2)',
                                            personaKey: 'BRANCH_HEAD_CHI_2',
                                            isSelected: session.isBranchHead && !session.isClanHead,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildPersonaChip(
                                            ref: ref,
                                            label: 'Thành Viên (Chỉ xem)',
                                            personaKey: 'MEMBER',
                                            isSelected: !session.isClanHead && !session.isBranchHead,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ROOT ANCESTOR NODE (Cụ Khởi Tổ • Đời 1 - Nhánh Gốc)
                            _buildRootAncestorCard(
                              context: context,
                              detail: rootUiDetail,
                              isSelected: activeBranchId == tree.branchId && _selectedMember == null,
                              isCurrentUser: isRootCurrentUser,
                              onTap: () => _handleSelectBranch(tree.branchId, selectedDetail, isWide),
                            ),

                            // Hiển thị các chi nhánh con
                            if (tree.children.isEmpty) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: kBorderColor.withValues(alpha: 0.6)),
                                ),
                                child: const Text(
                                  'Dòng họ hiện tại chưa có chi nhánh con. Bạn có thể thêm chi nhánh mới từ phân hệ quản lý.',
                                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: Color(0xFF6B584E)),
                                ),
                              ),
                            ] else if (tree.children.length == 1) ...[
                              // 1 Chi nhánh con trực thuộc
                              Container(
                                width: 2,
                                height: 28,
                                color: kPrimaryColor,
                              ),
                              _buildChildBranchColumn(
                                context: context,
                                child: tree.children.first,
                                isWide: isWide,
                                currentMemberId: currentMemberId,
                                currentUserName: currentUserName,
                                activeBranchId: activeBranchId,
                              ),
                            ] else ...[
                              // 2 Chi nhánh con trở lên (chạc chữ T phân nhánh)
                              SizedBox(
                                width: (tree.children.length * 354.0) / 2,
                                height: 36,
                                child: const CustomPaint(
                                  painter: TreeForkPainter(color: kPrimaryColor, strokeWidth: 2),
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (int i = 0; i < tree.children.length; i++) ...[
                                      if (i > 0) const SizedBox(width: 34),
                                      _buildChildBranchColumn(
                                        context: context,
                                        child: tree.children[i],
                                        isWide: isWide,
                                        currentMemberId: currentMemberId,
                                        currentUserName: currentUserName,
                                        activeBranchId: activeBranchId,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 36),

                            // Ghi chú chỉ dẫn phía dưới
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F3F1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kBorderColor.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lightbulb_outline, size: 18, color: kPrimaryColor),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Mẹo: Nhấp vào bất kỳ thẻ nào trên sơ đồ cây để xem toàn bộ danh sách thành viên thực tế, thông tin quản lý và phân cấp thế hệ từ hệ thống Backend.',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12,
                                        color: Color(0xFF54433E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. BẢNG SIDEBAR BÊN PHẢI (HIỂN THỊ TRÊN MÀN HÌNH RỘNG >= 900px)
              if (isWide)
                BranchDetailSidebar(
                  branch: selectedDetail,
                  onClose: () => setState(() {
                    _selectedMember = null;
                  }),
                  onEdit: selectedDetail.isRoot
                      ? () => context.push('/branches/root/edit')
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }

  /// Xây dựng cột phả hệ của một Chi Nhánh Con cùng các đời con cháu thực tế
  Widget _buildChildBranchColumn({
    required BuildContext context,
    required BranchTreeNodeDto child,
    required bool isWide,
    required String currentMemberId,
    required String currentUserName,
    required String activeBranchId,
  }) {
    const kPrimaryColor = Color(0xFF8F482F);
    final isChildCurrentUser = currentMemberId == child.representativeId ||
        currentUserName == child.representativeName;

    // Tải thành viên thực tế của chi nhánh từ API
    final childMembersAsync = ref.watch(branchMembersProvider(child.branchId));
    final childMembers = childMembersAsync.value ?? [];

    // Các thành viên đời dưới chi nhánh (không tính người đại diện chi đã hiện ở thẻ chi)
    final subMembers = childMembers.where((m) => m.memberId != child.representativeId).toList()
      ..sort((a, b) {
        final genCmp = a.generation.compareTo(b.generation);
        if (genCmp != 0) return genCmp;
        return a.fullName.compareTo(b.fullName);
      });

    final childUiDetail = BranchUiDetail(
      id: child.branchId,
      name: child.branchName,
      badge: isChildCurrentUser
          ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG CHI'
          : 'Chi ${child.branchName} • Đời ${child.generationLevel}',
      code: child.branchId,
      representative: child.representativeName ?? 'Chưa cập nhật',
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
            onSelect: () => _handleSelectBranch(child.branchId, childUiDetail, isWide),
          ),

          if (_isFullTreeExpanded) ...[
            if (subMembers.isEmpty) ...[
              Container(width: 2, height: 16, color: kPrimaryColor),
              Container(
                width: 320,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDAC1BA).withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'Chi nhánh chưa có thành viên đời tiếp theo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF6B584E),
                  ),
                ),
              ),
            ] else ...[
              for (final member in subMembers) ...[
                // Đường nối dọc
                Container(width: 2, height: 20, color: kPrimaryColor),

                // Thẻ thành viên đời kế tiếp từ Database
                _buildSubGenerationCard(
                  generation: 'ĐỜI ${member.generation}',
                  title: member.fullName,
                  subtitle: member.birthDeathInfo ?? (member.isActivated ? 'Đã xác thực hồ sơ' : 'Chờ xác thực'),
                  color: member.generation == 3
                      ? const Color(0xFF8F482F)
                      : (member.generation == 4 ? const Color(0xFFAD5F45) : const Color(0xFFC27B66)),
                  isSelected: _selectedMember?.memberId == member.memberId,
                  isCurrentUser: member.memberId == currentMemberId || member.fullName == currentUserName,
                  currentUserBadge: '★ VỊ TRÍ CỦA BẠN • ĐỜI ${member.generation}',
                  onTap: () => _handleSelectMember(child.branchId, member, isWide),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  void _handleSelectBranch(String branchId, BranchUiDetail detail, bool isWide) {
    setState(() {
      _selectedBranchId = branchId;
      _selectedMember = null;
    });

    if (!isWide) {
      _showMobileSheet(detail);
    }
  }

  void _handleSelectMember(String branchId, BranchMemberItem member, bool isWide) {
    setState(() {
      _selectedBranchId = branchId;
      _selectedMember = member;
    });

    if (!isWide) {
      final memberDetail = BranchUiDetail(
        id: member.memberId,
        name: 'Hồ Sơ: ${member.fullName}',
        badge: 'ĐỜI ${member.generation}',
        code: member.memberId,
        representative: member.fullName,
        representativeSubtext: member.birthDeathInfo ?? 'Thành viên Đời ${member.generation}',
        memberCount: 1,
        activatedMemberCount: member.isActivated ? 1 : 0,
        fundAmount: '0 đ',
        description: 'Hồ sơ thành viên chính thức thuộc phả hệ dòng họ.',
        members: [member],
        isRoot: false,
      );
      _showMobileSheet(memberDetail);
    }
  }

  void _showMobileSheet(BranchUiDetail detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BranchDetailSidebar(
            branch: detail,
            isMobileSheet: true,
            onClose: () => Navigator.of(ctx).pop(),
            onEdit: detail.isRoot
                ? () {
                    Navigator.of(ctx).pop();
                    context.push('/branches/root/edit');
                  }
                : null,
          ),
        ),
      ),
    );
  }

  // 1. Root Ancestor Node (Cụ Khởi Tổ)
  Widget _buildRootAncestorCard({
    required BuildContext context,
    required BranchUiDetail detail,
    required bool isSelected,
    required VoidCallback onTap,
    bool isCurrentUser = false,
  }) {
    const kPrimaryColor = Color(0xFF8F482F);
    const kDarkSurface = Color(0xFF31302F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: kDarkSurface,
          borderRadius: BorderRadius.circular(16),
          border: isCurrentUser
              ? Border.all(color: const Color(0xFF006E2A), width: 2)
              : (isSelected ? Border.all(color: const Color(0xFFFFB59D), width: 2) : null),
          boxShadow: [
            BoxShadow(
              color: isCurrentUser
                  ? const Color(0xFF006E2A).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: isSelected ? 0.25 : 0.12),
              blurRadius: isCurrentUser || isSelected ? 24 : 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? const Color(0xFF006E2A)
                              : kPrimaryColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCurrentUser ? Icons.stars : Icons.military_tech,
                              size: 14,
                              color: isCurrentUser ? Colors.white : const Color(0xFFFFB59D),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isCurrentUser
                                    ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC'
                                    : detail.badge,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentUser ? Colors.white : const Color(0xFFFFB59D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          if (isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF006E2A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '● Đang quản trị',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB59D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Đang xem',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF31302F),
                                ),
                              ),
                            ),
                          Text(
                            'MÃ: ${detail.code}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              color: Color(0xFFDAC1BA),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF54433E),
                          border: Border.all(
                            color: isCurrentUser ? const Color(0xFF006E2A) : const Color(0xFFFFB59D),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            detail.representative.isNotEmpty
                                ? detail.representative.replaceAll('Cụ ', '').replaceAll('Bác ', '')[0]
                                : 'H',
                            style: TextStyle(
                              fontFamily: 'Merriweather',
                              color: isCurrentUser ? Colors.white : const Color(0xFFFFB59D),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.representative,
                              style: const TextStyle(
                                fontFamily: 'Merriweather',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFCF9F6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              detail.name,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                color: Color(0xFFFFB59D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    detail.description,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12.5,
                      color: Color(0xFFE5E2E0),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  InkWell(
                    onTap: onTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.group, size: 15, color: Color(0xFFFFB59D)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${detail.memberCount} Thành viên (Xem chi tiết →)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFB59D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/branches/root/edit'),
                    icon: const Icon(Icons.edit_note, size: 18, color: Colors.white),
                    label: const Text(
                      'Chỉnh Sửa Nhánh Gốc',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Branch Node Card (Chi 1, Chi 2, ...)
  Widget _buildBranchNodeCard({
    required BuildContext context,
    required BranchUiDetail detail,
    required bool isSelected,
    required bool isWide,
    required VoidCallback onSelect,
    bool isCurrentUser = false,
  }) {
    const kPrimaryColor = Color(0xFF8F482F);
    const kBorderColor = Color(0xFFDAC1BA);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFFFCF6F3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentUser
                ? const Color(0xFF006E2A)
                : (isSelected ? kPrimaryColor : kBorderColor),
            width: isCurrentUser || isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrentUser
                  ? const Color(0xFF006E2A).withValues(alpha: 0.15)
                  : (isSelected ? kPrimaryColor.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04)),
              blurRadius: isCurrentUser || isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? const Color(0xFF006E2A)
                            : (isSelected
                                ? kPrimaryColor
                                : const Color(0xFF8F482F).withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        detail.badge,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: (isCurrentUser || isSelected) ? Colors.white : kPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006E2A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Đang xem',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      detail.code,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),

            // Representative & Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF0EDEB),
                    child: const Icon(Icons.person, color: kPrimaryColor, size: 22),
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                        Text(
                          detail.name,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            color: Color(0xFF6B584E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Info Box: Thành viên
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thành viên',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              color: Color(0xFF6B584E),
                            ),
                          ),
                          Text(
                            '${detail.memberCount} người',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trạng thái',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              color: Color(0xFF6B584E),
                            ),
                          ),
                          Text(
                            '${detail.activatedMemberCount} đã kích hoạt',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006E2A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

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
            Container(
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
          ],
        ),
      ),
    );
  }

  // 3. Sub-Generation Cards (Đời con cháu kế tiếp từ Database)
  Widget _buildSubGenerationCard({
    required String generation,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    bool isCurrentUser = false,
    String? currentUserBadge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFFFCF6F3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentUser
                ? const Color(0xFF006E2A)
                : (isSelected ? const Color(0xFF8F482F) : const Color(0xFFDAC1BA)),
            width: isCurrentUser || isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrentUser
                  ? const Color(0xFF006E2A).withValues(alpha: 0.15)
                  : (isSelected
                      ? const Color(0xFF8F482F).withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.03)),
              blurRadius: isCurrentUser || isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? const Color(0xFF006E2A).withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                generation,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? const Color(0xFF006E2A) : color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10.5,
                      color: Color(0xFF6B584E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006E2A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currentUserBadge ?? '★ VỊ TRÍ CỦA BẠN',
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF006E2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Đang xem',
                  style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            else
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8F482F)),
          ],
        ),
      ),
    );
  }

  /// [US-23] Widget Chip chuyển đổi Persona giả lập vai trò trên cây gia phả
  Widget _buildPersonaChip({
    required WidgetRef ref,
    required String label,
    required String personaKey,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(dualRbacSessionProvider.notifier).simulatePersona(personaKey);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.badge_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Đã chuyển vai trò giả lập sang: $label'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF8F482F),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8F482F) : const Color(0xFFF0EDEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF8F482F) : const Color(0xFFDAC1BA),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF54433E),
          ),
        ),
      ),
    );
  }
}
