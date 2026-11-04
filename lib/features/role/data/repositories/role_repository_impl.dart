import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/role_repository.dart';
import '../datasources/role_remote_datasource.dart';
import '../models/role_models.dart';

class RoleRepositoryImpl implements RoleRepository {
  final RoleRemoteDataSource _remoteDataSource;

  RoleRepositoryImpl(this._remoteDataSource);

  @override
  Future<RoleManagementOverviewModel> getOverview() {
    return _remoteDataSource.getOverview();
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs({
    String? memberId,
    String? scopeType,
    String? scopeId,
  }) {
    return _remoteDataSource.getAuditLogs(
      memberId: memberId,
      scopeType: scopeType,
      scopeId: scopeId,
    );
  }

  @override
  Future<RoleAssignmentResponseDto> assignRole(RoleAssignmentRequestDto request) {
    return _remoteDataSource.assignRole(request);
  }

  @override
  Future<RoleAssignmentResponseDto> revokeRole(RoleRevocationRequestDto request) {
    return _remoteDataSource.revokeRole(request);
  }
}

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  final remoteDataSource = ref.watch(roleRemoteDataSourceProvider);
  return RoleRepositoryImpl(remoteDataSource);
});
