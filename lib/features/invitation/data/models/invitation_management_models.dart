import 'package:flutter/material.dart';

/// Trạng thái vòng đời của mã mời (US-34 & US-16 & US-18)
enum InvitationCodeStatus {
  active(
    'Hoạt Động',
    Color(0xFF006E2A),
    Color(0xFFE8F5E9),
    Icons.check_circle_outline,
  ),
  usedUp(
    'Đã Dùng Hết',
    Color(0xFF4A148C),
    Color(0xFFF3E5F5),
    Icons.done_all_rounded,
  ),
  expired(
    'Hết Hạn',
    Color(0xFF7A5900),
    Color(0xFFFFF4D3),
    Icons.alarm_off_rounded,
  ),
  revoked(
    'Đã Thu Hồi',
    Color(0xFFBA1A1A),
    Color(0xFFFFDAD6),
    Icons.cancel_outlined,
  );

  final String label;
  final Color textColor;
  final Color bgColor;
  final IconData icon;

  const InvitationCodeStatus(this.label, this.textColor, this.bgColor, this.icon);
}

/// DTO tạo mã mời chung dòng họ hoặc chi nhánh (US-16 & US-34)
class CreateGeneralInviteRequestDto {
  final String? targetBranchId;
  final int maxUses;
  final int validityDays;
  final DateTime? expiresAt;

  const CreateGeneralInviteRequestDto({
    this.targetBranchId,
    this.maxUses = 10,
    this.validityDays = 30,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'maxUses': maxUses,
      'validityDays': validityDays,
    };
    if (targetBranchId != null && targetBranchId!.trim().isNotEmpty) {
      map['targetBranchId'] = targetBranchId!.trim();
    }
    if (expiresAt != null) {
      map['expiresAt'] = expiresAt!.toUtc().toIso8601String();
    }
    return map;
  }
}

/// DTO gia hạn hoặc cập nhật mã mời (US-34 & US-16)
class UpdateInvitationRequestDto {
  final bool? isActive;
  final int? validityDays;
  final int? maxUses;
  final DateTime? expiresAt;

  const UpdateInvitationRequestDto({
    this.isActive,
    this.validityDays,
    this.maxUses,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (isActive != null) {
      map['isActive'] = isActive;
    }
    if (validityDays != null) {
      map['validityDays'] = validityDays;
    }
    if (maxUses != null) {
      map['maxUses'] = maxUses;
    }
    if (expiresAt != null) {
      map['expiresAt'] = expiresAt!.toUtc().toIso8601String();
    }
    return map;
  }
}
