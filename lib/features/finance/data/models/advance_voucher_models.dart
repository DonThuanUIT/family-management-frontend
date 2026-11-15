import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';

/// Trạng thái phiếu tạm ứng sự kiện theo backend Flyway V25 và enum `AdvanceVoucherStatus`.
enum AdvanceVoucherStatusEnum {
  choGiaoTien('ChoGiaoTien', 'Chờ giao tiền'),
  chuaTatToan('ChuaTatToan', 'Chưa tất toán'),
  daTatToan('DaTatToan', 'Đã tất toán'),
  daHuy('DaHuy', 'Đã hủy');

  final String code;
  final String displayName;

  const AdvanceVoucherStatusEnum(this.code, this.displayName);

  static AdvanceVoucherStatusEnum fromCode(String? code) {
    if (code == null) return AdvanceVoucherStatusEnum.choGiaoTien;
    return AdvanceVoucherStatusEnum.values.firstWhere(
      (e) => e.code.toLowerCase() == code.toLowerCase(),
      orElse: () => AdvanceVoucherStatusEnum.choGiaoTien,
    );
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case AdvanceVoucherStatusEnum.choGiaoTien:
        return const Color(0xFFFEF3C7); // Hổ phách nhạt
      case AdvanceVoucherStatusEnum.chuaTatToan:
        return const Color(0xFFE0F2FE); // Xanh dương nhạt
      case AdvanceVoucherStatusEnum.daTatToan:
        return const Color(0xFFDCFCE7); // Xanh lá nhạt
      case AdvanceVoucherStatusEnum.daHuy:
        return const Color(0xFFF3F4F6); // Xám
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case AdvanceVoucherStatusEnum.choGiaoTien:
        return const Color(0xFFB45309);
      case AdvanceVoucherStatusEnum.chuaTatToan:
        return const Color(0xFF0369A1);
      case AdvanceVoucherStatusEnum.daTatToan:
        return const Color(0xFF15803D);
      case AdvanceVoucherStatusEnum.daHuy:
        return const Color(0xFF4B5563);
    }
  }

  Color get badgeBorderColor {
    switch (this) {
      case AdvanceVoucherStatusEnum.choGiaoTien:
        return const Color(0xFFF59E0B);
      case AdvanceVoucherStatusEnum.chuaTatToan:
        return const Color(0xFF38BDF8);
      case AdvanceVoucherStatusEnum.daTatToan:
        return const Color(0xFF4ADE80);
      case AdvanceVoucherStatusEnum.daHuy:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData get icon {
    switch (this) {
      case AdvanceVoucherStatusEnum.choGiaoTien:
        return Icons.hourglass_top_rounded;
      case AdvanceVoucherStatusEnum.chuaTatToan:
        return Icons.paid_outlined;
      case AdvanceVoucherStatusEnum.daTatToan:
        return Icons.check_circle_outline_rounded;
      case AdvanceVoucherStatusEnum.daHuy:
        return Icons.cancel_outlined;
    }
  }
}

/// DTO / Entity biểu diễn Phiếu tạm ứng sự kiện (US-46).
@immutable
class AdvanceVoucherModel {
  final String advanceVoucherId;
  final String taskId;
  final String? taskName;
  final String recipientMemberId;
  final String? recipientMemberName;
  final int advanceAmount; // Đơn vị: VNĐ (int)
  final AdvanceVoucherStatusEnum status;
  final DateTime receivedDate;
  final DateTime settlementDeadline;
  final String? commitmentNotes;
  final String? treasurerAccountId;
  final DateTime? disbursedAt;
  final String? disbursementNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AdvanceVoucherModel({
    required this.advanceVoucherId,
    required this.taskId,
    this.taskName,
    required this.recipientMemberId,
    this.recipientMemberName,
    required this.advanceAmount,
    required this.status,
    required this.receivedDate,
    required this.settlementDeadline,
    this.commitmentNotes,
    this.treasurerAccountId,
    this.disbursedAt,
    this.disbursementNotes,
    required this.createdAt,
    this.updatedAt,
  });

  String get formattedAdvanceAmount => AppFormatters.formatVnd(advanceAmount);

  String get formattedReceivedDate => AppFormatters.formatDate(receivedDate);

  String get formattedSettlementDeadline =>
      AppFormatters.formatDate(settlementDeadline);

  String? get formattedDisbursedAt =>
      disbursedAt != null ? AppFormatters.formatDateTime(disbursedAt!) : null;

  bool get isPendingDisbursement =>
      status == AdvanceVoucherStatusEnum.choGiaoTien;

  bool get isDisbursed => status == AdvanceVoucherStatusEnum.chuaTatToan;

  bool get isSettled => status == AdvanceVoucherStatusEnum.daTatToan;

  bool get isCancelled => status == AdvanceVoucherStatusEnum.daHuy;

  factory AdvanceVoucherModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['advanceAmount'];
    int amountInt = 0;
    if (rawAmount is num) {
      amountInt = rawAmount.round();
    } else if (rawAmount is String) {
      amountInt = (double.tryParse(rawAmount) ?? 0.0).round();
    }

    return AdvanceVoucherModel(
      advanceVoucherId: json['advanceVoucherId'] as String? ??
          json['voucherId'] as String? ??
          '',
      taskId: json['taskId'] as String? ?? '',
      taskName: json['taskName'] as String?,
      recipientMemberId: json['recipientMemberId'] as String? ?? '',
      recipientMemberName: json['recipientMemberName'] as String?,
      advanceAmount: amountInt,
      status: AdvanceVoucherStatusEnum.fromCode(json['status'] as String?),
      receivedDate: json['receivedDate'] != null
          ? DateTime.tryParse(json['receivedDate'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      settlementDeadline: json['settlementDeadline'] != null
          ? DateTime.tryParse(json['settlementDeadline'].toString())
                  ?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      commitmentNotes: json['commitmentNotes'] as String?,
      treasurerAccountId: json['treasurerAccountId'] as String?,
      disbursedAt: json['disbursedAt'] != null
          ? DateTime.tryParse(json['disbursedAt'].toString())?.toLocal()
          : null,
      disbursementNotes: json['disbursementNotes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'advanceVoucherId': advanceVoucherId,
        'taskId': taskId,
        'taskName': taskName,
        'recipientMemberId': recipientMemberId,
        'recipientMemberName': recipientMemberName,
        'advanceAmount': advanceAmount,
        'status': status.code,
        'receivedDate': receivedDate.toUtc().toIso8601String(),
        'settlementDeadline': settlementDeadline.toUtc().toIso8601String(),
        'commitmentNotes': commitmentNotes,
        'treasurerAccountId': treasurerAccountId,
        'disbursedAt': disbursedAt?.toUtc().toIso8601String(),
        'disbursementNotes': disbursementNotes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt?.toUtc().toIso8601String(),
      };

  AdvanceVoucherModel copyWith({
    String? advanceVoucherId,
    String? taskId,
    String? taskName,
    String? recipientMemberId,
    String? recipientMemberName,
    int? advanceAmount,
    AdvanceVoucherStatusEnum? status,
    DateTime? receivedDate,
    DateTime? settlementDeadline,
    String? commitmentNotes,
    String? treasurerAccountId,
    DateTime? disbursedAt,
    String? disbursementNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdvanceVoucherModel(
      advanceVoucherId: advanceVoucherId ?? this.advanceVoucherId,
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      recipientMemberId: recipientMemberId ?? this.recipientMemberId,
      recipientMemberName: recipientMemberName ?? this.recipientMemberName,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      status: status ?? this.status,
      receivedDate: receivedDate ?? this.receivedDate,
      settlementDeadline: settlementDeadline ?? this.settlementDeadline,
      commitmentNotes: commitmentNotes ?? this.commitmentNotes,
      treasurerAccountId: treasurerAccountId ?? this.treasurerAccountId,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      disbursementNotes: disbursementNotes ?? this.disbursementNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Request DTO lập phiếu tạm ứng mới (`POST /api/v1/advances`).
class CreateAdvanceVoucherRequestDto {
  final String taskId;
  final String recipientMemberId;
  final int advanceAmount; // VNĐ
  final DateTime receivedDate;
  final DateTime settlementDeadline;
  final String? commitmentNotes;

  const CreateAdvanceVoucherRequestDto({
    required this.taskId,
    required this.recipientMemberId,
    required this.advanceAmount,
    required this.receivedDate,
    required this.settlementDeadline,
    this.commitmentNotes,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'taskId': taskId.trim(),
      'recipientMemberId': recipientMemberId.trim(),
      'advanceAmount': advanceAmount,
      'receivedDate': receivedDate.toUtc().toIso8601String(),
      'settlementDeadline': settlementDeadline.toUtc().toIso8601String(),
    };
    if (commitmentNotes != null && commitmentNotes!.trim().isNotEmpty) {
      map['commitmentNotes'] = commitmentNotes!.trim();
    }
    return map;
  }
}

/// Request DTO xác nhận giải ngân cho Thủ quỹ (`POST /api/v1/advances/{id}/disburse`).
class ConfirmDisbursementRequestDto {
  final String? notes;

  const ConfirmDisbursementRequestDto({this.notes});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (notes != null && notes!.trim().isNotEmpty) {
      map['notes'] = notes!.trim();
    }
    return map;
  }
}
