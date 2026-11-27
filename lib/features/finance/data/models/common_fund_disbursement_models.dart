import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import 'ledger_adjustment_models.dart';

/// Danh mục khoản chi Quỹ chung cho việc lớn (`CommonFundExpenseCategory`, US-60).
enum CommonFundExpenseCategoryEnum {
  templeMaintenance(
    'TempleMaintenance',
    'Tu sửa Từ đường',
    'Bảo trì nhà thờ, ngói, gỗ lim',
    'Khảo sát hạng mục xuống cấp; lập dự toán tu sửa Từ đường và biên bản họp Ban Thường Trực.',
  ),
  reliefSupport(
    'ReliefSupport',
    'Cứu trợ / Thăm hỏi',
    'Hỗ trợ con cháu gặp khó khăn',
    'Thăm hỏi, hỗ trợ khẩn cấp gia đình thành viên dòng họ gặp thiên tai hoặc ốm đau nặng.',
  ),
  scholarship(
    'Scholarship',
    'Quỹ Khuyến học',
    'Khen thưởng học sinh, sinh viên',
    'Chi trao thưởng khuyến học & khuyến tài cho con cháu đạt thành tích xuất sắc năm học.',
  ),
  ceremony(
    'Ceremony',
    'Đại lễ dòng họ',
    'Giỗ Tổ, lễ hội cấp Thủy tộc',
    'Chi tổ chức nghi lễ Đại lễ Giỗ Tổ Xuân cấp Thủy tộc và đón tiếp con cháu về dâng hương.',
  ),
  other(
    'Other',
    'Chi lớn khác',
    'Hoạt động trọng đại hợp lệ',
    'Chi phí thực hiện việc lớn chung của dòng họ đã được Ban Thường Trực rà soát dự toán.',
  );

  final String code;
  final String displayName;
  final String shortDescription;
  final String purposeSuggestion;

  const CommonFundExpenseCategoryEnum(
    this.code,
    this.displayName,
    this.shortDescription,
    this.purposeSuggestion,
  );

  static CommonFundExpenseCategoryEnum fromCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return CommonFundExpenseCategoryEnum.other;
    }
    final normalized = code.trim().toLowerCase();
    for (final value in CommonFundExpenseCategoryEnum.values) {
      if (value.code.toLowerCase() == normalized) {
        return value;
      }
    }
    return CommonFundExpenseCategoryEnum.other;
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case CommonFundExpenseCategoryEnum.templeMaintenance:
        return const Color(0xFFFDF2F2);
      case CommonFundExpenseCategoryEnum.reliefSupport:
        return const Color(0xFFECFDF5);
      case CommonFundExpenseCategoryEnum.scholarship:
        return const Color(0xFFFFFBEB);
      case CommonFundExpenseCategoryEnum.ceremony:
        return const Color(0xFFFDF2F2);
      case CommonFundExpenseCategoryEnum.other:
        return const Color(0xFFF4F3F1);
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case CommonFundExpenseCategoryEnum.templeMaintenance:
        return const Color(0xFF8B1E1E);
      case CommonFundExpenseCategoryEnum.reliefSupport:
        return const Color(0xFF0F766E);
      case CommonFundExpenseCategoryEnum.scholarship:
        return const Color(0xFFB8860B);
      case CommonFundExpenseCategoryEnum.ceremony:
        return const Color(0xFF6A020A);
      case CommonFundExpenseCategoryEnum.other:
        return const Color(0xFF58413F);
    }
  }

  Color get badgeBorderColor {
    switch (this) {
      case CommonFundExpenseCategoryEnum.templeMaintenance:
        return const Color(0xFFFECACA);
      case CommonFundExpenseCategoryEnum.reliefSupport:
        return const Color(0xFF99F6E4);
      case CommonFundExpenseCategoryEnum.scholarship:
        return const Color(0xFFFDE68A);
      case CommonFundExpenseCategoryEnum.ceremony:
        return const Color(0xFFFECACA);
      case CommonFundExpenseCategoryEnum.other:
        return const Color(0xFFDFD8D0);
    }
  }

  IconData get iconData {
    switch (this) {
      case CommonFundExpenseCategoryEnum.templeMaintenance:
        return Icons.temple_buddhist_outlined;
      case CommonFundExpenseCategoryEnum.reliefSupport:
        return Icons.volunteer_activism_outlined;
      case CommonFundExpenseCategoryEnum.scholarship:
        return Icons.school_outlined;
      case CommonFundExpenseCategoryEnum.ceremony:
        return Icons.celebration_outlined;
      case CommonFundExpenseCategoryEnum.other:
        return Icons.receipt_long_outlined;
    }
  }
}

/// Trạng thái phê duyệt của Đề xuất chi Quỹ chung (`CommonFundDisbursementStatus`, US-60).
enum CommonFundDisbursementStatusEnum {
  pending('Pending', 'Chờ Trưởng tộc duyệt'),
  approved('Approved', 'Đã ký duyệt & Ghi sổ cái'),
  rejected('Rejected', 'Bị từ chối');

  final String code;
  final String displayName;

  const CommonFundDisbursementStatusEnum(this.code, this.displayName);

  static CommonFundDisbursementStatusEnum fromCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return CommonFundDisbursementStatusEnum.pending;
    }
    final normalized = code.trim().toLowerCase();
    for (final value in CommonFundDisbursementStatusEnum.values) {
      if (value.code.toLowerCase() == normalized) {
        return value;
      }
    }
    return CommonFundDisbursementStatusEnum.pending;
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case CommonFundDisbursementStatusEnum.pending:
        return const Color(0xFFFFFBEB);
      case CommonFundDisbursementStatusEnum.approved:
        return const Color(0xFFECFDF5);
      case CommonFundDisbursementStatusEnum.rejected:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case CommonFundDisbursementStatusEnum.pending:
        return const Color(0xFFB8860B);
      case CommonFundDisbursementStatusEnum.approved:
        return const Color(0xFF0F766E);
      case CommonFundDisbursementStatusEnum.rejected:
        return const Color(0xFFBA1A1A);
    }
  }

  Color get badgeBorderColor {
    switch (this) {
      case CommonFundDisbursementStatusEnum.pending:
        return const Color(0xFFFDE68A);
      case CommonFundDisbursementStatusEnum.approved:
        return const Color(0xFF99F6E4);
      case CommonFundDisbursementStatusEnum.rejected:
        return const Color(0xFFFECACA);
    }
  }
}

double _parseDisbAmount(dynamic raw) {
  if (raw == null) return 0.0;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim()) ?? 0.0;
  return 0.0;
}

DateTime _parseDisbDateTime(dynamic raw) {
  if (raw is DateTime) return raw;
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim()) ?? DateTime.now();
  }
  return DateTime.now();
}

DateTime? _parseDisbNullableDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim());
  }
  return null;
}

/// Snapshot số dư Quỹ chung hiện tại (`CommonFundBalanceResponse`, `GET /api/v1/ledger/balance`).
@immutable
class CommonFundBalanceModel {
  final String clanId;
  final double availableBalance;
  final double pendingDisbursementAmount;
  final String? latestTransactionId;
  final DateTime? latestTransactionAt;

  const CommonFundBalanceModel({
    required this.clanId,
    required this.availableBalance,
    required this.pendingDisbursementAmount,
    this.latestTransactionId,
    this.latestTransactionAt,
  });

  double get freeBalanceAfterPending =>
      availableBalance - pendingDisbursementAmount;

  CommonFundBalanceModel copyWith({
    String? clanId,
    double? availableBalance,
    double? pendingDisbursementAmount,
    String? latestTransactionId,
    DateTime? latestTransactionAt,
  }) {
    return CommonFundBalanceModel(
      clanId: clanId ?? this.clanId,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingDisbursementAmount:
          pendingDisbursementAmount ?? this.pendingDisbursementAmount,
      latestTransactionId: latestTransactionId ?? this.latestTransactionId,
      latestTransactionAt: latestTransactionAt ?? this.latestTransactionAt,
    );
  }

  factory CommonFundBalanceModel.fromJson(Map<String, dynamic> json) {
    return CommonFundBalanceModel(
      clanId: json['clanId'] as String? ?? '',
      availableBalance: _parseDisbAmount(json['availableBalance']),
      pendingDisbursementAmount:
          _parseDisbAmount(json['pendingDisbursementAmount']),
      latestTransactionId: json['latestTransactionId'] as String?,
      latestTransactionAt:
          _parseDisbNullableDateTime(json['latestTransactionAt']),
    );
  }
}

/// Payload gửi `POST /api/v1/ledger/disbursements` (`ProposeCommonFundDisbursementRequest`, US-60).
@immutable
class ProposeCommonFundDisbursementRequestDto {
  final String title;
  final CommonFundExpenseCategoryEnum category;
  final double amount;
  final String? beneficiaryName;
  final String? beneficiaryMemberId;
  final String purpose;
  final String? attachmentUrl;

  const ProposeCommonFundDisbursementRequestDto({
    required this.title,
    required this.category,
    required this.amount,
    this.beneficiaryName,
    this.beneficiaryMemberId,
    required this.purpose,
    this.attachmentUrl,
  });

  Map<String, dynamic> toJson() {
    final trimmedBeneficiary = beneficiaryName?.trim();
    final trimmedMemberId = beneficiaryMemberId?.trim();
    final trimmedAttachment = attachmentUrl?.trim();
    return {
      'title': title.trim(),
      'category': category.code,
      'amount': amount,
      if (trimmedBeneficiary != null && trimmedBeneficiary.isNotEmpty)
        'beneficiaryName': trimmedBeneficiary,
      if (trimmedMemberId != null && trimmedMemberId.isNotEmpty)
        'beneficiaryMemberId': trimmedMemberId,
      'purpose': purpose.trim(),
      if (trimmedAttachment != null && trimmedAttachment.isNotEmpty)
        'attachmentUrl': trimmedAttachment,
    };
  }
}

/// Payload gửi `POST /api/v1/ledger/disbursements/{requestId}/review` (`ReviewCommonFundDisbursementRequest`, US-60).
@immutable
class ReviewCommonFundDisbursementRequestDto {
  final String requestId;
  final bool approved;
  final String? confirmPassword;
  final String? rejectionReason;
  final String? description;

  const ReviewCommonFundDisbursementRequestDto({
    required this.requestId,
    required this.approved,
    this.confirmPassword,
    this.rejectionReason,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final trimmedPassword = confirmPassword?.trim();
    final trimmedReason = rejectionReason?.trim();
    final trimmedDesc = description?.trim();
    return {
      'requestId': requestId.trim(),
      'approved': approved,
      if (trimmedPassword != null && trimmedPassword.isNotEmpty)
        'confirmPassword': trimmedPassword,
      if (trimmedReason != null && trimmedReason.isNotEmpty)
        'rejectionReason': trimmedReason,
      if (trimmedDesc != null && trimmedDesc.isNotEmpty)
        'description': trimmedDesc,
    };
  }
}

/// Chi tiết đề xuất chi Quỹ chung (`CommonFundDisbursementResponse`, US-60).
@immutable
class CommonFundDisbursementModel {
  final String requestId;
  final String clanId;
  final String title;
  final CommonFundExpenseCategoryEnum category;
  final double amount;
  final String? beneficiaryName;
  final String? beneficiaryMemberId;
  final String purpose;
  final String? attachmentUrl;
  final String proposedByAccountId;
  final CommonFundDisbursementStatusEnum approvalStatus;
  final String? reviewedByAccountId;
  final String? rejectionReason;
  final String? ledgerTransactionId;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const CommonFundDisbursementModel({
    required this.requestId,
    required this.clanId,
    required this.title,
    required this.category,
    required this.amount,
    this.beneficiaryName,
    this.beneficiaryMemberId,
    required this.purpose,
    this.attachmentUrl,
    required this.proposedByAccountId,
    required this.approvalStatus,
    this.reviewedByAccountId,
    this.rejectionReason,
    this.ledgerTransactionId,
    required this.createdAt,
    this.reviewedAt,
  });

  String get formattedCreatedAt =>
      AppFormatters.formatDateTime(createdAt.toLocal());

  String? get formattedReviewedAt => reviewedAt != null
      ? AppFormatters.formatDateTime(reviewedAt!.toLocal())
      : null;

  factory CommonFundDisbursementModel.fromJson(Map<String, dynamic> json) {
    return CommonFundDisbursementModel(
      requestId: json['requestId'] as String? ?? '',
      clanId: json['clanId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category:
          CommonFundExpenseCategoryEnum.fromCode(json['category'] as String?),
      amount: _parseDisbAmount(json['amount']),
      beneficiaryName: json['beneficiaryName'] as String?,
      beneficiaryMemberId: json['beneficiaryMemberId'] as String?,
      purpose: json['purpose'] as String? ?? '',
      attachmentUrl: json['attachmentUrl'] as String?,
      proposedByAccountId: json['proposedByAccountId'] as String? ?? '',
      approvalStatus: CommonFundDisbursementStatusEnum.fromCode(
        json['approvalStatus'] as String?,
      ),
      reviewedByAccountId: json['reviewedByAccountId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      ledgerTransactionId: json['ledgerTransactionId'] as String?,
      createdAt: _parseDisbDateTime(json['createdAt']),
      reviewedAt: _parseDisbNullableDateTime(json['reviewedAt']),
    );
  }
}

/// Phản hồi sau khi Trưởng tộc / Admin ký duyệt hoặc từ chối (`ReviewCommonFundDisbursementResponse`, US-60).
@immutable
class ReviewCommonFundDisbursementResponseModel {
  final CommonFundDisbursementModel disbursementRequest;
  final ImmutableLedgerEntryModel? ledgerEntry;

  const ReviewCommonFundDisbursementResponseModel({
    required this.disbursementRequest,
    this.ledgerEntry,
  });

  factory ReviewCommonFundDisbursementResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final reqJson = json['disbursementRequest'] is Map<String, dynamic>
        ? json['disbursementRequest'] as Map<String, dynamic>
        : <String, dynamic>{};
    final entryJson = json['ledgerEntry'] is Map<String, dynamic>
        ? json['ledgerEntry'] as Map<String, dynamic>
        : null;
    return ReviewCommonFundDisbursementResponseModel(
      disbursementRequest: CommonFundDisbursementModel.fromJson(reqJson),
      ledgerEntry: entryJson != null
          ? ImmutableLedgerEntryModel.fromJson(entryJson)
          : null,
    );
  }
}
