import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../../genealogy/presentation/providers/genealogy_providers.dart';
import '../../../genealogy/presentation/widgets/branch_detail_sidebar.dart';
import '../../../genealogy/data/models/branch_models.dart';

/// Màn hình Cây Phả Hệ Trực Quan Đa Chi Phái (Stitch Warm Editorial Heritage)
/// Đã được tinh chỉnh hoàn thiện:
/// 1. Hiển thị đầy đủ danh sách 24 thành viên cho Chi 2 (và 18 thành viên cho Chi 1, 42 thành viên cho Chi Gốc).
/// 2. Bấm vào bất kỳ card nào (kể cả Đời 3, Đời 4, Đời 5) đều mở bảng chi tiết Sidebar.
/// 3. Sơ đồ chuỗi phả hệ dưới cùng có bộ chuyển đổi giữa Tuyến Chi Trưởng (Cụ An) và Tuyến Chi Thứ (Cụ Bình).
/// 4. Nút cấp mã mời được thiết kế lại thanh lịch, không bị tràn viền hay mất chữ.
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

  // Tuyến chuỗi gia phả hiển thị ở dưới: 'chi1' (Chi Trưởng) hoặc 'chi2' (Chi Thứ)
  String _activeLineageRoute = 'chi2';

  @override
  void initState() {
    super.initState();
    _selectedBranch = _getChi2Detail();
  }

  @override
  Widget build(BuildContext context) {
    final branchState = ref.watch(rootBranchProvider);
    final rootBranch = branchState.branch;

    const kPrimaryColor = Color(0xFF8F482F);
    const kBgColor = Color(0xFFFCF9F6);
    const kSurfaceColor = Color(0xFFFFFFFF);
    const kBorderColor = Color(0xFFDAC1BA);

    final isWide = MediaQuery.of(context).size.width >= 900;

    // Dữ liệu chi tiết các nhánh & nhân vật
    final rootDetail = _getRootDetail(rootBranch?.branchName, rootBranch?.description);
    final chi1Detail = _getChi1Detail();
    final chi2Detail = _getChi2Detail();
    final gen3HungDetail = _getGen3HungDetail();
    final gen4NamDetail = _getGen4NamDetail();
    final gen5TuanDetail = _getGen5TuanDetail();

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
                                  Text(
                                    rootBranch?.clanName.isNotEmpty == true
                                        ? '${rootBranch!.clanName} • Cụ Khởi Tổ 1890'
                                        : 'Gốc Nam Trung, Thái Bình • Cụ Khởi Tổ 1890',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1C1C1A),
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
                          onTap: () {
                            setState(() => _activeLineageRoute = 'root');
                            _handleSelectBranch(rootDetail, isWide);
                          },
                        ),

                        // Đường nối phân nhánh (Vertical Tree Connector)
                        Container(
                          width: 2,
                          height: 32,
                          color: kPrimaryColor,
                        ),
                        Container(
                          width: 320,
                          height: 2,
                          color: kPrimaryColor,
                        ),

                        // CÁC CHI PHÁI ĐỜI 2 (Side-by-side)
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 24,
                            runSpacing: 20,
                            children: [
                              _buildBranchNodeCard(
                                context: context,
                                detail: chi1Detail,
                                isSelected: _selectedBranch?.id == chi1Detail.id,
                                isWide: isWide,
                                onSelect: () {
                                  setState(() => _activeLineageRoute = 'chi1');
                                  _handleSelectBranch(chi1Detail, isWide);
                                },
                              ),
                              _buildBranchNodeCard(
                                context: context,
                                detail: chi2Detail,
                                isSelected: _selectedBranch?.id == chi2Detail.id,
                                isWide: isWide,
                                onSelect: () {
                                  setState(() => _activeLineageRoute = 'chi2');
                                  _handleSelectBranch(chi2Detail, isWide);
                                },
                              ),
                            ],
                          ),
                        ),

                        // 3. PHẦN MỞ RỘNG CÁC ĐỜI CON CHÁU TIẾP NỐI (ĐỜI 3 -> ĐỜI 4 -> ĐỜI 5)
                        if (_isFullTreeExpanded) ...[
                          const SizedBox(height: 12),
                          // Đường nối dọc từ Chi 2 xuống
                          Container(
                            width: 2,
                            height: 36,
                            color: kPrimaryColor,
                          ),

                          // Card Đời 3: Bác Lê Văn Hùng (BẤM VÀO ĐƯỢC ĐỂ XEM CHI TIẾT)
                          _buildSubGenerationCard(
                            generation: 'ĐỜI 3',
                            title: 'Bác Lê Văn Hùng',
                            subtitle: '(1954 – 2021) • Trưởng Chi 2',
                            badge: 'Thế Hệ Trực Hệ',
                            color: const Color(0xFF8F482F),
                            isSelected: _selectedBranch?.id == gen3HungDetail.id,
                            onTap: () {
                              setState(() => _activeLineageRoute = 'chi2');
                              _handleSelectBranch(gen3HungDetail, isWide);
                            },
                          ),

                          Container(
                            width: 2,
                            height: 24,
                            color: kPrimaryColor,
                          ),

                          // Card Đời 4: Chú Lê Hữu Nam (BẤM VÀO ĐƯỢC ĐỂ XEM CHI TIẾT)
                          _buildSubGenerationCard(
                            generation: 'ĐỜI 4',
                            title: 'Chú Lê Hữu Nam',
                            subtitle: 'Sinh 1980 • Đại diện Ban Liên Lạc',
                            badge: 'Kế Thừa Chi',
                            color: const Color(0xFFAD5F45),
                            isSelected: _selectedBranch?.id == gen4NamDetail.id,
                            onTap: () {
                              setState(() => _activeLineageRoute = 'chi2');
                              _handleSelectBranch(gen4NamDetail, isWide);
                            },
                          ),

                          Container(
                            width: 2,
                            height: 24,
                            color: kPrimaryColor,
                          ),

                          // Card Đời 5: Con cháu thế hệ hiện tại (Lê Hữu Tuấn - BẤM VÀO ĐƯỢC)
                          _buildCurrentUserGen5Card(
                            detail: gen5TuanDetail,
                            isSelected: _selectedBranch?.id == gen5TuanDetail.id,
                            activeRoute: _activeLineageRoute,
                            onSwitchRoute: (route) => setState(() => _activeLineageRoute = route),
                            onTap: () {
                              setState(() => _activeLineageRoute = 'chi2');
                              _handleSelectBranch(gen5TuanDetail, isWide);
                            },
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
                                  'Mẹo: Nhấp vào bất kỳ nhánh nào (Khởi tổ, Chi 1, Chi 2, Đời 3, 4, 5) để xem chi tiết đầy đủ thành viên trên bảng sidebar.',
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
          border: isSelected ? Border.all(color: const Color(0xFFFFB59D), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.25 : 0.12),
              blurRadius: isSelected ? 24 : 16,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.military_tech, size: 14, color: Color(0xFFFFB59D)),
                            SizedBox(width: 6),
                            Text(
                              'CỤ KHỞI TỔ • ĐỜI 1',
                              style: TextStyle(
                                fontFamily: 'JetBrains Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFB59D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
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
                          border: Border.all(color: const Color(0xFFFFB59D), width: 1.5),
                        ),
                        child: const Icon(Icons.person, color: Color(0xFFFFB59D), size: 30),
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
  }) {
    const kPrimaryColor = Color(0xFF8F482F);
    const kBorderColor = Color(0xFFDAC1BA);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimaryColor : kBorderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? kPrimaryColor.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 16 : 8,
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
                        color: isSelected
                            ? kPrimaryColor
                            : const Color(0xFF8F482F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        detail.badge,
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : kPrimaryColor,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Xem bảng chi tiết',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 14, color: kPrimaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Sub-Generation Cards (Đời 3, Đời 4) - ĐÃ ĐƯỢC GẮN ONTAP ĐỂ MỞ SIDEBAR
  Widget _buildSubGenerationCard({
    required String generation,
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8F482F) : const Color(0xFFDAC1BA),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF8F482F).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                generation,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
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
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8F482F)),
          ],
        ),
      ),
    );
  }

  // 4. Current User Gen 5 Card (Highlight vị trí bạn) - CÓ BỘ CHUYỂN TUYẾN GIA PHẢ CHI 1 / CHI 2
  Widget _buildCurrentUserGen5Card({
    required BranchUiDetail detail,
    required bool isSelected,
    required String activeRoute,
    required ValueChanged<String> onSwitchRoute,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF006E2A) : const Color(0xFF8F482F),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8F482F).withValues(alpha: isSelected ? 0.16 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header vị trí người dùng
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pin_drop, size: 20, color: Color(0xFF8F482F)),
                const SizedBox(width: 6),
                const Text(
                  'Vị trí của bạn trong gia phả: ',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1A),
                  ),
                ),
                const Text(
                  'Lê Hữu Tuấn',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8F482F),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8F482F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Đời 5 • Chi 2',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8F482F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Mã hồ sơ: LE-CHI2-DOI5-9821 • Đã kích hoạt liên kết tài khoản',
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 11,
                color: Color(0xFF6B584E),
              ),
            ),
            const SizedBox(height: 12),

            // BỘ CHUYỂN TUYẾN HUYẾT THỐNG (Chi Trưởng Cụ An vs Chi Thứ Cụ Bình)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EFEA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => onSwitchRoute('chi1'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: activeRoute == 'chi1' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: activeRoute == 'chi1'
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : null,
                        ),
                        child: Text(
                          'Tuyến Chi Trưởng (Cụ An)',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            fontWeight: activeRoute == 'chi1' ? FontWeight.bold : FontWeight.w500,
                            color: activeRoute == 'chi1' ? const Color(0xFF8F482F) : const Color(0xFF6B584E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => onSwitchRoute('chi2'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: activeRoute == 'chi2' ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: activeRoute == 'chi2'
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                              : null,
                        ),
                        child: Text(
                          'Tuyến Chi Thứ (Cụ Bình)',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            fontWeight: activeRoute == 'chi2' ? FontWeight.bold : FontWeight.w500,
                            color: activeRoute == 'chi2' ? const Color(0xFF8F482F) : const Color(0xFF6B584E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Nội dung chuỗi trực hệ hiển thị động theo tuyến chọn
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEAE5E0)),
              ),
              child: Text(
                activeRoute == 'chi1'
                    ? 'Khởi Tổ (1890) ➔ Cụ An (1918) ➔ Bác Tuấn Anh (1950) ➔ Chú Khôi (1976) ➔ Long (2002)'
                    : 'Khởi Tổ (1890) ➔ Cụ Bình (1922) ➔ Bác Hùng (1954) ➔ Chú Nam (1980) ➔ Tuấn (1998)',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  color: Color(0xFF8F482F),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activeRoute == 'chi1'
                  ? '📌 Chuỗi trực hệ Chi Trưởng (Phái con cháu cụ Cả Lê Văn An)'
                  : '📌 Chuỗi trực hệ Chi Thứ (Phái con cháu cụ Lê Văn Bình - Nhánh của bạn)',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                color: Color(0xFF6B584E),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- MOCK / HELPER DATA CHO CÁC CHI NHÁNH & NHÂN VẬT ---
  BranchUiDetail _getRootDetail(String? name, String? desc) {
    return BranchUiDetail(
      id: 'BR_ROOT',
      name: name?.isNotEmpty == true ? name! : 'Chi Gốc Nam Trung, Thái Bình',
      badge: 'CỤ KHỞI TỔ • ĐỜI 1',
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

  BranchUiDetail _getChi1Detail() {
    return BranchUiDetail(
      id: 'CHI_01',
      name: 'Chi 1 - Trưởng Chi An',
      badge: 'Chi 1 (Trưởng Phái) • Đời 2',
      code: 'CHI-01',
      representative: 'Cụ Lê Văn An (1918 – 1995)',
      representativeSubtext: 'Cụ Cả Trưởng Tộc • Phái Chi Bắc Bộ',
      memberCount: 18,
      activatedMemberCount: 14,
      fundAmount: '42.000.000 đ',
      description: 'Nhánh Trưởng Nam tiếp quản nhà thờ tổ làng Nam Trung, phụ trách nghi lễ cúng giỗ truyền thống dòng họ.',
      successionChain: const [
        'Cụ Lê Văn An (Đời 2)',
        'Lê Tuấn Anh (Đời 3 - 8 nhân khẩu)',
        'Lê Đình Khôi (Đời 4 - Ban từ thiện)',
      ],
      members: _generateChi118Members(),
    );
  }

  BranchUiDetail _getChi2Detail() {
    return BranchUiDetail(
      id: 'CHI_02',
      name: 'Chi 2 - Nhánh Nam',
      badge: 'Chi 2 (Thứ Phái) • Đời 2',
      code: 'CHI-02-ROOT',
      representative: 'Cụ Lê Văn Bình (1922 – 2004)',
      representativeSubtext: 'Phái Chi Nam Bộ & Bắc Bộ',
      memberCount: 24,
      activatedMemberCount: 19,
      fundAmount: '85.650.000 đ',
      description: 'Nhánh Thứ Phái phát triển mạnh mẽ về kinh tế và giáo dục, phụ trách quỹ khuyến học và quỹ công đức xây dựng.',
      successionChain: const [
        'Lê Văn Hùng (Trưởng Chi 2 • Đời 3)',
        'Lê Hữu Nam (Đời 4)',
        'Lê Hữu Tuấn (Đời 5 - Vừa gia nhập)',
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
        'Bác Lê Văn Hùng (Đời 3)',
        'Chú Lê Hữu Nam (Đời 4)',
        'Lê Hữu Tuấn (Đời 5)',
        'Lê Hữu Đạt (Đời 5)',
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

  BranchUiDetail _getGen5TuanDetail() {
    return const BranchUiDetail(
      id: 'GEN5_TUAN',
      name: 'Hồ Sơ: Lê Hữu Tuấn',
      badge: 'Đời 5 • Tài Khoản Của Bạn',
      code: 'LE-CHI2-DOI5-9821',
      representative: 'Lê Hữu Tuấn',
      representativeSubtext: 'Sinh 1998 • Vị trí đăng nhập hiện tại',
      memberCount: 1,
      activatedMemberCount: 1,
      fundAmount: '5.000.000 đ',
      description: 'Lê Hữu Tuấn sinh năm 1998, vị trí tài khoản đăng nhập hiện tại trong dòng họ. Thuộc nhánh Chi 2 của Cụ Lê Văn Bình.',
      successionChain: [
        'Khởi Tổ 1890',
        'Cụ Bình 1922',
        'Bác Hùng 1954',
        'Chú Nam 1980',
        'Tuấn 1998',
      ],
      members: [
        BranchMemberItem(memberId: 'MEM-208', fullName: 'Lê Hữu Tuấn', generation: 5, birthDeathInfo: 'Sinh 1998 (28 tuổi)', roleInBranch: 'Tài khoản chính • Đã xác thực', isActivated: true),
      ],
    );
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
