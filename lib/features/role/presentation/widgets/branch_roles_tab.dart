import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/role_models.dart';
import '../providers/role_providers.dart';
import 'assign_role_bottom_sheet.dart';
import 'revoke_role_dialog.dart';

class BranchRolesTab extends ConsumerWidget {
  const BranchRolesTab({super.key});

  void _openAssign(BuildContext context, String branchId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignRoleBottomSheet(
        initialScope: RoleScopeType.branch,
        initialTargetId: branchId,
      ),
    );
  }

  void _openRevoke(
    BuildContext context,
    BranchRoleOverviewModel branch,
  ) {
    showDialog(
      context: context,
      builder: (_) => RevokeRoleDialog(
        memberId: branch.representativeMemberId ?? '',
        memberName: branch.representativeFullName ?? 'Trưởng Chi',
        roleCode: AssignableRoleCode.roleBranchHead.code,
        roleDisplayName: 'Trưởng Chi / Nhánh',
        scopeType: RoleScopeType.branch,
        scopeId: branch.branchId,
        scopeName: branch.branchName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(roleManagementProvider);
    final branches = roleState.overview?.branches ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Rule info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFEEEB)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF6A020A), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quy Ước Bổ Nhiệm Trưởng Chi',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Trưởng Chi (ROLE_BRANCH_HEAD) đại diện cho nhánh phụ trách phả hệ và thu chi nội bộ chi. Bắt buộc thành viên phải có tài khoản đã kích hoạt (Active).',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF58413F),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (roleState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF6A020A)),
            ),
          )
        else if (branches.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: const Text(
              'Chưa có dữ liệu chi nhánh dòng họ.',
              style: TextStyle(fontSize: 13, color: Color(0xFF8B716E)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: branches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final branch = branches[index];
              return _buildBranchCard(context, branch, index + 1);
            },
          ),
      ],
    );
  }

  Widget _buildBranchCard(
    BuildContext context,
    BranchRoleOverviewModel branch,
    int index,
  ) {
    final hasRep = branch.hasRepresentative;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasRep ? const Color(0xFFEFEEEB) : const Color(0xFFDFBFBC),
          style: hasRep ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(42, 42, 42, 0.03),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Branch Name & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFED65B).withAlpha(50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF735C00),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    branch.branchName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: hasRep
                      ? const Color(0xFFDCF5E3)
                      : const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasRep ? 'Đã Bổ Nhiệm' : 'Khuyết Trưởng Chi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasRep
                        ? const Color(0xFF1B873F)
                        : const Color(0xFFBA1A1A),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: Color(0xFFF4F3F1)),

          // Body: Representative Details or Empty prompt
          if (hasRep)
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFFFDAD6),
                  foregroundColor: const Color(0xFF6A020A),
                  child: Text(
                    branch.representativeFullName!.isNotEmpty
                        ? branch.representativeFullName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.representativeFullName!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (branch.generationLevel != null)
                            Text(
                              'Đời ${branch.generationLevel}  •  ',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF58413F),
                              ),
                            ),
                          const Icon(
                            Icons.check_circle,
                            size: 11,
                            color: Color(0xFF1B873F),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'TK Active',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B873F),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Change Button
                OutlinedButton.icon(
                  onPressed: () => _openAssign(context, branch.branchId),
                  icon: const Icon(Icons.sync_alt, size: 14),
                  label: const Text('Đổi'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: const Size(54, 32),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Color(0xFFE9E8E5)),
                  ),
                ),
                const SizedBox(width: 6),
                // Revoke Button
                IconButton(
                  tooltip: 'Thu hồi vai trò Trưởng Chi',
                  onPressed: () => _openRevoke(context, branch),
                  icon: const Icon(Icons.remove_moderator, size: 18),
                  color: const Color(0xFFBA1A1A),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDAD6),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chưa bổ nhiệm người đại diện quản lý chi nhánh',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF8B716E),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openAssign(context, branch.branchId),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Bổ Nhiệm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A020A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: const Size(80, 32),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
