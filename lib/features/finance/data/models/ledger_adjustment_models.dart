import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/vietnamese_lunar_calendar.dart';

/// Loại giao dịch trong Sổ cái Quỹ chung bất biến (NFR-01 / US-15 / US-60 / US-62).
enum LedgerTransactionTypeEnum {
  surplusTransfer('SurplusTransfer', 'Chuyển thặng dư'),
  commonFundDisbursement('CommonFundDisbursement', 'Chi quỹ chung'),
  adjustmentTransaction('AdjustmentTransaction', 'Bút toán bù trừ'),
  openingBalanceCarryForward('OpeningBalanceCarryForward', 'Kết chuyển đầu kỳ');

  final String code;
  final String displayName;

  const LedgerTransactionTypeEnum(this.code, this.displayName);

  static LedgerTransactionTypeEnum fromCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return LedgerTransactionTypeEnum.surplusTransfer;
    }
    final normalized = code.trim().toLowerCase();
    for (final value in LedgerTransactionTypeEnum.values) {
      if (value.code.toLowerCase() == normalized) {
        return value;
      }
    }
    return LedgerTransactionTypeEnum.surplusTransfer;
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case LedgerTransactionTypeEnum.surplusTransfer:
        return const Color(0xFFECFDF5);
      case LedgerTransactionTypeEnum.commonFundDisbursement:
        return const Color(0xFFFEF2F2);
      case LedgerTransactionTypeEnum.adjustmentTransaction:
        return const Color(0xFFFFFBEB);
      case LedgerTransactionTypeEnum.openingBalanceCarryForward:
        return const Color(0xFFF4F3F1);
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case LedgerTransactionTypeEnum.surplusTransfer:
        return const Color(0xFF0F766E);
      case LedgerTransactionTypeEnum.commonFundDisbursement:
        return const Color(0xFFBA1A1A);
      case LedgerTransactionTypeEnum.adjustmentTransaction:
        return const Color(0xFFB8860B);
      case LedgerTransactionTypeEnum.openingBalanceCarryForward:
        return const Color(0xFF58413F);
    }
  }

  Color get badgeBorderColor {
    switch (this) {
      case LedgerTransactionTypeEnum.surplusTransfer:
        return const Color(0xFF99F6E4);
      case LedgerTransactionTypeEnum.commonFundDisbursement:
        return const Color(0xFFFECACA);
      case LedgerTransactionTypeEnum.adjustmentTransaction:
        return const Color(0xFFFDE68A);
      case LedgerTransactionTypeEnum.openingBalanceCarryForward:
        return const Color(0xFFDFD8D0);
    }
  }
}

/// Trạng thái phê duyệt của Đề xuất điều chỉnh Sổ cái (US-15 / US-59).
enum LedgerAdjustmentStatusEnum {
  pending('Pending', 'Chờ Trưởng tộc duyệt'),
  approved('Approved', 'Đã duyệt & Ghi sổ cái'),
  rejected('Rejected', 'Bị từ chối');

  final String code;
  final String displayName;

  const LedgerAdjustmentStatusEnum(this.code, this.displayName);

  static LedgerAdjustmentStatusEnum fromCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return LedgerAdjustmentStatusEnum.pending;
    }
    final normalized = code.trim().toLowerCase();
    for (final value in LedgerAdjustmentStatusEnum.values) {
      if (value.code.toLowerCase() == normalized) {
        return value;
      }
    }
    return LedgerAdjustmentStatusEnum.pending;
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case LedgerAdjustmentStatusEnum.pending:
        return const Color(0xFFFFFBEB);
      case LedgerAdjustmentStatusEnum.approved:
        return const Color(0xFFECFDF5);
      case LedgerAdjustmentStatusEnum.rejected:
        return const Color(0xFFFEF2F2);
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case LedgerAdjustmentStatusEnum.pending:
        return const Color(0xFFB8860B);
      case LedgerAdjustmentStatusEnum.approved:
        return const Color(0xFF0F766E);
      case LedgerAdjustmentStatusEnum.rejected:
        return const Color(0xFFBA1A1A);
    }
  }

  Color get badgeBorderColor {
    switch (this) {
      case LedgerAdjustmentStatusEnum.pending:
        return const Color(0xFFFDE68A);
      case LedgerAdjustmentStatusEnum.approved:
        return const Color(0xFF99F6E4);
      case LedgerAdjustmentStatusEnum.rejected:
        return const Color(0xFFFECACA);
    }
  }
}

double _parseAmount(dynamic raw) {
  if (raw == null) return 0.0;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw.trim()) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic raw, [int fallback = 0]) {
  if (raw == null) return fallback;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
  return fallback;
}

DateTime _parseDateTime(dynamic raw) {
  if (raw is DateTime) return raw;
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim()) ?? DateTime.now();
  }
  return DateTime.now();
}

DateTime? _parseNullableDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim());
  }
  return null;
}

String formatSignedLedgerVnd(double amount) {
  if (amount > 0) return '+${AppFormatters.formatVnd(amount)}';
  if (amount < 0) return '−${AppFormatters.formatVnd(amount.abs())}';
  return AppFormatters.formatVnd(0);
}

/// Giao dịch liên kết hai chiều trong Sổ cái Quỹ chung (`LinkedLedgerTransactionDto`).
@immutable
class LinkedLedgerTransactionModel {
  final String transactionId;
  final LedgerTransactionTypeEnum transactionType;
  final double amount;
  final double runningBalance;
  final String description;
  final String? adjustmentRequestId;
  final String? adjustmentReason;
  final String? evidenceAttachmentUrl;
  final String? createdByName;
  final String? approvedByName;
  final DateTime createdAt;

  const LinkedLedgerTransactionModel({
    required this.transactionId,
    required this.transactionType,
    required this.amount,
    required this.runningBalance,
    required this.description,
    this.adjustmentRequestId,
    this.adjustmentReason,
    this.evidenceAttachmentUrl,
    this.createdByName,
    this.approvedByName,
    required this.createdAt,
  });

  factory LinkedLedgerTransactionModel.fromJson(Map<String, dynamic> json) {
    return LinkedLedgerTransactionModel(
      transactionId: json['transactionId'] as String? ?? '',
      transactionType:
          LedgerTransactionTypeEnum.fromCode(json['transactionType'] as String?),
      amount: _parseAmount(json['amount']),
      runningBalance: _parseAmount(json['runningBalance']),
      description: json['description'] as String? ?? '',
      adjustmentRequestId: json['adjustmentRequestId'] as String?,
      adjustmentReason: json['adjustmentReason'] as String?,
      evidenceAttachmentUrl: json['evidenceAttachmentUrl'] as String?,
      createdByName: json['createdByName'] as String?,
      approvedByName: json['approvedByName'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

/// Một bút toán trong lịch sử Sổ cái Quỹ chung bất biến (`LedgerHistoryItemResponse`).
@immutable
class LedgerHistoryItemModel {
  final String transactionId;
  final String clanId;
  final String? eventId;
  final String? eventName;
  final String? adjustmentRequestId;
  final String? adjustmentReason;
  final String? evidenceAttachmentUrl;
  final String? disbursementRequestId;
  final String? disbursementTitle;
  final String? originalTransactionId;
  final LedgerTransactionTypeEnum transactionType;
  final double amount;
  final double runningBalance;
  final String description;
  final String createdByAccountId;
  final String? createdByName;
  final String approvedByAccountId;
  final String? approvedByName;
  final String previousHash;
  final String recordHash;
  final DateTime createdAt;
  final bool isAdjustment;
  final bool hasAdjustments;
  final int adjustmentCount;
  final double netAdjustedAmount;
  final int pendingAdjustmentRequestCount;
  final LinkedLedgerTransactionModel? originalTransaction;
  final List<LinkedLedgerTransactionModel> adjustmentTransactions;

  const LedgerHistoryItemModel({
    required this.transactionId,
    required this.clanId,
    this.eventId,
    this.eventName,
    this.adjustmentRequestId,
    this.adjustmentReason,
    this.evidenceAttachmentUrl,
    this.disbursementRequestId,
    this.disbursementTitle,
    this.originalTransactionId,
    required this.transactionType,
    required this.amount,
    required this.runningBalance,
    required this.description,
    this.createdByAccountId = '',
    this.createdByName,
    this.approvedByAccountId = '',
    this.approvedByName,
    this.previousHash = '',
    this.recordHash = '',
    required this.createdAt,
    this.isAdjustment = false,
    this.hasAdjustments = false,
    this.adjustmentCount = 0,
    required this.netAdjustedAmount,
    this.pendingAdjustmentRequestCount = 0,
    this.originalTransaction,
    this.adjustmentTransactions = const [],
  });

  /// Ràng buộc US-15: Khóa không cho tạo đề xuất thứ 2 nếu giao dịch gốc đang có đề xuất Pending.
  bool get isLockedByPendingAdjustment => pendingAdjustmentRequestCount > 0;

  String get formattedSolarDate => AppFormatters.formatDate(createdAt.toLocal());

  String get formattedLunarDate {
    final lunar =
        VietnameseLunarCalendar.convertSolarToLunar(createdAt.toLocal());
    return '${lunar.toShortAnniversaryString()} ÂL';
  }

  factory LedgerHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final amountVal = _parseAmount(json['amount']);
    final adjListRaw = json['adjustmentTransactions'];
    return LedgerHistoryItemModel(
      transactionId: json['transactionId'] as String? ?? '',
      clanId: json['clanId'] as String? ?? '',
      eventId: json['eventId'] as String?,
      eventName: json['eventName'] as String?,
      adjustmentRequestId: json['adjustmentRequestId'] as String?,
      adjustmentReason: json['adjustmentReason'] as String?,
      evidenceAttachmentUrl: json['evidenceAttachmentUrl'] as String?,
      disbursementRequestId: json['disbursementRequestId'] as String?,
      disbursementTitle: json['disbursementTitle'] as String?,
      originalTransactionId: json['originalTransactionId'] as String?,
      transactionType:
          LedgerTransactionTypeEnum.fromCode(json['transactionType'] as String?),
      amount: amountVal,
      runningBalance: _parseAmount(json['runningBalance']),
      description: json['description'] as String? ?? '',
      createdByAccountId: json['createdByAccountId'] as String? ?? '',
      createdByName: json['createdByName'] as String?,
      approvedByAccountId: json['approvedByAccountId'] as String? ?? '',
      approvedByName: json['approvedByName'] as String?,
      previousHash: json['previousHash'] as String? ?? '',
      recordHash: json['recordHash'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      isAdjustment: json['isAdjustment'] == true,
      hasAdjustments: json['hasAdjustments'] == true,
      adjustmentCount: _parseInt(json['adjustmentCount']),
      netAdjustedAmount: json['netAdjustedAmount'] != null
          ? _parseAmount(json['netAdjustedAmount'])
          : amountVal,
      pendingAdjustmentRequestCount:
          _parseInt(json['pendingAdjustmentRequestCount']),
      originalTransaction: json['originalTransaction'] is Map<String, dynamic>
          ? LinkedLedgerTransactionModel.fromJson(
              json['originalTransaction'] as Map<String, dynamic>,
            )
          : null,
      adjustmentTransactions: adjListRaw is List
          ? adjListRaw
              .whereType<Map<String, dynamic>>()
              .map(LinkedLedgerTransactionModel.fromJson)
              .toList()
          : const [],
    );
  }
}

/// Tổng hợp số dư Quỹ chung & dòng tiền kỳ lọc (`LedgerFlowSummaryResponse`).
@immutable
class LedgerFlowSummaryModel {
  final double currentFundBalance;
  final String? latestTransactionId;
  final DateTime? latestTransactionAt;
  final double openingBalanceBeforePeriod;
  final double closingBalanceAtPeriodEnd;
  final int filteredTransactionCount;
  final double filteredTotalInflow;
  final double filteredTotalOutflow;
  final double filteredNetAmount;

  const LedgerFlowSummaryModel({
    required this.currentFundBalance,
    this.latestTransactionId,
    this.latestTransactionAt,
    this.openingBalanceBeforePeriod = 0,
    this.closingBalanceAtPeriodEnd = 0,
    this.filteredTransactionCount = 0,
    this.filteredTotalInflow = 0,
    this.filteredTotalOutflow = 0,
    this.filteredNetAmount = 0,
  });

  factory LedgerFlowSummaryModel.fromJson(Map<String, dynamic> json) {
    return LedgerFlowSummaryModel(
      currentFundBalance: _parseAmount(json['currentFundBalance']),
      latestTransactionId: json['latestTransactionId'] as String?,
      latestTransactionAt:
          _parseNullableDateTime(json['latestTransactionAt']),
      openingBalanceBeforePeriod:
          _parseAmount(json['openingBalanceBeforePeriod']),
      closingBalanceAtPeriodEnd:
          _parseAmount(json['closingBalanceAtPeriodEnd']),
      filteredTransactionCount: _parseInt(json['filteredTransactionCount']),
      filteredTotalInflow: _parseAmount(json['filteredTotalInflow']),
      filteredTotalOutflow: _parseAmount(json['filteredTotalOutflow']),
      filteredNetAmount: _parseAmount(json['filteredNetAmount']),
    );
  }
}

/// Kết quả phân trang tra cứu Sổ cái Quỹ chung (`LedgerHistoryPageResponse`).
@immutable
class LedgerHistoryPageModel {
  final String clanId;
  final List<LedgerHistoryItemModel> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final LedgerFlowSummaryModel summary;

  const LedgerHistoryPageModel({
    required this.clanId,
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.summary,
  });

  factory LedgerHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return LedgerHistoryPageModel(
      clanId: json['clanId'] as String? ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(LedgerHistoryItemModel.fromJson)
              .toList()
          : const [],
      page: _parseInt(json['page']),
      size: _parseInt(json['size'], 20),
      totalElements: _parseInt(json['totalElements']),
      totalPages: _parseInt(json['totalPages']),
      summary: json['summary'] is Map<String, dynamic>
          ? LedgerFlowSummaryModel.fromJson(
              json['summary'] as Map<String, dynamic>,
            )
          : const LedgerFlowSummaryModel(currentFundBalance: 0),
    );
  }
}

/// Payload gửi `POST /api/v1/ledger/propose-adjustment` (`ProposeLedgerAdjustmentRequest`).
@immutable
class ProposeLedgerAdjustmentRequestDto {
  final String originalTransactionId;
  final double proposedAdjustmentAmount;
  final String adjustmentReason;
  final String? evidenceAttachmentUrl;

  const ProposeLedgerAdjustmentRequestDto({
    required this.originalTransactionId,
    required this.proposedAdjustmentAmount,
    required this.adjustmentReason,
    this.evidenceAttachmentUrl,
  });

  Map<String, dynamic> toJson() {
    final trimmedUrl = evidenceAttachmentUrl?.trim();
    return {
      'originalTransactionId': originalTransactionId.trim(),
      'proposedAdjustmentAmount': proposedAdjustmentAmount,
      'adjustmentReason': adjustmentReason.trim(),
      if (trimmedUrl != null && trimmedUrl.isNotEmpty)
        'evidenceAttachmentUrl': trimmedUrl,
    };
  }
}

/// Chi tiết đề xuất điều chỉnh bù trừ Sổ cái (`LedgerAdjustmentRequestResponse`).
@immutable
class LedgerAdjustmentRequestModel {
  final String requestId;
  final String originalTransactionId;
  final String clanId;
  final String? eventId;
  final LedgerTransactionTypeEnum originalTransactionType;
  final double originalTransactionAmount;
  final double proposedAdjustmentAmount;
  final String adjustmentReason;
  final String? evidenceAttachmentUrl;
  final String proposedByAccountId;
  final LedgerAdjustmentStatusEnum approvalStatus;
  final String? reviewedByAccountId;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const LedgerAdjustmentRequestModel({
    required this.requestId,
    required this.originalTransactionId,
    required this.clanId,
    this.eventId,
    required this.originalTransactionType,
    required this.originalTransactionAmount,
    required this.proposedAdjustmentAmount,
    required this.adjustmentReason,
    this.evidenceAttachmentUrl,
    required this.proposedByAccountId,
    required this.approvalStatus,
    this.reviewedByAccountId,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  String get formattedCreatedAt =>
      AppFormatters.formatDateTime(createdAt.toLocal());

  String? get formattedReviewedAt => reviewedAt != null
      ? AppFormatters.formatDateTime(reviewedAt!.toLocal())
      : null;

  factory LedgerAdjustmentRequestModel.fromJson(Map<String, dynamic> json) {
    return LedgerAdjustmentRequestModel(
      requestId: json['requestId'] as String? ?? '',
      originalTransactionId: json['originalTransactionId'] as String? ?? '',
      clanId: json['clanId'] as String? ?? '',
      eventId: json['eventId'] as String?,
      originalTransactionType: LedgerTransactionTypeEnum.fromCode(
        json['originalTransactionType'] as String?,
      ),
      originalTransactionAmount: _parseAmount(json['originalTransactionAmount']),
      proposedAdjustmentAmount: _parseAmount(json['proposedAdjustmentAmount']),
      adjustmentReason: json['adjustmentReason'] as String? ?? '',
      evidenceAttachmentUrl: json['evidenceAttachmentUrl'] as String?,
      proposedByAccountId: json['proposedByAccountId'] as String? ?? '',
      approvalStatus: LedgerAdjustmentStatusEnum.fromCode(
        json['approvalStatus'] as String?,
      ),
      reviewedByAccountId: json['reviewedByAccountId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      reviewedAt: _parseNullableDateTime(json['reviewedAt']),
    );
  }
}

/// Phản hồi sau khi tải lên file biên bản (`POST /api/v1/ledger/evidence-upload`).
@immutable
class LedgerEvidenceUploadResult {
  final String evidenceUrl;
  final String fileName;
  final String originalFilename;
  final String mimeType;
  final int sizeBytes;
  final String sha256Checksum;

  const LedgerEvidenceUploadResult({
    required this.evidenceUrl,
    required this.fileName,
    required this.originalFilename,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256Checksum,
  });

  factory LedgerEvidenceUploadResult.fromJson(Map<String, dynamic> json) {
    return LedgerEvidenceUploadResult(
      evidenceUrl: json['evidenceUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      originalFilename: json['originalFilename'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: _parseInt(json['sizeBytes']),
      sha256Checksum: json['sha256Checksum'] as String? ?? '',
    );
  }
}

/// Tệp biên bản đang giữ tạm trên bộ nhớ FE chờ tải lên lúc xác nhận gửi (Deferred Upload).
@immutable
class SelectedEvidenceFile {
  final String name;
  final int sizeBytes;
  final Uint8List bytes;

  const SelectedEvidenceFile({
    required this.name,
    required this.sizeBytes,
    required this.bytes,
  });

  String get extension => name.contains('.')
      ? name.split('.').last.toLowerCase()
      : '';

  bool get isPdf => extension == 'pdf';

  String get formattedSize {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    final kb = (sizeBytes / 1024).round();
    return '${kb < 1 ? 1 : kb} KB';
  }
}

/// Payload gửi `POST /api/v1/ledger/review-adjustment` (`ReviewLedgerAdjustmentRequest`, US-59).
@immutable
class ReviewLedgerAdjustmentRequestDto {
  final String requestId;
  final bool approved;
  final String? rejectionReason;
  final String? description;

  const ReviewLedgerAdjustmentRequestDto({
    required this.requestId,
    required this.approved,
    this.rejectionReason,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final trimmedReason = rejectionReason?.trim();
    final trimmedDesc = description?.trim();
    return {
      'requestId': requestId.trim(),
      'approved': approved,
      if (trimmedReason != null && trimmedReason.isNotEmpty)
        'rejectionReason': trimmedReason,
      if (trimmedDesc != null && trimmedDesc.isNotEmpty)
        'description': trimmedDesc,
    };
  }
}

/// Bút toán bất biến mới được ghi vào Sổ cái (`ImmutableLedgerEntryResponse`, US-59).
@immutable
class ImmutableLedgerEntryModel {
  final String transactionId;
  final String clanId;
  final String? eventId;
  final String? adjustmentRequestId;
  final String? disbursementRequestId;
  final String? originalTransactionId;
  final LedgerTransactionTypeEnum transactionType;
  final double amount;
  final double runningBalance;
  final String description;
  final String createdByAccountId;
  final String approvedByAccountId;
  final String previousHash;
  final String recordHash;
  final DateTime createdAt;

  const ImmutableLedgerEntryModel({
    required this.transactionId,
    required this.clanId,
    this.eventId,
    this.adjustmentRequestId,
    this.disbursementRequestId,
    this.originalTransactionId,
    required this.transactionType,
    required this.amount,
    required this.runningBalance,
    required this.description,
    this.createdByAccountId = '',
    this.approvedByAccountId = '',
    this.previousHash = '',
    this.recordHash = '',
    required this.createdAt,
  });

  String get formattedCreatedAt =>
      AppFormatters.formatDateTime(createdAt.toLocal());

  factory ImmutableLedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return ImmutableLedgerEntryModel(
      transactionId: json['transactionId'] as String? ?? '',
      clanId: json['clanId'] as String? ?? '',
      eventId: json['eventId'] as String?,
      adjustmentRequestId: json['adjustmentRequestId'] as String?,
      disbursementRequestId: json['disbursementRequestId'] as String?,
      originalTransactionId: json['originalTransactionId'] as String?,
      transactionType:
          LedgerTransactionTypeEnum.fromCode(json['transactionType'] as String?),
      amount: _parseAmount(json['amount']),
      runningBalance: _parseAmount(json['runningBalance']),
      description: json['description'] as String? ?? '',
      createdByAccountId: json['createdByAccountId'] as String? ?? '',
      approvedByAccountId: json['approvedByAccountId'] as String? ?? '',
      previousHash: json['previousHash'] as String? ?? '',
      recordHash: json['recordHash'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  factory ImmutableLedgerEntryModel.fromHistoryItem(
    LedgerHistoryItemModel item,
  ) {
    return ImmutableLedgerEntryModel(
      transactionId: item.transactionId,
      clanId: item.clanId,
      eventId: item.eventId,
      adjustmentRequestId: item.adjustmentRequestId,
      disbursementRequestId: item.disbursementRequestId,
      originalTransactionId: item.originalTransactionId,
      transactionType: item.transactionType,
      amount: item.amount,
      runningBalance: item.runningBalance,
      description: item.description,
      createdByAccountId: item.createdByAccountId,
      approvedByAccountId: item.approvedByAccountId,
      previousHash: item.previousHash,
      recordHash: item.recordHash,
      createdAt: item.createdAt,
    );
  }
}

/// Phản hồi sau khi Trưởng tộc / Admin phê duyệt hoặc từ chối (`ReviewLedgerAdjustmentResponse`, US-59).
@immutable
class ReviewLedgerAdjustmentResponseModel {
  final LedgerAdjustmentRequestModel adjustmentRequest;
  final ImmutableLedgerEntryModel? ledgerEntry;

  const ReviewLedgerAdjustmentResponseModel({
    required this.adjustmentRequest,
    this.ledgerEntry,
  });

  factory ReviewLedgerAdjustmentResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final reqJson = json['adjustmentRequest'] is Map<String, dynamic>
        ? json['adjustmentRequest'] as Map<String, dynamic>
        : <String, dynamic>{};
    final entryJson = json['ledgerEntry'] is Map<String, dynamic>
        ? json['ledgerEntry'] as Map<String, dynamic>
        : null;
    return ReviewLedgerAdjustmentResponseModel(
      adjustmentRequest: LedgerAdjustmentRequestModel.fromJson(reqJson),
      ledgerEntry: entryJson != null
          ? ImmutableLedgerEntryModel.fromJson(entryJson)
          : null,
    );
  }
}
