import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/audit_log_models.dart';

class AuditRemoteDataSource {
  final Dio _dio;

  AuditRemoteDataSource(this._dio);

  static final List<AuditLogItemModel> _mockItems = [
    AuditLogItemModel(
      auditId: 'AUD_01HZX87K91',
      actionType: 'ROLE_ASSIGN',
      entityType: 'ROLE',
      entityId: 'BR_02',
      actorAccountId: 'ACC_01',
      actorFullName: 'Nguyễn Văn Trưởng',
      targetMemberId: 'MEM_08',
      targetMemberFullName: 'Nguyễn Văn Hùng',
      description: 'Bổ nhiệm thành viên Nguyễn Văn Hùng làm Trưởng Chi 2 (ROLE_BRANCH_HEAD) thay cho cụ Nguyễn Văn Đạt',
      ipAddress: '113.190.234.12',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      hasDiff: true,
    ),
    AuditLogItemModel(
      auditId: 'AUD_01HZX78J42',
      actionType: 'BRANCH_JOIN_APPROVE',
      entityType: 'JOIN_REQUEST',
      entityId: 'REQ_902',
      actorAccountId: 'ACC_02',
      actorFullName: 'Nguyễn Văn An',
      targetMemberId: 'MEM_19',
      targetMemberFullName: 'Nguyễn Thị Mai',
      description: 'Duyệt đơn gia nhập dòng họ của Nguyễn Thị Mai vào Chi Phái 1 (Đời 11)',
      ipAddress: '14.232.180.45',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      hasDiff: true,
    ),
    AuditLogItemModel(
      auditId: 'AUD_01HZX65G33',
      actionType: 'BRANCH_UPDATE',
      entityType: 'GENEALOGY_BRANCH',
      entityId: 'BR_03',
      actorAccountId: 'ACC_01',
      actorFullName: 'Nguyễn Văn Trưởng',
      targetMemberId: null,
      targetMemberFullName: null,
      description: 'Cập nhật thông tin chi nhánh: Đổi tên thành "Chi Ất - Nhánh Trưởng Nam" & bổ sung mô tả',
      ipAddress: '113.190.234.12',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      hasDiff: true,
    ),
    AuditLogItemModel(
      auditId: 'AUD_01HZX54D19',
      actionType: 'EVENT_STATUS_CHANGE',
      entityType: 'EVENT',
      entityId: 'EVT_2026_01',
      actorAccountId: 'ACC_01',
      actorFullName: 'Nguyễn Văn Trưởng',
      targetMemberId: null,
      targetMemberFullName: null,
      description: 'Chuyển trạng thái sự kiện "Đại Lễ Giỗ Tổ 2026": Draft → RegistrationOpen (Mở đăng ký)',
      ipAddress: '113.190.234.12',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      hasDiff: true,
    ),
  ];

  static final Map<String, AuditLogDetailModel> _mockDetails = {
    'AUD_01HZX87K91': AuditLogDetailModel(
      auditId: 'AUD_01HZX87K91',
      actionType: 'ROLE_ASSIGN',
      entityType: 'ROLE',
      entityId: 'BR_02',
      actorAccountId: 'ACC_01',
      actorFullName: 'Nguyễn Văn Trưởng',
      targetMemberId: 'MEM_08',
      targetMemberFullName: 'Nguyễn Văn Hùng',
      description: 'Bổ nhiệm thành viên Nguyễn Văn Hùng làm Trưởng Chi 2 thay cho cụ Nguyễn Văn Đạt',
      oldValue: null,
      newValue: {
        'roleCode': 'ROLE_BRANCH_HEAD',
        'scopeType': 'BRANCH',
        'scopeId': 'BR_02',
        'scopeName': 'Chi 2',
        'memberId': 'MEM_08',
        'accountId': 'ACC_08 (Active)',
      },
      ipAddress: '113.190.234.12',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    'AUD_01HZX78J42': AuditLogDetailModel(
      auditId: 'AUD_01HZX78J42',
      actionType: 'BRANCH_JOIN_APPROVE',
      entityType: 'JOIN_REQUEST',
      entityId: 'REQ_902',
      actorAccountId: 'ACC_02',
      actorFullName: 'Nguyễn Văn An',
      targetMemberId: 'MEM_19',
      targetMemberFullName: 'Nguyễn Thị Mai',
      description: 'Duyệt đơn gia nhập dòng họ của Nguyễn Thị Mai vào Chi Phái 1 (Đời 11)',
      oldValue: {
        'requestId': 'REQ_902',
        'status': 'PENDING',
        'branchId': 'BR_01',
        'phone': '0912***888',
        'reviewedBy': null,
      },
      newValue: {
        'requestId': 'REQ_902',
        'status': 'APPROVED',
        'branchId': 'BR_01',
        'phone': '0912***888',
        'reviewedBy': 'ACC_02 (Nguyễn Văn An)',
      },
      ipAddress: '14.232.180.45',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    'AUD_01HZX65G33': AuditLogDetailModel(
      auditId: 'AUD_01HZX65G33',
      actionType: 'BRANCH_UPDATE',
      entityType: 'GENEALOGY_BRANCH',
      entityId: 'BR_03',
      actorAccountId: 'ACC_01',
      actorFullName: 'Nguyễn Văn Trưởng',
      targetMemberId: null,
      targetMemberFullName: null,
      description: 'Cập nhật thông tin chi nhánh: Đổi tên thành "Chi Ất - Nhánh Trưởng Nam" & bổ sung mô tả',
      oldValue: {
        'branchId': 'BR_03',
        'branchName': 'Chi Ất (Cũ)',
        'description': 'Mô tả sơ khai năm 2020',
        'generation': 10,
      },
      newValue: {
        'branchId': 'BR_03',
        'branchName': 'Chi Ất - Nhánh Trưởng Nam',
        'description': 'Nhánh con cụ Nguyễn Văn Phúc, từ đường đặt tại thôn Trung',
        'generation': 10,
      },
      ipAddress: '113.190.234.12',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    'AUD_01HZX54D19': AuditLogDetailModel(
      auditId: 'AUD_01HZX54D19',
      actionType: 'EVENT_STATUS_CHANGE',
      entityType: 'EVENT',
      entityId: 'EVT_2026_01',
      actorAccountId: 'ACC_01',
      actorFullName: 'Nguyễn Văn Trưởng',
      targetMemberId: null,
      targetMemberFullName: null,
      description: 'Chuyển trạng thái sự kiện "Đại Lễ Giỗ Tổ 2026": Draft → RegistrationOpen (Mở đăng ký)',
      oldValue: {
        'eventId': 'EVT_2026_01',
        'title': 'Đại Lễ Giỗ Tổ 2026',
        'status': 'Draft',
        'isLocked': false,
      },
      newValue: {
        'eventId': 'EVT_2026_01',
        'title': 'Đại Lễ Giỗ Tổ 2026',
        'status': 'RegistrationOpen',
        'isLocked': false,
      },
      ipAddress: '113.190.234.12',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  };

  /// Lấy danh sách nhật ký có phân trang và bộ lọc (GET /api/v1/audit-logs)
  Future<AuditLogPageResponse> fetchAuditLogs(AuditLogFilter filter) async {
    try {
      final queryParams = <String, dynamic>{
        'page': filter.page,
        'size': filter.size,
      };

      if (filter.actionType != null && filter.actionType!.isNotEmpty) {
        queryParams['actionType'] = filter.actionType;
      }
      if (filter.entityType != null && filter.entityType!.isNotEmpty) {
        queryParams['entityType'] = filter.entityType;
      }
      if (filter.actorAccountId != null && filter.actorAccountId!.isNotEmpty) {
        queryParams['actorAccountId'] = filter.actorAccountId;
      }

      // Xử lý bộ lọc theo Category
      if (filter.category == AuditCategory.assign) {
        queryParams['entityType'] = 'ROLE';
      } else if (filter.category == AuditCategory.join) {
        queryParams['entityType'] = 'JOIN_REQUEST';
      } else if (filter.category == AuditCategory.genealogy) {
        queryParams['entityType'] = 'GENEALOGY_BRANCH';
      } else if (filter.category == AuditCategory.event) {
        queryParams['entityType'] = 'EVENT';
      }

      final response = await _dio.get('audit-logs', queryParameters: queryParams);
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AuditLogPageResponse.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _buildFilteredMockResponse(filter);
    } on DioException {
      return _buildFilteredMockResponse(filter);
    }
  }

  /// Lấy chi tiết bản ghi kiểm toán kèm Diff (GET /api/v1/audit-logs/{auditId})
  Future<AuditLogDetailModel> fetchAuditLogDetail(String auditId) async {
    try {
      final response = await _dio.get('audit-logs/$auditId');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AuditLogDetailModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _mockDetails[auditId] ?? _mockDetails.values.first;
    } on DioException {
      return _mockDetails[auditId] ?? _mockDetails.values.first;
    }
  }

  AuditLogPageResponse _buildFilteredMockResponse(AuditLogFilter filter) {
    var items = List<AuditLogItemModel>.from(_mockItems);

    if (filter.category == AuditCategory.assign) {
      items = items.where((i) => i.entityType == 'ROLE').toList();
    } else if (filter.category == AuditCategory.join) {
      items = items.where((i) => i.entityType == 'JOIN_REQUEST').toList();
    } else if (filter.category == AuditCategory.genealogy) {
      items = items.where((i) => i.entityType == 'GENEALOGY_BRANCH').toList();
    } else if (filter.category == AuditCategory.event) {
      items = items.where((i) => i.entityType == 'EVENT').toList();
    }

    if (filter.keyword.isNotEmpty) {
      final kw = filter.keyword.toLowerCase();
      items = items.where((i) =>
          (i.actorFullName?.toLowerCase().contains(kw) ?? false) ||
          (i.targetMemberFullName?.toLowerCase().contains(kw) ?? false) ||
          (i.description?.toLowerCase().contains(kw) ?? false) ||
          i.auditId.toLowerCase().contains(kw)).toList();
    }

    return AuditLogPageResponse(
      items: items,
      page: filter.page,
      size: filter.size,
      totalElements: 128,
      totalPages: (128 / filter.size).ceil(),
    );
  }
}

final auditRemoteDataSourceProvider = Provider<AuditRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AuditRemoteDataSource(dio);
});
