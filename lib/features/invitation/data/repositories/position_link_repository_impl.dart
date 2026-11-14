import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/position_link_repository.dart';
import '../datasources/position_link_remote_datasource.dart';
import '../models/position_link_models.dart';

final positionLinkRepositoryProvider = Provider<PositionLinkRepository>((ref) {
  final remote = ref.watch(positionLinkRemoteDataSourceProvider);
  return PositionLinkRepositoryImpl(remote);
});

class PositionLinkRepositoryImpl implements PositionLinkRepository {
  final PositionLinkRemoteDataSource _remoteDataSource;

  PositionLinkRepositoryImpl(this._remoteDataSource);

  @override
  Future<CreateVirtualMemberResponseDto> createVirtualMember({
    required String branchId,
    required CreateVirtualMemberRequestDto request,
  }) {
    return _remoteDataSource.createVirtualMember(
      branchId: branchId,
      request: request,
    );
  }

  @override
  Future<List<PositionLinkItemModel>> getIssuedPositionLinks() {
    return _remoteDataSource.getIssuedPositionLinks();
  }

  @override
  Future<PositionLinkPreviewDto> getPositionLinkPreview(String inviteCode) {
    return _remoteDataSource.getPositionLinkPreview(inviteCode);
  }

  @override
  Future<ClaimPositionResponseDto> claimPosition({
    required String inviteCode,
    required ClaimPositionRequestDto request,
  }) {
    return _remoteDataSource.claimPosition(
      inviteCode: inviteCode,
      request: request,
    );
  }
}
