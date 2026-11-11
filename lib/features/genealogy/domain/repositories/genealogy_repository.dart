import '../entities/family_branch.dart';
import '../../data/models/branch_models.dart';
import '../../data/models/privacy_setting_models.dart';

abstract class GenealogyRepository {
  Future<FamilyBranchDetail> getRootBranch();
  Future<FamilyBranchDetail> updateRootBranch(UpdateRootBranchRequestDto request);
  Future<BranchTreeNodeDto> getBranchTree();
  Future<List<BranchMemberItem>> getBranchMembers(String branchId);
  Future<List<BranchMemberItem>> getClanMembers();
  Future<MemberPrivacySettingDto> getMyPrivacySettings();
  Future<MemberPrivacySettingDto> updateMyPrivacySettings(UpdateMemberPrivacySettingRequestDto request);
}
