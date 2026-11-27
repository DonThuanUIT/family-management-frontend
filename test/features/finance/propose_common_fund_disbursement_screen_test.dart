import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
import 'package:familyfund_app/features/finance/presentation/screens/propose_common_fund_disbursement_screen.dart';
import 'package:familyfund_app/features/genealogy/data/models/branch_models.dart';
import 'package:familyfund_app/features/genealogy/presentation/providers/genealogy_providers.dart';

class _FixedProposeDisbRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _fixed;
  _FixedProposeDisbRbacNotifier(this._fixed);

  @override
  DualRbacSession build() => _fixed;
}

class FakeProposeDisbursementRepo implements CommonFundDisbursementRepository {
  CommonFundBalanceModel balance;
  final List<CommonFundDisbursementModel> items;
  int proposeCallCount = 0;
  ProposeCommonFundDisbursementRequestDto? lastDto;

  FakeProposeDisbursementRepo({
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
    return items.where((item) {
      if (status != null && item.approvalStatus != status) return false;
      if (category != null && item.category != category) return false;
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
  ) async {
    proposeCallCount++;
    lastDto = request;
    return CommonFundDisbursementModel(
      requestId: 'CFD00NEW999888777',
      clanId: balance.clanId,
      title: request.title,
      category: request.category,
      amount: request.amount,
      beneficiaryName: request.beneficiaryName,
      beneficiaryMemberId: request.beneficiaryMemberId,
      purpose: request.purpose,
      attachmentUrl: request.attachmentUrl,
      proposedByAccountId: 'ACC_TRUONG_CHI',
      approvalStatus: CommonFundDisbursementStatusEnum.pending,
      createdAt: DateTime(2026, 11, 27, 15, 0),
    );
  }

  @override
  Future<ReviewCommonFundDisbursementResponseModel> reviewDisbursement(
    String requestId,
    ReviewCommonFundDisbursementRequestDto request,
  ) {
    throw UnimplementedError();
  }
}

class FakeEvidenceLedgerRepo implements LedgerRepository {
  int uploadCallCount = 0;
  String? lastFilename;

  @override
  Future<LedgerEvidenceUploadResult> uploadEvidence({
    required Uint8List bytes,
    required String filename,
    String? originalTransactionId,
  }) async {
    uploadCallCount++;
    lastFilename = filename;
    return LedgerEvidenceUploadResult(
      evidenceUrl:
          '/api/v1/ledger/evidence/661e8400-e29b-41d4-a716-446655440111.pdf',
      fileName: '661e8400-e29b-41d4-a716-446655440111.pdf',
      originalFilename: filename,
      mimeType: 'application/pdf',
      sizeBytes: bytes.length,
      sha256Checksum: 'a' * 64,
    );
  }

  @override
  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl) async {
    return Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits);
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
  Future<LedgerHistoryItemModel> getTransactionDetail(String transactionId) {
    throw UnimplementedError();
  }

  @override
  Future<LedgerAdjustmentRequestModel> proposeAdjustment(
    ProposeLedgerAdjustmentRequestDto request,
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
  Future<LedgerAdjustmentRequestModel> getAdjustmentRequestById(
    String requestId,
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

class FakeDisbFileActions extends MemberFileActions {
  final List<SelectedMediaFile> picked;
  FakeDisbFileActions(this.picked);

  @override
  Future<List<SelectedMediaFile>> pick({bool portrait = false}) async => picked;

  @override
  Future<bool> save(Uint8List bytes, String filename, String mimeType) async =>
      true;
}

void main() {
  const branchHeadSession = DualRbacSession(
    accountId: 'ACC_TRUONG_CHI',
    memberId: 'MEM_CHI',
    fullName: 'Nguyễn Văn An',
    branchName: 'Chi 2',
    globalRoles: {SystemRole.roleBranchHead, SystemRole.roleMember},
  );

  final sampleMembers = [
    const BranchMemberItem(
      memberId: 'MEM_HOA_01',
      fullName: 'Nguyễn Văn Hòa',
      generation: 5,
      roleInBranch: 'Chi 2',
    ),
  ];

  Widget buildApp({
    required FakeProposeDisbursementRepo disbRepo,
    required FakeEvidenceLedgerRepo ledgerRepo,
    FakeDisbFileActions? fileActions,
    DualRbacSession session = branchHeadSession,
  }) {
    return ProviderScope(
      overrides: [
        commonFundDisbursementRepositoryProvider.overrideWithValue(disbRepo),
        ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
        dualRbacSessionProvider.overrideWith(
          () => _FixedProposeDisbRbacNotifier(session),
        ),
        genealogyMemberListProvider.overrideWith((_) async => sampleMembers),
        if (fileActions != null)
          memberFileActionsProvider.overrideWithValue(fileActions),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProposeCommonFundDisbursementScreen(),
      ),
    );
  }

  testWidgets(
      'Desktop 1280x900: Overdraft blocks submit, Member selector + Deferred PDF upload -> Confirm -> CFD success',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final disbRepo = FakeProposeDisbursementRepo(
      balance: const CommonFundBalanceModel(
        clanId: 'CLAN_01',
        availableBalance: 850000000,
        pendingDisbursementAmount: 100000000,
      ),
      items: const [],
    );
    final ledgerRepo = FakeEvidenceLedgerRepo();
    final fileActions = FakeDisbFileActions([
      SelectedMediaFile(
        'Du_toan_trung_tu_2026.pdf',
        1024,
        () async => Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits),
      ),
    ]);

    await tester.pumpWidget(
      buildApp(
        disbRepo: disbRepo,
        ledgerRepo: ledgerRepo,
        fileActions: fileActions,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Select category & fill title
    await tester.tap(find.byKey(const Key('category_card_ReliefSupport')));
    await tester.enterText(
      find.byKey(const Key('disbursement_title_input')),
      'Hỗ trợ gia đình anh Hòa sửa mái nhà sau bão',
    );
    await tester.pumpAndSettle();

    // 2. Overdraft amount (900,000,000 > 850,000,000) shows hard block
    await tester.enterText(
      find.byKey(const Key('disbursement_amount_input')),
      '900000000',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('disbursement_overdraft_warning')), findsOneWidget);
    final blockedBtn = tester.widget<ElevatedButton>(
      find.byKey(const Key('submit_disbursement_desktop_button')),
    );
    expect(blockedBtn.onPressed, isNull);

    // 3. Valid amount 25,000,000 + Member beneficiary
    await tester.enterText(
      find.byKey(const Key('disbursement_amount_input')),
      '25000000',
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Hai mươi lăm triệu đồng chẵn'),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('beneficiary_mode_member')),
    );
    await tester.tap(find.byKey(const Key('beneficiary_mode_member')));
    await tester.pumpAndSettle();

    // 4. Purpose + Deferred PDF upload
    await tester.ensureVisible(
      find.byKey(const Key('disbursement_purpose_input')),
    );
    await tester.tap(find.textContaining('+ Gợi ý mẫu'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('evidence_dropzone_button')));
    await tester.tap(find.byKey(const Key('evidence_dropzone_button')));
    await tester.pumpAndSettle();
    expect(find.text('Du_toan_trung_tu_2026.pdf'), findsOneWidget);
    expect(ledgerRepo.uploadCallCount, 0);

    // 5. Submit -> Confirm -> uploads + proposes
    await tester.ensureVisible(
      find.byKey(const Key('submit_disbursement_desktop_button')),
    );
    await tester.tap(
      find.byKey(const Key('submit_disbursement_desktop_button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('confirm_submit_disbursement_button')),
    );
    await tester.pumpAndSettle();

    expect(ledgerRepo.uploadCallCount, 1);
    expect(ledgerRepo.lastFilename, 'Du_toan_trung_tu_2026.pdf');
    expect(disbRepo.proposeCallCount, 1);
    expect(
      disbRepo.lastDto?.category,
      CommonFundExpenseCategoryEnum.reliefSupport,
    );
    expect(disbRepo.lastDto?.amount, 25000000.0);
    expect(disbRepo.lastDto?.beneficiaryMemberId, 'MEM_HOA_01');
    expect(
      disbRepo.lastDto?.attachmentUrl,
      '/api/v1/ledger/evidence/661e8400-e29b-41d4-a716-446655440111.pdf',
    );
    expect(find.text('CFD00NEW999888777'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile 390x844 layout renders cleanly with sticky footer and zero overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final disbRepo = FakeProposeDisbursementRepo(
      balance: const CommonFundBalanceModel(
        clanId: 'CLAN_01',
        availableBalance: 850000000,
        pendingDisbursementAmount: 0,
      ),
      items: const [],
    );

    await tester.pumpWidget(
      buildApp(
        disbRepo: disbRepo,
        ledgerRepo: FakeEvidenceLedgerRepo(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('submit_disbursement_mobile_button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Regular MEMBER sees RBAC warning banner and cannot submit',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const memberSession = DualRbacSession(
      accountId: 'ACC_MEM',
      memberId: 'MEM_01',
      fullName: 'Thành viên thường',
      branchName: 'Chi 2',
      globalRoles: {SystemRole.roleMember},
    );

    final disbRepo = FakeProposeDisbursementRepo(
      balance: const CommonFundBalanceModel(
        clanId: 'CLAN_01',
        availableBalance: 850000000,
        pendingDisbursementAmount: 0,
      ),
      items: const [],
    );

    await tester.pumpWidget(
      buildApp(
        disbRepo: disbRepo,
        ledgerRepo: FakeEvidenceLedgerRepo(),
        session: memberSession,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('disbursement_propose_rbac_banner')),
      findsOneWidget,
    );
    final btn = tester.widget<ElevatedButton>(
      find.byKey(const Key('submit_disbursement_desktop_button')),
    );
    expect(btn.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
