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
  final String? email;
  final bool isDateOfBirthRestricted;
  final bool isPhoneRestricted;
  final bool isEmailRestricted;
  final String status;
  final DateTime? dateOfBirth;
  final DateTime? deathDate;
  final String? deathDateLunar;
  final String? burialPlace;

  bool get isDeceased => status.toLowerCase() == 'deceased';

  const BranchMemberItem({
    required this.memberId,
    required this.fullName,
    required this.generation,
    this.birthDeathInfo,
    required this.roleInBranch,
    this.gender = 'male',
    this.isActivated = true,
    this.phone,
    this.email,
    this.isDateOfBirthRestricted = false,
    this.isPhoneRestricted = false,
    this.isEmailRestricted = false,
    this.status = 'Living',
    this.dateOfBirth,
    this.deathDate,
    this.deathDateLunar,
    this.burialPlace,
  });

  factory BranchMemberItem.fromJson(Map<String, dynamic> json) {
    final dob = json['dateOfBirth']?.toString();
    final status = json['status']?.toString();
    final deathLunar = json['deathDateLunar']?.toString();
    final isLiving = status != 'Deceased';

    final fieldVisibility = json['fieldVisibility'] as Map<String, dynamic>?;
    final isDobRestricted = fieldVisibility != null &&
        fieldVisibility['dateOfBirth']?.toString() == 'RESTRICTED';
    final isPhoneRestricted = fieldVisibility != null &&
        fieldVisibility['phoneNumber']?.toString() == 'RESTRICTED';
    final isEmailRestricted = fieldVisibility != null &&
        fieldVisibility['email']?.toString() == 'RESTRICTED';

    String? birthDeath;
    if (isDobRestricted) {
      birthDeath = 'Ngày sinh riêng tư';
    } else if (dob != null && dob.isNotEmpty) {
      final year = dob.split('-').first;
      if (isLiving) {
        birthDeath = 'Sinh $year';
      } else {
        birthDeath = 'Năm sinh: $year${deathLunar != null ? ' • Mất: $deathLunar' : ''}';
      }
    }

    final gen = (json['generation'] as num?)?.toInt() ?? 1;
    final isPlaceholder = json['isPlaceholder'] == true;
    final phone = json['phoneNumber']?.toString();
    final email = json['email']?.toString();
    final deathDate = json['deathDate'] != null ? DateTime.tryParse(json['deathDate'].toString()) : null;
    final dateOfBirth = dob != null ? DateTime.tryParse(dob) : null;
    final burialPlace = json['burialPlace']?.toString();

    return BranchMemberItem(
      memberId: json['memberId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      generation: gen,
      birthDeathInfo: birthDeath,
      roleInBranch: gen == 1 ? 'Khởi Tổ / Trưởng Tộc' : 'Đời $gen',
      gender: (json['gender']?.toString().toLowerCase() == 'female') ? 'female' : 'male',
      isActivated: !isPlaceholder,
      phone: phone,
      email: email,
      isDateOfBirthRestricted: isDobRestricted,
      isPhoneRestricted: isPhoneRestricted,
      isEmailRestricted: isEmailRestricted,
      status: status ?? 'Living',
      dateOfBirth: dateOfBirth,
      deathDate: deathDate,
      deathDateLunar: deathLunar,
      burialPlace: burialPlace,
    );
  }
}

/// Model hiển thị thông tin chi tiết một chi/nhánh trên Sidebar / BottomSheet
class BranchUiDetail {
  final String id;
  final String name;
  final String badge;
  final String code;
  final String representative;
  final String representativeSubtext;
  final String? representativeId;
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
    this.representativeId,
    required this.memberCount,
    required this.activatedMemberCount,
    required this.fundAmount,
    this.kycStatus = 'Đã xác minh KYC 100%',
    required this.description,
    this.successionChain = const [],
    this.members = const [],
    this.isRoot = false,
  });

  BranchUiDetail copyWith({
    String? id,
    String? name,
    String? badge,
    String? code,
    String? representative,
    String? representativeSubtext,
    String? representativeId,
    int? memberCount,
    int? activatedMemberCount,
    String? fundAmount,
    String? kycStatus,
    String? description,
    List<String>? successionChain,
    List<BranchMemberItem>? members,
    bool? isRoot,
  }) {
    return BranchUiDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      badge: badge ?? this.badge,
      code: code ?? this.code,
      representative: representative ?? this.representative,
      representativeSubtext: representativeSubtext ?? this.representativeSubtext,
      representativeId: representativeId ?? this.representativeId,
      memberCount: memberCount ?? this.memberCount,
      activatedMemberCount: activatedMemberCount ?? this.activatedMemberCount,
      fundAmount: fundAmount ?? this.fundAmount,
      kycStatus: kycStatus ?? this.kycStatus,
      description: description ?? this.description,
      successionChain: successionChain ?? this.successionChain,
      members: members ?? this.members,
      isRoot: isRoot ?? this.isRoot,
    );
  }

  factory BranchUiDetail.fromTreeNode(
    BranchTreeNodeDto node, {
    List<BranchMemberItem> members = const [],
    String? description,
  }) {
    final isRoot = node.parentBranchId == null || node.generationLevel == 1;
    final repName = node.representativeName ?? 'Chưa cập nhật';
    return BranchUiDetail(
      id: node.branchId,
      name: node.branchName,
      badge: isRoot ? 'KHỞI TỔ • ĐỜI 1' : 'CHI ĐỜI ${node.generationLevel}',
      code: node.branchId,
      representative: repName,
      representativeSubtext: isRoot
          ? 'Trưởng Tộc • Đại diện Dòng họ'
          : 'Đại diện Chi • Đời ${node.generationLevel}',
      representativeId: node.representativeId,
      memberCount: node.memberCount,
      activatedMemberCount: members.where((m) => m.isActivated).isNotEmpty
          ? members.where((m) => m.isActivated).length
          : node.memberCount,
      fundAmount: '0 đ',
      description: description ?? (isRoot
          ? 'Chi nhánh gốc khởi lập gia phả dòng họ.'
          : 'Chi nhánh trực thuộc phả hệ dòng họ.'),
      successionChain: [repName],
      members: members,
      isRoot: isRoot,
    );
  }
}

/// Payload yêu cầu cập nhật tình trạng sinh/tử (US-27)
class UpdateLifeStatusRequestDto {
  final String status;
  final DateTime? deathDate;
  final String? burialPlace;

  const UpdateLifeStatusRequestDto({
    required this.status,
    this.deathDate,
    this.burialPlace,
  });

  bool get isDeceased => status.toLowerCase() == 'deceased';

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'deathDate': deathDate != null
          ? '${deathDate!.year.toString().padLeft(4, '0')}-${deathDate!.month.toString().padLeft(2, '0')}-${deathDate!.day.toString().padLeft(2, '0')}'
          : null,
      'burialPlace': burialPlace,
    };
  }
}
