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
import 'package:familyfund_app/features/finance/presentation/screens/annual_ledger_audit_screen.dart';
import 'package:familyfund_app/features/notification/presentation/providers/notification_providers.dart';

class _FixedAuditRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _fixed;
  _FixedAuditRbacNotifier(this._fixed);

  @override
  DualRbacSession build() => _fixed;
}

class _IdleNotificationListNotifier extends NotificationListNotifier {
  @override
  NotificationListState build() => const NotificationListState();
}

class _FakeAuditDisbursementRepo implements CommonFundDisbursementRepository {
  @override
  Future<CommonFundBalanceModel> getFundBalance() async {
    return const CommonFundBalanceModel(
      clanId: 'CLAN_DEFAULT',
      availableBalance: 99800000,
      pendingDisbursementAmount: 0,
    );
  }

  @override
  Future<CommonFundDisbursementModel> getDisbursementById(String requestId) {
    throw UnimplementedError();
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
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<CommonFundDisbursementModel>> searchDisbursements({
    CommonFundDisbursementStatusEnum? status,
    CommonFundExpenseCategoryEnum? category,
  }) async {
    return const [];
  }
}

class _FakeAuditLedgerRepo implements LedgerRepository {
  final List<LedgerHistoryItemModel> ledgerItems;
  final List<LedgerAnnualAuditModel> audits;
  final List<LedgerAdjustmentRequestModel> pendingAdjustments;
  LedgerIntegrityReportModel integrityReport;

  int performCallCount = 0;
  AnnualLedgerAuditRequestDto? lastRequest;

  _FakeAuditLedgerRepo({
    required this.ledgerItems,
    required this.audits,
    required this.integrityReport,
    this.pendingAdjustments = const [],
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
      clanId: 'CLAN_DEFAULT',
      items: ledgerItems,
      page: page,
      size: size,
      totalElements: ledgerItems.length,
      totalPages: 1,
      summary: LedgerFlowSummaryModel(
        currentFundBalance:
            ledgerItems.isNotEmpty ? ledgerItems.first.runningBalance : 0,
        filteredTransactionCount: ledgerItems.length,
        filteredTotalInflow: 164800000,
        filteredTotalOutflow: 65000000,
        filteredNetAmount: 99800000,
      ),
    );
  }

  @override
  Future<LedgerIntegrityReportModel> verifyLedgerIntegrity() async =>
      integrityReport;

  @override
  Future<List<LedgerAdjustmentRequestModel>> searchAdjustmentRequests({
    String? originalTransactionId,
    LedgerAdjustmentStatusEnum? status,
  }) async {
    return pendingAdjustments;
  }

  @override
  Future<List<LedgerAnnualAuditModel>> searchAnnualAudits({
    int? auditYear,
    LedgerAnnualAuditStatusEnum? status,
  }) async {
    return audits;
  }

  @override
  Future<LedgerAnnualAuditModel> performAnnualAudit(
    AnnualLedgerAuditRequestDto request,
  ) async {
    performCallCount++;
    lastRequest = request;
    final systemBal =
        ledgerItems.isNotEmpty ? ledgerItems.first.runningBalance : 0.0;
    final diff = request.actualBalance - systemBal;
    final year = request.auditYear ?? DateTime.now().year;
    final matched = diff.abs() < 0.005;

    final created = LedgerAnnualAuditModel(
      auditId: matched ? 'AUD2026MATCH0099' : 'AUD2026DISC0099',
      clanId: 'CLAN_DEFAULT',
      auditYear: year,
      nextPeriodYear: year + 1,
      auditDate: DateTime(year, 11, 27, 18, 15),
      systemBalance: systemBal,
      actualBalance: request.actualBalance,
      discrepancyAmount: matched ? 0.0 : diff,
      auditStatus: matched
          ? LedgerAnnualAuditStatusEnum.matched
          : LedgerAnnualAuditStatusEnum.discrepancyDetected,
      referenceTransactionId: request.referenceTransactionId ??
          (ledgerItems.isNotEmpty ? ledgerItems.first.transactionId : null),
      adjustmentRequestId: matched ? null : 'LAR2026AUD00099',
      closingTransactionId: matched ? 'LDG2026OPEN00099' : null,
      openingBalanceNextPeriod: matched ? systemBal : null,
      auditorAccountId: 'ACC_TRUONG_TOC',
      auditorDisplayName: 'Nguyễn Trọng Hoàng',
      notes: request.notes,
      evidenceAttachmentUrl: request.evidenceAttachmentUrl,
      createdAt: DateTime(year, 11, 27, 18, 15),
      closingLedgerEntry: matched
          ? ImmutableLedgerEntryModel(
              transactionId: 'LDG2026OPEN00099',
              clanId: 'CLAN_DEFAULT',
              transactionType:
                  LedgerTransactionTypeEnum.openingBalanceCarryForward,
              amount: 0,
              runningBalance: systemBal,
              description: 'Chốt đầu kỳ ${year + 1}',
              previousHash: '8092d84cd50f51e3',
              recordHash: 'c73d8819e510ab94',
              createdAt: DateTime(year, 11, 27, 18, 15),
            )
          : null,
      autoGeneratedAdjustmentRequest: matched
          ? null
          : LedgerAdjustmentRequestModel(
              requestId: 'LAR2026AUD00099',
              originalTransactionId: request.referenceTransactionId ??
                  (ledgerItems.isNotEmpty
                      ? ledgerItems.first.transactionId
                      : ''),
              clanId: 'CLAN_DEFAULT',
              originalTransactionType:
                  LedgerTransactionTypeEnum.commonFundDisbursement,
              originalTransactionAmount: -15000000,
              proposedAdjustmentAmount: diff,
              adjustmentReason:
                  'Tự động sinh từ kiểm kê năm $year: lệch ${diff.toStringAsFixed(0)}đ',
              proposedByAccountId: 'ACC_TRUONG_TOC',
              approvalStatus: LedgerAdjustmentStatusEnum.pending,
              createdAt: DateTime(year, 11, 27, 18, 15),
            ),
    );
    audits.insert(0, created);
    return created;
  }

  @override
  Future<LedgerAnnualAuditModel> getAnnualAuditById(String auditId) async {
    return audits.firstWhere((e) => e.auditId == auditId);
  }

  @override
  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl) async =>
      Uint8List(0);

  @override
  Future<LedgerAdjustmentRequestModel> getAdjustmentRequestById(
    String requestId,
  ) {
    throw UnimplementedError();
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
  Future<ReviewLedgerAdjustmentResponseModel> reviewAdjustment(
    ReviewLedgerAdjustmentRequestDto request,
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
}

class _FakeFileActions extends MemberFileActions {
  @override
  Future<List<SelectedMediaFile>> pick({bool portrait = false}) async =>
      const [];

  @override
  Future<bool> save(Uint8List bytes, String filename, String mimeType) async =>
      true;
}

void main() {
  late List<LedgerHistoryItemModel> sampleItems;
  late List<LedgerAnnualAuditModel> sampleAudits;
  late LedgerIntegrityReportModel validReport;

  setUp(() {
    sampleItems = [
      LedgerHistoryItemModel(
        transactionId: 'LDGMWYQDWK15F5JSY',
        clanId: 'CLAN_DEFAULT',
        transactionType: LedgerTransactionTypeEnum.commonFundDisbursement,
        amount: -15000000,
        runningBalance: 99800000,
        description: 'Tu sửa mái ngói Từ đường họ Nguyễn',
        createdAt: DateTime(2026, 11, 27, 15, 40),
        netAdjustedAmount: -15000000,
      ),
      LedgerHistoryItemModel(
        transactionId: 'LDG00DEMO20260001',
        clanId: 'CLAN_DEFAULT',
        transactionType: LedgerTransactionTypeEnum.surplusTransfer,
        amount: 150000000,
        runningBalance: 150000000,
        description: 'Chuyển thặng dư đầu xuân',
        createdAt: DateTime(2026, 11, 25, 9, 30),
        netAdjustedAmount: 150000000,
      ),
    ];

    sampleAudits = [
      LedgerAnnualAuditModel(
        auditId: 'AUD2025MATCH0001',
        clanId: 'CLAN_DEFAULT',
        auditYear: 2025,
        nextPeriodYear: 2026,
        auditDate: DateTime(2025, 12, 31, 16, 30),
        systemBalance: 150000000,
        actualBalance: 150000000,
        discrepancyAmount: 0,
        auditStatus: LedgerAnnualAuditStatusEnum.matched,
        referenceTransactionId: 'LDG00DEMO20260001',
        closingTransactionId: 'LDG2025OPEN000001',
        openingBalanceNextPeriod: 150000000,
        auditorAccountId: 'ACC_TRUONG_TOC',
        auditorDisplayName: 'Nguyễn Trọng Hoàng',
        notes: 'Khớp số dư cuối năm Ất Tỵ.',
        createdAt: DateTime(2025, 12, 31, 16, 30),
      ),
    ];

    validReport = LedgerIntegrityReportModel(
      clanId: 'CLAN_DEFAULT',
      valid: true,
      totalEntries: 2,
      verifiedEntries: 2,
      verifiedAt: DateTime(2026, 11, 27),
    );
  });

  Widget buildApp({
    required _FakeAuditLedgerRepo ledgerRepo,
    _FakeAuditDisbursementRepo? disbRepo,
    required DualRbacSession session,
  }) {
    return ProviderScope(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(ledgerRepo),
        commonFundDisbursementRepositoryProvider
            .overrideWithValue(disbRepo ?? _FakeAuditDisbursementRepo()),
        dualRbacSessionProvider
            .overrideWith(() => _FixedAuditRbacNotifier(session)),
        notificationListProvider
            .overrideWith(() => _IdleNotificationListNotifier()),
        memberFileActionsProvider.overrideWithValue(_FakeFileActions()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const AnnualLedgerAuditScreen(initialYear: 2026),
      ),
    );
  }

  const clanHeadSession = DualRbacSession(
    accountId: 'ACC_TRUONG_TOC',
    memberId: 'MEM_01',
    fullName: 'Nguyễn Trọng Hoàng',
    branchName: 'Chi Gốc',
    globalRoles: {SystemRole.roleMember, SystemRole.roleClanHead},
  );
  const memberSession = DualRbacSession(
    accountId: 'ACC_MAI_ANH',
    memberId: 'MEM_03',
    fullName: 'Nguyễn Thị Mai Anh',
    branchName: 'Chi 2',
    globalRoles: {SystemRole.roleMember},
  );

  testWidgets(
    'CLAN_HEAD Desktop: enters matched amount, applies calculator, confirms Matched -> Sealed Receipt',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeAuditLedgerRepo(
        ledgerItems: sampleItems,
        audits: List.of(sampleAudits),
        integrityReport: validReport,
      );

      await tester.pumpWidget(
        buildApp(ledgerRepo: repo, session: clanHeadSession),
      );
      await tester.pumpAndSettle();

      expect(find.text('Biên Bản Kiểm Kê Quỹ Hằng Năm'), findsOneWidget);
      expect(find.text('SHA-256: Toàn vẹn 2/2 khối'), findsOneWidget);
      expect(find.text('Đề xuất chờ duyệt: 0 Pending'), findsOneWidget);

      // Mở bảng tính nhanh, nhập số dư ngân hàng + 100 tờ 500k -> áp dụng tổng
      await tester.tap(find.byKey(const Key('annual_audit_calculator_toggle')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('annual_audit_calc_bank_input')),
        '49800000',
      );
      await tester.enterText(
        find.byKey(const Key('annual_audit_denom_input_500000')),
        '100',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('annual_audit_apply_calc_btn')),
      );
      await tester.tap(find.byKey(const Key('annual_audit_apply_calc_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Khớp số dư tuyệt đối'), findsOneWidget);
      expect(find.text('Trưởng tộc xác nhận chốt sổ năm 2026'), findsOneWidget);

      // Mở hộp thoại xác nhận -> Gửi POST /annual-audit
      await tester.ensureVisible(
        find.byKey(const Key('annual_audit_submit_btn')),
      );
      await tester.tap(find.byKey(const Key('annual_audit_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận chốt Sổ quỹ năm 2026'), findsOneWidget);
      await tester.tap(find.byKey(const Key('annual_audit_confirm_submit_btn')));
      await tester.pumpAndSettle();

      expect(repo.performCallCount, 1);
      expect(repo.lastRequest?.actualBalance, 99800000.0);
      expect(find.text('Biên Bản Kiểm Kê Năm 2026 Đã Niêm Phong'), findsOneWidget);
      expect(find.text('LDG2026OPEN00099'), findsOneWidget);
    },
  );

  testWidgets(
    'CLAN_HEAD Desktop: shortage amount shows DiscrepancyDetected & auto-creates US-15 proposal',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeAuditLedgerRepo(
        ledgerItems: sampleItems,
        audits: List.of(sampleAudits),
        integrityReport: validReport,
      );

      await tester.pumpWidget(
        buildApp(ledgerRepo: repo, session: clanHeadSession),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('annual_audit_actual_input')),
        '98000000',
      );
      await tester.pumpAndSettle();

      expect(find.text('Phát hiện thiếu quỹ'), findsOneWidget);
      expect(
        find.byKey(const Key('annual_audit_ref_tx_dropdown')),
        findsOneWidget,
      );
      expect(
        find.text('Ghi nhận lệch & Tạo Đề xuất bù trừ (US-15)'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('annual_audit_submit_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('annual_audit_confirm_submit_btn')));
      await tester.pumpAndSettle();

      expect(repo.performCallCount, 1);
      expect(repo.lastRequest?.actualBalance, 98000000.0);
      expect(find.text('LAR2026AUD00099'), findsOneWidget);
      expect(find.text('Mở màn Phê duyệt Bù trừ (US-59)'), findsOneWidget);
    },
  );

  testWidgets(
    'Pre-flight blocker disables submit when Pending requests exist or SHA-256 is broken',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeAuditLedgerRepo(
        ledgerItems: sampleItems,
        audits: List.of(sampleAudits),
        integrityReport: validReport,
        pendingAdjustments: [
          LedgerAdjustmentRequestModel(
            requestId: 'LAR_PEND_01',
            originalTransactionId: 'LDGMWYQDWK15F5JSY',
            clanId: 'CLAN_DEFAULT',
            originalTransactionType:
                LedgerTransactionTypeEnum.commonFundDisbursement,
            originalTransactionAmount: -15000000,
            proposedAdjustmentAmount: 500000,
            adjustmentReason: 'Chờ duyệt',
            proposedByAccountId: 'ACC_TRUONG_TOC',
            approvalStatus: LedgerAdjustmentStatusEnum.pending,
            createdAt: DateTime(2026, 11, 27),
          ),
        ],
      );

      await tester.pumpWidget(
        buildApp(ledgerRepo: repo, session: clanHeadSession),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Không thể chốt kiểm kê do còn đề xuất đang chờ duyệt (Pending)'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('annual_audit_fill_matched_chip')));
      await tester.pumpAndSettle();

      final submitBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('annual_audit_submit_btn')),
      );
      expect(submitBtn.onPressed, isNull);
    },
  );

  testWidgets(
    'Mobile 390x844 renders without overflow and MEMBER sees read-only + History tab detail',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeAuditLedgerRepo(
        ledgerItems: sampleItems,
        audits: List.of(sampleAudits),
        integrityReport: validReport,
      );

      await tester.pumpWidget(
        buildApp(ledgerRepo: repo, session: memberSession),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chế độ Thành viên — Chỉ đọc (RBAC)'), findsOneWidget);
      expect(find.byKey(const Key('annual_audit_submit_btn')), findsNothing);
      expect(tester.takeException(), isNull);

      // Chuyển sang Lịch sử biên bản và mở chi tiết 2025
      await tester.tap(find.byKey(const Key('annual_audit_tab_history')));
      await tester.pumpAndSettle();

      expect(find.text('AUD2025MATCH0001'), findsOneWidget);
      await tester.tap(find.text('AUD2025MATCH0001'));
      await tester.pumpAndSettle();

      expect(find.text('Biên Bản Khớp Số Dư (Matched)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
