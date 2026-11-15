import '../../data/models/invitation_management_models.dart';
import '../../data/models/position_link_models.dart';

abstract class PositionLinkRepository {
  Future<CreateVirtualMemberResponseDto> createVirtualMember({
    required String branchId,
    required CreateVirtualMemberRequestDto request,
  });

  Future<List<PositionLinkItemModel>> getIssuedPositionLinks();

  Future<PositionLinkPreviewDto> getPositionLinkPreview(String inviteCode);

  Future<ClaimPositionResponseDto> claimPosition({
    required String inviteCode,
    required ClaimPositionRequestDto request,
  });

  Future<PositionLinkItemModel> createGeneralInvite(CreateGeneralInviteRequestDto request);

  Future<void> deactivateInvite(String inviteCode);

  Future<PositionLinkItemModel> updateInvite(
    String inviteCode,
    UpdateInvitationRequestDto request,
  );

  Future<PositionLinkItemModel> regenerateInvite(
    String inviteCode, {
    UpdateInvitationRequestDto? request,
  });
}
