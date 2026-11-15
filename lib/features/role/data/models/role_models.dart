import '../../../../core/utils/formatters.dart';

enum RoleScopeType {
  branch('BRANCH', 'Chi Nhánh'),
  event('EVENT', 'Sự Kiện');

  final String code;
  final String displayName;

  const RoleScopeType(this.code, this.displayName);

  static RoleScopeType fromCode(String? code) {
    if (code == null) return RoleScopeType.branch;
    for (final s in values) {
      if (s.code.toLowerCase() == code.trim().toLowerCase()) return s;
    }
    return RoleScopeType.branch;
  }
}

enum AssignableRoleCode {
  roleBranchHead('ROLE_BRANCH_HEAD', 'Trưởng Chi / Nhánh', RoleScopeType.branch),
  headOfOrganizer('HeadOfOrganizer', 'Trưởng Ban Tổ Chức', RoleScopeType.event),
  organizerMember('OrganizerMember', 'Thành Viên Ban Tổ Chức', RoleScopeType.event),
  eventTreasurer('EventTreasurer', 'Thủ Quỹ Sự Kiện', RoleScopeType.event);

  final String code;
  final String displayName;
  final RoleScopeType supportedScope;

  const AssignableRoleCode(this.code, this.displayName, this.supportedScope);

  static AssignableRoleCode fromCode(String? code) {
    if (code == null) return AssignableRoleCode.organizerMember;
    for (final r in values) {
      if (r.code.toLowerCase() == code.trim().toLowerCase()) return r;
    }
    return AssignableRoleCode.organizerMember;
  }
}

/// DTO tổng quan vai trò Trưởng chi của các nhánh trong gia tộc
class BranchRoleOverviewModel {
  final String branchId;
  final String branchName;
  final int? generationLevel;
  final String? representativeMemberId;
  final String? representativeFullName;
  final String? representativeAccountId;

  const BranchRoleOverviewModel({
    required this.branchId,
    required this.branchName,
    this.generationLevel,
    this.representativeMemberId,
    this.representativeFullName,
    this.representativeAccountId,
  });

  bool get hasRepresentative =>
      representativeMemberId != null && representativeMemberId!.isNotEmpty;

  factory BranchRoleOverviewModel.fromJson(Map<String, dynamic> json) {
    return BranchRoleOverviewModel(
      branchId: json['branchId'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      generationLevel: json['generationLevel'] as int?,
      representativeMemberId: json['representativeMemberId'] as String?,
      representativeFullName: json['representativeFullName'] as String?,
      representativeAccountId: json['representativeAccountId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'branchId': branchId,
        'branchName': branchName,
        'generationLevel': generationLevel,
        'representativeMemberId': representativeMemberId,
        'representativeFullName': representativeFullName,
        'representativeAccountId': representativeAccountId,
      };
}

/// DTO thông tin ứng viên thành viên khi chọn bổ nhiệm
class MemberRoleOptionModel {
  final String memberId;
  final String fullName;
  final String? branchId;
  final String? branchName;
  final bool hasActiveAccount;
  final String? accountId;

  const MemberRoleOptionModel({
    required this.memberId,
    required this.fullName,
    this.branchId,
    this.branchName,
    required this.hasActiveAccount,
    this.accountId,
  });

  factory MemberRoleOptionModel.fromJson(Map<String, dynamic> json) {
    return MemberRoleOptionModel(
      memberId: json['memberId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      hasActiveAccount: json['hasActiveAccount'] as bool? ?? false,
      accountId: json['accountId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'fullName': fullName,
        'branchId': branchId,
        'branchName': branchName,
        'hasActiveAccount': hasActiveAccount,
        'accountId': accountId,
      };
}

/// DTO trả về từ API `GET /api/v1/roles/overview`
class RoleManagementOverviewModel {
  final String clanId;
  final List<BranchRoleOverviewModel> branches;
  final List<MemberRoleOptionModel> members;

  const RoleManagementOverviewModel({
    required this.clanId,
    required this.branches,
    required this.members,
  });

  factory RoleManagementOverviewModel.fromJson(Map<String, dynamic> json) {
    return RoleManagementOverviewModel(
      clanId: json['clanId'] as String? ?? '',
      branches: (json['branches'] as List<dynamic>?)
              ?.map((e) =>
                  BranchRoleOverviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      members: (json['members'] as List<dynamic>?)
              ?.map((e) =>
                  MemberRoleOptionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'clanId': clanId,
        'branches': branches.map((e) => e.toJson()).toList(),
        'members': members.map((e) => e.toJson()).toList(),
      };
}

/// Model nhật ký kiểm toán (Audit Log) từ `GET /api/v1/roles/audit-logs`
class AuditLogModel {
  final String auditId;
  final String clanId;
  final String? actorAccountId;
  final String actorFullName;
  final String? targetMemberId;
  final String targetFullName;
  final String? targetAccountId;
  final String actionType; // ASSIGN hoặc REVOKE
  final String roleCode;
  final String roleDisplayName;
  final String scopeType; // BRANCH hoặc EVENT
  final String scopeId;
  final String? scopeName;
  final String? description;
  final DateTime? createdAt;

  const AuditLogModel({
    required this.auditId,
    required this.clanId,
    this.actorAccountId,
    required this.actorFullName,
    this.targetMemberId,
    required this.targetFullName,
    this.targetAccountId,
    required this.actionType,
    required this.roleCode,
    required this.roleDisplayName,
    required this.scopeType,
    required this.scopeId,
    this.scopeName,
    this.description,
    this.createdAt,
  });

  bool get isAssign => actionType.toUpperCase() == 'ASSIGN';
  bool get isRevoke => actionType.toUpperCase() == 'REVOKE';

  String get formattedCreatedAt {
    if (createdAt == null) return 'Vừa xong';
    return AppFormatters.formatDateTime(createdAt!);
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        parsedDate = DateTime.tryParse(json['createdAt'] as String);
      }
    }

    return AuditLogModel(
      auditId: json['auditId'] as String? ?? '',
      clanId: json['clanId'] as String? ?? '',
      actorAccountId: json['actorAccountId'] as String?,
      actorFullName: json['actorFullName'] as String? ?? 'Quản trị viên',
      targetMemberId: json['targetMemberId'] as String?,
      targetFullName: json['targetFullName'] as String? ?? 'Thành viên',
      targetAccountId: json['targetAccountId'] as String?,
      actionType: json['actionType'] as String? ?? 'ASSIGN',
      roleCode: json['roleCode'] as String? ?? '',
      roleDisplayName: json['roleDisplayName'] as String? ?? '',
      scopeType: json['scopeType'] as String? ?? 'BRANCH',
      scopeId: json['scopeId'] as String? ?? '',
      scopeName: json['scopeName'] as String?,
      description: json['description'] as String?,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'auditId': auditId,
        'clanId': clanId,
        'actorAccountId': actorAccountId,
        'actorFullName': actorFullName,
        'targetMemberId': targetMemberId,
        'targetFullName': targetFullName,
        'targetAccountId': targetAccountId,
        'actionType': actionType,
        'roleCode': roleCode,
        'roleDisplayName': roleDisplayName,
        'scopeType': scopeType,
        'scopeId': scopeId,
        'scopeName': scopeName,
        'description': description,
        'createdAt': createdAt?.toIso8601String(),
      };
}

/// Request DTO gọi `POST /api/v1/roles/assign`
class RoleAssignmentRequestDto {
  final String memberId;
  final String roleCode;
  final String scopeType;
  final String scopeId;
  final String? description;

  const RoleAssignmentRequestDto({
    required this.memberId,
    required this.roleCode,
    required this.scopeType,
    required this.scopeId,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'roleCode': roleCode,
        'scopeType': scopeType,
        'scopeId': scopeId,
        if (description != null && description!.isNotEmpty)
          'description': description,
      };
}

/// Request DTO gọi `POST /api/v1/roles/revoke`
class RoleRevocationRequestDto {
  final String memberId;
  final String roleCode;
  final String scopeType;
  final String scopeId;
  final String? reason;

  const RoleRevocationRequestDto({
    required this.memberId,
    required this.roleCode,
    required this.scopeType,
    required this.scopeId,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'roleCode': roleCode,
        'scopeType': scopeType,
        'scopeId': scopeId,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
      };
}

/// Response DTO từ các endpoint assign / revoke
class RoleAssignmentResponseDto {
  final String memberId;
  final String roleCode;
  final String scopeType;
  final String scopeId;
  final String actionType;
  final String? message;

  const RoleAssignmentResponseDto({
    required this.memberId,
    required this.roleCode,
    required this.scopeType,
    required this.scopeId,
    required this.actionType,
    this.message,
  });

  factory RoleAssignmentResponseDto.fromJson(Map<String, dynamic> json) {
    return RoleAssignmentResponseDto(
      memberId: json['memberId'] as String? ?? '',
      roleCode: json['roleCode'] as String? ?? '',
      scopeType: json['scopeType'] as String? ?? '',
      scopeId: json['scopeId'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      message: json['message'] as String?,
    );
  }
}
