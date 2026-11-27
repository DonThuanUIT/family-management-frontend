import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/features/finance/data/models/immutable_ledger_integrity_models.dart';

void main() {
  group('LedgerIntegrityReportModel & hash formatters', () {
    test('parses valid integrity report from JSON', () {
      final report = LedgerIntegrityReportModel.fromJson({
        'clanId': 'CLAN_DEFAULT',
        'valid': true,
        'totalEntries': 4,
        'verifiedEntries': 4,
        'genesisAnchor': 'GENESIS',
        'latestTransactionId': 'LDGMWYQDWK15F5JSY',
        'latestRecordHash':
            '8092d84cd50f51e38fc15ea98db9204566c3ace2d80ba105fee465ea422290d8',
        'brokenLinks': <dynamic>[],
        'verifiedAt': '2026-11-27T08:40:13.582943Z',
      });

      expect(report.clanId, 'CLAN_DEFAULT');
      expect(report.valid, isTrue);
      expect(report.totalEntries, 4);
      expect(report.verifiedEntries, 4);
      expect(report.genesisAnchor, 'GENESIS');
      expect(report.latestTransactionId, 'LDGMWYQDWK15F5JSY');
      expect(report.brokenLinks, isEmpty);
    });

    test('parses broken integrity report with brokenLinks', () {
      final report = LedgerIntegrityReportModel.fromJson({
        'clanId': 'CLAN_DEFAULT',
        'valid': false,
        'totalEntries': 4,
        'verifiedEntries': 2,
        'brokenLinks': [
          {
            'transactionId': 'LDGMWYGB7CX9V7NQZ',
            'chainIndex': 2,
            'reason': 'recordHash không khớp chữ ký lưu sổ cái',
            'expectedPreviousHash':
                'f5ca443d668b5adf5c58c21c7d55187b11db87544d10ca8ff61e14fe18cfe2ff',
            'actualPreviousHash':
                'f5ca443d668b5adf5c58c21c7d55187b11db87544d10ca8ff61e14fe18cfe2ff',
            'expectedRecordHash': 'aaaa' * 16,
            'actualRecordHash':
                '5ecbe194fcaab9e4e845d9f8f9ee7ae787e6af208a0c86d13efb24b8d94f072e',
          },
        ],
        'verifiedAt': '2026-11-27T09:00:00Z',
      });

      expect(report.valid, isFalse);
      expect(report.verifiedEntries, 2);
      expect(report.brokenLinks, hasLength(1));
      expect(report.brokenLinks.first.transactionId, 'LDGMWYGB7CX9V7NQZ');
      expect(report.brokenLinks.first.chainIndex, 2);
      expect(
        report.brokenLinks.first.reason,
        'recordHash không khớp chữ ký lưu sổ cái',
      );
    });

    test('shortLedgerHash and shortLedgerHashCompact format GENESIS and hex', () {
      const fullHash =
          '8092d84cd50f51e38fc15ea98db9204566c3ace2d80ba105fee465ea422290d8';

      expect(shortLedgerHash('GENESIS'), 'GENESIS');
      expect(shortLedgerHash('  '), '');
      expect(shortLedgerHash(fullHash), '8092d84c…2290d8');

      expect(shortLedgerHashCompact('GENESIS'), 'GENESIS');
      expect(shortLedgerHashCompact(''), '');
      expect(shortLedgerHashCompact(fullHash), '8092d8…90d8');
    });
  });
}
