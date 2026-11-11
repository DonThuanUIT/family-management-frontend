/// Model cấu hình quyền riêng tư cá nhân của thành viên từ Backend API (US-25).
class MemberPrivacySettingDto {
  final String memberId;
  final bool shareDateOfBirth;
  final bool sharePhoneNumber;
  final bool shareEmail;
  final DateTime? updatedAt;

  const MemberPrivacySettingDto({
    required this.memberId,
    required this.shareDateOfBirth,
    required this.sharePhoneNumber,
    required this.shareEmail,
    this.updatedAt,
  });

  factory MemberPrivacySettingDto.fromJson(Map<String, dynamic> json) {
    return MemberPrivacySettingDto(
      memberId: json['memberId']?.toString() ?? '',
      shareDateOfBirth: json['shareDateOfBirth'] == true,
      sharePhoneNumber: json['sharePhoneNumber'] == true,
      shareEmail: json['shareEmail'] == true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'shareDateOfBirth': shareDateOfBirth,
      'sharePhoneNumber': sharePhoneNumber,
      'shareEmail': shareEmail,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  MemberPrivacySettingDto copyWith({
    String? memberId,
    bool? shareDateOfBirth,
    bool? sharePhoneNumber,
    bool? shareEmail,
    DateTime? updatedAt,
  }) {
    return MemberPrivacySettingDto(
      memberId: memberId ?? this.memberId,
      shareDateOfBirth: shareDateOfBirth ?? this.shareDateOfBirth,
      sharePhoneNumber: sharePhoneNumber ?? this.sharePhoneNumber,
      shareEmail: shareEmail ?? this.shareEmail,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Request DTO cập nhật cấu hình quyền riêng tư cá nhân (US-25).
class UpdateMemberPrivacySettingRequestDto {
  final bool shareDateOfBirth;
  final bool sharePhoneNumber;
  final bool shareEmail;

  const UpdateMemberPrivacySettingRequestDto({
    required this.shareDateOfBirth,
    required this.sharePhoneNumber,
    required this.shareEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'shareDateOfBirth': shareDateOfBirth,
      'sharePhoneNumber': sharePhoneNumber,
      'shareEmail': shareEmail,
    };
  }
}
