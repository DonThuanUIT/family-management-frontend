import 'package:flutter/foundation.dart';

/// Chi tiết một mắt xích bị sai lệch khi kiểm toán chuỗi SHA-256 (`BrokenLinkResponse`).
@immutable
class LedgerBrokenLinkModel {
  final String transactionId;
  final int chainIndex;
  final String reason;
  final String? expectedPreviousHash;
  final String? actualPreviousHash;
  final String? expectedRecordHash;
  final String? actualRecordHash;

  const LedgerBrokenLinkModel({
    required this.transactionId,
    required this.chainIndex,
    required this.reason,
    this.expectedPreviousHash,
    this.actualPreviousHash,
    this.expectedRecordHash,
    this.actualRecordHash,
  });

  factory LedgerBrokenLinkModel.fromJson(Map<String, dynamic> json) {
    final rawIndex = json['chainIndex'];
    final chainIndex = rawIndex is int
        ? rawIndex
        : (rawIndex is num
            ? rawIndex.toInt()
            : int.tryParse('${rawIndex ?? 0}') ?? 0);
    return LedgerBrokenLinkModel(
      transactionId: json['transactionId'] as String? ?? '',
      chainIndex: chainIndex,
      reason: json['reason'] as String? ?? '',
      expectedPreviousHash: json['expectedPreviousHash'] as String?,
      actualPreviousHash: json['actualPreviousHash'] as String?,
      expectedRecordHash: json['expectedRecordHash'] as String?,
      actualRecordHash: json['actualRecordHash'] as String?,
    );
  }
}

/// Báo cáo kết quả kiểm toán toàn vẹn chuỗi mã băm SHA-256 của Sổ cái (`LedgerIntegrityReportResponse`).
@immutable
class LedgerIntegrityReportModel {
  final String clanId;
  final bool valid;
  final int totalEntries;
  final int verifiedEntries;
  final String genesisAnchor;
  final String? latestTransactionId;
  final String? latestRecordHash;
  final List<LedgerBrokenLinkModel> brokenLinks;
  final DateTime verifiedAt;

  const LedgerIntegrityReportModel({
    required this.clanId,
    required this.valid,
    required this.totalEntries,
    required this.verifiedEntries,
    this.genesisAnchor = 'GENESIS',
    this.latestTransactionId,
    this.latestRecordHash,
    this.brokenLinks = const [],
    required this.verifiedAt,
  });

  factory LedgerIntegrityReportModel.fromJson(Map<String, dynamic> json) {
    int parseCount(dynamic raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw.trim()) ?? 0;
      return 0;
    }

    final rawLinks = json['brokenLinks'];
    final parsedLinks = rawLinks is List
        ? rawLinks
            .whereType<Map<String, dynamic>>()
            .map(LedgerBrokenLinkModel.fromJson)
            .toList()
        : const <LedgerBrokenLinkModel>[];

    final rawTime = json['verifiedAt'];
    final parsedTime = rawTime is DateTime
        ? rawTime
        : (rawTime is String && rawTime.trim().isNotEmpty
            ? DateTime.tryParse(rawTime.trim()) ?? DateTime.now()
            : DateTime.now());

    return LedgerIntegrityReportModel(
      clanId: json['clanId'] as String? ?? '',
      valid: json['valid'] == true,
      totalEntries: parseCount(json['totalEntries']),
      verifiedEntries: parseCount(json['verifiedEntries']),
      genesisAnchor: (json['genesisAnchor'] as String?)?.trim().isNotEmpty == true
          ? (json['genesisAnchor'] as String).trim()
          : 'GENESIS',
      latestTransactionId: json['latestTransactionId'] as String?,
      latestRecordHash: json['latestRecordHash'] as String?,
      brokenLinks: parsedLinks,
      verifiedAt: parsedTime,
    );
  }
}

/// Rút gọn chuỗi mã băm SHA-256 hiển thị trong bảng Desktop (`8092d84c…2290d8`).
String shortLedgerHash(String hash) {
  final trimmed = hash.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.toUpperCase() == 'GENESIS') return 'GENESIS';
  if (trimmed.length < 16) return trimmed;
  return '${trimmed.substring(0, 8)}…${trimmed.substring(trimmed.length - 6)}';
}

/// Rút gọn cực ngắn cho thẻ Mobile và nhãn `previousHash` (`5ecbe1…072e`).
String shortLedgerHashCompact(String hash) {
  final trimmed = hash.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.toUpperCase() == 'GENESIS') return 'GENESIS';
  if (trimmed.length < 12) return trimmed;
  return '${trimmed.substring(0, 6)}…${trimmed.substring(trimmed.length - 4)}';
}
