import 'dart:typed_data';

import '../entities/family_branch.dart';
import '../../data/models/branch_models.dart';
import '../../data/models/member_import_models.dart';
import '../../data/models/privacy_setting_models.dart';

abstract class GenealogyRepository {
  Future<FamilyBranchDetail> getRootBranch();
  Future<FamilyBranchDetail> updateRootBranch(UpdateRootBranchRequestDto request);
  Future<BranchTreeNodeDto> getBranchTree();
  Future<List<BranchMemberItem>> getBranchMembers(String branchId);
  Future<List<BranchMemberItem>> getClanMembers();
  Future<MemberPrivacySettingDto> getMyPrivacySettings();
  Future<MemberPrivacySettingDto> updateMyPrivacySettings(UpdateMemberPrivacySettingRequestDto request);
  Future<void> updateLifeStatus({
    required String memberId,
    required UpdateLifeStatusRequestDto request,
  });
  Future<Uint8List> downloadImportTemplate();
  Future<ImportMembersPreviewResponseDto> previewMemberImport({
    required Uint8List bytes,
    required String fileName,
  });
  Future<ImportMembersConfirmResponseDto> confirmMemberImport(
    ConfirmMemberImportRequestDto request,
  );
}
