import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/role_models.dart';

class RoleRemoteDataSource {
  final Dio _dio;

  RoleRemoteDataSource(this._dio);

  static final List<AuditLogModel> _mockAuditLogs = [
    AuditLogModel(
      auditId: 'AUD_001',
      clanId: 'CLAN_01',
      actorAccountId: 'ACC_001',
      actorFullName: 'Trưởng Tộc (Nguyễn Văn An)',
      targetMemberId: 'MEM_004',
      targetFullName: 'Bác Nguyễn Trọng Khoa',
      targetAccountId: 'ACC_004',
      actionType: 'REVOKE',
      roleCode: 'EventTreasurer',
      roleDisplayName: 'Thủ Quỹ Sự Kiện',
      scopeType: 'EVENT',
      scopeId: 'EVT_2026_GIOTO',
      scopeName: 'Đại Lễ Giỗ Tiền Tổ',
      description: 'Hoàn thành đợt kiểm toán công đức rằm tháng Chạp.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    AuditLogModel(
      auditId: 'AUD_002',
      clanId: 'CLAN_01',
      actorAccountId: 'ACC_001',
      actorFullName: 'Trưởng Tộc (Nguyễn Văn An)',
      targetMemberId: 'MEM_002',
      targetFullName: 'Nguyễn Văn Hùng',
      targetAccountId: 'ACC_002',
      actionType: 'ASSIGN',
      roleCode: 'ROLE_BRANCH_HEAD',
      roleDisplayName: 'Trưởng Chi / Nhánh',
      scopeType: 'BRANCH',
      scopeId: 'b2',
      scopeName: 'Chi 2 (Định Chi)',
      description: 'Bổ nhiệm nhân sự theo nghị quyết Hội Đồng Tộc Biểu.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AuditLogModel(
      auditId: 'AUD_003',
      clanId: 'CLAN_01',
      actorAccountId: 'ACC_001',
      actorFullName: 'Trưởng Tộc (Nguyễn Văn An)',
      targetMemberId: 'MEM_001',
      targetFullName: 'Nguyễn Văn Bình',
      targetAccountId: 'ACC_001',
      actionType: 'ASSIGN',
      roleCode: 'ROLE_BRANCH_HEAD',
      roleDisplayName: 'Trưởng Chi / Nhánh',
      scopeType: 'BRANCH',
      scopeId: 'b1',
      scopeName: 'Chi 1 (Trưởng Nam)',
      description: 'Phân công nhiệm kỳ thường trực 2024-2029.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static final RoleManagementOverviewModel _mockOverview =
      RoleManagementOverviewModel(
    clanId: 'CLAN_01',
    branches: const [
      BranchRoleOverviewModel(
        branchId: 'b1',
        branchName: 'Chi 1 (Trưởng Nam - Bác Trưởng)',
        generationLevel: 10,
        representativeMemberId: 'MEM_001',
        representativeFullName: 'Nguyễn Văn Bình',
        representativeAccountId: 'ACC_001',
      ),
      BranchRoleOverviewModel(
        branchId: 'b2',
        branchName: 'Chi 2 (Định Chi • Nghệ An)',
        generationLevel: 11,
        representativeMemberId: 'MEM_002',
        representativeFullName: 'Nguyễn Văn Hùng',
        representativeAccountId: 'ACC_002',
      ),
      BranchRoleOverviewModel(
        branchId: 'b3',
        branchName: 'Chi 3 (Ất Chi • Kim Liên)',
        generationLevel: 11,
        representativeMemberId: null,
        representativeFullName: null,
        representativeAccountId: null,
      ),
      BranchRoleOverviewModel(
        branchId: 'b4',
        branchName: 'Chi 4 (Bính Chi • Hà Tĩnh)',
        generationLevel: 12,
        representativeMemberId: 'MEM_005',
        representativeFullName: 'Nguyễn Quốc Tuấn',
        representativeAccountId: 'ACC_005',
      ),
      BranchRoleOverviewModel(
        branchId: 'b5',
        branchName: 'Chi 5 (Đinh Chi • Đô Lương)',
        generationLevel: 12,
        representativeMemberId: null,
        representativeFullName: null,
        representativeAccountId: null,
      ),
    ],
    members: const [
      MemberRoleOptionModel(
        memberId: 'MEM_001',
        fullName: 'Nguyễn Văn Bình',
        branchId: 'b1',
        branchName: 'Chi 1',
        hasActiveAccount: true,
        accountId: 'ACC_001',
      ),
      MemberRoleOptionModel(
        memberId: 'MEM_002',
        fullName: 'Nguyễn Văn Hùng',
        branchId: 'b2',
        branchName: 'Chi 2',
        hasActiveAccount: true,
        accountId: 'ACC_002',
      ),
      MemberRoleOptionModel(
        memberId: 'MEM_003',
        fullName: 'Anh Nguyễn Hoàng Nam',
        branchId: 'b3',
        branchName: 'Chi 3',
        hasActiveAccount: true,
        accountId: 'ACC_003',
      ),
      MemberRoleOptionModel(
        memberId: 'MEM_004',
        fullName: 'Bác Nguyễn Trọng Khoa',
        branchId: 'b1',
        branchName: 'Chi 1',
        hasActiveAccount: true,
        accountId: 'ACC_004',
      ),
      MemberRoleOptionModel(
        memberId: 'MEM_005',
        fullName: 'Cô Nguyễn Thị Mai',
        branchId: 'b2',
        branchName: 'Chi 2',
        hasActiveAccount: true,
        accountId: 'ACC_005',
      ),
      MemberRoleOptionModel(
        memberId: 'MEM_006',
        fullName: 'Nguyễn Văn Đức',
        branchId: 'b3',
        branchName: 'Chi 3',
        hasActiveAccount: false,
        accountId: null,
      ),
    ],
  );

  /// Lấy tổng quan phân quyền: Các nhánh (kèm Trưởng chi) và danh sách ứng viên
  Future<RoleManagementOverviewModel> getOverview() async {
    try {
      final response = await _dio.get('roles/overview');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RoleManagementOverviewModel.fromJson(
            json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _mockOverview;
    } on DioException {
      return _mockOverview;
    }
  }

  /// Lấy danh sách nhật ký kiểm toán (Audit Logs)
  Future<List<AuditLogModel>> getAuditLogs({
    String? memberId,
    String? scopeType,
    String? scopeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (memberId != null && memberId.isNotEmpty) {
        queryParams['memberId'] = memberId;
      }
      if (scopeType != null && scopeType.isNotEmpty) {
        queryParams['scopeType'] = scopeType;
      }
      if (scopeId != null && scopeId.isNotEmpty) {
        queryParams['scopeId'] = scopeId;
      }

      final response = await _dio.get(
        'roles/audit-logs',
        queryParameters: queryParams,
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List<dynamic>)
            .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _mockAuditLogs;
    } on DioException {
      return _mockAuditLogs;
    }
  }

  /// Chỉ định vai trò mới (POST /api/v1/roles/assign)
  Future<RoleAssignmentResponseDto> assignRole(
      RoleAssignmentRequestDto request) async {
    try {
      final response = await _dio.post(
        'roles/assign',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            RoleAssignmentResponseDto.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map<String, dynamic>)['message'] as String?
          : null;
      if (errorMsg != null && errorMsg.isNotEmpty) {
        throw Exception(errorMsg);
      }
      // Khi offline fallback mô phỏng
    }

    // Mock local addition
    final newLog = AuditLogModel(
      auditId: 'AUD_${DateTime.now().millisecondsSinceEpoch}',
      clanId: 'CLAN_01',
      actorFullName: 'Trưởng Tộc (Nguyễn Văn An)',
      targetMemberId: request.memberId,
      targetFullName: _findMemberName(request.memberId),
      actionType: 'ASSIGN',
      roleCode: request.roleCode,
      roleDisplayName: AssignableRoleCode.fromCode(request.roleCode).displayName,
      scopeType: request.scopeType,
      scopeId: request.scopeId,
      description: request.description ?? 'Chỉ định vai trò',
      createdAt: DateTime.now(),
    );
    _mockAuditLogs.insert(0, newLog);

    return RoleAssignmentResponseDto(
      memberId: request.memberId,
      roleCode: request.roleCode,
      scopeType: request.scopeType,
      scopeId: request.scopeId,
      actionType: 'ASSIGN',
      message: 'Chỉ định vai trò thành công',
    );
  }

  /// Thu hồi vai trò (POST /api/v1/roles/revoke)
  Future<RoleAssignmentResponseDto> revokeRole(
      RoleRevocationRequestDto request) async {
    try {
      final response = await _dio.post(
        'roles/revoke',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            RoleAssignmentResponseDto.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map<String, dynamic>)['message'] as String?
          : null;
      if (errorMsg != null && errorMsg.isNotEmpty) {
        throw Exception(errorMsg);
      }
    }

    // Mock local addition
    final newLog = AuditLogModel(
      auditId: 'AUD_${DateTime.now().millisecondsSinceEpoch}',
      clanId: 'CLAN_01',
      actorFullName: 'Trưởng Tộc (Nguyễn Văn An)',
      targetMemberId: request.memberId,
      targetFullName: _findMemberName(request.memberId),
      actionType: 'REVOKE',
      roleCode: request.roleCode,
      roleDisplayName: AssignableRoleCode.fromCode(request.roleCode).displayName,
      scopeType: request.scopeType,
      scopeId: request.scopeId,
      description: request.reason ?? 'Thu hồi vai trò',
      createdAt: DateTime.now(),
    );
    _mockAuditLogs.insert(0, newLog);

    return RoleAssignmentResponseDto(
      memberId: request.memberId,
      roleCode: request.roleCode,
      scopeType: request.scopeType,
      scopeId: request.scopeId,
      actionType: 'REVOKE',
      message: 'Thu hồi vai trò thành công',
    );
  }

  static String _findMemberName(String memberId) {
    for (final m in _mockOverview.members) {
      if (m.memberId == memberId) return m.fullName;
    }
    return 'Thành viên $memberId';
  }
}

final roleRemoteDataSourceProvider = Provider<RoleRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return RoleRemoteDataSource(dio);
});
