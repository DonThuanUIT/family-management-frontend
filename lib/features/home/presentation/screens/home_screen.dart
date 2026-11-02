import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../../genealogy/presentation/providers/genealogy_providers.dart';

/// Màn hình Cây Phả Hệ Trực Quan Đa Chi Phái (Stitch Warm Editorial Heritage)
/// Tích hợp điểm điều hướng đến Form Chỉnh Sửa Nhánh Gốc (Task #16).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(rootBranchProvider);
    final rootBranch = branchState.branch;

    const kPrimaryColor = Color(0xFF8F482F);
    const kBgColor = Color(0xFFFCF9F6);
    const kSurfaceColor = Color(0xFFFFFFFF);
    const kBorderColor = Color(0xFFDAC1BA);
    const kDarkSurface = Color(0xFF31302F);

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: const HeritageNavBar(currentRoute: '/home'),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/home'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  // Thanh bộ lọc & trạng thái
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
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lan_outlined, size: 18, color: kPrimaryColor),
                            SizedBox(width: 8),
                            Text(
                              'Gốc Nam Trung, Thái Bình • Cụ Khởi Tổ 1890',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C1C1A),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  ),
                  const SizedBox(height: 32),

                  // ROOT ANCESTOR NODE (Cụ Khởi Tổ • Đời 1 - Nhánh Gốc)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 540),
                    decoration: BoxDecoration(
                      color: kDarkSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Node
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
                                  Text(
                                    'MÃ: ${rootBranch?.branchId ?? "BR_ROOT"}',
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 11,
                                      color: Color(0xFFDAC1BA),
                                    ),
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
                                          rootBranch?.representativeName ?? 'Cụ Lê Phúc Khang',
                                          style: const TextStyle(
                                            fontFamily: 'Merriweather',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFCF9F6),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          rootBranch?.branchName ?? 'Chi Gốc Nam Trung, Thái Bình',
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
                              if (rootBranch?.description != null && rootBranch!.description!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  rootBranch.description!,
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
                            ],
                          ),
                        ),

                        // Action Bar: Chỉnh sửa nhánh gốc (Task #16)
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
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_outline, size: 14, color: Color(0xFFDAC1BA)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Quyền: Trưởng Tộc (Clan Head)',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11.5,
                                      color: Color(0xFFDAC1BA),
                                    ),
                                  ),
                                ],
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

                  // Đường nối phân nhánh (Vertical Tree Connector)
                  Container(
                    width: 2,
                    height: 36,
                    color: kPrimaryColor,
                  ),
                  Container(
                    width: 280,
                    height: 2,
                    color: kPrimaryColor,
                  ),

                  // Các chi phái nhánh con (Preview)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBranchPreviewCard(
                        context: context,
                        title: 'Chi 1 - Trưởng Chi An',
                        badge: 'Đời 2 • Trưởng Nam',
                        members: '18 Thành viên',
                      ),
                      const SizedBox(width: 24),
                      _buildBranchPreviewCard(
                        context: context,
                        title: 'Chi 2 - Nhánh Nam',
                        badge: 'Đời 2 • Thứ Chi',
                        members: '24 Thành viên',
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranchPreviewCard({
    required BuildContext context,
    required String title,
    required String badge,
    required String members,
  }) {
    return Column(
      children: [
        Container(
          width: 2,
          height: 20,
          color: const Color(0xFF8F482F),
        ),
        Container(
          width: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDAC1BA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8F482F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8F482F),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                members,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11.5,
                  color: Color(0xFF54433E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
