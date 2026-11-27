import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/finance/data/models/common_fund_disbursement_models.dart';

void main() {
  group('CommonFundDisbursementModels & DualRbacSession US-60', () {
    test('CommonFundBalanceModel parses Backend US-60 response accurately', () {
      final balance = CommonFundBalanceModel.fromJson({
        'clanId': 'CLAN_DEFAULT',
        'availableBalance': 850000000.00,
        'pendingDisbursementAmount': 145000000.00,
        'latestTransactionId': 'LDG00DEMO20260001',
        'latestTransactionAt': '2026-11-27T04:00:00Z',
      });

      expect(balance.clanId, 'CLAN_DEFAULT');
      expect(balance.availableBalance, 850000000.0);
      expect(balance.pendingDisbursementAmount, 145000000.0);
      expect(balance.freeBalanceAfterPending, 705000000.0);
      expect(balance.latestTransactionId, 'LDG00DEMO20260001');
    });

    test('ProposeCommonFundDisbursementRequestDto serializes & omits blank fields', () {
      const dtoFull = ProposeCommonFundDisbursementRequestDto(
        title: ' Trùng tu Tiền Đường ',
        category: CommonFundExpenseCategoryEnum.templeMaintenance,
        amount: 120000000,
        beneficiaryName: 'CTCP Tu bổ Di tích',
        beneficiaryMemberId: '  ',
        purpose: ' Sửa chữa mái ngói dột ',
        attachmentUrl: '/api/v1/ledger/evidence/uuid.pdf',
      );
      expect(dtoFull.toJson(), {
        'title': 'Trùng tu Tiền Đường',
        'category': 'TempleMaintenance',
        'amount': 120000000.0,
        'beneficiaryName': 'CTCP Tu bổ Di tích',
        'purpose': 'Sửa chữa mái ngói dột',
        'attachmentUrl': '/api/v1/ledger/evidence/uuid.pdf',
      });
    });

    test('ReviewCommonFundDisbursementRequestDto & ResponseModel parse Approved and Rejected', () {
      const approveDto = ReviewCommonFundDisbursementRequestDto(
        requestId: 'CFD001',
        approved: true,
        confirmPassword: 'secret-password',
        description: '  Duyệt theo biên bản  ',
      );
      expect(approveDto.toJson(), {
        'requestId': 'CFD001',
        'approved': true,
        'confirmPassword': 'secret-password',
        'description': 'Duyệt theo biên bản',
      });

      final approvedRes = ReviewCommonFundDisbursementResponseModel.fromJson({
        'disbursementRequest': {
          'requestId': 'CFD001',
          'clanId': 'CLAN_01',
          'title': 'Trùng tu Từ đường',
          'category': 'TempleMaintenance',
          'amount': 120000000.00,
          'beneficiaryName': 'CTCP Mỹ nghệ',
          'purpose': 'Sửa mái ngói',
          'proposedByAccountId': 'ACC_CHI',
          'approvalStatus': 'Approved',
          'reviewedByAccountId': 'ACC_HEAD',
          'ledgerTransactionId': 'LDG00DISB001',
          'createdAt': '2026-11-27T08:00:00Z',
          'reviewedAt': '2026-11-27T09:00:00Z',
        },
        'ledgerEntry': {
          'transactionId': 'LDG00DISB001',
          'clanId': 'CLAN_01',
          'disbursementRequestId': 'CFD001',
          'transactionType': 'CommonFundDisbursement',
          'amount': -120000000.00,
          'runningBalance': 730000000.00,
          'description': 'Duyệt theo biên bản',
          'createdByAccountId': 'ACC_CHI',
          'approvedByAccountId': 'ACC_HEAD',
          'previousHash': 'a' * 64,
          'recordHash': 'b' * 64,
          'createdAt': '2026-11-27T09:00:00Z',
        },
      });

      expect(
        approvedRes.disbursementRequest.approvalStatus,
        CommonFundDisbursementStatusEnum.approved,
      );
      expect(approvedRes.disbursementRequest.ledgerTransactionId, 'LDG00DISB001');
      expect(approvedRes.ledgerEntry, isNotNull);
      expect(approvedRes.ledgerEntry!.amount, -120000000.0);
      expect(approvedRes.ledgerEntry!.runningBalance, 730000000.0);
      expect(approvedRes.ledgerEntry!.recordHash, 'b' * 64);
    });

    test('DualRbacSession US-60 permissions match Backend rules', () {
      const clanHead = DualRbacSession(
        accountId: 'A1',
        memberId: 'M1',
        fullName: 'Trưởng tộc',
        branchName: 'Chi Gốc',
        globalRoles: {SystemRole.roleClanHead},
      );
      const branchHead = DualRbacSession(
        accountId: 'A2',
        memberId: 'M2',
        fullName: 'Trưởng chi',
        branchName: 'Chi 2',
        globalRoles: {SystemRole.roleBranchHead, SystemRole.roleMember},
      );
      const eventTreasurer = DualRbacSession(
        accountId: 'A3',
        memberId: 'M3',
        fullName: 'Thủ quỹ sự kiện',
        branchName: 'Chi 2',
        globalRoles: {SystemRole.roleMember},
        eventRolesByEventId: {
          'EVT_1': EventPermissionContext(
            eventId: 'EVT_1',
            role: EventContextualRole.eventTreasurer,
            eventStatus: EventLifecycleStatus.closed,
          ),
        },
      );
      const regularMember = DualRbacSession(
        accountId: 'A4',
        memberId: 'M4',
        fullName: 'Thành viên',
        branchName: 'Chi 2',
        globalRoles: {SystemRole.roleMember},
      );

      expect(clanHead.canProposeCommonFundDisbursement, isTrue);
      expect(clanHead.canReviewCommonFundDisbursement, isTrue);

      expect(branchHead.canProposeCommonFundDisbursement, isTrue);
      expect(branchHead.canReviewCommonFundDisbursement, isFalse);

      expect(eventTreasurer.canProposeCommonFundDisbursement, isTrue);
      expect(eventTreasurer.canReviewCommonFundDisbursement, isFalse);

      expect(regularMember.canProposeCommonFundDisbursement, isFalse);
      expect(regularMember.canReviewCommonFundDisbursement, isFalse);
    });
  });
}
