import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/position_link_providers.dart';

class PedigreeStructureCard extends ConsumerWidget {
  const PedigreeStructureCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clanInvitesProvider);
    final selectedBranch = state.selectedBranch;
    final memberName =
        state.memberName.trim().isNotEmpty ? state.memberName.trim() : 'Lê Hữu Tuấn';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE6E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      'CƠ CẤU VỊ TRÍ CÂY',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Color(0xFF54433E),
                      ),
                    ),
                    Text(
                      '100% Khớp Mã',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006E2A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Pedigree Branch Micro-Visual Diagram
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E0DA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          color: Color(0xFF8F482F),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mô Thức Ghép Nhánh',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Line 1: Root of branch
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8F482F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF54433E),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Gốc Chi: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: selectedBranch.rootAncestor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Line 2: Branch leader (indented)
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF87736D),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF54433E),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Trưởng Nhánh: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: selectedBranch.leaderName),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Line 3: Target member (more indented & highlighted)
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFAD5F45),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8F482F),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Vị Trí Đích: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text:
                                        '$memberName (Đời ${state.generation} - Hậu duệ)',
                                  ),
                                ],
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

              // 3. Explanatory text
              const Text(
                'Mã mời có thời hạn bảo mật trong 14 ngày. Sau khi hoàn tất xác minh danh tính qua CCCD/Sinh trắc học họ tộc, hồ sơ sẽ tự động ghi danh vào sổ bộ hương ước số #2026-DK.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFF54433E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Verification token footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBE6E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Color(0xFF006E2A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Mã hóa SHA-256',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF54433E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Ký số: ${selectedBranch.id.toUpperCase().replaceAll('-', '_')}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF54433E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
