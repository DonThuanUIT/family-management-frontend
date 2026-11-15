import '../entities/family_branch.dart';
import '../../data/models/branch_models.dart';

abstract class GenealogyRepository {
  Future<FamilyBranchDetail> getRootBranch();
  Future<FamilyBranchDetail> updateRootBranch(UpdateRootBranchRequestDto request);
  Future<BranchTreeNodeDto> getBranchTree();
  Future<List<BranchMemberItem>> getBranchMembers(String branchId);
  Future<List<BranchMemberItem>> getClanMembers();
  Future<BranchDetailDto> updateBranch(String branchId, UpdateBranchRequestDto request);
  Future<void> assignMemberToBranch(String memberId, String branchId);
  Future<List<MemberSearchDto>> searchMembers({
    String? keyword,
    String? memberId,
    String? fullName,
    int? generation,
    String? branchId,
    String? status,
  });
}
