import '../../data/models/position_link_models.dart';

abstract class PositionLinkRepository {
  Future<CreateVirtualMemberResponseDto> createVirtualMember({
    required String branchId,
    required CreateVirtualMemberRequestDto request,
  });

  Future<List<PositionLinkItemModel>> getIssuedPositionLinks();
}
