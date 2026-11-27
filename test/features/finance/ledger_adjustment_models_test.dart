import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/finance/data/datasources/ledger_remote_datasource.dart';
import 'package:familyfund_app/features/finance/data/models/ledger_adjustment_models.dart';

void main() {
  group('LedgerAdjustmentModels & DualRbacSession', () {
    test('LedgerHistoryPageModel parses Backend US-62 payload accurately', () {
      final json = {
        'clanId': 'CLAN_01',
        'page': 0,
        'size': 20,
        'totalElements': 2,
        'totalPages': 1,
        'summary': {
          'currentFundBalance': 245500000.00,
          'latestTransactionId': 'LDG00K9A2F8X7P4Q2',
          'latestTransactionAt': '2026-11-18T10:00:00Z',
          'openingBalanceBeforePeriod': 177000000.00,
          'closingBalanceAtPeriodEnd': 245500000.00,
          'filteredTransactionCount': 2,
          'filteredTotalInflow': 68500000.00,
          'filteredTotalOutflow': 0.00,
          'filteredNetAmount': 68500000.00,
        },
        'items': [
          {
            'transactionId': 'LDG00K9A2F8X7P4Q2',
            'clanId': 'CLAN_01',
            'eventId': 'EVT_2026_GIOTO',
            'eventName': 'Đại lễ Giỗ Tổ 2026',
            'transactionType': 'SurplusTransfer',
            'amount': 68500000.00,
            'runningBalance': 245500000.00,
            'description': 'Chuyển thặng dư Đại lễ Giỗ Tổ',
            'createdByAccountId': 'ACC_TREASURER',
            'createdByName': 'Nguyễn Thị Lan',
            'approvedByAccountId': 'ACC_HEAD',
            'approvedByName': 'Nguyễn Trọng Hoàng',
            'previousHash': 'GENESIS',
            'recordHash': 'a' * 64,
            'createdAt': '2026-11-18T10:00:00Z',
            'isAdjustment': false,
            'hasAdjustments': false,
            'adjustmentCount': 0,
            'netAdjustedAmount': 68500000.00,
            'pendingAdjustmentRequestCount': 0,
          },
          {
            'transactionId': 'LDG00K8Z1C3V5N7M9',
            'clanId': 'CLAN_01',
            'transactionType': 'CommonFundDisbursement',
            'amount': -32000000.00,
            'runningBalance': 177000000.00,
            'description': 'Chi tu sửa mái ngói Từ đường',
            'createdAt': '2026-11-02T09:00:00Z',
            'isAdjustment': false,
            'hasAdjustments': true,
            'adjustmentCount': 1,
            'netAdjustedAmount': -34400000.00,
            'pendingAdjustmentRequestCount': 1,
          },
        ],
      };

      final page = LedgerHistoryPageModel.fromJson(json);

      expect(page.clanId, 'CLAN_01');
      expect(page.summary.currentFundBalance, 245500000.0);
      expect(page.items.length, 2);
      expect(
        page.items[0].transactionType,
        LedgerTransactionTypeEnum.surplusTransfer,
      );
      expect(page.items[0].isLockedByPendingAdjustment, isFalse);
      expect(page.items[1].amount, -32000000.0);
      expect(page.items[1].netAdjustedAmount, -34400000.0);
      expect(page.items[1].isLockedByPendingAdjustment, isTrue);
    });

    test('ProposeLedgerAdjustmentRequestDto serializes and omits blank evidenceUrl', () {
      const dtoWithEvidence = ProposeLedgerAdjustmentRequestDto(
        originalTransactionId: 'LDG001',
        proposedAdjustmentAmount: -1500000,
        adjustmentReason: 'Bù trừ hóa đơn phát sinh',
        evidenceAttachmentUrl: '/api/v1/ledger/evidence/uuid.pdf',
      );
      expect(dtoWithEvidence.toJson(), {
        'originalTransactionId': 'LDG001',
        'proposedAdjustmentAmount': -1500000.0,
        'adjustmentReason': 'Bù trừ hóa đơn phát sinh',
        'evidenceAttachmentUrl': '/api/v1/ledger/evidence/uuid.pdf',
      });

      const dtoWithoutEvidence = ProposeLedgerAdjustmentRequestDto(
        originalTransactionId: 'LDG001',
        proposedAdjustmentAmount: 500000,
        adjustmentReason: 'Điều chỉnh số liệu',
        evidenceAttachmentUrl: '   ',
      );
      expect(dtoWithoutEvidence.toJson().containsKey('evidenceAttachmentUrl'), isFalse);
    });

    test('LedgerEvidenceUploadResult & internal proxy filename extractor', () {
      final res = LedgerEvidenceUploadResult.fromJson({
        'evidenceUrl': '/api/v1/ledger/evidence/550e8400-e29b-41d4-a716-446655440000.pdf',
        'fileName': '550e8400-e29b-41d4-a716-446655440000.pdf',
        'originalFilename': 'Bien_ban.pdf',
        'mimeType': 'application/pdf',
        'sizeBytes': 12345,
        'sha256Checksum': 'f' * 64,
      });

      expect(res.fileName, '550e8400-e29b-41d4-a716-446655440000.pdf');
      expect(
        LedgerRemoteDataSourceImpl.extractInternalEvidenceFilename(res.evidenceUrl),
        '550e8400-e29b-41d4-a716-446655440000.pdf',
      );
      expect(
        LedgerRemoteDataSourceImpl.extractInternalEvidenceFilename(
          'https://evil.example.com/api/v1/ledger/evidence/../secret.pdf',
        ),
        isNull,
      );
    });

    test('DualRbacSession.canProposeLedgerAdjustment matches Backend rules including closed events', () {
      const clanHead = DualRbacSession(
        accountId: 'ACC_HEAD',
        memberId: 'MEM_HEAD',
        fullName: 'Trưởng tộc',
        branchName: 'Chi Gốc',
        globalRoles: {SystemRole.roleClanHead},
      );
      expect(clanHead.canProposeLedgerAdjustment(eventId: null), isTrue);

      const eventTreasurerClosed = DualRbacSession(
        accountId: 'ACC_TR',
        memberId: 'MEM_TR',
        fullName: 'Thủ quỹ sự kiện',
        branchName: 'Chi 2',
        globalRoles: {SystemRole.roleMember},
        eventRolesByEventId: {
          'EVT_CLOSED': EventPermissionContext(
            eventId: 'EVT_CLOSED',
            role: EventContextualRole.eventTreasurer,
            eventStatus: EventLifecycleStatus.closed,
          ),
        },
      );
      expect(
        eventTreasurerClosed.canProposeLedgerAdjustment(eventId: 'EVT_CLOSED'),
        isTrue,
      );
      expect(
        eventTreasurerClosed.canProposeLedgerAdjustment(eventId: 'EVT_OTHER'),
        isFalse,
      );

      const regularMember = DualRbacSession(
        accountId: 'ACC_MEM',
        memberId: 'MEM_MEM',
        fullName: 'Thành viên',
        branchName: 'Chi 2',
        globalRoles: {SystemRole.roleMember},
      );
      expect(regularMember.canProposeLedgerAdjustment(eventId: 'EVT_CLOSED'), isFalse);
      expect(regularMember.canAccessLedgerAdjustmentProposal, isFalse);
    });

    test('ReviewLedgerAdjustmentRequestDto serializes approve & reject payloads accurately', () {
      const approveDto = ReviewLedgerAdjustmentRequestDto(
        requestId: ' LAR001 ',
        approved: true,
        description: '  Ghi nhận bù trừ theo biên bản ',
      );
      expect(approveDto.toJson(), {
        'requestId': 'LAR001',
        'approved': true,
        'description': 'Ghi nhận bù trừ theo biên bản',
      });

      const approveBlankDescDto = ReviewLedgerAdjustmentRequestDto(
        requestId: 'LAR001',
        approved: true,
        description: '   ',
      );
      expect(approveBlankDescDto.toJson().containsKey('description'), isFalse);

      const rejectDto = ReviewLedgerAdjustmentRequestDto(
        requestId: 'LAR002',
        approved: false,
        rejectionReason: 'Thiếu chứng từ đối chiếu gốc.',
      );
      expect(rejectDto.toJson(), {
        'requestId': 'LAR002',
        'approved': false,
        'rejectionReason': 'Thiếu chứng từ đối chiếu gốc.',
      });
    });

    test('ReviewLedgerAdjustmentResponseModel parses Approved and Rejected responses', () {
      final approvedRes = ReviewLedgerAdjustmentResponseModel.fromJson({
        'adjustmentRequest': {
          'requestId': 'LAR001',
          'originalTransactionId': 'LDG001',
          'clanId': 'CLAN_01',
          'originalTransactionType': 'SurplusTransfer',
          'originalTransactionAmount': 150000000.0,
          'proposedAdjustmentAmount': 14800000.0,
          'adjustmentReason': 'Bổ sung tiền công đức Chi 3',
          'proposedByAccountId': 'ACC_TR',
          'approvalStatus': 'Approved',
          'reviewedByAccountId': 'ACC_HEAD',
          'createdAt': '2026-11-27T02:00:00Z',
          'reviewedAt': '2026-11-27T04:00:00Z',
        },
        'ledgerEntry': {
          'transactionId': 'LDG00NEW001',
          'clanId': 'CLAN_01',
          'adjustmentRequestId': 'LAR001',
          'originalTransactionId': 'LDG001',
          'transactionType': 'AdjustmentTransaction',
          'amount': 14800000.0,
          'runningBalance': 114800000.0,
          'description': 'Bù trừ giao dịch LDG001',
          'createdByAccountId': 'ACC_TR',
          'approvedByAccountId': 'ACC_HEAD',
          'previousHash': '0' * 64,
          'recordHash': 'f' * 64,
          'createdAt': '2026-11-27T04:00:00Z',
        },
      });

      expect(
        approvedRes.adjustmentRequest.approvalStatus,
        LedgerAdjustmentStatusEnum.approved,
      );
      expect(approvedRes.ledgerEntry, isNotNull);
      expect(approvedRes.ledgerEntry!.transactionId, 'LDG00NEW001');
      expect(approvedRes.ledgerEntry!.runningBalance, 114800000.0);
      expect(approvedRes.ledgerEntry!.recordHash, 'f' * 64);

      final rejectedRes = ReviewLedgerAdjustmentResponseModel.fromJson({
        'adjustmentRequest': {
          'requestId': 'LAR002',
          'originalTransactionId': 'LDG002',
          'clanId': 'CLAN_01',
          'originalTransactionType': 'CommonFundDisbursement',
          'originalTransactionAmount': -50000000.0,
          'proposedAdjustmentAmount': -120000000.0,
          'adjustmentReason': 'Kiểm thử',
          'proposedByAccountId': 'ACC_TR',
          'approvalStatus': 'Rejected',
          'reviewedByAccountId': 'ACC_HEAD',
          'rejectionReason': 'Làm âm Quỹ chung',
          'createdAt': '2026-11-27T02:00:00Z',
          'reviewedAt': '2026-11-27T04:05:00Z',
        },
        'ledgerEntry': null,
      });

      expect(
        rejectedRes.adjustmentRequest.approvalStatus,
        LedgerAdjustmentStatusEnum.rejected,
      );
      expect(rejectedRes.adjustmentRequest.rejectionReason, 'Làm âm Quỹ chung');
      expect(rejectedRes.ledgerEntry, isNull);
    });

    test('DualRbacSession.canApproveLedgerAdjustment matches CLAN_HEAD or ADMIN only', () {
      const clanHead = DualRbacSession(
        accountId: 'ACC_1',
        memberId: 'M1',
        fullName: 'Trưởng tộc',
        branchName: 'Chi Gốc',
        globalRoles: {SystemRole.roleClanHead},
      );
      const admin = DualRbacSession(
        accountId: 'ACC_2',
        memberId: 'M2',
        fullName: 'Admin',
        branchName: 'Chi Gốc',
        globalRoles: {SystemRole.roleAdmin},
      );
      const branchHead = DualRbacSession(
        accountId: 'ACC_3',
        memberId: 'M3',
        fullName: 'Trưởng chi',
        branchName: 'Chi 2',
        globalRoles: {SystemRole.roleBranchHead, SystemRole.roleMember},
      );
      const member = DualRbacSession(
        accountId: 'ACC_4',
        memberId: 'M4',
        fullName: 'Thành viên',
        branchName: 'Chi 2',
        globalRoles: {SystemRole.roleMember},
      );

      expect(clanHead.canApproveLedgerAdjustment, isTrue);
      expect(admin.canApproveLedgerAdjustment, isTrue);
      expect(branchHead.canApproveLedgerAdjustment, isFalse);
      expect(member.canApproveLedgerAdjustment, isFalse);
    });
  });
}
