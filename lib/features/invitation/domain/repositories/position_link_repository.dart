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
}
