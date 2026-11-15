import 'package:flutter/material.dart';

/// Danh mục nhóm thao tác cho Quick Filter Pills
enum AuditCategory {
  all('ALL', 'Tất cả', Icons.list_alt),
  assign('ASSIGN', 'Phân quyền & Thu hồi', Icons.key),
  join('JOIN', 'Duyệt đơn gia nhập', Icons.person_add_alt_1),
  genealogy('GENEALOGY', 'Sửa Cây gia phả', Icons.park_outlined),
  event('EVENT', 'Thay đổi sự kiện', Icons.celebration_outlined);

  final String code;
  final String label;
  final IconData icon;

  const AuditCategory(this.code, this.label, this.icon);
}

/// DTO một dòng tóm tắt nhật ký kiểm toán (GET /api/v1/audit-logs)
class AuditLogItemModel {
  final String auditId;
  final String actionType;
  final String entityType;
  final String? entityId;
  final String? actorAccountId;
  final String? actorFullName;
  final String? targetMemberId;
  final String? targetMemberFullName;
  final String? description;
  final String? ipAddress;
  final DateTime createdAt;
  final bool hasDiff;

  const AuditLogItemModel({
    required this.auditId,
    required this.actionType,
    required this.entityType,
    this.entityId,
    this.actorAccountId,
    this.actorFullName,
    this.targetMemberId,
    this.targetMemberFullName,
    this.description,
    this.ipAddress,
    required this.createdAt,
    required this.hasDiff,
  });

  factory AuditLogItemModel.fromJson(Map<String, dynamic> json) {
    return AuditLogItemModel(
      auditId: json['auditId'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String?,
      actorAccountId: json['actorAccountId'] as String?,
      actorFullName: json['actorFullName'] as String?,
      targetMemberId: json['targetMemberId'] as String?,
      targetMemberFullName: json['targetMemberFullName'] as String?,
      description: json['description'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      hasDiff: json['hasDiff'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'auditId': auditId,
        'actionType': actionType,
        'entityType': entityType,
        'entityId': entityId,
        'actorAccountId': actorAccountId,
        'actorFullName': actorFullName,
        'targetMemberId': targetMemberId,
        'targetMemberFullName': targetMemberFullName,
        'description': description,
        'ipAddress': ipAddress,
        'createdAt': createdAt.toIso8601String(),
        'hasDiff': hasDiff,
      };

  /// Tên hiển thị hành động tiếng Việt thân thiện
  String get actionDisplayName {
    switch (actionType) {
      case 'ROLE_ASSIGN':
      case 'ASSIGN':
        return 'PHÂN QUYỀN';
      case 'ROLE_REVOKE':
      case 'REVOKE':
        return 'THU HỒI QUYỀN';
      case 'BRANCH_JOIN_APPROVE':
      case 'JOIN_APPROVE':
      case 'APPROVE':
        return 'PHÊ DUYỆT';
      case 'BRANCH_JOIN_REJECT':
      case 'JOIN_REJECT':
      case 'REJECT':
        return 'TỪ CHỐI';
      case 'BRANCH_CREATE':
      case 'MEMBER_CREATE':
      case 'EVENT_CREATE':
      case 'CREATE':
        return 'TẠO MỚI';
      case 'BRANCH_UPDATE':
      case 'UPDATE':
        return 'CẬP NHẬT CÂY';
      case 'BRANCH_DELETE':
      case 'DELETE':
        return 'XÓA BỎ';
      case 'EVENT_STATUS_CHANGE':
      case 'STATUS_CHANGE':
        return 'TRẠNG THÁI SK';
      case 'EVENT_PERSONNEL_ASSIGN':
        return 'PHÂN CÔNG SK';
      default:
        return actionType;
    }
  }

  /// Màu sắc ngữ nghĩa theo DESIGN.md
  Color get actionColor {
    switch (actionType) {
      case 'ROLE_ASSIGN':
      case 'ASSIGN':
      case 'BRANCH_JOIN_APPROVE':
      case 'APPROVE':
        return const Color(0xFF1B873F); // Success
      case 'ROLE_REVOKE':
      case 'REVOKE':
      case 'BRANCH_JOIN_REJECT':
      case 'REJECT':
        return const Color(0xFFD32F2F); // Danger
      case 'BRANCH_UPDATE':
      case 'UPDATE':
        return const Color(0xFFE67E22); // Warning
      case 'EVENT_STATUS_CHANGE':
      case 'STATUS_CHANGE':
        return const Color(0xFF7C3AED); // Event purple
      default:
        return const Color(0xFF0F766E); // Ledger Teal
    }
  }

  /// Tên loại đối tượng tiếng Việt
  String get entityTypeDisplayName {
    switch (entityType) {
      case 'ROLE':
        return 'VAI TRÒ';
      case 'JOIN_REQUEST':
        return 'ĐƠN GIA NHẬP';
      case 'GENEALOGY_BRANCH':
      case 'BRANCH':
        return 'CHI NHÁNH';
      case 'MEMBER':
        return 'THÀNH VIÊN';
      case 'EVENT':
        return 'SỰ KIỆN';
      case 'EVENT_PERSONNEL':
        return 'NHÂN SỰ';
      default:
        return entityType;
    }
  }
}

/// DTO chi tiết bản ghi kiểm toán kèm Diff (GET /api/v1/audit-logs/{auditId})
class AuditLogDetailModel {
  final String auditId;
  final String actionType;
  final String entityType;
  final String? entityId;
  final String? actorAccountId;
  final String? actorFullName;
  final String? targetMemberId;
  final String? targetMemberFullName;
  final String? description;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String? ipAddress;
  final DateTime createdAt;

  const AuditLogDetailModel({
    required this.auditId,
    required this.actionType,
    required this.entityType,
    this.entityId,
    this.actorAccountId,
    this.actorFullName,
    this.targetMemberId,
    this.targetMemberFullName,
    this.description,
    this.oldValue,
    this.newValue,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLogDetailModel.fromJson(Map<String, dynamic> json) {
    return AuditLogDetailModel(
      auditId: json['auditId'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String?,
      actorAccountId: json['actorAccountId'] as String?,
      actorFullName: json['actorFullName'] as String?,
      targetMemberId: json['targetMemberId'] as String?,
      targetMemberFullName: json['targetMemberFullName'] as String?,
      description: json['description'] as String?,
      oldValue: json['oldValue'] as Map<String, dynamic>?,
      newValue: json['newValue'] as Map<String, dynamic>?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Trích xuất danh sách tất cả các trường dữ liệu để so sánh Diff trực quan
  List<DiffFieldComparison> get diffFields {
    final fields = <String>{};
    if (oldValue != null) fields.addAll(oldValue!.keys);
    if (newValue != null) fields.addAll(newValue!.keys);

    final result = <DiffFieldComparison>[];
    for (final field in fields) {
      final oldVal = oldValue?[field];
      final newVal = newValue?[field];
      result.add(DiffFieldComparison(
        fieldKey: field,
        oldValue: oldVal,
        newValue: newVal,
      ));
    }
    return result;
  }
}

/// Mô hình so sánh từng trường dữ liệu Cũ - Mới
class DiffFieldComparison {
  final String fieldKey;
  final dynamic oldValue;
  final dynamic newValue;

  const DiffFieldComparison({
    required this.fieldKey,
    required this.oldValue,
    required this.newValue,
  });

  bool get isAdded => oldValue == null && newValue != null;
  bool get isRemoved => oldValue != null && newValue == null;
  bool get isModified => oldValue != null && newValue != null && oldValue.toString() != newValue.toString();
  bool get isUnchanged => oldValue.toString() == newValue.toString();

  /// Tên nhãn tiếng Việt dễ hiểu cho các bô lão
  String get labelDisplayName {
    switch (fieldKey) {
      case 'roleCode':
        return 'Mã vai trò (roleCode)';
      case 'roleName':
      case 'roleDisplayName':
        return 'Tên chức vụ / vai trò';
      case 'scopeType':
        return 'Cấp độ phân quyền (scopeType)';
      case 'scopeId':
        return 'Mã chi / sự kiện (scopeId)';
      case 'scopeName':
        return 'Tên chi / sự kiện được phân công';
      case 'accountId':
        return 'Mã tài khoản (accountId)';
      case 'memberId':
        return 'Mã thành viên gia phả';
      case 'fullName':
        return 'Họ và tên thành viên';
      case 'approvalStatus':
      case 'status':
        return 'Trạng thái xét duyệt / Vòng đời';
      case 'branchName':
        return 'Tên chi nhánh gia phả';
      case 'branchDescription':
      case 'description':
        return 'Mô tả chi tiết / Nghị quyết';
      case 'eventName':
      case 'title':
        return 'Tiêu đề sự kiện';
      case 'eventDate':
      case 'startDate':
        return 'Thời gian tổ chức lễ';
      default:
        return fieldKey;
    }
  }
}

/// DTO phân trang từ Backend (PageResponse)
class AuditLogPageResponse {
  final List<AuditLogItemModel> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const AuditLogPageResponse({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory AuditLogPageResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return AuditLogPageResponse(
      items: rawItems
          .map((e) => AuditLogItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? rawItems.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Bộ lọc tìm kiếm nhật ký
class AuditLogFilter {
  final AuditCategory category;
  final String? actionType;
  final String? entityType;
  final String? actorAccountId;
  final String datePreset;
  final String keyword;
  final int page;
  final int size;

  const AuditLogFilter({
    this.category = AuditCategory.all,
    this.actionType,
    this.entityType,
    this.actorAccountId,
    this.datePreset = '7_days',
    this.keyword = '',
    this.page = 0,
    this.size = 20,
  });

  AuditLogFilter copyWith({
    AuditCategory? category,
    String? actionType,
    String? entityType,
    String? actorAccountId,
    String? datePreset,
    String? keyword,
    int? page,
    int? size,
  }) {
    return AuditLogFilter(
      category: category ?? this.category,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      actorAccountId: actorAccountId ?? this.actorAccountId,
      datePreset: datePreset ?? this.datePreset,
      keyword: keyword ?? this.keyword,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }
}
