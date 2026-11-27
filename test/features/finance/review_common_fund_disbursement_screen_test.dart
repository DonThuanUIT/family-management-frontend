import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/core/error/failures.dart';
import 'package:familyfund_app/core/files/member_file_actions.dart';
import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/core/theme/app_theme.dart';
import 'package:familyfund_app/features/finance/data/models/common_fund_disbursement_models.dart';
import 'package:familyfund_app/features/finance/data/models/immutable_ledger_integrity_models.dart';
import 'package:familyfund_app/features/finance/data/models/ledger_adjustment_models.dart';
import 'package:familyfund_app/features/finance/data/models/ledger_annual_audit_models.dart';
import 'package:familyfund_app/features/finance/data/repositories/common_fund_disbursement_repository_impl.dart';
import 'package:familyfund_app/features/finance/data/repositories/ledger_repository_impl.dart';
import 'package:familyfund_app/features/finance/domain/repositories/common_fund_disbursement_repository.dart';
import 'package:familyfund_app/features/finance/domain/repositories/ledger_repository.dart';
import 'package:familyfund_app/features/finance/presentation/screens/review_common_fund_disbursement_screen.dart';

class _FixedDisbReviewRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _fixed;
  _FixedDisbReviewRbacNotifier(this._fixed);

  @override
  DualRbacSession build() => _fixed;
}

class FakeReviewDisbursementRepo implements CommonFundDisbursementRepository {
  CommonFundBalanceModel balance;
  final List<CommonFundDisbursementModel> items;

  int reviewCallCount = 0;
  ReviewCommonFundDisbursementRequestDto? lastReviewDto;

  FakeReviewDisbursementRepo({
    required this.balance,
    required this.items,
  });

  @override
  Future<CommonFundBalanceModel> getFundBalance() async => balance;

  @override
  Future<List<CommonFundDisbursementModel>> searchDisbursements({
    CommonFundDisbursementStatusEnum? status,
    CommonFundExpenseCategoryEnum? category,
  }) async {
    return items.where((e) {
      if (status != null && e.approvalStatus != status) return false;
      if (category != null && e.category != category) return false;
      return true;
    }).toList();
  }

  @override
  Future<CommonFundDisbursementModel> getDisbursementById(
    String requestId,
  ) async {
    return items.firstWhere((e) => e.requestId == requestId);
  }

  @override
  Future<CommonFundDisbursementModel> proposeDisbursement(
    ProposeCommonFundDisbursementRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ReviewCommonFundDisbursementResponseModel> reviewDisbursement(
    String requestId,
    ReviewCommonFundDisbursementRequestDto request,
  ) async {
    reviewCallCount++;
    lastReviewDto = request;

    final idx = items.indexWhere((e) => e.requestId == requestId);
    final existing = items[idx];

    if (request.approved) {
      if (request.confirmPassword?.trim() != '123456') {
        throw const BusinessInvariantFailure(
          message:
              'Mật khẩu xác nhận không chính xác hoặc tài khoản không ở trạng thái hoạt động',
          statusCode: 400,
        );
      }

      final newBalance = balance.availableBalance - existing.amount;
      balance = balance.copyWith(
        availableBalance: newBalance,
        pendingDisbursementAmount: balance.pendingDisbursementAmount - existing.amount,
      );

      final updated = CommonFundDisbursementModel(
        requestId: existing.requestId,
        clanId: existing.clanId,
        title: existing.title,
        category: existing.category,
        amount: existing.amount,
        beneficiaryName: existing.beneficiaryName,
        beneficiaryMemberId: existing.beneficiaryMemberId,
        purpose: existing.purpose,
        attachmentUrl: existing.attachmentUrl,
        proposedByAccountId: existing.proposedByAccountId,
        approvalStatus: CommonFundDisbursementStatusEnum.approved,
        reviewedByAccountId: 'ACC_TRUONG_TOC',
        ledgerTransactionId: 'LDG00NEWDISB001',
        createdAt: existing.createdAt,
        reviewedAt: DateTime(2026, 11, 27, 15, 30),
      );
      items[idx] = updated;

      final entry = ImmutableLedgerEntryModel(
        transactionId: 'LDG00NEWDISB001',
        clanId: existing.clanId,
        disbursementRequestId: existing.requestId,
        transactionType: LedgerTransactionTypeEnum.commonFundDisbursement,
        amount: -existing.amount,
        runningBalance: newBalance,
        description: request.description?.trim().isNotEmpty == true
            ? request.description!.trim()
            : 'Chi Quỹ chung (${existing.requestId}): ${existing.title}',
        createdByAccountId: existing.proposedByAccountId,
        approvedByAccountId: 'ACC_TRUONG_TOC',
        previousHash: 'a' * 64,
        recordHash: 'c' * 64,
        createdAt: DateTime(2026, 11, 27, 15, 30),
      );

      return ReviewCommonFundDisbursementResponseModel(
        disbursementRequest: updated,
        ledgerEntry: entry,
      );
    } else {
      final updated = CommonFundDisbursementModel(
        requestId: existing.requestId,
        clanId: existing.clanId,
        title: existing.title,
        category: existing.category,
        amount: existing.amount,
        beneficiaryName: existing.beneficiaryName,
        beneficiaryMemberId: existing.beneficiaryMemberId,
        purpose: existing.purpose,
        attachmentUrl: existing.attachmentUrl,
        proposedByAccountId: existing.proposedByAccountId,
        approvalStatus: CommonFundDisbursementStatusEnum.rejected,
        reviewedByAccountId: 'ACC_TRUONG_TOC',
        rejectionReason: request.rejectionReason,
        createdAt: existing.createdAt,
        reviewedAt: DateTime(2026, 11, 27, 15, 35),
      );
      items[idx] = updated;
      return ReviewCommonFundDisbursementResponseModel(
        disbursementRequest: updated,
        ledgerEntry: null,
      );
    }
  }
}

class FakeDisbReviewLedgerRepo implements LedgerRepository {
  int downloadCount = 0;
  String? lastDownloadedUrl;

  @override
  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl) async {
    downloadCount++;
    lastDownloadedUrl = evidenceUrl;
    return Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits);
  }

  @override
  Future<LedgerHistoryItemModel> getTransactionDetail(String transactionId) {
    throw UnimplementedError();
  }

  @override
  Future<LedgerAdjustmentRequestModel> getAdjustmentRequestById(String requestId) {
    throw UnimplementedError();
  }

  @override
  Future<LedgerAdjustmentRequestModel> proposeAdjustment(
    ProposeLedgerAdjustmentRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ReviewLedgerAdjustmentResponseModel> reviewAdjustment(
    ReviewLedgerAdjustmentRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<LedgerAdjustmentRequestModel>> searchAdjustmentRequests({
    String? originalTransactionId,
    LedgerAdjustmentStatusEnum? status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LedgerHistoryPageModel> searchLedgerHistory({
    String? keyword,
    LedgerTransactionTypeEnum? transactionType,
    bool? onlyWithAdjustments,
    String sortDirection = 'DESC',
    String? from,
    String? to,
    int page = 0,
    int size = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LedgerIntegrityReportModel> verifyLedgerIntegrity() async {
    return LedgerIntegrityReportModel(
      clanId: 'CLAN_DEFAULT',
      valid: true,
      totalEntries: 0,
      verifiedEntries: 0,
      verifiedAt: DateTime(2026, 11, 27),
    );
  }

  @override
  Future<LedgerEvidenceUploadResult> uploadEvidence({
    required Uint8List bytes,
    required String filename,
    String? originalTransactionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LedgerAnnualAuditModel> performAnnualAudit(
    AnnualLedgerAuditRequestDto request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<LedgerAnnualAuditModel>> searchAnnualAudits({
    int? auditYear,
    LedgerAnnualAuditStatusEnum? status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LedgerAnnualAuditModel> getAnnualAuditById(String auditId) {
    throw UnimplementedError();
  }
}

class FakeDisbReviewFileActions extends MemberFileActions {
  int saveCount = 0;
  String? lastSavedName;

  @override
  Future<List<SelectedMediaFile>> pick({bool portrait = false}) async =>
      const [];

  @override
  Future<bool> save(Uint8List bytes, String filename, String mimeType) async {
    saveCount++;
    lastSavedName = filename;
    return true;
  }
}

void main() {
  late List<CommonFundDisbursementModel> sampleItems;

  setUp(() {
    sampleItems = [
      CommonFundDisbursementModel(
        requestId: 'CFD00VALID000001',
        clanId: 'CLAN_01',
        title: 'Trùng tu mái ngói Tiền Đường & thay xà gồ gỗ lim',
        category: CommonFundExpenseCategoryEnum.templeMaintenance,
        amount: 120000000,
        beneficiaryName: 'CTCP Tu bổ Di tích Cố Đô',
        purpose: 'Khảo sát dột nhiều điểm và thay xà gồ bị mối mọt.',
        attachmentUrl:
            '/api/v1/ledger/evidence/661e8400-e29b-41d4-a716-446655440111.pdf',
        proposedByAccountId: 'ACC_TRUONG_CHI',
        approvalStatus: CommonFundDisbursementStatusEnum.pending,
        createdAt: DateTime(2026, 11, 27, 10, 15),
      ),
      CommonFundDisbursementModel(
        requestId: 'CFD00OVERDRAFT02',
        clanId: 'CLAN_01',
        title: 'Kiểm thử chi vượt số dư Quỹ khả dụng',
        category: CommonFundExpenseCategoryEnum.ceremony,
        amount: 920000000,
        beneficiaryName: 'Ban Khánh Tiết',
        purpose: 'Thử nghiệm khóa nút Ký duyệt khi vượt số dư.',
        proposedByAccountId: 'ACC_TRUONG_CHI',
        approvalStatus: CommonFundDisbursementStatusEnum.pending,
        createdAt: DateTime(2026, 11, 27, 11, 0),
      ),
    ];
  });

  const clanHeadSession = DualRbacSession(
    accountId: 'ACC_TRUONG_TOC',
    memberId: 'MEM_HEAD',
    fullName: 'Nguyễn Trọng Hoàng',
    branchName: 'Chi Gốc',
    globalRoles: {SystemRole.roleClanHead},
  );

  Widget buildApp({
    required FakeReviewDisbursementRepo repo,
    FakeDisbReviewLedgerRepo? ledgerRepo,
    FakeDisbReviewFileActions? fileActions,
    DualRbacSession session = clanHeadSession,
  }) {
    return ProviderScope(
      overrides: [
        commonFundDisbursementRepositoryProvider.overrideWithValue(repo),
        ledgerRepositoryProvider.overrideWithValue(
          ledgerRepo ?? FakeDisbReviewLedgerRepo(),
        ),
        dualRbacSessionProvider.overrideWith(
          () => _FixedDisbReviewRbacNotifier(session),
        ),
        if (fileActions != null)
          memberFileActionsProvider.overrideWithValue(fileActions),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ReviewCommonFundDisbursementScreen(),
      ),
    );
  }

  testWidgets(
      'Desktop 1280x900: Overdraft blocks Approve, wrong password keeps dialog with inline error, correct password seals SHA-256 and updates Fund Balance',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeReviewDisbursementRepo(
      balance: const CommonFundBalanceModel(
        clanId: 'CLAN_01',
        availableBalance: 850000000,
        pendingDisbursementAmount: 1040000000,
      ),
      items: sampleItems,
    );

    await tester.pumpWidget(buildApp(repo: repo));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('disbursement_review_queue_panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('disbursement_desktop_decision_bar')),
      findsOneWidget,
    );

    // 1. Overdraft item locks Approve while Reject remains enabled
    await tester.tap(
      find.byKey(const Key('disbursement_queue_item_CFD00OVERDRAFT02')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('disbursement_review_overdraft_banner')),
      findsOneWidget,
    );
    final disabledApprove = tester.widget<ElevatedButton>(
      find.byKey(const Key('approve_disbursement_button')),
    );
    expect(disabledApprove.onPressed, isNull);
    final enabledReject = tester.widget<OutlinedButton>(
      find.byKey(const Key('reject_disbursement_button')),
    );
    expect(enabledReject.onPressed, isNotNull);

    // 2. Select valid item -> open Password 2FA modal
    await tester.tap(
      find.byKey(const Key('disbursement_queue_item_CFD00VALID000001')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('approve_disbursement_button')));
    await tester.pumpAndSettle();

    // Confirm disabled until password entered
    final emptyPwdConfirm = tester.widget<ElevatedButton>(
      find.byKey(const Key('confirm_approve_disbursement_button')),
    );
    expect(emptyPwdConfirm.onPressed, isNull);

    // Wrong password -> inline error shown cleanly without closing dialog
    await tester.enterText(
      find.byKey(const Key('approve_disbursement_password_input')),
      'wrongpass',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm_approve_disbursement_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('approve_disbursement_error_box')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Mật khẩu xác nhận không chính xác'),
      findsOneWidget,
    );

    // Correct password ('123456') -> seals SHA-256 & updates header balance (850M - 120M = 730M)
    await tester.enterText(
      find.byKey(const Key('approve_disbursement_password_input')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('approve_disbursement_description_input')),
      'Trưởng tộc đã kiểm tra dự toán và ký duyệt chi.',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm_approve_disbursement_button')),
    );
    await tester.pumpAndSettle();

    expect(repo.lastReviewDto?.confirmPassword, '123456');
    expect(
      find.byKey(const Key('disbursement_sealed_ledger_card')),
      findsOneWidget,
    );
    expect(find.text('LDG00NEWDISB001'), findsOneWidget);
    expect(find.text('c' * 64), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('disbursement_header_balance_pill')),
        matching: find.textContaining('730.000.000'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medium Desktop 1024x800 renders cleanly with zero overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeReviewDisbursementRepo(
      balance: const CommonFundBalanceModel(
        clanId: 'CLAN_01',
        availableBalance: 850000000,
        pendingDisbursementAmount: 1040000000,
      ),
      items: sampleItems,
    );

    await tester.pumpWidget(buildApp(repo: repo));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('disbursement_desktop_decision_bar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reject flow enforces mandatory reason and keeps fund balance intact',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeReviewDisbursementRepo(
      balance: const CommonFundBalanceModel(
        clanId: 'CLAN_01',
        availableBalance: 850000000,
        pendingDisbursementAmount: 1040000000,
      ),
      items: sampleItems,
    );

    await tester.pumpWidget(buildApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reject_disbursement_button')));
    await tester.pumpAndSettle();

    final emptyRejectBtn = tester.widget<ElevatedButton>(
      find.byKey(const Key('confirm_reject_disbursement_button')),
    );
    expect(emptyRejectBtn.onPressed, isNull);

    await tester.tap(
      find.text('Thiếu hóa đơn, dự toán hoặc biên bản nghiệm thu đính kèm.'),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('confirm_reject_disbursement_button')),
    );
    await tester.pumpAndSettle();

    expect(repo.lastReviewDto?.approved, isFalse);
    expect(find.byKey(const Key('disbursement_rejected_card')), findsOneWidget);
    expect(repo.balance.availableBalance, 850000000);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile 390x844 navigates List <-> Detail with sticky bar & zero overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeReviewDisbursementRepo(
      balance: const CommonFundBalanceModel(
        clanId: 'CLAN_01',
        availableBalance: 850000000,
        pendingDisbursementAmount: 1040000000,
      ),
      items: sampleItems,
    );

    await tester.pumpWidget(buildApp(repo: repo));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('disbursement_review_queue_panel')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('disbursement_queue_item_CFD00VALID000001')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('disbursement_mobile_decision_bar')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('disbursement_review_back_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('disbursement_review_queue_panel')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RBAC Guard locks Approve & Reject for BRANCH_HEAD & downloads evidence',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const branchHeadSession = DualRbacSession(
      accountId: 'ACC_CHI',
      memberId: 'MEM_CHI',
      fullName: 'Trưởng chi 2',
      branchName: 'Chi 2',
      globalRoles: {SystemRole.roleBranchHead, SystemRole.roleMember},
    );

    final repo = FakeReviewDisbursementRepo(
      balance: const CommonFundBalanceModel(
        clanId: 'CLAN_01',
        availableBalance: 850000000,
        pendingDisbursementAmount: 1040000000,
      ),
      items: sampleItems,
    );
    final ledgerRepo = FakeDisbReviewLedgerRepo();
    final fileActions = FakeDisbReviewFileActions();

    await tester.pumpWidget(
      buildApp(
        repo: repo,
        ledgerRepo: ledgerRepo,
        fileActions: fileActions,
        session: branchHeadSession,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('disbursement_review_rbac_banner')),
      findsOneWidget,
    );
    final approveBtn = tester.widget<ElevatedButton>(
      find.byKey(const Key('approve_disbursement_button')),
    );
    final rejectBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('reject_disbursement_button')),
    );
    expect(approveBtn.onPressed, isNull);
    expect(rejectBtn.onPressed, isNull);

    final evBtn = find.byKey(const Key('disbursement_open_evidence_button'));
    await tester.ensureVisible(evBtn);
    await tester.tap(evBtn);
    await tester.pumpAndSettle();

    expect(ledgerRepo.downloadCount, 1);
    expect(fileActions.saveCount, 1);
    expect(
      fileActions.lastSavedName,
      '661e8400-e29b-41d4-a716-446655440111.pdf',
    );
    expect(tester.takeException(), isNull);
  });
}
