/// Model thông tin hồ sơ cá nhân của thành viên từ Backend API (US-22).
class UserProfileDto {
  final String accountId;
  final String? memberId;
  final String? clanId;
  final String? accountStatus;
  final List<String> roles;

  // Nhóm thông tin liên lạc (cho phép chỉnh sửa)
  final String phoneNumber;
  final String? email;
  final String? address;

  // Nhóm thông tin phả hệ nhân khẩu (chỉ xem - read only)
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final int? generation;
  final String? branchId;
  final String? branchName;

  const UserProfileDto({
    required this.accountId,
    this.memberId,
    this.clanId,
    this.accountStatus,
    this.roles = const [],
    required this.phoneNumber,
    this.email,
    this.address,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.generation,
    this.branchId,
    this.branchName,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      accountId: json['accountId']?.toString() ?? '',
      memberId: json['memberId']?.toString(),
      clanId: json['clanId']?.toString(),
      accountStatus: json['accountStatus']?.toString(),
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      fullName: json['fullName']?.toString(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      gender: json['gender']?.toString(),
      generation: (json['generation'] as num?)?.toInt(),
      branchId: json['branchId']?.toString(),
      branchName: json['branchName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'memberId': memberId,
      'clanId': clanId,
      'accountStatus': accountStatus,
      'roles': roles,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth?.toIso8601String().split('T').first,
      'gender': gender,
      'generation': generation,
      'branchId': branchId,
      'branchName': branchName,
    };
  }

  UserProfileDto copyWith({
    String? accountId,
    String? memberId,
    String? clanId,
    String? accountStatus,
    List<String>? roles,
    String? phoneNumber,
    String? email,
    String? address,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    int? generation,
    String? branchId,
    String? branchName,
  }) {
    return UserProfileDto(
      accountId: accountId ?? this.accountId,
      memberId: memberId ?? this.memberId,
      clanId: clanId ?? this.clanId,
      accountStatus: accountStatus ?? this.accountStatus,
      roles: roles ?? this.roles,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      generation: generation ?? this.generation,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
    );
  }
}

/// Request DTO cập nhật thông tin liên lạc cá nhân (US-22).
/// Cố tình không cho phép sửa full_name, date_of_birth, generation.
class UpdateContactProfileRequestDto {
  final String phoneNumber;
  final String? email;
  final String? address;

  const UpdateContactProfileRequestDto({
    required this.phoneNumber,
    this.email,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber.trim(),
      'email': email?.trim(),
      'address': address?.trim(),
    };
  }
}

/// Request DTO đổi mật khẩu đăng nhập cá nhân (US-22).
class ChangePasswordRequestDto {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}
