import 'package:flutter/foundation.dart';

/// Request DTO để gọi POST /api/v1/branches/{branchId}/virtual-members (US-18).
class CreateVirtualMemberRequestDto {
  final String fullName;
  final String? dateOfBirth; // YYYY-MM-DD
  final String gender; // 'Male', 'Female', 'Other'
  final int generation;
  final String? status; // 'Living', 'Deceased'
  final String? deathDateLunar;
  final int? validityDays; // 1..365

  const CreateVirtualMemberRequestDto({
    required this.fullName,
    this.dateOfBirth,
    this.gender = 'Male',
    required this.generation,
    this.status = 'Living',
    this.deathDateLunar,
    this.validityDays = 14,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'fullName': fullName,
      'gender': gender,
      'generation': generation,
      'status': status ?? 'Living',
    };
    if (dateOfBirth != null && dateOfBirth!.isNotEmpty) {
      map['dateOfBirth'] = dateOfBirth;
    }
    if (deathDateLunar != null && deathDateLunar!.isNotEmpty) {
      map['deathDateLunar'] = deathDateLunar;
    }
    if (validityDays != null) {
      map['validityDays'] = validityDays;
    }
    return map;
  }
}

/// DTO thông tin thành viên ảo vừa được tạo (VirtualMemberDto)
class VirtualMemberDto {
  final String memberId;
  final String fullName;
  final String? dateOfBirth;
  final String gender;
  final int generation;
  final String status;
  final String? deathDateLunar;
  final String branchId;
  final String branchName;
  final String clanId;
  final bool isPlaceholder;
  final String? createdAt;

  const VirtualMemberDto({
    required this.memberId,
    required this.fullName,
    this.dateOfBirth,
    required this.gender,
    required this.generation,
    required this.status,
    this.deathDateLunar,
    required this.branchId,
    required this.branchName,
    required this.clanId,
    required this.isPlaceholder,
    this.createdAt,
  });

  factory VirtualMemberDto.fromJson(Map<String, dynamic> json) {
    return VirtualMemberDto(
      memberId: (json['memberId'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: (json['gender'] as String?) ?? 'Male',
      generation: (json['generation'] as num?)?.toInt() ?? 1,
      status: (json['status'] as String?) ?? 'Living',
      deathDateLunar: json['deathDateLunar'] as String?,
      branchId: (json['branchId'] as String?) ?? '',
      branchName: (json['branchName'] as String?) ?? '',
      clanId: (json['clanId'] as String?) ?? '',
      isPlaceholder: (json['isPlaceholder'] as bool?) ?? true,
      createdAt: json['createdAt'] as String?,
    );
  }
}

/// DTO chi tiết mã liên kết vị trí (PositionLinkCode)
class PositionLinkCodeDto {
  final String inviteCode;
  final String clanId;
  final String? clanName;
  final String? inviteType;
  final String shareableUrl;
  final String targetBranchId;
  final String? targetBranchName;
  final String targetMemberId;
  final int maxUses;
  final int usedCount;
  final String? expiresAt;
  final bool isActive;
  final String? createdByAccountId;
  final String? createdAt;

  const PositionLinkCodeDto({
    required this.inviteCode,
    required this.clanId,
    this.clanName,
    this.inviteType,
    required this.shareableUrl,
    required this.targetBranchId,
    this.targetBranchName,
    required this.targetMemberId,
    this.maxUses = 1,
    this.usedCount = 0,
    this.expiresAt,
    this.isActive = true,
    this.createdByAccountId,
    this.createdAt,
  });

  factory PositionLinkCodeDto.fromJson(Map<String, dynamic> json) {
    return PositionLinkCodeDto(
      inviteCode: (json['inviteCode'] as String?) ?? '',
      clanId: (json['clanId'] as String?) ?? '',
      clanName: json['clanName'] as String?,
      inviteType: json['inviteType'] as String?,
      shareableUrl: (json['shareableUrl'] as String?) ?? '',
      targetBranchId: (json['targetBranchId'] as String?) ?? '',
      targetBranchName: json['targetBranchName'] as String?,
      targetMemberId: (json['targetMemberId'] as String?) ?? '',
      maxUses: (json['maxUses'] as num?)?.toInt() ?? 1,
      usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      expiresAt: json['expiresAt'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      createdByAccountId: json['createdByAccountId'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

/// Response payload từ POST /api/v1/branches/{branchId}/virtual-members (US-18)
class CreateVirtualMemberResponseDto {
  final VirtualMemberDto member;
  final PositionLinkCodeDto positionLinkCode;

  const CreateVirtualMemberResponseDto({
    required this.member,
    required this.positionLinkCode,
  });

  factory CreateVirtualMemberResponseDto.fromJson(Map<String, dynamic> json) {
    return CreateVirtualMemberResponseDto(
      member: VirtualMemberDto.fromJson(
        (json['member'] as Map<String, dynamic>?) ?? {},
      ),
      positionLinkCode: PositionLinkCodeDto.fromJson(
        (json['positionLinkCode'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

/// Model hiển thị trên bảng/danh sách mã đã cấp phát (UI Model)
@immutable
class PositionLinkItemModel {
  final String code;
  final String branchId;
  final String branchName;
  final int generation;
  final String fullName;
  final String issuedBy;
  final DateTime createdAt;
  final bool isActivated;
  final String shareableUrl;
  final String? targetMemberId;

  const PositionLinkItemModel({
    required this.code,
    required this.branchId,
    required this.branchName,
    required this.generation,
    required this.fullName,
    required this.issuedBy,
    required this.createdAt,
    required this.isActivated,
    required this.shareableUrl,
    this.targetMemberId,
  });

  PositionLinkItemModel copyWith({
    String? code,
    String? branchId,
    String? branchName,
    int? generation,
    String? fullName,
    String? issuedBy,
    DateTime? createdAt,
    bool? isActivated,
    String? shareableUrl,
    String? targetMemberId,
  }) {
    return PositionLinkItemModel(
      code: code ?? this.code,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      generation: generation ?? this.generation,
      fullName: fullName ?? this.fullName,
      issuedBy: issuedBy ?? this.issuedBy,
      createdAt: createdAt ?? this.createdAt,
      isActivated: isActivated ?? this.isActivated,
      shareableUrl: shareableUrl ?? this.shareableUrl,
      targetMemberId: targetMemberId ?? this.targetMemberId,
    );
  }
}
