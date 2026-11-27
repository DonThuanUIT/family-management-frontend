import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/core/files/member_file_actions.dart';
import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/core/theme/app_theme.dart';
import 'package:familyfund_app/features/finance/data/models/immutable_ledger_integrity_models.dart';
import 'package:familyfund_app/features/finance/data/models/ledger_adjustment_models.dart';
import 'package:familyfund_app/features/finance/data/models/ledger_annual_audit_models.dart';
import 'package:familyfund_app/features/finance/data/repositories/ledger_repository_impl.dart';
import 'package:familyfund_app/features/finance/domain/repositories/ledger_repository.dart';
import 'package:familyfund_app/features/finance/presentation/screens/review_ledger_adjustment_screen.dart';

class _FixedReviewRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _fixed;
  _FixedReviewRbacNotifier(this._fixed);

  @override
  DualRbacSession build() => _fixed;
}

class FakeReviewLedgerRepository implements LedgerRepository {
  final List<LedgerHistoryItemModel> ledgerItems;
  final List<LedgerAdjustmentRequestModel> adjustmentItems;
  double currentFundBalance;

  int reviewCallCount = 0;
  ReviewLedgerAdjustmentRequestDto? lastReviewDto;
  int downloadEvidenceCallCount = 0;
  String? lastDownloadedEvidenceUrl;

  FakeReviewLedgerRepository({
    required this.ledgerItems,
    required this.adjustmentItems,
    this.currentFundBalance = 100000000,
  });

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
  }) async {
    return LedgerHistoryPageModel(
      clanId: 'CLAN_01',
      items: ledgerItems,
      page: page,
      size: size,
      totalElements: ledgerItems.length,
      totalPages: 1,
      summary: LedgerFlowSummaryModel(currentFundBalance: currentFundBalance),
    );
  }

  @override
  Future<LedgerIntegrityReportModel> verifyLedgerIntegrity() async {
    return LedgerIntegrityReportModel(
      clanId: 'CLAN_01',
      valid: true,
      totalEntries: ledgerItems.length,
      verifiedEntries: ledgerItems.length,
      verifiedAt: DateTime(2026, 11, 27),
    );
  }

  @override
  Future<LedgerHistoryItemModel> getTransactionDetail(
    String transactionId,
  ) async {
    return ledgerItems.firstWhere((e) => e.transactionId == transactionId);
  }

  @override
  Future<List<LedgerAdjustmentRequestModel>> searchAdjustmentRequests({
    String? originalTransactionId,
    LedgerAdjustmentStatusEnum? status,
  }) async {
    return adjustmentItems.where((item) {
      if (status != null && item.approvalStatus != status) return false;
      if (originalTransactionId != null &&
          item.originalTransactionId != originalTransactionId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<LedgerAdjustmentRequestModel> getAdjustmentRequestById(
    String requestId,
  ) async {
    return adjustmentItems.firstWhere((e) => e.requestId == requestId);
  }

  @override
  Future<ReviewLedgerAdjustmentResponseModel> reviewAdjustment(
    ReviewLedgerAdjustmentRequestDto request,
  ) async {
    reviewCallCount++;
    lastReviewDto = request;

    final idx = adjustmentItems.indexWhere(
      (e) => e.requestId == request.requestId,
    );
    final existing = adjustmentItems[idx];

    if (request.approved) {
      currentFundBalance += existing.proposedAdjustmentAmount;
      final updatedReq = LedgerAdjustmentRequestModel(
        requestId: existing.requestId,
        originalTransactionId: existing.originalTransactionId,
        clanId: existing.clanId,
        eventId: existing.eventId,
        originalTransactionType: existing.originalTransactionType,
        originalTransactionAmount: existing.originalTransactionAmount,
        proposedAdjustmentAmount: existing.proposedAdjustmentAmount,
        adjustmentReason: existing.adjustmentReason,
        evidenceAttachmentUrl: existing.evidenceAttachmentUrl,
        proposedByAccountId: existing.proposedByAccountId,
        approvalStatus: LedgerAdjustmentStatusEnum.approved,
        reviewedByAccountId: 'ACC_TRUONG_TOC',
        createdAt: existing.createdAt,
        reviewedAt: DateTime(2026, 11, 27, 10, 30),
      );
      adjustmentItems[idx] = updatedReq;

      final entry = ImmutableLedgerEntryModel(
        transactionId: 'LDG00NEWADJUST01',
        clanId: existing.clanId,
        eventId: existing.eventId,
        adjustmentRequestId: existing.requestId,
        originalTransactionId: existing.originalTransactionId,
        transactionType: LedgerTransactionTypeEnum.adjustmentTransaction,
        amount: existing.proposedAdjustmentAmount,
        runningBalance: currentFundBalance,
        description: request.description?.trim().isNotEmpty == true
            ? request.description!.trim()
            : 'Bù trừ giao dịch ${existing.originalTransactionId} (${existing.requestId})',
        createdByAccountId: existing.proposedByAccountId,
        approvedByAccountId: 'ACC_TRUONG_TOC',
        previousHash: 'a' * 64,
        recordHash: 'b' * 64,
        createdAt: DateTime(2026, 11, 27, 10, 30),
      );

      return ReviewLedgerAdjustmentResponseModel(
        adjustmentRequest: updatedReq,
        ledgerEntry: entry,
      );
    } else {
      final updatedReq = LedgerAdjustmentRequestModel(
        requestId: existing.requestId,
        originalTransactionId: existing.originalTransactionId,
        clanId: existing.clanId,
        eventId: existing.eventId,
        originalTransactionType: existing.originalTransactionType,
        originalTransactionAmount: existing.originalTransactionAmount,
        proposedAdjustmentAmount: existing.proposedAdjustmentAmount,
        adjustmentReason: existing.adjustmentReason,
        evidenceAttachmentUrl: existing.evidenceAttachmentUrl,
        proposedByAccountId: existing.proposedByAccountId,
        approvalStatus: LedgerAdjustmentStatusEnum.rejected,
        reviewedByAccountId: 'ACC_TRUONG_TOC',
        rejectionReason: request.rejectionReason,
        createdAt: existing.createdAt,
        reviewedAt: DateTime(2026, 11, 27, 10, 35),
      );
      adjustmentItems[idx] = updatedReq;
      return ReviewLedgerAdjustmentResponseModel(
        adjustmentRequest: updatedReq,
        ledgerEntry: null,
      );
    }
  }

  @override
  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl) async {
    downloadEvidenceCallCount++;
    lastDownloadedEvidenceUrl = evidenceUrl;
    return Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits);
  }

  @override
  Future<LedgerAdjustmentRequestModel> proposeAdjustment(
    ProposeLedgerAdjustmentRequestDto request,
  ) {
    throw UnimplementedError();
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

class FakeReviewFileActions extends MemberFileActions {
  int saveCallCount = 0;
  String? lastSavedFilename;
  String? lastSavedMimeType;

  @override
  Future<List<SelectedMediaFile>> pick({bool portrait = false}) async {
    return const [];
  }

  @override
  Future<bool> save(Uint8List bytes, String filename, String mimeType) async {
    saveCallCount++;
    lastSavedFilename = filename;
    lastSavedMimeType = mimeType;
    return true;
  }
}

void main() {
  late List<LedgerHistoryItemModel> sampleLedger;
  late List<LedgerAdjustmentRequestModel> sampleAdjustments;

  setUp(() {
    sampleLedger = [
      LedgerHistoryItemModel(
        transactionId: 'LDG00DEMO20260001',
        clanId: 'CLAN_01',
        eventId: 'EVT_2026_GIOTO',
        transactionType: LedgerTransactionTypeEnum.surplusTransfer,
        amount: 150000000,
        runningBalance: 150000000,
        description: 'Chuyển thặng dư Đại lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        createdAt: DateTime(2026, 11, 25, 9, 0),
        netAdjustedAmount: 150000000,
      ),
      LedgerHistoryItemModel(
        transactionId: 'LDG00DEMO20260002',
        clanId: 'CLAN_01',
        transactionType: LedgerTransactionTypeEnum.commonFundDisbursement,
        amount: -50000000,
        runningBalance: 100000000,
        description: 'Chi tổ chức lễ vật, cỗ bàn Đại lễ Giỗ Tổ 2026',
        createdAt: DateTime(2026, 11, 26, 10, 0),
        netAdjustedAmount: -50000000,
      ),
    ];

    sampleAdjustments = [
      LedgerAdjustmentRequestModel(
        requestId: 'LAR00VALID000001',
        originalTransactionId: 'LDG00DEMO20260001',
        clanId: 'CLAN_01',
        eventId: 'EVT_2026_GIOTO',
        originalTransactionType: LedgerTransactionTypeEnum.surplusTransfer,
        originalTransactionAmount: 150000000,
        proposedAdjustmentAmount: 14800000,
        adjustmentReason:
            'Đối soát lại phiếu thu tiền công đức bổ sung từ Chi 3 nộp sau đại lễ.',
        evidenceAttachmentUrl:
            '/api/v1/ledger/evidence/550e8400-e29b-41d4-a716-446655440000.pdf',
        proposedByAccountId: 'ACC_THU_QUY',
        approvalStatus: LedgerAdjustmentStatusEnum.pending,
        createdAt: DateTime(2026, 11, 27, 9, 15),
      ),
      LedgerAdjustmentRequestModel(
        requestId: 'LAR00OVERDRAFT02',
        originalTransactionId: 'LDG00DEMO20260002',
        clanId: 'CLAN_01',
        originalTransactionType:
            LedgerTransactionTypeEnum.commonFundDisbursement,
        originalTransactionAmount: -50000000,
        proposedAdjustmentAmount: -120000000,
        adjustmentReason:
            'Kiểm thử đề xuất trừ vượt số dư Quỹ chung để kiểm tra khóa nút Phê duyệt.',
        proposedByAccountId: 'ACC_THU_QUY',
        approvalStatus: LedgerAdjustmentStatusEnum.pending,
        createdAt: DateTime(2026, 11, 27, 9, 45),
      ),
      LedgerAdjustmentRequestModel(
        requestId: 'LAR00REJECTED003',
        originalTransactionId: 'LDG00DEMO20260001',
        clanId: 'CLAN_01',
        originalTransactionType: LedgerTransactionTypeEnum.surplusTransfer,
        originalTransactionAmount: 150000000,
        proposedAdjustmentAmount: -5000000,
        adjustmentReason: 'Điều chỉnh giảm quỹ dự kiến ban đầu.',
        proposedByAccountId: 'ACC_THU_QUY',
        approvalStatus: LedgerAdjustmentStatusEnum.rejected,
        reviewedByAccountId: 'ACC_TRUONG_TOC',
        rejectionReason: 'Chưa đính kèm chứng từ ngân hàng đối chiếu.',
        createdAt: DateTime(2026, 11, 20, 14, 0),
        reviewedAt: DateTime(2026, 11, 20, 15, 0),
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
    required FakeReviewLedgerRepository repo,
    FakeReviewFileActions? fileActions,
    DualRbacSession session = clanHeadSession,
    String? initialRequestId,
  }) {
    return ProviderScope(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repo),
        dualRbacSessionProvider.overrideWith(
          () => _FixedReviewRbacNotifier(session),
        ),
        if (fileActions != null)
          memberFileActionsProvider.overrideWithValue(fileActions),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: ReviewLedgerAdjustmentScreen(
          initialRequestId: initialRequestId,
        ),
      ),
    );
  }

  testWidgets(
      'Desktop 1280x900: Overdraft blocks Approve, Valid Approve seals SHA-256 entry and updates Fund Balance',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeReviewLedgerRepository(
      ledgerItems: sampleLedger,
      adjustmentItems: sampleAdjustments,
      currentFundBalance: 100000000,
    );

    await tester.pumpWidget(buildApp(repo: repo));
    await tester.pumpAndSettle();

    // Master-Detail visible side by side
    expect(find.byKey(const Key('review_queue_panel')), findsOneWidget);
    expect(
      find.byKey(const Key('desktop_decision_action_bar')),
      findsOneWidget,
    );
    expect(find.text('LAR00VALID000001'), findsAtLeastNWidgets(1));

    // Select overdraft item -> Approve disabled, Reject stays enabled
    await tester.tap(find.byKey(const Key('queue_item_LAR00OVERDRAFT02')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('review_overdraft_warning_banner')),
      findsOneWidget,
    );
    final disabledApprove = tester.widget<ElevatedButton>(
      find.byKey(const Key('approve_adjustment_button')),
    );
    expect(disabledApprove.onPressed, isNull);
    final enabledReject = tester.widget<OutlinedButton>(
      find.byKey(const Key('reject_adjustment_button')),
    );
    expect(enabledReject.onPressed, isNotNull);

    // Select valid item -> Approve dialog -> Confirm -> Sealed SHA-256 card
    await tester.tap(find.byKey(const Key('queue_item_LAR00VALID000001')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('approve_adjustment_button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('approve_description_input')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('approve_description_input')),
      'Đồng ý bổ sung công đức Chi 3 vào Sổ cái.',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_approve_adjustment_button')));
    await tester.pumpAndSettle();

    expect(repo.reviewCallCount, 1);
    expect(repo.lastReviewDto?.requestId, 'LAR00VALID000001');
    expect(repo.lastReviewDto?.approved, isTrue);
    expect(
      repo.lastReviewDto?.description,
      'Đồng ý bổ sung công đức Chi 3 vào Sổ cái.',
    );

    expect(find.byKey(const Key('sealed_ledger_entry_card')), findsOneWidget);
    expect(find.text('LDG00NEWADJUST01'), findsOneWidget);
    expect(find.text('b' * 64), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('header_fund_balance_pill')),
        matching: find.textContaining('114.800.000'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Medium Desktop 1024x800: Master-Detail + Decision Bar fit cleanly with zero overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeReviewLedgerRepository(
      ledgerItems: sampleLedger,
      adjustmentItems: sampleAdjustments,
      currentFundBalance: 100000000,
    );

    await tester.pumpWidget(buildApp(repo: repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review_queue_panel')), findsOneWidget);
    expect(
      find.byKey(const Key('desktop_decision_action_bar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Reject flow: Enforces mandatory rejectionReason >= 5 chars and renders rejected outcome card',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeReviewLedgerRepository(
      ledgerItems: sampleLedger,
      adjustmentItems: sampleAdjustments,
      currentFundBalance: 100000000,
    );

    await tester.pumpWidget(buildApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('queue_item_LAR00OVERDRAFT02')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reject_adjustment_button')));
    await tester.pumpAndSettle();

    // Initially confirm button is disabled
    final initialConfirmBtn = tester.widget<ElevatedButton>(
      find.byKey(const Key('confirm_reject_adjustment_button')),
    );
    expect(initialConfirmBtn.onPressed, isNull);

    // Quick chip populates valid reason and enables confirm button
    await tester.tap(
      find.text('Số liệu đối chiếu chưa khớp với sao kê ngân hàng.'),
    );
    await tester.pumpAndSettle();

    final enabledConfirmBtn = tester.widget<ElevatedButton>(
      find.byKey(const Key('confirm_reject_adjustment_button')),
    );
    expect(enabledConfirmBtn.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('confirm_reject_adjustment_button')));
    await tester.pumpAndSettle();

    expect(repo.reviewCallCount, 1);
    expect(repo.lastReviewDto?.approved, isFalse);
    expect(
      repo.lastReviewDto?.rejectionReason,
      'Số liệu đối chiếu chưa khớp với sao kê ngân hàng.',
    );
    expect(repo.currentFundBalance, 100000000);
    expect(find.byKey(const Key('rejected_outcome_card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Mobile 390x844: Navigates List <-> Detail cleanly without overflow and shows sticky footer',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeReviewLedgerRepository(
      ledgerItems: sampleLedger,
      adjustmentItems: sampleAdjustments,
      currentFundBalance: 100000000,
    );

    await tester.pumpWidget(buildApp(repo: repo));
    await tester.pumpAndSettle();

    // Initially on Queue List
    expect(find.byKey(const Key('review_queue_panel')), findsOneWidget);
    expect(
      find.byKey(const Key('mobile_decision_action_bar')),
      findsNothing,
    );

    // Tap item -> enters Detail screen with sticky footer
    await tester.tap(find.byKey(const Key('queue_item_LAR00VALID000001')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mobile_decision_action_bar')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('approve_adjustment_button')), findsOneWidget);
    expect(find.byKey(const Key('reject_adjustment_button')), findsOneWidget);

    // Tap AppBar back -> returns to Queue List
    await tester.tap(find.byKey(const Key('review_back_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review_queue_panel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'RBAC Guard: BRANCH_HEAD sees read-only banner and both Approve & Reject are disabled',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const branchHeadSession = DualRbacSession(
      accountId: 'ACC_BRANCH',
      memberId: 'MEM_BRANCH',
      fullName: 'Trưởng chi 2',
      branchName: 'Chi 2',
      globalRoles: {SystemRole.roleBranchHead, SystemRole.roleMember},
    );

    final repo = FakeReviewLedgerRepository(
      ledgerItems: sampleLedger,
      adjustmentItems: sampleAdjustments,
    );

    await tester.pumpWidget(
      buildApp(repo: repo, session: branchHeadSession),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('review_rbac_warning_banner')), findsOneWidget);
    final approveBtn = tester.widget<ElevatedButton>(
      find.byKey(const Key('approve_adjustment_button')),
    );
    final rejectBtn = tester.widget<OutlinedButton>(
      find.byKey(const Key('reject_adjustment_button')),
    );
    expect(approveBtn.onPressed, isNull);
    expect(rejectBtn.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Evidence button downloads internal PDF via authenticated proxy',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeReviewLedgerRepository(
      ledgerItems: sampleLedger,
      adjustmentItems: sampleAdjustments,
    );
    final fileActions = FakeReviewFileActions();

    await tester.pumpWidget(
      buildApp(repo: repo, fileActions: fileActions),
    );
    await tester.pumpAndSettle();

    final evidenceBtn = find.byKey(const Key('review_open_evidence_button'));
    await tester.ensureVisible(evidenceBtn);
    await tester.tap(evidenceBtn);
    await tester.pumpAndSettle();

    expect(repo.downloadEvidenceCallCount, 1);
    expect(
      repo.lastDownloadedEvidenceUrl,
      '/api/v1/ledger/evidence/550e8400-e29b-41d4-a716-446655440000.pdf',
    );
    expect(fileActions.saveCallCount, 1);
    expect(
      fileActions.lastSavedFilename,
      '550e8400-e29b-41d4-a716-446655440000.pdf',
    );
    expect(fileActions.lastSavedMimeType, 'application/pdf');
    expect(tester.takeException(), isNull);
  });
}
