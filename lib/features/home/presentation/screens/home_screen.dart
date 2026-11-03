import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../../genealogy/presentation/providers/genealogy_providers.dart';
import '../../../genealogy/presentation/widgets/branch_detail_sidebar.dart';
import '../../../genealogy/data/models/branch_models.dart';

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
/// Đã được hoàn thiện theo phản hồi chuyên sâu:
/// 1. Tách biệt cột con cháu Chi 1 và Chi 2 rõ ràng (Đời 3, Đời 4, Đời 5 nằm đúng trục dọc dưới từng chi).
/// 2. Bỏ hộp chuyển tuyến chuỗi gia phả ở đáy màn hình (không scale được khi mở rộng nhiều chi).
/// 3. Đồng bộ danh tính người dùng với tài khoản Lê Hữu Tuấn (Đời 5 • Chi 2).
/// 4. Click vào bất kỳ node nào (Khởi tổ, Chi 1, Chi 2, Đời 3, 4, 5) đều mở Sidebar chi tiết.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Trạng thái hiển thị mở rộng toàn bộ 5 đời phả hệ
  bool _isFullTreeExpanded = false;

  // Chi/nhánh hoặc nhân vật đang được chọn để hiển thị chi tiết ở Sidebar bên phải
  BranchUiDetail? _selectedBranch;
  bool _initialBranchInitialized = false;

  @override
  void initState() {
    super.initState();
    _selectedBranch = _getChi2Detail();
  }

  @override
  Widget build(BuildContext context) {
    final branchState = ref.watch(rootBranchProvider);
    final rootBranch = branchState.branch;

    final authState = ref.watch(authStateProvider);
    final session = ref.watch(dualRbacSessionProvider);

    final currentUserName = authState.user?.fullName.isNotEmpty == true
        ? authState.user!.fullName
        : (session.fullName.isNotEmpty ? session.fullName : 'Lê Hữu Tuấn');
    final isClanHead = authState.user?.roles.contains('ROLE_CLAN_HEAD') == true ||
        (session.globalRoles.contains(SystemRole.roleClanHead) && !session.fullName.contains('Tuấn'));
    final isBranchHead = authState.user?.roles.contains('ROLE_BRANCH_HEAD') == true ||
        session.globalRoles.contains(SystemRole.roleBranchHead);
    final currentMemberId = authState.user?.memberId ?? session.memberId;

    final isNguyenClan = currentUserName.startsWith('Nguyễn');

    // Xác định vị trí người dùng hiện tại trên cây phả hệ
    final isGen5TuanCurrentUser = (currentUserName == 'Lê Hữu Tuấn' || currentMemberId == 'MEM-208') && !isNguyenClan;
    final isRootCurrentUser = isClanHead && !isGen5TuanCurrentUser;
    final isChi1CurrentUser = (currentUserName == 'Nguyễn Văn An' || currentUserName == 'Lê Tuấn Anh' || currentMemberId == 'MEM_TRUONG_CHI');
    final isChi2CurrentUser = !isChi1CurrentUser && !isRootCurrentUser && !isGen5TuanCurrentUser && isBranchHead;

    const kPrimaryColor = Color(0xFF8F482F);
    const kBgColor = Color(0xFFFCF9F6);
    const kSurfaceColor = Color(0xFFFFFFFF);
    const kBorderColor = Color(0xFFDAC1BA);

    final isWide = MediaQuery.of(context).size.width >= 900;

    // Dữ liệu chi tiết các nhánh & nhân vật theo Dòng Họ của tài khoản đăng nhập
    final BranchUiDetail rootDetail;
    final BranchUiDetail chi1Detail;
    final BranchUiDetail chi2Detail;
    final BranchUiDetail gen3TuanAnhDetail;
    final BranchUiDetail gen4KhoiDetail;
    final BranchUiDetail gen5LongDetail;
    final BranchUiDetail gen3HungDetail;
    final BranchUiDetail gen4NamDetail;
    final BranchUiDetail gen5TuanDetail;

    if (isNguyenClan) {
      rootDetail = _getNguyenRootDetail(isClanHead: isRootCurrentUser);
      chi1Detail = _getNguyenChi1Detail(isCurrentUser: isChi1CurrentUser);
      chi2Detail = _getNguyenChi2Detail(isCurrentUser: isChi2CurrentUser);
      gen3TuanAnhDetail = _getNguyenGen3MaiAnhDetail(isCurrentUser: currentUserName == 'Nguyễn Thị Mai Anh');
      gen4KhoiDetail = _getNguyenGen4LongDetail();
      gen5LongDetail = _getNguyenGen5Detail();
      gen3HungDetail = _getNguyenGen3NamDetail();
      gen4NamDetail = _getNguyenGen4DatDetail();
      gen5TuanDetail = _getNguyenGen5TuanDetail();
    } else {
      rootDetail = _getRootDetail(rootBranch?.branchName, rootBranch?.description, isCurrentUser: isRootCurrentUser);
      chi1Detail = _getChi1Detail(isCurrentUser: isChi1CurrentUser);
      chi2Detail = _getChi2Detail(isCurrentUser: isChi2CurrentUser);
      gen3TuanAnhDetail = _getGen3TuanAnhDetail();
      gen4KhoiDetail = _getGen4KhoiDetail();
      gen5LongDetail = _getGen5LongDetail();
      gen3HungDetail = _getGen3HungDetail();
      gen4NamDetail = _getGen4NamDetail();
      gen5TuanDetail = _getGen5TuanDetail(isCurrentUser: isGen5TuanCurrentUser);
    }

    if (!_initialBranchInitialized) {
      _initialBranchInitialized = true;
      if (isRootCurrentUser) {
        _selectedBranch = rootDetail;
      } else if (isChi1CurrentUser) {
        _selectedBranch = chi1Detail;
      }
    }

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: const HeritageNavBar(currentRoute: '/home'),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/home'),
      body: Row(
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
                            border: Border.all(color: kBorderColor.withValues(alpha: 0.6)),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lan_outlined, size: 18, color: kPrimaryColor),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isNguyenClan
                                          ? 'Dòng Họ Nguyễn Việt Nam • Chi Gốc'
                                          : (rootBranch?.clanName.isNotEmpty == true
                                              ? '${rootBranch!.clanName} • Cụ Khởi Tổ 1890'
                                              : 'Họ Lê - Nam Trung, Thái Bình • Cụ Khởi Tổ 1890'),
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1C1C1A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
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
                                      _isFullTreeExpanded ? 'Thu Gọn Sơ Đồ' : 'Hiện Đầy Đủ Cây (5 Đời)',
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
                                  // Badge trạng thái
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF99F8A2).withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      '● Trực tuyến 4 chi',
                                      style: TextStyle(
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
                        const SizedBox(height: 28),

                        // ROOT ANCESTOR NODE (Cụ Khởi Tổ • Đời 1 - Nhánh Gốc)
                        _buildRootAncestorCard(
                          context: context,
                          detail: rootDetail,
                          isSelected: _selectedBranch?.id == rootDetail.id,
                          isCurrentUser: isRootCurrentUser,
                          onTap: () => _handleSelectBranch(rootDetail, isWide),
                        ),

                        // Đường nối dọc từ Khởi Tổ xuống chạc phân nhánh
                        Container(
                          width: 2,
                          height: 24,
                          color: kPrimaryColor,
                        ),

                        // KHUNG PHÂN NHÁNH 2 CỘT (CHI 1 & CHI 2) CÓ KHẢ NĂNG CUỘN NGANG KHI MÀN HÌNH HẸP
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Chạc nối hình chữ T nối giữa tâm Cột Chi 1 (160px) và tâm Cột Chi 2 (514px)
                              const SizedBox(
                                width: 354,
                                height: 36,
                                child: CustomPaint(
                                  painter: TreeForkPainter(color: kPrimaryColor, strokeWidth: 2),
                                ),
                              ),

                              // Hàng chứa 2 CỘT PHẢ HỆ ĐỨNG SONG SONG (Chi 1 bên trái, Chi 2 bên phải)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ==================== CỘT 1: CHI 1 (TRƯỞNG PHÁI) ====================
                                  SizedBox(
                                    width: 320,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildBranchNodeCard(
                                          context: context,
                                          detail: chi1Detail,
                                          isSelected: _selectedBranch?.id == chi1Detail.id,
                                          isWide: isWide,
                                          isCurrentUser: isChi1CurrentUser,
                                          onSelect: () => _handleSelectBranch(chi1Detail, isWide),
                                        ),

                                        if (_isFullTreeExpanded) ...[
                                          // Đường nối dọc
                                          Container(width: 2, height: 24, color: kPrimaryColor),

                                          // Đời 3: Bác Lê Tuấn Anh / Nguyễn Thị Mai Anh
                                          _buildSubGenerationCard(
                                            generation: 'ĐỜI 3',
                                            title: isNguyenClan ? 'Nguyễn Thị Mai Anh' : 'Bác Lê Tuấn Anh',
                                            subtitle: gen3TuanAnhDetail.representativeSubtext,
                                            color: const Color(0xFF8F482F),
                                            isSelected: _selectedBranch?.id == gen3TuanAnhDetail.id,
                                            isCurrentUser: isNguyenClan ? (currentUserName == 'Nguyễn Thị Mai Anh') : false,
                                            currentUserBadge: '★ VỊ TRÍ CỦA BẠN • ĐỜI 3',
                                            onTap: () => _handleSelectBranch(gen3TuanAnhDetail, isWide),
                                          ),

                                          // Đường nối dọc
                                          Container(width: 2, height: 24, color: kPrimaryColor),

                                          // Đời 4: Chú Lê Đình Khôi / Nguyễn Hoàng Long
                                          _buildSubGenerationCard(
                                            generation: 'ĐỜI 4',
                                            title: isNguyenClan ? 'Nguyễn Hoàng Long' : 'Chú Lê Đình Khôi',
                                            subtitle: gen4KhoiDetail.representativeSubtext,
                                            color: const Color(0xFFAD5F45),
                                            isSelected: _selectedBranch?.id == gen4KhoiDetail.id,
                                            onTap: () => _handleSelectBranch(gen4KhoiDetail, isWide),
                                          ),

                                          // Đường nối dọc
                                          Container(width: 2, height: 24, color: kPrimaryColor),

                                          // Đời 5: Lê Hoàng Long / Nguyễn Minh Triết
                                          _buildSubGenerationCard(
                                            generation: 'ĐỜI 5',
                                            title: isNguyenClan ? 'Nguyễn Minh Triết' : 'Lê Hoàng Long',
                                            subtitle: gen5LongDetail.representativeSubtext,
                                            color: const Color(0xFFC27B66),
                                            isSelected: _selectedBranch?.id == gen5LongDetail.id,
                                            onTap: () => _handleSelectBranch(gen5LongDetail, isWide),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 34),

                                  // ==================== CỘT 2: CHI 2 (THỨ PHÁI) ====================
                                  SizedBox(
                                    width: 320,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildBranchNodeCard(
                                          context: context,
                                          detail: chi2Detail,
                                          isSelected: _selectedBranch?.id == chi2Detail.id,
                                          isWide: isWide,
                                          isCurrentUser: isChi2CurrentUser,
                                          onSelect: () => _handleSelectBranch(chi2Detail, isWide),
                                        ),

                                        if (_isFullTreeExpanded) ...[
                                          // Đường nối dọc
                                          Container(width: 2, height: 24, color: kPrimaryColor),

                                          // Đời 3: Bác Lê Văn Hùng / Bác Nguyễn Hữu Nam
                                          _buildSubGenerationCard(
                                            generation: 'ĐỜI 3',
                                            title: isNguyenClan ? 'Bác Nguyễn Hữu Nam' : 'Bác Lê Văn Hùng',
                                            subtitle: gen3HungDetail.representativeSubtext,
                                            color: const Color(0xFF8F482F),
                                            isSelected: _selectedBranch?.id == gen3HungDetail.id,
                                            onTap: () => _handleSelectBranch(gen3HungDetail, isWide),
                                          ),

                                          // Đường nối dọc
                                          Container(width: 2, height: 24, color: kPrimaryColor),

                                          // Đời 4: Chú Lê Hữu Nam / Chú Nguyễn Hữu Đạt
                                          _buildSubGenerationCard(
                                            generation: 'ĐỜI 4',
                                            title: isNguyenClan ? 'Chú Nguyễn Hữu Đạt' : 'Chú Lê Hữu Nam',
                                            subtitle: gen4NamDetail.representativeSubtext,
                                            color: const Color(0xFFAD5F45),
                                            isSelected: _selectedBranch?.id == gen4NamDetail.id,
                                            onTap: () => _handleSelectBranch(gen4NamDetail, isWide),
                                          ),

                                          // Đường nối dọc
                                          Container(width: 2, height: 24, color: kPrimaryColor),

                                          // Đời 5: Lê Hữu Tuấn (VỊ TRÍ TÀI KHOẢN CỦA BẠN TRONG DÒNG HỌ)
                                          if (isGen5TuanCurrentUser) ...[
                                            _buildCurrentUserGen5Card(
                                              detail: gen5TuanDetail,
                                              isSelected: _selectedBranch?.id == gen5TuanDetail.id,
                                              onTap: () => _handleSelectBranch(gen5TuanDetail, isWide),
                                            ),
                                          ] else ...[
                                            _buildSubGenerationCard(
                                              generation: 'ĐỜI 5',
                                              title: isNguyenClan ? 'Nguyễn Hữu Tuấn' : 'Lê Hữu Tuấn',
                                              subtitle: gen5TuanDetail.representativeSubtext,
                                              color: const Color(0xFFC27B66),
                                              isSelected: _selectedBranch?.id == gen5TuanDetail.id,
                                              onTap: () => _handleSelectBranch(gen5TuanDetail, isWide),
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

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
                                  'Mẹo: Nhấp vào bất kỳ thẻ nào trên sơ đồ cây để xem toàn bộ danh sách thành viên, quỹ chi và chuỗi kế thừa trực hệ trên bảng chi tiết sidebar.',
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
          if (isWide && _selectedBranch != null)
            BranchDetailSidebar(
              branch: _selectedBranch!,
              onClose: () => setState(() => _selectedBranch = null),
              onEdit: _selectedBranch!.isRoot
                  ? () => context.push('/branches/root/edit')
                  : null,
            ),
        ],
      ),
    );
  }

  void _handleSelectBranch(BranchUiDetail detail, bool isWide) {
    setState(() {
      _selectedBranch = detail;
    });

    // Nếu là màn hình hẹp (Mobile), mở dưới dạng Bottom Sheet
    if (!isWide) {
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
                            Text(
                              isCurrentUser
                                  ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC'
                                  : detail.badge,
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser ? Colors.white : const Color(0xFFFFB59D),
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
                        Text(
                          '${detail.memberCount} Thành viên (Xem chi tiết →)',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFB59D),
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

  // 2. Branch Node Card (Chi 1, Chi 2)
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
            const SizedBox(height: 12),

            // Metrics Row: Bấm vào số thành viên sẽ mở Sidebar / Sheet
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thành viên',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF6B584E)),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${detail.memberCount}',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1C1C1A),
                                ),
                              ),
                              const Text(' người', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 28, color: const Color(0xFFDAC1BA)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quỹ chi',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF6B584E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            detail.fundAmount,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 13,
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
            const SizedBox(height: 12),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEFECE8))),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Xem bảng chi tiết',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  // 3. Sub-Generation Cards (Đời 3, Đời 4, Đời 5 con cháu)
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

  // 4. Current User Gen 5 Card (Highlight vị trí tài khoản của bạn tại Đời 5 Chi 2)
  Widget _buildCurrentUserGen5Card({
    required BranchUiDetail detail,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const kPrimaryColor = Color(0xFF8F482F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF6F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF006E2A) : kPrimaryColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: isSelected ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top badge row (Responsive Wrap)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pin_drop, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'VỊ TRÍ CỦA BẠN • ĐỜI 5',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006E2A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '● Đã kích hoạt',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006E2A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Person info
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: kPrimaryColor.withValues(alpha: 0.15),
                  child: const Text(
                    'T',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                      fontSize: 14,
                    ),
                  ),
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
                      const SizedBox(height: 1),
                      const Text(
                        'Sinh 1998 • Chi 2 (Nhánh Nam)',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: Color(0xFF6B584E),
                        ),
                      ),
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
                  const Icon(Icons.chevron_right, size: 18, color: kPrimaryColor),
              ],
            ),
            const SizedBox(height: 8),

            // Mã hồ sơ & nút xem chi tiết
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFDAC1BA).withValues(alpha: 0.5)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    'Mã: ${detail.code}',
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10,
                      color: Color(0xFF6B584E),
                    ),
                  ),
                  const Text(
                    'Xem hồ sơ →',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
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

  // --- MOCK / HELPER DATA CHO CÁC CHI NHÁNH & NHÂN VẬT ---
  BranchUiDetail _getRootDetail(String? name, String? desc, {bool isCurrentUser = false}) {
    return BranchUiDetail(
      id: 'BR_ROOT',
      name: name?.isNotEmpty == true ? name! : 'Chi Gốc Nam Trung, Thái Bình',
      badge: isCurrentUser ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC' : 'CỤ KHỞI TỔ • ĐỜI 1',
      code: 'BR_ROOT_TB',
      representative: 'Cụ Lê Phúc Khang (1890 – 1968)',
      representativeSubtext: 'Thủy Tổ Đại Tôn Khởi Phái',
      memberCount: 42,
      activatedMemberCount: 38,
      fundAmount: '127.650.000 đ',
      description: desc?.isNotEmpty == true
          ? desc!
          : 'Nhánh Thủy tổ khởi lập từ cụ Lê Phúc Khang năm 1890 tại làng Nam Trung. Cội nguồn phát tích toàn bộ con cháu các chi phái hiện nay.',
      successionChain: const [
        'Cụ Lê Phúc Khang (Thủy tổ 1890)',
        'Chi 1: Cụ Lê Văn An (1918)',
        'Chi 2: Cụ Lê Văn Bình (1922)',
      ],
      isRoot: true,
      members: _generateRoot42Members(),
    );
  }

  BranchUiDetail _getChi1Detail({bool isCurrentUser = false}) {
    return BranchUiDetail(
      id: 'CHI_01',
      name: 'Chi 1 - Trưởng Chi An',
      badge: isCurrentUser ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG CHI' : 'Chi 1 (Trưởng Phái) • Đời 2',
      code: 'CHI-01',
      representative: 'Cụ Lê Văn An (1918 – 1995)',
      representativeSubtext: 'Cụ Cả Trưởng Tộc • Phái Chi Bắc Bộ',
      memberCount: 18,
      activatedMemberCount: 14,
      fundAmount: '42.000.000 đ',
      description: 'Nhánh Trưởng Nam tiếp quản nhà thờ tổ làng Nam Trung, phụ trách nghi lễ cúng giỗ truyền thống dòng họ.',
      successionChain: const [
        'Cụ Lê Phúc Khang (Khởi tổ 1890)',
        'Cụ Lê Văn An (Đời 2)',
        'Bác Lê Tuấn Anh (Đời 3)',
        'Chú Lê Đình Khôi (Đời 4)',
        'Lê Hoàng Long (Đời 5)',
      ],
      members: _generateChi118Members(),
    );
  }

  BranchUiDetail _getGen3TuanAnhDetail() {
    return const BranchUiDetail(
      id: 'GEN3_TUAN_ANH',
      name: 'Nhánh Bác Lê Tuấn Anh',
      badge: 'Đời 3 • Trưởng Chi 1',
      code: 'LE-CHI1-DOI3-ANH',
      representative: 'Bác Lê Tuấn Anh',
      representativeSubtext: 'Sinh 1950 • Trưởng Nam Cụ An',
      memberCount: 10,
      activatedMemberCount: 8,
      fundAmount: '26.000.000 đ',
      description: 'Bác Lê Tuấn Anh tiếp quản phụng dưỡng từ đường Chi Trưởng tại làng Nam Trung, phụ trách các nghi thức đại lễ giỗ tổ hàng năm của dòng họ.',
      successionChain: [
        'Cụ Lê Phúc Khang (Khởi tổ 1890)',
        'Cụ Lê Văn An (Đời 2)',
        'Bác Lê Tuấn Anh (Đời 3)',
        'Chú Lê Đình Khôi (Đời 4)',
        'Lê Hoàng Long (Đời 5)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-102', fullName: 'Lê Tuấn Anh', generation: 3, birthDeathInfo: 'Sinh 1950', roleInBranch: 'Trưởng Nam Chi 1', isActivated: true),
        BranchMemberItem(memberId: 'MEM-102B', fullName: 'Đỗ Thị Nga', generation: 3, birthDeathInfo: 'Sinh 1952', roleInBranch: 'Dâu Chi 1', gender: 'female', isActivated: true),
        BranchMemberItem(memberId: 'MEM-104', fullName: 'Lê Đình Khôi', generation: 4, birthDeathInfo: 'Sinh 1976', roleInBranch: 'Trưởng nam Bác Tuấn Anh', isActivated: true),
        BranchMemberItem(memberId: 'MEM-104B', fullName: 'Nguyễn Thùy Chi', generation: 4, birthDeathInfo: 'Sinh 1978', roleInBranch: 'Dâu Đời 4', gender: 'female', isActivated: true),
        BranchMemberItem(memberId: 'MEM-105', fullName: 'Lê Đình Bảo', generation: 4, birthDeathInfo: 'Sinh 1982', roleInBranch: 'Thứ nam Bác Tuấn Anh', isActivated: true),
        BranchMemberItem(memberId: 'MEM-108', fullName: 'Lê Hoàng Long', generation: 5, birthDeathInfo: 'Sinh 2002', roleInBranch: 'Trưởng nam Đời 5 Chi 1', isActivated: false),
        BranchMemberItem(memberId: 'MEM-109', fullName: 'Lê Thảo My', generation: 5, birthDeathInfo: 'Sinh 2005', roleInBranch: 'Con gái Chú Khôi', gender: 'female', isActivated: true),
        BranchMemberItem(memberId: 'MEM-110', fullName: 'Lê Minh Triết', generation: 5, birthDeathInfo: 'Sinh 2008', roleInBranch: 'Con trai Chú Bảo', isActivated: true),
      ],
    );
  }

  BranchUiDetail _getGen4KhoiDetail() {
    return const BranchUiDetail(
      id: 'GEN4_KHOI',
      name: 'Gia Đình Chú Lê Đình Khôi',
      badge: 'Đời 4 • Ban Quản Lý',
      code: 'LE-CHI1-DOI4-KHOI',
      representative: 'Chú Lê Đình Khôi',
      representativeSubtext: 'Sinh 1976 • Trưởng Nam Bác Tuấn Anh',
      memberCount: 4,
      activatedMemberCount: 4,
      fundAmount: '16.000.000 đ',
      description: 'Chú Lê Đình Khôi sinh năm 1976, phụ trách ban quản lý từ đường và tổ chức các hoạt động thiện nguyện, khuyến học trong Chi Trưởng.',
      successionChain: [
        'Cụ Lê Phúc Khang (Khởi tổ 1890)',
        'Cụ Lê Văn An (Đời 2)',
        'Bác Lê Tuấn Anh (Đời 3)',
        'Chú Lê Đình Khôi (Đời 4)',
        'Lê Hoàng Long (Đời 5)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-104', fullName: 'Lê Đình Khôi', generation: 4, birthDeathInfo: 'Sinh 1976', roleInBranch: 'Chủ hộ • Đời 4', isActivated: true),
        BranchMemberItem(memberId: 'MEM-104B', fullName: 'Nguyễn Thùy Chi', generation: 4, birthDeathInfo: 'Sinh 1978', roleInBranch: 'Vợ (Dâu họ)', gender: 'female', isActivated: true),
        BranchMemberItem(memberId: 'MEM-108', fullName: 'Lê Hoàng Long', generation: 5, birthDeathInfo: 'Sinh 2002', roleInBranch: 'Con trai trưởng', isActivated: false),
        BranchMemberItem(memberId: 'MEM-109', fullName: 'Lê Thảo My', generation: 5, birthDeathInfo: 'Sinh 2005', roleInBranch: 'Con gái', gender: 'female', isActivated: true),
      ],
    );
  }

  BranchUiDetail _getGen5LongDetail() {
    return const BranchUiDetail(
      id: 'GEN5_LONG',
      name: 'Hồ Sơ: Lê Hoàng Long',
      badge: 'Đời 5 • Chi Trưởng',
      code: 'LE-CHI1-DOI5-0312',
      representative: 'Lê Hoàng Long',
      representativeSubtext: 'Sinh 2002 • Kế thừa Chi 1',
      memberCount: 1,
      activatedMemberCount: 1,
      fundAmount: '2.500.000 đ',
      description: 'Lê Hoàng Long sinh năm 2002, con cháu thế hệ thứ 5 thuộc Chi Trưởng (Cụ Lê Văn An), nhiệt tình tham gia số hóa phả hệ họ tộc.',
      successionChain: [
        'Cụ Lê Phúc Khang (Khởi tổ 1890)',
        'Cụ Lê Văn An (Đời 2)',
        'Bác Lê Tuấn Anh (Đời 3)',
        'Chú Lê Đình Khôi (Đời 4)',
        'Lê Hoàng Long (Đời 5)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-108', fullName: 'Lê Hoàng Long', generation: 5, birthDeathInfo: 'Sinh 2002 (24 tuổi)', roleInBranch: 'Con cháu Đời 5 Chi Trưởng', isActivated: true),
      ],
    );
  }

  BranchUiDetail _getChi2Detail({bool isCurrentUser = false}) {
    return BranchUiDetail(
      id: 'CHI_02',
      name: 'Chi 2 - Nhánh Nam',
      badge: isCurrentUser ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG CHI' : 'Chi 2 (Thứ Phái) • Đời 2',
      code: 'CHI-02-ROOT',
      representative: 'Cụ Lê Văn Bình (1922 – 2004)',
      representativeSubtext: 'Phái Chi Nam Bộ & Bắc Bộ',
      memberCount: 24,
      activatedMemberCount: 19,
      fundAmount: '85.650.000 đ',
      description: 'Nhánh Thứ Phái phát triển mạnh mẽ về kinh tế và giáo dục, phụ trách quỹ khuyến học và quỹ công đức xây dựng.',
      successionChain: const [
        'Cụ Lê Phúc Khang (Khởi tổ 1890)',
        'Cụ Lê Văn Bình (Đời 2)',
        'Bác Lê Văn Hùng (Trưởng Chi 2 • Đời 3)',
        'Chú Lê Hữu Nam (Đời 4)',
        'Lê Hữu Tuấn (Đời 5 - Vị trí của bạn)',
      ],
      members: _generateChi224Members(),
    );
  }

  BranchUiDetail _getGen3HungDetail() {
    return const BranchUiDetail(
      id: 'GEN3_HUNG',
      name: 'Nhánh Bác Lê Văn Hùng',
      badge: 'Đời 3 • Trưởng Chi 2',
      code: 'LE-CHI2-DOI3-HUNG',
      representative: 'Bác Lê Văn Hùng (1954 – 2021)',
      representativeSubtext: 'Trưởng Chi 2 • Trưởng Nam Cụ Bình',
      memberCount: 14,
      activatedMemberCount: 12,
      fundAmount: '56.200.000 đ',
      description: 'Bác Lê Văn Hùng là Trưởng Nam của Cụ Bình, phụ trách phát triển và kết nối dòng họ Chi 2, duy trì ngày cúng giỗ truyền thống.',
      successionChain: [
        'Cụ Lê Phúc Khang (Khởi tổ 1890)',
        'Cụ Lê Văn Bình (Đời 2)',
        'Bác Lê Văn Hùng (Đời 3)',
        'Chú Lê Hữu Nam (Đời 4)',
        'Lê Hữu Tuấn (Đời 5)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-202', fullName: 'Lê Văn Hùng', generation: 3, birthDeathInfo: '1954 – 2021', roleInBranch: 'Trưởng Chi 2', isActivated: true),
        BranchMemberItem(memberId: 'MEM-203', fullName: 'Nguyễn Thị Huệ', generation: 3, birthDeathInfo: 'Sinh 1956', roleInBranch: 'Dâu Chi 2', gender: 'female', isActivated: true),
        BranchMemberItem(memberId: 'MEM-204', fullName: 'Lê Hữu Nam', generation: 4, birthDeathInfo: 'Sinh 1980', roleInBranch: 'Trưởng nam Bác Hùng', isActivated: true),
        BranchMemberItem(memberId: 'MEM-205', fullName: 'Vũ Thị Thanh Hà', generation: 4, birthDeathInfo: 'Sinh 1982', roleInBranch: 'Dâu Đời 4', gender: 'female', isActivated: true),
        BranchMemberItem(memberId: 'MEM-206', fullName: 'Lê Hữu Phong', generation: 4, birthDeathInfo: 'Sinh 1984', roleInBranch: 'Thứ nam Bác Hùng', isActivated: true),
        BranchMemberItem(memberId: 'MEM-207', fullName: 'Lê Thị Bích Ngọc', generation: 4, birthDeathInfo: 'Sinh 1986', roleInBranch: 'Con gái Bác Hùng', gender: 'female', isActivated: true),
        BranchMemberItem(memberId: 'MEM-208', fullName: 'Lê Hữu Tuấn', generation: 5, birthDeathInfo: 'Sinh 1998', roleInBranch: 'Cháu đích tôn Đời 5', isActivated: true),
        BranchMemberItem(memberId: 'MEM-209', fullName: 'Lê Hữu Đạt', generation: 5, birthDeathInfo: 'Sinh 2005', roleInBranch: 'Con trai Chú Nam', isActivated: false),
        BranchMemberItem(memberId: 'MEM-210', fullName: 'Lê Thị Diệu Linh', generation: 5, birthDeathInfo: 'Sinh 2008', roleInBranch: 'Con gái Chú Nam', gender: 'female', isActivated: true),
        BranchMemberItem(memberId: 'MEM-211', fullName: 'Lê Hữu Hoàng', generation: 5, birthDeathInfo: 'Sinh 2012', roleInBranch: 'Con trai Chú Phong', isActivated: false),
        BranchMemberItem(memberId: 'MEM-212', fullName: 'Lê Bảo Châu', generation: 5, birthDeathInfo: 'Sinh 2015', roleInBranch: 'Con gái Chú Phong', gender: 'female', isActivated: false),
      ],
    );
  }

  BranchUiDetail _getGen4NamDetail() {
    return const BranchUiDetail(
      id: 'GEN4_NAM',
      name: 'Gia Đình Chú Lê Hữu Nam',
      badge: 'Đời 4 • Ban Liên Lạc',
      code: 'LE-CHI2-DOI4-NAM',
      representative: 'Chú Lê Hữu Nam',
      representativeSubtext: 'Sinh 1980 • Trưởng Nam Bác Hùng',
      memberCount: 5,
      activatedMemberCount: 4,
      fundAmount: '28.450.000 đ',
      description: 'Chú Lê Hữu Nam sinh năm 1980, phụ trách Ban Liên Lạc Dòng Họ Chi 2, kết nối các thế hệ con cháu thanh niên và số hóa phả hệ.',
      successionChain: [
        'Cụ Lê Phúc Khang (Khởi tổ 1890)',
        'Cụ Lê Văn Bình (Đời 2)',
        'Bác Lê Văn Hùng (Đời 3)',
        'Chú Lê Hữu Nam (Đời 4)',
        'Lê Hữu Tuấn (Đời 5)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-204', fullName: 'Lê Hữu Nam', generation: 4, birthDeathInfo: 'Sinh 1980', roleInBranch: 'Chủ hộ • Đời 4', isActivated: true),
        BranchMemberItem(memberId: 'MEM-205', fullName: 'Vũ Thị Thanh Hà', generation: 4, birthDeathInfo: 'Sinh 1982', roleInBranch: 'Vợ (Dâu họ)', gender: 'female', isActivated: true),
        BranchMemberItem(memberId: 'MEM-208', fullName: 'Lê Hữu Tuấn', generation: 5, birthDeathInfo: 'Sinh 1998', roleInBranch: 'Trưởng nam Đời 5', isActivated: true),
        BranchMemberItem(memberId: 'MEM-209', fullName: 'Lê Hữu Đạt', generation: 5, birthDeathInfo: 'Sinh 2005', roleInBranch: 'Thứ nam Đời 5', isActivated: false),
        BranchMemberItem(memberId: 'MEM-210', fullName: 'Lê Thị Diệu Linh', generation: 5, birthDeathInfo: 'Sinh 2008', roleInBranch: 'Con gái út', gender: 'female', isActivated: true),
      ],
    );
  }

  BranchUiDetail _getGen5TuanDetail({bool isCurrentUser = true}) {
    return BranchUiDetail(
      id: 'GEN5_TUAN',
      name: isCurrentUser ? 'Hồ Sơ: Lê Hữu Tuấn' : 'Hồ Sơ Thành Viên: Lê Hữu Tuấn',
      badge: isCurrentUser ? 'Đời 5 • Tài Khoản Của Bạn' : 'Đời 5 • Chi 2',
      code: 'LE-CHI2-DOI5-9821',
      representative: 'Lê Hữu Tuấn',
      representativeSubtext: isCurrentUser ? 'Sinh 1998 • Vị trí đăng nhập hiện tại' : 'Sinh 1998 • Con cháu Đời 5',
      memberCount: 1,
      activatedMemberCount: 1,
      fundAmount: '5.000.000 đ',
      description: isCurrentUser
          ? 'Lê Hữu Tuấn sinh năm 1998, vị trí tài khoản đăng nhập hiện tại trong dòng họ. Thuộc nhánh Chi 2 của Cụ Lê Văn Bình.'
          : 'Lê Hữu Tuấn sinh năm 1998, con cháu thế hệ thứ 5 thuộc Chi 2 của Cụ Lê Văn Bình.',
      successionChain: [
        'Cụ Lê Phúc Khang (Khởi tổ 1890)',
        'Cụ Lê Văn Bình (Đời 2)',
        'Bác Lê Văn Hùng (Đời 3)',
        'Chú Lê Hữu Nam (Đời 4)',
        isCurrentUser ? 'Lê Hữu Tuấn (Đời 5 - Tài khoản của bạn)' : 'Lê Hữu Tuấn (Đời 5)',
      ],
      members: [
        BranchMemberItem(
          memberId: 'MEM-208',
          fullName: 'Lê Hữu Tuấn',
          generation: 5,
          birthDeathInfo: 'Sinh 1998 (28 tuổi)',
          roleInBranch: isCurrentUser ? 'Tài khoản chính • Đã xác thực' : 'Thành viên Đời 5',
          isActivated: true,
        ),
      ],
    );
  }

  // --- DỮ LIỆU CÂY PHẢ HỆ CHO DÒNG HỌ NGUYỄN (TÀI KHOẢN MẪU TỪ BACKEND DATABASE) ---
  BranchUiDetail _getNguyenRootDetail({required bool isClanHead}) {
    return BranchUiDetail(
      id: 'BR_ROOT',
      name: 'Chi Gốc (Đại Tôn) • Nam Trung, Thái Bình',
      badge: isClanHead ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC' : 'CỤ KHỞI TỔ • TRƯỞNG TỘC',
      code: 'BR_ROOT_TB',
      representative: 'Nguyễn Trọng Hoàng',
      representativeSubtext: 'Trưởng Tộc Đương Nhiệm • Chi Gốc',
      memberCount: 36,
      activatedMemberCount: 32,
      fundAmount: '115.000.000 đ',
      description: 'Nhánh Thủy tổ khởi lập từ cụ Nguyễn Tiên Tổ tại làng Nam Trung. Toàn quyền quản trị sổ cái, bảo vật và kết nối các chi nhánh dòng họ.',
      successionChain: const [
        'Nguyễn Tiên Tổ (Thủy tổ)',
        'Chi 1: Nguyễn Văn An (1978)',
        'Chi 2: Nguyễn Văn Hùng (1982)',
      ],
      isRoot: true,
      members: _generateNguyenRootMembers(),
    );
  }

  BranchUiDetail _getNguyenChi1Detail({bool isCurrentUser = false}) {
    return BranchUiDetail(
      id: 'CHI_01',
      name: 'Chi 1 - Trưởng Chi An',
      badge: isCurrentUser ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG CHI' : 'Chi 1 (Trưởng Phái) • Đời 2',
      code: 'CHI-01',
      representative: 'Nguyễn Văn An (Sinh 1978)',
      representativeSubtext: 'Trưởng Chi 1 • Nhánh Giáp',
      memberCount: 16,
      activatedMemberCount: 14,
      fundAmount: '45.000.000 đ',
      description: 'Nhánh Trưởng Nam tiếp quản nhà thờ tổ làng Nam Trung, phụ trách các nghi thức đại lễ giỗ tổ hàng năm của dòng họ.',
      successionChain: const [
        'Nguyễn Tiên Tổ (Khởi tổ)',
        'Nguyễn Văn An (Đời 2)',
        'Nguyễn Thị Mai Anh (Đời 3)',
        'Nguyễn Hoàng Long (Đời 4)',
      ],
      members: _generateNguyenChi1Members(),
    );
  }

  BranchUiDetail _getNguyenChi2Detail({bool isCurrentUser = false}) {
    return BranchUiDetail(
      id: 'CHI_02',
      name: 'Chi 2 - Nhánh Thứ',
      badge: isCurrentUser ? '★ VỊ TRÍ CỦA BẠN • TRƯỞNG CHI' : 'Chi 2 (Thứ Phái) • Đời 2',
      code: 'CHI-02-ROOT',
      representative: 'Nguyễn Văn Hùng (Sinh 1982)',
      representativeSubtext: 'Trưởng Chi 2 • Nhánh Ất',
      memberCount: 20,
      activatedMemberCount: 18,
      fundAmount: '70.000.000 đ',
      description: 'Nhánh Thứ Phái phát triển mạnh mẽ về kinh tế và giáo dục, phụ trách quỹ khuyến học và các hoạt động thiện nguyện dòng họ.',
      successionChain: const [
        'Nguyễn Tiên Tổ (Khởi tổ)',
        'Nguyễn Văn Hùng (Đời 2)',
        'Nguyễn Hữu Nam (Đời 3)',
        'Nguyễn Hữu Đạt (Đời 4)',
        'Nguyễn Hữu Tuấn (Đời 5)',
      ],
      members: _generateNguyenChi2Members(),
    );
  }

  BranchUiDetail _getNguyenGen3MaiAnhDetail({bool isCurrentUser = false}) {
    return BranchUiDetail(
      id: 'GEN3_MAI_ANH',
      name: 'Hồ Sơ: Nguyễn Thị Mai Anh',
      badge: isCurrentUser ? '★ VỊ TRÍ CỦA BẠN • ĐỜI 3' : 'Đời 3 • Chi 1',
      code: 'NG-CHI1-DOI3-MAI',
      representative: 'Nguyễn Thị Mai Anh',
      representativeSubtext: isCurrentUser ? 'Sinh 1992 • Vị trí đăng nhập hiện tại' : 'Sinh 1992 • Ban Kiểm Soát',
      memberCount: 1,
      activatedMemberCount: 1,
      fundAmount: '12.000.000 đ',
      description: 'Nguyễn Thị Mai Anh sinh năm 1992, thuộc Chi 1 Dòng Họ Nguyễn. Phụ trách công tác kiểm toán nội bộ và quản lý biên lai đóng góp.',
      successionChain: const [
        'Nguyễn Tiên Tổ (Khởi tổ)',
        'Nguyễn Văn An (Đời 2)',
        'Nguyễn Thị Mai Anh (Đời 3)',
      ],
      members: const [
        BranchMemberItem(memberId: 'MEM_MAI_ANH', fullName: 'Nguyễn Thị Mai Anh', generation: 3, birthDeathInfo: 'Sinh 1992 (34 tuổi)', roleInBranch: 'Ban Kiểm Soát • Đã kích hoạt', gender: 'female', isActivated: true),
      ],
    );
  }

  BranchUiDetail _getNguyenGen4LongDetail() {
    return const BranchUiDetail(
      id: 'GEN4_NG_LONG',
      name: 'Gia Đình Nguyễn Hoàng Long',
      badge: 'Đời 4 • Kế Thừa Chi Trưởng',
      code: 'NG-CHI1-DOI4-LONG',
      representative: 'Nguyễn Hoàng Long',
      representativeSubtext: 'Sinh 2015 • Hậu Duệ Đời 4',
      memberCount: 3,
      activatedMemberCount: 2,
      fundAmount: '5.000.000 đ',
      description: 'Nguyễn Hoàng Long sinh năm 2015, con cháu thế hệ thứ 4 thuộc Chi Trưởng Dòng Họ Nguyễn.',
      successionChain: [
        'Nguyễn Tiên Tổ',
        'Nguyễn Văn An (Đời 2)',
        'Nguyễn Thị Mai Anh (Đời 3)',
        'Nguyễn Hoàng Long (Đời 4)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-N06', fullName: 'Nguyễn Hoàng Long', generation: 4, birthDeathInfo: 'Sinh 2015', roleInBranch: 'Con cháu Đời 4', isActivated: true),
      ],
    );
  }

  BranchUiDetail _getNguyenGen5Detail() {
    return const BranchUiDetail(
      id: 'GEN5_NG_TRIET',
      name: 'Hồ Sơ: Nguyễn Minh Triết',
      badge: 'Đời 5 • Chi Trưởng',
      code: 'NG-CHI1-DOI5-TRIET',
      representative: 'Nguyễn Minh Triết',
      representativeSubtext: 'Sinh 2022 • Hậu Duệ Đời 5',
      memberCount: 1,
      activatedMemberCount: 1,
      fundAmount: '1.000.000 đ',
      description: 'Nguyễn Minh Triết sinh năm 2022, thế hệ mầm non kế thừa Chi Trưởng.',
      successionChain: [
        'Nguyễn Tiên Tổ',
        'Nguyễn Văn An (Đời 2)',
        'Nguyễn Thị Mai Anh (Đời 3)',
        'Nguyễn Hoàng Long (Đời 4)',
        'Nguyễn Minh Triết (Đời 5)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-N09', fullName: 'Nguyễn Minh Triết', generation: 5, birthDeathInfo: 'Sinh 2022', roleInBranch: 'Con cháu Đời 5', isActivated: true),
      ],
    );
  }

  BranchUiDetail _getNguyenGen3NamDetail() {
    return const BranchUiDetail(
      id: 'GEN3_NG_NAM',
      name: 'Nhánh Bác Nguyễn Hữu Nam',
      badge: 'Đời 3 • Trưởng Nam Chi 2',
      code: 'NG-CHI2-DOI3-NAM',
      representative: 'Bác Nguyễn Hữu Nam',
      representativeSubtext: 'Sinh 1980 • Trưởng Nam Chi 2',
      memberCount: 8,
      activatedMemberCount: 7,
      fundAmount: '38.000.000 đ',
      description: 'Bác Nguyễn Hữu Nam sinh năm 1980, phụ trách Ban Liên Lạc Dòng Họ Chi 2.',
      successionChain: [
        'Nguyễn Tiên Tổ',
        'Nguyễn Văn Hùng (Đời 2)',
        'Nguyễn Hữu Nam (Đời 3)',
        'Nguyễn Hữu Đạt (Đời 4)',
        'Nguyễn Hữu Tuấn (Đời 5)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-N05', fullName: 'Nguyễn Hữu Nam', generation: 3, birthDeathInfo: 'Sinh 1980', roleInBranch: 'Trưởng Nam Chi 2', isActivated: true),
      ],
    );
  }

  BranchUiDetail _getNguyenGen4DatDetail() {
    return const BranchUiDetail(
      id: 'GEN4_NG_DAT',
      name: 'Gia Đình Chú Nguyễn Hữu Đạt',
      badge: 'Đời 4 • Ban Liên Lạc',
      code: 'NG-CHI2-DOI4-DAT',
      representative: 'Chú Nguyễn Hữu Đạt',
      representativeSubtext: 'Sinh 2005 • Đại diện Ban Liên Lạc',
      memberCount: 4,
      activatedMemberCount: 3,
      fundAmount: '15.000.000 đ',
      description: 'Chú Nguyễn Hữu Đạt sinh năm 2005, đại diện kết nối thanh niên dòng họ Chi 2.',
      successionChain: [
        'Nguyễn Tiên Tổ',
        'Nguyễn Văn Hùng (Đời 2)',
        'Nguyễn Hữu Nam (Đời 3)',
        'Nguyễn Hữu Đạt (Đời 4)',
        'Nguyễn Hữu Tuấn (Đời 5)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-N07', fullName: 'Nguyễn Hữu Đạt', generation: 4, birthDeathInfo: 'Sinh 2005', roleInBranch: 'Cháu đích tôn Đời 4', isActivated: true),
      ],
    );
  }

  BranchUiDetail _getNguyenGen5TuanDetail() {
    return const BranchUiDetail(
      id: 'GEN5_NG_TUAN',
      name: 'Hồ Sơ: Nguyễn Hữu Tuấn',
      badge: 'Đời 5 • Chi 2',
      code: 'NG-CHI2-DOI5-TUAN',
      representative: 'Nguyễn Hữu Tuấn',
      representativeSubtext: 'Sinh 2020 • Con cháu Đời 5',
      memberCount: 1,
      activatedMemberCount: 1,
      fundAmount: '2.000.000 đ',
      description: 'Nguyễn Hữu Tuấn sinh năm 2020, con cháu thế hệ thứ 5 thuộc Chi 2 Dòng Họ Nguyễn.',
      successionChain: [
        'Nguyễn Tiên Tổ',
        'Nguyễn Văn Hùng (Đời 2)',
        'Nguyễn Hữu Nam (Đời 3)',
        'Nguyễn Hữu Đạt (Đời 4)',
        'Nguyễn Hữu Tuấn (Đời 5)',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-N08', fullName: 'Nguyễn Hữu Tuấn', generation: 5, birthDeathInfo: 'Sinh 2020', roleInBranch: 'Hậu duệ Đời 5', isActivated: true),
      ],
    );
  }

  static List<BranchMemberItem> _generateNguyenRootMembers() {
    return const [
      BranchMemberItem(memberId: 'MEM_TRUONG_TOC', fullName: 'Nguyễn Trọng Hoàng', generation: 1, birthDeathInfo: 'Sinh 1965', roleInBranch: 'Trưởng Tộc • Chi Gốc', isActivated: true),
      BranchMemberItem(memberId: 'MEM_TRUONG_CHI', fullName: 'Nguyễn Văn An', generation: 2, birthDeathInfo: 'Sinh 1978', roleInBranch: 'Trưởng Chi 1', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N03', fullName: 'Nguyễn Văn Hùng', generation: 2, birthDeathInfo: 'Sinh 1982', roleInBranch: 'Trưởng Chi 2', isActivated: true),
      BranchMemberItem(memberId: 'MEM_MAI_ANH', fullName: 'Nguyễn Thị Mai Anh', generation: 3, birthDeathInfo: 'Sinh 1992', roleInBranch: 'Ban Kiểm Soát', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N05', fullName: 'Nguyễn Hữu Nam', generation: 3, birthDeathInfo: 'Sinh 1980', roleInBranch: 'Ban Liên Lạc', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N06', fullName: 'Nguyễn Hoàng Long', generation: 4, birthDeathInfo: 'Sinh 2015', roleInBranch: 'Hậu duệ Đời 4', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N07', fullName: 'Nguyễn Hữu Đạt', generation: 4, birthDeathInfo: 'Sinh 2005', roleInBranch: 'Hậu duệ Đời 4', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N08', fullName: 'Nguyễn Hữu Tuấn', generation: 5, birthDeathInfo: 'Sinh 2020', roleInBranch: 'Hậu duệ Đời 5', isActivated: true),
    ];
  }

  static List<BranchMemberItem> _generateNguyenChi1Members() {
    return const [
      BranchMemberItem(memberId: 'MEM_TRUONG_CHI', fullName: 'Nguyễn Văn An', generation: 2, birthDeathInfo: 'Sinh 1978', roleInBranch: 'Trưởng Chi 1', isActivated: true),
      BranchMemberItem(memberId: 'MEM_MAI_ANH', fullName: 'Nguyễn Thị Mai Anh', generation: 3, birthDeathInfo: 'Sinh 1992', roleInBranch: 'Thành viên Đời 3', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N06', fullName: 'Nguyễn Hoàng Long', generation: 4, birthDeathInfo: 'Sinh 2015', roleInBranch: 'Con cháu Đời 4', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N10', fullName: 'Nguyễn Thảo My', generation: 4, birthDeathInfo: 'Sinh 2018', roleInBranch: 'Con gái Đời 4', gender: 'female', isActivated: true),
    ];
  }

  static List<BranchMemberItem> _generateNguyenChi2Members() {
    return const [
      BranchMemberItem(memberId: 'MEM-N03', fullName: 'Nguyễn Văn Hùng', generation: 2, birthDeathInfo: 'Sinh 1982', roleInBranch: 'Trưởng Chi 2', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N05', fullName: 'Nguyễn Hữu Nam', generation: 3, birthDeathInfo: 'Sinh 1980', roleInBranch: 'Thứ nam Đời 3', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N07', fullName: 'Nguyễn Hữu Đạt', generation: 4, birthDeathInfo: 'Sinh 2005', roleInBranch: 'Cháu đích tôn Đời 4', isActivated: true),
      BranchMemberItem(memberId: 'MEM-N08', fullName: 'Nguyễn Hữu Tuấn', generation: 5, birthDeathInfo: 'Sinh 2020', roleInBranch: 'Con cháu Đời 5', isActivated: true),
    ];
  }

  // --- SINH DANH SÁCH 24 THÀNH VIÊN ĐẦY ĐỦ CHO CHI 2 ---
  static List<BranchMemberItem> _generateChi224Members() {
    return const [
      // Đời 2 (2 người)
      BranchMemberItem(memberId: 'MEM-201', fullName: 'Cụ Lê Văn Bình', generation: 2, birthDeathInfo: '1922 – 2004', roleInBranch: 'Thủy Tổ Chi 2', isActivated: true),
      BranchMemberItem(memberId: 'MEM-201B', fullName: 'Cụ Bà Trần Thị Sen', generation: 2, birthDeathInfo: '1925 – 2010', roleInBranch: 'Cụ Bà Chi 2', gender: 'female', isActivated: true),
      // Đời 3 (5 người)
      BranchMemberItem(memberId: 'MEM-202', fullName: 'Lê Văn Hùng', generation: 3, birthDeathInfo: '1954 – 2021', roleInBranch: 'Trưởng Chi 2', isActivated: true),
      BranchMemberItem(memberId: 'MEM-202B', fullName: 'Nguyễn Thị Huệ', generation: 3, birthDeathInfo: 'Sinh 1956', roleInBranch: 'Dâu Chi 2', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-203', fullName: 'Lê Văn Dũng', generation: 3, birthDeathInfo: 'Sinh 1958', roleInBranch: 'Thứ nam Chi 2', isActivated: true),
      BranchMemberItem(memberId: 'MEM-203B', fullName: 'Hoàng Thị Mai', generation: 3, birthDeathInfo: 'Sinh 1960', roleInBranch: 'Dâu Chi 2', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-204A', fullName: 'Lê Thị Nga', generation: 3, birthDeathInfo: 'Sinh 1962', roleInBranch: 'Trưởng nữ Chi 2', gender: 'female', isActivated: true),
      // Đời 4 (7 người)
      BranchMemberItem(memberId: 'MEM-204', fullName: 'Lê Hữu Nam', generation: 4, birthDeathInfo: 'Sinh 1980', roleInBranch: 'Trưởng nam Bác Hùng', isActivated: true),
      BranchMemberItem(memberId: 'MEM-205', fullName: 'Vũ Thị Thanh Hà', generation: 4, birthDeathInfo: 'Sinh 1982', roleInBranch: 'Dâu Đời 4', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-206', fullName: 'Lê Hữu Phong', generation: 4, birthDeathInfo: 'Sinh 1984', roleInBranch: 'Thứ nam Bác Hùng', isActivated: true),
      BranchMemberItem(memberId: 'MEM-207', fullName: 'Lê Thị Bích Ngọc', generation: 4, birthDeathInfo: 'Sinh 1986', roleInBranch: 'Con gái Bác Hùng', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-208A', fullName: 'Lê Quang Huy', generation: 4, birthDeathInfo: 'Sinh 1985', roleInBranch: 'Trưởng nam Chú Dũng', isActivated: true),
      BranchMemberItem(memberId: 'MEM-208B', fullName: 'Lê Thu Trang', generation: 4, birthDeathInfo: 'Sinh 1988', roleInBranch: 'Con gái Chú Dũng', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-208C', fullName: 'Lê Quang Minh', generation: 4, birthDeathInfo: 'Sinh 1990', roleInBranch: 'Thứ nam Chú Dũng', isActivated: true),
      // Đời 5 (10 người)
      BranchMemberItem(memberId: 'MEM-208', fullName: 'Lê Hữu Tuấn', generation: 5, birthDeathInfo: 'Sinh 1998', roleInBranch: 'Con trai Chú Nam (Tài khoản của bạn)', isActivated: true),
      BranchMemberItem(memberId: 'MEM-209', fullName: 'Lê Hữu Đạt', generation: 5, birthDeathInfo: 'Sinh 2005', roleInBranch: 'Con trai Chú Nam', isActivated: false),
      BranchMemberItem(memberId: 'MEM-210', fullName: 'Lê Thị Diệu Linh', generation: 5, birthDeathInfo: 'Sinh 2008', roleInBranch: 'Con gái Chú Nam', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-211', fullName: 'Lê Hữu Hoàng', generation: 5, birthDeathInfo: 'Sinh 2012', roleInBranch: 'Con trai Chú Phong', isActivated: false),
      BranchMemberItem(memberId: 'MEM-212', fullName: 'Lê Bảo Châu', generation: 5, birthDeathInfo: 'Sinh 2015', roleInBranch: 'Con gái Chú Phong', gender: 'female', isActivated: false),
      BranchMemberItem(memberId: 'MEM-213', fullName: 'Lê Quốc Anh', generation: 5, birthDeathInfo: 'Sinh 2014', roleInBranch: 'Con trai Chú Huy', isActivated: true),
      BranchMemberItem(memberId: 'MEM-214', fullName: 'Lê Tuệ Lâm', generation: 5, birthDeathInfo: 'Sinh 2017', roleInBranch: 'Con gái Chú Huy', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-215', fullName: 'Lê Nhật Minh', generation: 5, birthDeathInfo: 'Sinh 2018', roleInBranch: 'Con trai Chú Minh', isActivated: false),
      BranchMemberItem(memberId: 'MEM-216', fullName: 'Lê Minh An', generation: 5, birthDeathInfo: 'Sinh 2021', roleInBranch: 'Con trai Chú Minh', isActivated: false),
      BranchMemberItem(memberId: 'MEM-217', fullName: 'Lê Khánh An', generation: 5, birthDeathInfo: 'Sinh 2024', roleInBranch: 'Con gái út Chú Minh', gender: 'female', isActivated: false),
    ];
  }

  // --- SINH DANH SÁCH 18 THÀNH VIÊN ĐẦY ĐỦ CHO CHI 1 ---
  static List<BranchMemberItem> _generateChi118Members() {
    return const [
      // Đời 2 (2 người)
      BranchMemberItem(memberId: 'MEM-101', fullName: 'Cụ Lê Văn An', generation: 2, birthDeathInfo: '1918 – 1995', roleInBranch: 'Cụ Cả Trưởng Tộc', isActivated: true),
      BranchMemberItem(memberId: 'MEM-101B', fullName: 'Cụ Bà Ngô Thị Vui', generation: 2, birthDeathInfo: '1920 – 2001', roleInBranch: 'Cụ Bà Chi 1', gender: 'female', isActivated: true),
      // Đời 3 (4 người)
      BranchMemberItem(memberId: 'MEM-102', fullName: 'Lê Tuấn Anh', generation: 3, birthDeathInfo: 'Sinh 1950', roleInBranch: 'Trưởng Nam Chi 1', isActivated: true),
      BranchMemberItem(memberId: 'MEM-102B', fullName: 'Đỗ Thị Nga', generation: 3, birthDeathInfo: 'Sinh 1952', roleInBranch: 'Dâu Chi 1', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-103', fullName: 'Lê Tuấn Cường', generation: 3, birthDeathInfo: 'Sinh 1955', roleInBranch: 'Thứ Nam Chi 1', isActivated: true),
      BranchMemberItem(memberId: 'MEM-103B', fullName: 'Lê Thị Tuyết', generation: 3, birthDeathInfo: 'Sinh 1958', roleInBranch: 'Con gái Chi 1', gender: 'female', isActivated: true),
      // Đời 4 (5 người)
      BranchMemberItem(memberId: 'MEM-104', fullName: 'Lê Đình Khôi', generation: 4, birthDeathInfo: 'Sinh 1976', roleInBranch: 'Đại diện Ban Từ Thiện', isActivated: true),
      BranchMemberItem(memberId: 'MEM-104B', fullName: 'Nguyễn Thùy Chi', generation: 4, birthDeathInfo: 'Sinh 1978', roleInBranch: 'Dâu Đời 4', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-105', fullName: 'Lê Đình Bảo', generation: 4, birthDeathInfo: 'Sinh 1982', roleInBranch: 'Thứ nam Bác Tuấn Anh', isActivated: true),
      BranchMemberItem(memberId: 'MEM-106', fullName: 'Lê Thị Vân', generation: 4, birthDeathInfo: 'Sinh 1985', roleInBranch: 'Con gái Bác Cường', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-107', fullName: 'Lê Trọng Hiếu', generation: 4, birthDeathInfo: 'Sinh 1988', roleInBranch: 'Con trai Bác Cường', isActivated: true),
      // Đời 5 (7 người)
      BranchMemberItem(memberId: 'MEM-108', fullName: 'Lê Hoàng Long', generation: 5, birthDeathInfo: 'Sinh 2002', roleInBranch: 'Trưởng nam Đời 5 Chi 1', isActivated: false),
      BranchMemberItem(memberId: 'MEM-109', fullName: 'Lê Thảo My', generation: 5, birthDeathInfo: 'Sinh 2005', roleInBranch: 'Con gái Chú Khôi', gender: 'female', isActivated: true),
      BranchMemberItem(memberId: 'MEM-110', fullName: 'Lê Minh Triết', generation: 5, birthDeathInfo: 'Sinh 2008', roleInBranch: 'Con trai Chú Bảo', isActivated: true),
      BranchMemberItem(memberId: 'MEM-111', fullName: 'Lê Khôi Nguyên', generation: 5, birthDeathInfo: 'Sinh 2012', roleInBranch: 'Con trai Chú Bảo', isActivated: false),
      BranchMemberItem(memberId: 'MEM-112', fullName: 'Lê Gia Hưng', generation: 5, birthDeathInfo: 'Sinh 2016', roleInBranch: 'Con trai Chú Hiếu', isActivated: false),
      BranchMemberItem(memberId: 'MEM-113', fullName: 'Lê Thục Anh', generation: 5, birthDeathInfo: 'Sinh 2019', roleInBranch: 'Con gái Chú Hiếu', gender: 'female', isActivated: false),
      BranchMemberItem(memberId: 'MEM-114', fullName: 'Lê Minh Khang', generation: 5, birthDeathInfo: 'Sinh 2022', roleInBranch: 'Con trai út', isActivated: false),
    ];
  }

  // --- SINH DANH SÁCH 42 THÀNH VIÊN ĐẦY ĐỦ CHO CHI GỐC (ĐẠI TÔN) ---
  static List<BranchMemberItem> _generateRoot42Members() {
    return [
      const BranchMemberItem(memberId: 'MEM-001', fullName: 'Cụ Lê Phúc Khang', generation: 1, birthDeathInfo: '1890 – 1968', roleInBranch: 'Cụ Thủy Tổ Đại Tôn', isActivated: true),
      const BranchMemberItem(memberId: 'MEM-002', fullName: 'Cụ Bà Hoàng Thị Mùi', generation: 1, birthDeathInfo: '1895 – 1974', roleInBranch: 'Cụ Bà Thủy Tổ', gender: 'female', isActivated: true),
      ..._generateChi118Members(),
      ..._generateChi224Members().sublist(0, 22),
    ];
  }
}
