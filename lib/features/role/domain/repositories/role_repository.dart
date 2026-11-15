import '../../data/models/role_models.dart';

abstract class RoleRepository {
  Future<RoleManagementOverviewModel> getOverview();

  Future<List<AuditLogModel>> getAuditLogs({
    String? memberId,
    String? scopeType,
    String? scopeId,
  });

  Future<RoleAssignmentResponseDto> assignRole(RoleAssignmentRequestDto request);

  Future<RoleAssignmentResponseDto> revokeRole(RoleRevocationRequestDto request);
}
