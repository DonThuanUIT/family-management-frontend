import '../entities/family_branch.dart';
import '../../data/models/branch_models.dart';

abstract class GenealogyRepository {
  Future<FamilyBranchDetail> getRootBranch();
  Future<FamilyBranchDetail> updateRootBranch(UpdateRootBranchRequestDto request);
  Future<BranchTreeNodeDto> getBranchTree();
  Future<List<BranchMemberItem>> getBranchMembers(String branchId);
  Future<List<BranchMemberItem>> getClanMembers();
}
