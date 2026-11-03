/// Model chi tiết nhánh dòng họ từ Backend API (`BranchDetailResponse`).
class BranchDetailDto {
  final String branchId;
  final String clanId;
  final String clanName;
  final String branchName;
  final int generationLevel;
  final String? parentBranchId;
  final String? representativeId;
  final String? representativeName;
  final String? description;
  final DateTime? createdAt;

  const BranchDetailDto({
    required this.branchId,
    required this.clanId,
    required this.clanName,
    required this.branchName,
    required this.generationLevel,
    this.parentBranchId,
    this.representativeId,
    this.representativeName,
    this.description,
    this.createdAt,
  });

  factory BranchDetailDto.fromJson(Map<String, dynamic> json) {
    return BranchDetailDto(
      branchId: json['branchId']?.toString() ?? '',
      clanId: json['clanId']?.toString() ?? '',
      clanName: json['clanName']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      generationLevel: (json['generationLevel'] as num?)?.toInt() ?? 1,
      parentBranchId: json['parentBranchId']?.toString(),
      representativeId: json['representativeId']?.toString(),
      representativeName: json['representativeName']?.toString(),
      description: json['description']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'clanId': clanId,
      'clanName': clanName,
      'branchName': branchName,
      'generationLevel': generationLevel,
      'parentBranchId': parentBranchId,
      'representativeId': representativeId,
      'representativeName': representativeName,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  BranchDetailDto copyWith({
    String? branchId,
    String? clanId,
    String? clanName,
    String? branchName,
    int? generationLevel,
    String? parentBranchId,
    String? representativeId,
    String? representativeName,
    String? description,
    DateTime? createdAt,
  }) {
    return BranchDetailDto(
      branchId: branchId ?? this.branchId,
      clanId: clanId ?? this.clanId,
      clanName: clanName ?? this.clanName,
      branchName: branchName ?? this.branchName,
      generationLevel: generationLevel ?? this.generationLevel,
      parentBranchId: parentBranchId ?? this.parentBranchId,
      representativeId: representativeId ?? this.representativeId,
      representativeName: representativeName ?? this.representativeName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Request DTO cập nhật thông tin nhánh gốc (`UpdateRootBranchRequest`).
class UpdateRootBranchRequestDto {
  final String branchName;
  final String? description;
  final String? representativeId;

  const UpdateRootBranchRequestDto({
    required this.branchName,
    this.description,
    this.representativeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'branchName': branchName.trim(),
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim()
      else
        'description': null,
      if (representativeId != null && representativeId!.trim().isNotEmpty)
        'representativeId': representativeId!.trim()
      else
        'representativeId': null,
    };
  }
}

/// Model node cây phả hệ (`BranchTreeNodeResponse`).
class BranchTreeNodeDto {
  final String branchId;
  final String clanId;
  final String branchName;
  final String clanName;
  final int generationLevel;
  final String? parentBranchId;
  final String? representativeId;
  final String? representativeName;
  final int memberCount;
  final List<BranchTreeNodeDto> children;

  const BranchTreeNodeDto({
    required this.branchId,
    required this.clanId,
    required this.branchName,
    required this.clanName,
    required this.generationLevel,
    this.parentBranchId,
    this.representativeId,
    this.representativeName,
    required this.memberCount,
    this.children = const [],
  });

  factory BranchTreeNodeDto.fromJson(Map<String, dynamic> json) {
    return BranchTreeNodeDto(
      branchId: json['branchId']?.toString() ?? '',
      clanId: json['clanId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      clanName: json['clanName']?.toString() ?? '',
      generationLevel: (json['generationLevel'] as num?)?.toInt() ?? 1,
      parentBranchId: json['parentBranchId']?.toString(),
      representativeId: json['representativeId']?.toString(),
      representativeName: json['representativeName']?.toString(),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => BranchTreeNodeDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Model thông tin thành viên hiển thị trong bảng sidebar chi nhánh
class BranchMemberItem {
  final String memberId;
  final String fullName;
  final int generation;
  final String? birthDeathInfo;
  final String roleInBranch;
  final String gender;
  final bool isActivated;
  final String? phone;

  const BranchMemberItem({
    required this.memberId,
    required this.fullName,
    required this.generation,
    this.birthDeathInfo,
    required this.roleInBranch,
    this.gender = 'male',
    this.isActivated = true,
    this.phone,
  });
}

/// Model hiển thị thông tin chi tiết một chi/nhánh trên Sidebar / BottomSheet
class BranchUiDetail {
  final String id;
  final String name;
  final String badge;
  final String code;
  final String representative;
  final String representativeSubtext;
  final int memberCount;
  final int activatedMemberCount;
  final String fundAmount;
  final String kycStatus;
  final String description;
  final List<String> successionChain;
  final List<BranchMemberItem> members;
  final bool isRoot;

  const BranchUiDetail({
    required this.id,
    required this.name,
    required this.badge,
    required this.code,
    required this.representative,
    required this.representativeSubtext,
    required this.memberCount,
    required this.activatedMemberCount,
    required this.fundAmount,
    this.kycStatus = 'Đã xác minh KYC 100%',
    required this.description,
    this.successionChain = const [],
    this.members = const [],
    this.isRoot = false,
  });
}
