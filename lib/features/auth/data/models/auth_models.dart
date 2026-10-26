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

class RegisterMemberRequestDto {
  final String inviteCode;
  final String fullName;
  final String phoneNumber;
  final String password;
  final String gender;
  final String? dateOfBirth;
  final String? email;

  const RegisterMemberRequestDto({
    required this.inviteCode,
    required this.fullName,
    required this.phoneNumber,
    required this.password,
    required this.gender,
    this.dateOfBirth,
    this.email,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'inviteCode': inviteCode.trim(),
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'password': password.trim(),
      'gender': gender,
    };
    if (dateOfBirth != null && dateOfBirth!.trim().isNotEmpty) {
      map['dateOfBirth'] = dateOfBirth!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) {
      map['email'] = email!.trim();
    }
    return map;
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
  final String? inviteType;
  final String? shareableUrl;
  final String? targetBranchId;
  final String? targetMemberId;
  final int? maxUses;
  final int? usedCount;
  final String? expiresAt;
  final bool isActive;

  const InviteCodePreviewDto({
    required this.inviteCode,
    this.clanId,
    this.inviteType,
    this.shareableUrl,
    this.targetBranchId,
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
      inviteType: json['inviteType'] as String?,
      shareableUrl: json['shareableUrl'] as String?,
      targetBranchId: json['targetBranchId'] as String?,
      targetMemberId: json['targetMemberId'] as String?,
      maxUses: (json['maxUses'] as num?)?.toInt(),
      usedCount: (json['usedCount'] as num?)?.toInt(),
      expiresAt: json['expiresAt'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }
}
