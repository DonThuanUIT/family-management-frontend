import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/core/theme/app_theme.dart';
import 'package:familyfund_app/core/utils/formatters.dart';
import 'package:familyfund_app/features/finance/data/models/immutable_ledger_integrity_models.dart';
import 'package:familyfund_app/features/finance/data/models/ledger_adjustment_models.dart';
import 'package:familyfund_app/features/finance/data/models/ledger_annual_audit_models.dart';
import 'package:familyfund_app/features/finance/data/repositories/ledger_repository_impl.dart';
import 'package:familyfund_app/features/finance/domain/repositories/ledger_repository.dart';
import 'package:familyfund_app/features/finance/presentation/providers/immutable_ledger_providers.dart';
import 'package:familyfund_app/features/finance/presentation/screens/immutable_ledger_screen.dart';
import 'package:familyfund_app/features/notification/presentation/providers/notification_providers.dart';

class _FixedLedgerRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _fixed;
  _FixedLedgerRbacNotifier(this._fixed);

  @override
  DualRbacSession build() => _fixed;
}

class _IdleNotificationListNotifier extends NotificationListNotifier {
  @override
  NotificationListState build() => const NotificationListState();
}

class FakeImmutableLedgerRepository implements LedgerRepository {
  final List<LedgerHistoryItemModel> allItems;
  LedgerIntegrityReportModel integrityReport;

  int searchCallCount = 0;
  int verifyCallCount = 0;
  String? lastKeyword;
  LedgerTransactionTypeEnum? lastTransactionType;
  bool? lastOnlyWithAdjustments;
  String? lastFrom;
  String? lastTo;
  String lastSortDirection = 'DESC';

  FakeImmutableLedgerRepository({
    required this.allItems,
    required this.integrityReport,
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
    searchCallCount++;
    lastKeyword = keyword;
    lastTransactionType = transactionType;
    lastOnlyWithAdjustments = onlyWithAdjustments;
    lastFrom = from;
    lastTo = to;
    lastSortDirection = sortDirection;

    final q = (keyword ?? '').trim().toLowerCase();
    var filtered = allItems.where((item) {
      if (transactionType != null && item.transactionType != transactionType) {
        return false;
      }
      if (onlyWithAdjustments == true &&
          !item.hasAdjustments &&
          item.adjustmentCount == 0 &&
          !item.isAdjustment) {
        return false;
      }
      if (q.isNotEmpty) {
        return item.transactionId.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q) ||
            item.recordHash.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    if (sortDirection.toUpperCase() == 'ASC') {
      filtered = filtered.reversed.toList();
    }

    double inflow = 0;
    double outflow = 0;
    for (final e in filtered) {
      if (e.amount >= 0) {
        inflow += e.amount;
      } else {
        outflow += e.amount.abs();
      }
    }
    final netAmount = inflow - outflow;
    final opening = from != null ? 100000000.0 : 0.0;
    final closing = opening + netAmount;

    return LedgerHistoryPageModel(
      clanId: 'CLAN_DEFAULT',
      items: filtered,
      page: page,
      size: size,
      totalElements: filtered.length,
      totalPages: 1,
      summary: LedgerFlowSummaryModel(
        currentFundBalance: 99800000,
        latestTransactionId: allItems.first.transactionId,
        latestTransactionAt: allItems.first.createdAt,
        openingBalanceBeforePeriod: opening,
        closingBalanceAtPeriodEnd: closing,
        filteredTransactionCount: filtered.length,
        filteredTotalInflow: inflow,
        filteredTotalOutflow: outflow,
        filteredNetAmount: netAmount,
      ),
    );
  }

  @override
  Future<LedgerIntegrityReportModel> verifyLedgerIntegrity() async {
    verifyCallCount++;
    return integrityReport;
  }

  @override
  Future<LedgerHistoryItemModel> getTransactionDetail(
    String transactionId,
  ) async {
    return allItems.firstWhere((e) => e.transactionId == transactionId);
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
  Future<LedgerEvidenceUploadResult> uploadEvidence({
    required Uint8List bytes,
    required String filename,
    String? originalTransactionId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl) {
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

void main() {
  const hash1 =
      '2ed2315728656968864bd1684e9c5a38d15734cc6e9b33e13ea020a100d8e5e1';
  const hash2 =
      'f5ca443d668b5adf5c58c21c7d55187b11db87544d10ca8ff61e14fe18cfe2ff';
  const hash3 =
      '5ecbe194fcaab9e4e845d9f8f9ee7ae787e6af208a0c86d13efb24b8d94f072e';
  const hash4 =
      '8092d84cd50f51e38fc15ea98db9204566c3ace2d80ba105fee465ea422290d8';

  late List<LedgerHistoryItemModel> chainedItems;

  setUp(() {
    final adjLinked = LinkedLedgerTransactionModel(
      transactionId: 'LDGMWYGB7CX9V7NQZ',
      transactionType: LedgerTransactionTypeEnum.adjustmentTransaction,
      amount: 14800000,
      runningBalance: 114800000,
      description: 'Bù trừ quyết toán chi Lễ Giỗ Tổ Xuân 2026',
      createdAt: DateTime(2026, 11, 27, 10, 58),
    );
    final origLinked = LinkedLedgerTransactionModel(
      transactionId: 'LDG00DEMO20260002',
      transactionType: LedgerTransactionTypeEnum.commonFundDisbursement,
      amount: -50000000,
      runningBalance: 100000000,
      description: 'Chi tổ chức Đại lễ Giỗ Tổ Xuân 2026',
      createdAt: DateTime(2026, 3, 14, 9, 15),
    );

    chainedItems = [
      LedgerHistoryItemModel(
        transactionId: 'LDGMWYQDWK15F5JSY',
        clanId: 'CLAN_DEFAULT',
        disbursementRequestId: 'CFDMWYQ9EDD6AZ5PD',
        disbursementTitle: 'Tu sửa Từ đường',
        transactionType: LedgerTransactionTypeEnum.commonFundDisbursement,
        amount: -15000000,
        runningBalance: 99800000,
        description: 'Tu sửa mái ngói Từ đường họ Nguyễn',
        createdByName: 'Nguyễn Văn Hùng',
        approvedByName: 'Cụ Nguyễn Thế Khiêm',
        previousHash: hash3,
        recordHash: hash4,
        createdAt: DateTime(2026, 11, 27, 15, 40),
        netAdjustedAmount: -15000000,
      ),
      LedgerHistoryItemModel(
        transactionId: 'LDGMWYGB7CX9V7NQZ',
        clanId: 'CLAN_DEFAULT',
        eventId: 'EVT_GIO_TO_2026',
        eventName: 'Đại lễ Giỗ Tổ Xuân 2026',
        originalTransactionId: 'LDG00DEMO20260002',
        transactionType: LedgerTransactionTypeEnum.adjustmentTransaction,
        amount: 14800000,
        runningBalance: 114800000,
        description: 'Bù trừ quyết toán chi Lễ Giỗ Tổ Xuân 2026',
        adjustmentReason: 'Hoàn nhập 14.800.000 đ phần vật tư kết dư.',
        createdByName: 'Ông Nguyễn Văn Phúc',
        approvedByName: 'Cụ Nguyễn Thế Khiêm',
        previousHash: hash2,
        recordHash: hash3,
        createdAt: DateTime(2026, 11, 27, 10, 58),
        isAdjustment: true,
        netAdjustedAmount: 14800000,
        originalTransaction: origLinked,
      ),
      LedgerHistoryItemModel(
        transactionId: 'LDG00DEMO20260002',
        clanId: 'CLAN_DEFAULT',
        eventId: 'EVT_GIO_TO_2026',
        eventName: 'Đại lễ Giỗ Tổ Xuân 2026',
        transactionType: LedgerTransactionTypeEnum.commonFundDisbursement,
        amount: -50000000,
        runningBalance: 100000000,
        description: 'Chi tổ chức Đại lễ Giỗ Tổ Xuân 2026',
        createdByName: 'Nguyễn Văn Hùng',
        approvedByName: 'Cụ Nguyễn Thế Khiêm',
        previousHash: hash1,
        recordHash: hash2,
        createdAt: DateTime(2026, 3, 14, 9, 15),
        hasAdjustments: true,
        adjustmentCount: 1,
        netAdjustedAmount: -35200000,
        adjustmentTransactions: [adjLinked],
      ),
      LedgerHistoryItemModel(
        transactionId: 'LDG00DEMO20260001',
        clanId: 'CLAN_DEFAULT',
        eventName: 'Quỹ công đức đầu xuân 2026',
        transactionType: LedgerTransactionTypeEnum.surplusTransfer,
        amount: 150000000,
        runningBalance: 150000000,
        description: 'Chuyển thặng dư Quỹ đóng góp đầu năm 2026',
        createdByName: 'Ông Nguyễn Văn Phúc',
        approvedByName: 'Cụ Nguyễn Thế Khiêm',
        previousHash: 'GENESIS',
        recordHash: hash1,
        createdAt: DateTime(2026, 2, 1, 8, 0),
        netAdjustedAmount: 150000000,
      ),
    ];
  });

  Widget buildTestApp({
    required FakeImmutableLedgerRepository repo,
    required DualRbacSession session,
    Key? scopeKey,
  }) {
    return ProviderScope(
      key: scopeKey,
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repo),
        dualRbacSessionProvider
            .overrideWith(() => _FixedLedgerRbacNotifier(session)),
        notificationListProvider
            .overrideWith(() => _IdleNotificationListNotifier()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ImmutableLedgerScreen(),
      ),
    );
  }

  void expectNoEditOrDeleteButtons() {
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.text('Sửa'), findsNothing);
    expect(find.text('Xóa'), findsNothing);
  }

  const clanHeadSession = DualRbacSession(
    accountId: 'ACC_TRUONG_TOC',
    memberId: 'MEM_01',
    fullName: 'Cụ Nguyễn Thế Khiêm',
    branchName: 'Chi Gốc',
    globalRoles: {SystemRole.roleClanHead, SystemRole.roleMember},
  );

  const branchHeadSession = DualRbacSession(
    accountId: 'ACC_TRUONG_CHI',
    memberId: 'MEM_02',
    fullName: 'Nguyễn Văn Hùng',
    branchName: 'Chi II',
    globalRoles: {SystemRole.roleBranchHead, SystemRole.roleMember},
  );

  const memberSession = DualRbacSession(
    accountId: 'ACC_MAI_ANH',
    memberId: 'MEM_03',
    fullName: 'Nguyễn Mai Anh',
    branchName: 'Chi II',
    globalRoles: {SystemRole.roleMember},
  );

  const adminSession = DualRbacSession(
    accountId: 'ACC_ADMIN',
    memberId: 'MEM_00',
    fullName: 'Quản trị hệ thống',
    branchName: 'Chi Gốc',
    globalRoles: {SystemRole.roleAdmin},
  );

  testWidgets(
      'Desktop (1280px) & Laptop (1024px) render 5 cash-flow columns, Lunar dates, running balance, and SHA-256 without overflow',
      (tester) async {
    for (final viewportSize in [
      const Size(1280, 900),
      const Size(1024, 800),
    ]) {
      tester.view.physicalSize = viewportSize;
      tester.view.devicePixelRatio = 1.0;

      final repo = FakeImmutableLedgerRepository(
        allItems: chainedItems,
        integrityReport: LedgerIntegrityReportModel(
          clanId: 'CLAN_DEFAULT',
          valid: true,
          totalEntries: 4,
          verifiedEntries: 4,
          verifiedAt: DateTime(2026, 11, 27, 16, 0),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          repo: repo,
          session: clanHeadSession,
          scopeKey: ValueKey(viewportSize.width),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sổ Cái Quỹ Chung Bất Biến'), findsOneWidget);
      expect(find.text('BIẾN ĐỘNG'), findsOneWidget);
      expect(find.text('SỐ DƯ LŨY KẾ'), findsOneWidget);
      expect(find.text('NIÊM PHONG SHA-256'), findsOneWidget);
      expect(find.text(AppFormatters.formatVnd(99800000)), findsWidgets);
      expect(find.text('+${AppFormatters.formatVnd(164800000)}'), findsOneWidget);
      expect(find.text('-${AppFormatters.formatVnd(65000000)}'), findsOneWidget);
      expect(find.text('Bất biến'), findsNWidgets(4));
      expect(find.text('8092d8…90d8'), findsOneWidget);
      expect(find.text('← GENESIS'), findsOneWidget);
      expect(find.textContaining('ÂL'), findsWidgets);
      expect(
        find.textContaining('Ròng sau bù trừ:'),
        findsOneWidget,
      );
      expect(find.text('Đề xuất bù trừ'), findsOneWidget);

      expectNoEditOrDeleteButtons();
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
  });

  testWidgets(
      'Zero Edit/Delete controls exist across all 4 roles and RBAC hides + Đề xuất bù trừ for Member',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    for (final session in [
      clanHeadSession,
      branchHeadSession,
      memberSession,
      adminSession,
    ]) {
      final repo = FakeImmutableLedgerRepository(
        allItems: chainedItems,
        integrityReport: LedgerIntegrityReportModel(
          clanId: 'CLAN_DEFAULT',
          valid: true,
          totalEntries: 4,
          verifiedEntries: 4,
          verifiedAt: DateTime(2026, 11, 27, 16, 0),
        ),
      );
      await tester.pumpWidget(
        buildTestApp(
          repo: repo,
          session: session,
          scopeKey: ValueKey(session.accountId),
        ),
      );
      await tester.pumpAndSettle();
      expectNoEditOrDeleteButtons();

      if (session == clanHeadSession || session == adminSession) {
        expect(find.text('Đề xuất bù trừ'), findsOneWidget);
      } else {
        expect(find.text('Đề xuất bù trừ'), findsNothing);
      }

      // Also verify inside the inspection drawer
      await tester.tap(find.text('Tu sửa mái ngói Từ đường họ Nguyễn'));
      await tester.pumpAndSettle();
      expectNoEditOrDeleteButtons();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
      'Clicking Quick-Jump tag scrolls & highlights target row, or opens detail when filtered out',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeImmutableLedgerRepository(
      allItems: chainedItems,
      integrityReport: LedgerIntegrityReportModel(
        clanId: 'CLAN_DEFAULT',
        valid: true,
        totalEntries: 4,
        verifiedEntries: 4,
        verifiedAt: DateTime(2026, 11, 27, 16, 0),
      ),
    );

    await tester.pumpWidget(
      buildTestApp(repo: repo, session: clanHeadSession),
    );
    await tester.pumpAndSettle();

    // 1. Click visible Quick-Jump tag on adjustment row (#3 -> #2)
    final jumpToOrig = find.text('↳ Gốc: LDG00DEMO20260002 ↓');
    expect(jumpToOrig, findsOneWidget);
    await tester.tap(jumpToOrig);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('Đã nhảy tới bút toán LDG00DEMO20260002'),
      findsOneWidget,
    );

    // Clear highlight timer before ending test
    await tester.pump(const Duration(seconds: 3));

    // 2. Filter to 'Chi quỹ chung' so adjustment LDGMWYGB7CX9V7NQZ is hidden
    await tester.tap(find.widgetWithText(FilterChip, 'Chi quỹ chung'));
    await tester.pumpAndSettle();

    // Click Quick-Jump tag on original row (#2 -> hidden #3) -> opens detail drawer directly
    final jumpToAdj = find.text('⇄ Bù trừ (1): LDGMWYGB7CX9V7NQZ ↑');
    expect(jumpToAdj, findsOneWidget);
    await tester.tap(jumpToAdj);
    await tester.pumpAndSettle();

    expect(find.text('LIÊN KẾT GIAO DỊCH GỐC'), findsOneWidget);
    expect(
      find.text(
        'Bút toán LDGMWYGB7CX9V7NQZ nằm ngoài bộ lọc hiện tại — đã mở thẳng chi tiết.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Period dropdown and Sort toggle forward from/to/sortDirection and show reconciliation strip',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeImmutableLedgerRepository(
      allItems: chainedItems,
      integrityReport: LedgerIntegrityReportModel(
        clanId: 'CLAN_DEFAULT',
        valid: true,
        totalEntries: 4,
        verifiedEntries: 4,
        verifiedAt: DateTime(2026, 11, 27, 16, 0),
      ),
    );

    await tester.pumpWidget(
      buildTestApp(repo: repo, session: clanHeadSession),
    );
    await tester.pumpAndSettle();
    expect(repo.lastSortDirection, 'DESC');

    // Toggle sort direction DESC -> ASC
    await tester.tap(find.text('Mới nhất ↓'));
    await tester.pumpAndSettle();
    expect(repo.lastSortDirection, 'ASC');
    expect(find.text('Cũ nhất ↑'), findsOneWidget);
    // Arrow on Quick-Jump tag adapts when sorted ASC
    expect(find.text('↳ Gốc: LDG00DEMO20260002 ↑'), findsOneWidget);

    // Select Period 'Năm nay' -> forwards from/to and shows reconciliation strip
    await tester.tap(find.byType(DropdownButton<ImmutableLedgerPeriod>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Năm nay').last);
    await tester.pumpAndSettle();

    expect(repo.lastFrom, isNotNull);
    expect(repo.lastTo, isNotNull);
    expect(find.text('Đối chiếu Năm nay:'), findsOneWidget);
    expect(find.textContaining('Đầu kỳ: '), findsOneWidget);
    expect(find.textContaining('Cuối kỳ: '), findsOneWidget);
  });

  testWidgets(
      'Clicking Kiểm toán chuỗi invokes verifyLedgerIntegrity and shows broken-link banner',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeImmutableLedgerRepository(
      allItems: chainedItems,
      integrityReport: LedgerIntegrityReportModel(
        clanId: 'CLAN_DEFAULT',
        valid: true,
        totalEntries: 4,
        verifiedEntries: 4,
        verifiedAt: DateTime(2026, 11, 27, 16, 0),
      ),
    );

    await tester.pumpWidget(
      buildTestApp(repo: repo, session: clanHeadSession),
    );
    await tester.pumpAndSettle();
    expect(repo.verifyCallCount, 1);

    repo.integrityReport = LedgerIntegrityReportModel(
      clanId: 'CLAN_DEFAULT',
      valid: false,
      totalEntries: 4,
      verifiedEntries: 2,
      brokenLinks: const [
        LedgerBrokenLinkModel(
          transactionId: 'LDGMWYGB7CX9V7NQZ',
          chainIndex: 2,
          reason: 'recordHash không khớp chữ ký lưu sổ cái',
        ),
      ],
      verifiedAt: DateTime(2026, 11, 27, 16, 5),
    );

    await tester.tap(find.text('Kiểm toán chuỗi'));
    await tester.pumpAndSettle();

    expect(repo.verifyCallCount, 2);
    expect(
      find.text('Cảnh báo bảo mật: Phát hiện 1 sai lệch chuỗi SHA-256'),
      findsOneWidget,
    );
    expect(find.text('Kiểm tra khối #3'), findsOneWidget);
    expect(find.text('Sai lệch'), findsOneWidget);
  });

  testWidgets(
      'Desktop detail drawer displays 64-char hashes, bidirectional jump, and RBAC footer',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeImmutableLedgerRepository(
      allItems: chainedItems,
      integrityReport: LedgerIntegrityReportModel(
        clanId: 'CLAN_DEFAULT',
        valid: true,
        totalEntries: 4,
        verifiedEntries: 4,
        verifiedAt: DateTime(2026, 11, 27, 16, 0),
      ),
    );

    // 1. Clan Head sees 'Đề xuất bù trừ' on non-adjustment transaction
    await tester.pumpWidget(
      buildTestApp(repo: repo, session: clanHeadSession),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chi tổ chức Đại lễ Giỗ Tổ Xuân 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Chứng thực chuỗi SHA-256'), findsOneWidget);
    expect(find.text(hash2), findsOneWidget);
    expect(find.text(hash1), findsOneWidget);
    expect(find.text('BÚT TOÁN BÙ TRỪ LIÊN QUAN (1)'), findsOneWidget);
    // Expect 2 buttons with text 'Đề xuất bù trừ' (banner + drawer footer)
    expect(find.text('Đề xuất bù trừ'), findsNWidgets(2));

    // Jump to adjustment transaction inside drawer
    final adjFinder = find.text(
      '${formatSignedLedgerVnd(14800000)} • LDGMWYGB7CX9V7NQZ',
    );
    await tester.ensureVisible(adjFinder);
    await tester.pumpAndSettle();
    await tester.tap(adjFinder);
    await tester.pumpAndSettle();

    expect(find.text('LIÊN KẾT GIAO DỊCH GỐC'), findsOneWidget);
    expect(find.text('Chỉ đọc'), findsOneWidget);

    // Close drawer before switching to Member session
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 2. Member role sees 'Chỉ đọc' even on original transaction
    await tester.pumpWidget(
      buildTestApp(
        repo: repo,
        session: memberSession,
        scopeKey: const ValueKey('member-scope'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tu sửa mái ngói Từ đường họ Nguyễn'));
    await tester.pumpAndSettle();

    expect(find.text('Chỉ đọc'), findsOneWidget);
    expect(find.text('Đề xuất bù trừ'), findsNothing);
    expectNoEditOrDeleteButtons();
  });

  testWidgets(
      'Filter chips and keyword search forward exact parameters to repository',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeImmutableLedgerRepository(
      allItems: chainedItems,
      integrityReport: LedgerIntegrityReportModel(
        clanId: 'CLAN_DEFAULT',
        valid: true,
        totalEntries: 4,
        verifiedEntries: 4,
        verifiedAt: DateTime(2026, 11, 27, 16, 0),
      ),
    );

    await tester.pumpWidget(
      buildTestApp(repo: repo, session: clanHeadSession),
    );
    await tester.pumpAndSettle();

    // Filter by 'Có bù trừ' -> onlyWithAdjustments = true
    await tester.tap(find.widgetWithText(FilterChip, 'Có bù trừ'));
    await tester.pumpAndSettle();
    expect(repo.lastOnlyWithAdjustments, isTrue);
    expect(repo.lastTransactionType, isNull);

    // Filter by 'Chi quỹ chung' -> transactionType = commonFundDisbursement
    await tester.tap(find.widgetWithText(FilterChip, 'Chi quỹ chung'));
    await tester.pumpAndSettle();
    expect(
      repo.lastTransactionType,
      LedgerTransactionTypeEnum.commonFundDisbursement,
    );
    expect(repo.lastOnlyWithAdjustments, isNull);

    // Reset filter & search by keyword
    await tester.tap(find.widgetWithText(FilterChip, 'Tất cả'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'GENESIS');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repo.lastKeyword, 'GENESIS');
  });

  testWidgets(
      'Mobile (390x844) renders 2-column Biến động & Số dư lũy kế, Quick-Jump tags, and opens bottom sheet without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = FakeImmutableLedgerRepository(
      allItems: chainedItems,
      integrityReport: LedgerIntegrityReportModel(
        clanId: 'CLAN_DEFAULT',
        valid: true,
        totalEntries: 4,
        verifiedEntries: 4,
        verifiedAt: DateTime(2026, 11, 27, 16, 0),
      ),
    );

    await tester.pumpWidget(
      buildTestApp(repo: repo, session: memberSession),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sổ Cái Quỹ Chung'), findsOneWidget);
    expect(find.text('Biến động'), findsWidgets);
    expect(find.text('Số dư lũy kế'), findsWidgets);
    expect(find.text('8092d8…90d8'), findsOneWidget);
    expect(find.text('↳ Gốc: LDG00DEMO20260002 ↓'), findsOneWidget);
    expectNoEditOrDeleteButtons();

    await tester.tap(find.text('Tu sửa mái ngói Từ đường họ Nguyễn'));
    await tester.pumpAndSettle();

    expect(find.text('Chứng thực chuỗi SHA-256'), findsOneWidget);
    expect(find.text('Chỉ đọc'), findsOneWidget);
    expectNoEditOrDeleteButtons();
    expect(tester.takeException(), isNull);
  });
}
