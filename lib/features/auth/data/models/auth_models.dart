/// Models phục vụ phân hệ Authentication & Onboarding
class LoginRequestDto {
  final String loginIdentifier;
  final String password;

  const LoginRequestDto({
    required this.loginIdentifier,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'loginIdentifier': loginIdentifier.trim(),
        'password': password.trim(),
      };
}

class RegisterCreatorRequestDto {
  final String clanName;
  final String? ancestorName;
  final String? originLocation;
  final int? establishedYear;
  final String? description;
  final String fullName;
  final String phoneNumber;
  final String password;
  final String gender; // 'Male', 'Female', 'Other'
  final String? email;
  final String? dateOfBirth; // YYYY-MM-DD
  final int generation;

  const RegisterCreatorRequestDto({
    required this.clanName,
    this.ancestorName,
    this.originLocation,
    this.establishedYear,
    this.description,
    required this.fullName,
    required this.phoneNumber,
    required this.password,
    required this.gender,
    this.email,
    this.dateOfBirth,
    this.generation = 1,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'clanName': clanName.trim(),
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'password': password.trim(),
      'gender': gender,
      'generation': generation,
    };
    if (ancestorName != null && ancestorName!.trim().isNotEmpty) {
      map['ancestorName'] = ancestorName!.trim();
    }
    if (originLocation != null && originLocation!.trim().isNotEmpty) {
      map['originLocation'] = originLocation!.trim();
    }
    if (establishedYear != null) {
      map['establishedYear'] = establishedYear;
    }
    if (description != null && description!.trim().isNotEmpty) {
      map['description'] = description!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      map['email'] = email!.trim();
    }
    if (dateOfBirth != null && dateOfBirth!.trim().isNotEmpty) {
      map['dateOfBirth'] = dateOfBirth!.trim();
    }
    return map;
  }
}

enum ProposalType {
  existingBranchLeaf('ExistingBranchLeaf'),
  newChildBranch('NewChildBranch');

  final String value;
  const ProposalType(this.value);

  static ProposalType fromString(String? val) {
    if (val == 'NewChildBranch') return ProposalType.newChildBranch;
    return ProposalType.existingBranchLeaf;
  }
}

enum JoinRequestApprovalStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  final String value;
  const JoinRequestApprovalStatus(this.value);

  static JoinRequestApprovalStatus fromString(String? val) {
    if (val == 'Approved') return JoinRequestApprovalStatus.approved;
    if (val == 'Rejected') return JoinRequestApprovalStatus.rejected;
    return JoinRequestApprovalStatus.pending;
  }
}

class OnboardingBranchTreeNodeDto {
  final String branchId;
  final String clanId;
  final String clanName;
  final String branchName;
  final int? generationLevel;
  final String? parentBranchId;
  final String? representativeName;
  final int memberCount;
  final List<OnboardingBranchTreeNodeDto> children;

  const OnboardingBranchTreeNodeDto({
    required this.branchId,
    required this.clanId,
    required this.clanName,
    required this.branchName,
    this.generationLevel,
    this.parentBranchId,
    this.representativeName,
    this.memberCount = 0,
    this.children = const [],
  });

  factory OnboardingBranchTreeNodeDto.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final List<OnboardingBranchTreeNodeDto> parsedChildren = [];
    if (rawChildren is List) {
      for (final child in rawChildren) {
        if (child is Map<String, dynamic>) {
          parsedChildren.add(OnboardingBranchTreeNodeDto.fromJson(child));
        }
      }
    }

    return OnboardingBranchTreeNodeDto(
      branchId: (json['branchId'] as String?) ?? '',
      clanId: (json['clanId'] as String?) ?? '',
      clanName: (json['clanName'] as String?) ?? '',
      branchName: (json['branchName'] as String?) ?? '',
      generationLevel: (json['generationLevel'] as num?)?.toInt(),
      parentBranchId: json['parentBranchId'] as String?,
      representativeName: json['representativeName'] as String?,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      children: parsedChildren,
    );
  }
}

class RegisterMemberRequestDto {
  final String inviteCode;
  final String fullName;
  final String phoneNumber;
  final String password;
  final String gender;
  final ProposalType proposalType;
  final String targetBranchId;
  final int proposedGeneration;
  final String? proposedNewBranchName;
  final String? relationshipNote;
  final String? dateOfBirth;
  final String? email;

  const RegisterMemberRequestDto({
    required this.inviteCode,
    required this.fullName,
    required this.phoneNumber,
    required this.password,
    required this.gender,
    this.proposalType = ProposalType.existingBranchLeaf,
    required this.targetBranchId,
    this.proposedGeneration = 1,
    this.proposedNewBranchName,
    this.relationshipNote,
    this.dateOfBirth,
    this.email,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'phoneNumber': phoneNumber.trim(),
      'password': password.trim(),
      'fullName': fullName.trim(),
      'gender': gender,
      'proposalType': proposalType.value,
      'targetBranchId': targetBranchId.trim(),
      'proposedGeneration': proposedGeneration,
    };
    if (proposedNewBranchName != null && proposedNewBranchName!.trim().isNotEmpty) {
      map['proposedNewBranchName'] = proposedNewBranchName!.trim();
    }
    if (relationshipNote != null && relationshipNote!.trim().isNotEmpty) {
      map['relationshipNote'] = relationshipNote!.trim();
    }
    if (dateOfBirth != null && dateOfBirth!.trim().isNotEmpty) {
      map['dateOfBirth'] = dateOfBirth!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      map['email'] = email!.trim();
    }
    return map;
  }
}

class JoinRequestResponseDto {
  final String requestId;
  final String accountId;
  final String clanId;
  final String inviteCode;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String? dateOfBirth;
  final String gender;
  final ProposalType proposalType;
  final String targetBranchId;
  final String? targetBranchName;
  final String? proposedNewBranchName;
  final int proposedGeneration;
  final String? relationshipNote;
  final JoinRequestApprovalStatus approvalStatus;
  final String? reviewedByAccountId;
  final String? rejectionReason;
  final String? createdAt;
  final String? reviewedAt;

  const JoinRequestResponseDto({
    required this.requestId,
    required this.accountId,
    required this.clanId,
    required this.inviteCode,
    required this.fullName,
    this.phoneNumber,
    this.email,
    this.dateOfBirth,
    required this.gender,
    required this.proposalType,
    required this.targetBranchId,
    this.targetBranchName,
    this.proposedNewBranchName,
    required this.proposedGeneration,
    this.relationshipNote,
    required this.approvalStatus,
    this.reviewedByAccountId,
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
  });

  factory JoinRequestResponseDto.fromJson(Map<String, dynamic> json) {
    return JoinRequestResponseDto(
      requestId: (json['requestId'] as String?) ?? '',
      accountId: (json['accountId'] as String?) ?? '',
      clanId: (json['clanId'] as String?) ?? '',
      inviteCode: (json['inviteCode'] as String?) ?? '',
      fullName: (json['fullName'] as String?) ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: (json['gender'] as String?) ?? 'Male',
      proposalType: ProposalType.fromString(json['proposalType'] as String?),
      targetBranchId: (json['targetBranchId'] as String?) ?? '',
      targetBranchName: json['targetBranchName'] as String?,
      proposedNewBranchName: json['proposedNewBranchName'] as String?,
      proposedGeneration: (json['proposedGeneration'] as num?)?.toInt() ?? 1,
      relationshipNote: json['relationshipNote'] as String?,
      approvalStatus: JoinRequestApprovalStatus.fromString(json['approvalStatus'] as String?),
      reviewedByAccountId: json['reviewedByAccountId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
    );
  }
}

class AuthTokenResponseDto {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final String accountId;
  final String phoneNumber;
  final String? email;
  final String fullName;
  final String? clanId;
  final String? memberId;
  final List<String> roles;

  const AuthTokenResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.accountId,
    required this.phoneNumber,
    this.email,
    required this.fullName,
    this.clanId,
    this.memberId,
    required this.roles,
  });

  factory AuthTokenResponseDto.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final List<String> parsedRoles = [];
    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r != null) parsedRoles.add(r.toString());
      }
    }

    return AuthTokenResponseDto(
      accessToken: (json['accessToken'] as String?) ?? '',
      refreshToken: (json['refreshToken'] as String?) ?? '',
      tokenType: (json['tokenType'] as String?) ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 3600,
      accountId: (json['accountId'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      email: json['email'] as String?,
      fullName: (json['fullName'] as String?) ?? '',
      clanId: json['clanId'] as String?,
      memberId: json['memberId'] as String?,
      roles: parsedRoles,
    );
  }
}

class InviteCodePreviewDto {
  final String inviteCode;
  final String? clanId;
  final String? clanName;
  final String? inviteType;
  final String? shareableUrl;
  final String? targetBranchId;
  final String? targetBranchName;
  final String? targetMemberId;
  final int? maxUses;
  final int? usedCount;
  final String? expiresAt;
  final bool isActive;

  const InviteCodePreviewDto({
    required this.inviteCode,
    this.clanId,
    this.clanName,
    this.inviteType,
    this.shareableUrl,
    this.targetBranchId,
    this.targetBranchName,
    this.targetMemberId,
    this.maxUses,
    this.usedCount,
    this.expiresAt,
    this.isActive = true,
  });

  factory InviteCodePreviewDto.fromJson(Map<String, dynamic> json) {
    return InviteCodePreviewDto(
      inviteCode: (json['inviteCode'] as String?) ?? '',
      clanId: json['clanId'] as String?,
      clanName: json['clanName'] as String?,
      inviteType: json['inviteType'] as String?,
      shareableUrl: json['shareableUrl'] as String?,
      targetBranchId: json['targetBranchId'] as String?,
      targetBranchName: json['targetBranchName'] as String?,
      targetMemberId: json['targetMemberId'] as String?,
      maxUses: (json['maxUses'] as num?)?.toInt(),
      usedCount: (json['usedCount'] as num?)?.toInt(),
      expiresAt: json['expiresAt'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }
}
