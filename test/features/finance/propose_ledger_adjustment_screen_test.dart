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
import 'package:familyfund_app/features/finance/presentation/screens/propose_ledger_adjustment_screen.dart';

class _FixedDualRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _fixed;
  _FixedDualRbacNotifier(this._fixed);

  @override
  DualRbacSession build() => _fixed;
}

class FakeLedgerRepository implements LedgerRepository {
  final List<LedgerHistoryItemModel> ledgerItems;
  final List<LedgerAdjustmentRequestModel> historyItems;
  double currentFundBalance;

  int uploadCallCount = 0;
  int proposeCallCount = 0;
  String? lastUploadedFilename;
  ProposeLedgerAdjustmentRequestDto? lastProposedDto;

  FakeLedgerRepository({
    required this.ledgerItems,
    required this.historyItems,
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
    final q = (keyword ?? '').trim().toLowerCase();
    final filtered = ledgerItems.where((item) {
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
            item.description.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return LedgerHistoryPageModel(
      clanId: 'CLAN_01',
      items: filtered,
      page: page,
      size: size,
      totalElements: filtered.length,
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
  Future<LedgerHistoryItemModel> getTransactionDetail(String transactionId) async {
    return ledgerItems.firstWhere((e) => e.transactionId == transactionId);
  }

  @override
  Future<LedgerEvidenceUploadResult> uploadEvidence({
    required Uint8List bytes,
    required String filename,
    String? originalTransactionId,
  }) async {
    uploadCallCount++;
    lastUploadedFilename = filename;
    return LedgerEvidenceUploadResult(
      evidenceUrl: '/api/v1/ledger/evidence/550e8400-e29b-41d4-a716-446655440000.pdf',
      fileName: '550e8400-e29b-41d4-a716-446655440000.pdf',
      originalFilename: filename,
      mimeType: 'application/pdf',
      sizeBytes: bytes.length,
      sha256Checksum: 'a' * 64,
    );
  }

  @override
  Future<LedgerAdjustmentRequestModel> proposeAdjustment(
    ProposeLedgerAdjustmentRequestDto request,
  ) async {
    proposeCallCount++;
    lastProposedDto = request;
    final orig = ledgerItems.firstWhere(
      (e) => e.transactionId == request.originalTransactionId,
    );
    return LedgerAdjustmentRequestModel(
      requestId: 'LAR00NEW123456789',
      originalTransactionId: request.originalTransactionId,
      clanId: 'CLAN_01',
      eventId: orig.eventId,
      originalTransactionType: orig.transactionType,
      originalTransactionAmount: orig.amount,
      proposedAdjustmentAmount: request.proposedAdjustmentAmount,
      adjustmentReason: request.adjustmentReason,
      evidenceAttachmentUrl: request.evidenceAttachmentUrl,
      proposedByAccountId: 'ACC_HEAD',
      approvalStatus: LedgerAdjustmentStatusEnum.pending,
      createdAt: DateTime(2026, 11, 27, 9, 30),
    );
  }

  @override
  Future<List<LedgerAdjustmentRequestModel>> searchAdjustmentRequests({
    String? originalTransactionId,
    LedgerAdjustmentStatusEnum? status,
  }) async {
    return historyItems.where((item) {
      if (status != null && item.approvalStatus != status) return false;
      if (originalTransactionId != null &&
          item.originalTransactionId != originalTransactionId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl) async {
    return Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits);
  }

  @override
  Future<LedgerAdjustmentRequestModel> getAdjustmentRequestById(
    String requestId,
  ) async {
    return historyItems.firstWhere((e) => e.requestId == requestId);
  }

  @override
  Future<ReviewLedgerAdjustmentResponseModel> reviewAdjustment(
    ReviewLedgerAdjustmentRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<LedgerAnnualAuditModel> performAnnualAudit(
    AnnualLedgerAuditRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<LedgerAnnualAuditModel>> searchAnnualAudits({
    int? auditYear,
    LedgerAnnualAuditStatusEnum? status,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<LedgerAnnualAuditModel> getAnnualAuditById(String auditId) async {
    throw UnimplementedError();
  }
}

class FakeMemberFileActions extends MemberFileActions {
  final List<SelectedMediaFile> nextPickedFiles;

  FakeMemberFileActions(this.nextPickedFiles);

  @override
  Future<List<SelectedMediaFile>> pick({bool portrait = false}) async {
    return nextPickedFiles;
  }

  @override
  Future<bool> save(Uint8List bytes, String filename, String mimeType) async {
    return true;
  }
}

void main() {
  late LedgerHistoryItemModel eligibleTx;
  late LedgerHistoryItemModel lockedPendingTx;
  late List<LedgerAdjustmentRequestModel> sampleHistory;

  setUp(() {
    eligibleTx = LedgerHistoryItemModel(
      transactionId: 'LDG00K9A2F8X7P4Q2',
      clanId: 'CLAN_01',
      eventId: 'EVT_2026_GIOTO',
      eventName: 'Đại lễ Giỗ Tổ 2026',
      transactionType: LedgerTransactionTypeEnum.surplusTransfer,
      amount: 68500000,
      runningBalance: 100000000,
      description: 'Chuyển thặng dư Đại lễ Giỗ Tổ Xuân Bính Ngọ 2026',
      createdAt: DateTime(2026, 11, 18, 10, 0),
      netAdjustedAmount: 68500000,
      pendingAdjustmentRequestCount: 0,
    );

    lockedPendingTx = LedgerHistoryItemModel(
      transactionId: 'LDG00K8Z1C3V5N7M9',
      clanId: 'CLAN_01',
      transactionType: LedgerTransactionTypeEnum.commonFundDisbursement,
      amount: -32000000,
      runningBalance: 31500000,
      description: 'Chi tu sửa mái ngói Từ Đường',
      createdAt: DateTime(2026, 11, 2, 9, 0),
      netAdjustedAmount: -32000000,
      pendingAdjustmentRequestCount: 1,
    );

    sampleHistory = [
      LedgerAdjustmentRequestModel(
        requestId: 'LAR00PENDING00001',
        originalTransactionId: 'LDG00K8Z1C3V5N7M9',
        clanId: 'CLAN_01',
        originalTransactionType:
            LedgerTransactionTypeEnum.commonFundDisbursement,
        originalTransactionAmount: -32000000,
        proposedAdjustmentAmount: -2400000,
        adjustmentReason: 'Bổ sung chi phí vận chuyển ngói',
        proposedByAccountId: 'ACC_TR',
        approvalStatus: LedgerAdjustmentStatusEnum.pending,
        createdAt: DateTime(2026, 11, 25, 14, 20),
      ),
      LedgerAdjustmentRequestModel(
        requestId: 'LAR00REJECTED0002',
        originalTransactionId: 'LDG00K7Y6T4R2E9W3',
        clanId: 'CLAN_01',
        originalTransactionType: LedgerTransactionTypeEnum.surplusTransfer,
        originalTransactionAmount: 45200000,
        proposedAdjustmentAmount: -8000000,
        adjustmentReason: 'Trích giảm kết dư',
        proposedByAccountId: 'ACC_TR',
        approvalStatus: LedgerAdjustmentStatusEnum.rejected,
        rejectionReason: 'Chưa đính kèm biên bản xác nhận của Hội đồng.',
        createdAt: DateTime(2026, 8, 20, 16, 40),
      ),
    ];
  });

  const clanHeadSession = DualRbacSession(
    accountId: 'ACC_HEAD',
    memberId: 'MEM_HEAD',
    fullName: 'Nguyễn Trọng Hoàng',
    branchName: 'Chi Gốc',
    globalRoles: {SystemRole.roleClanHead},
  );

  Widget buildTestApp({
    required FakeLedgerRepository repo,
    FakeMemberFileActions? fileActions,
    DualRbacSession session = clanHeadSession,
    String? initialTransactionId,
  }) {
    return ProviderScope(
      overrides: [
        ledgerRepositoryProvider.overrideWithValue(repo),
        dualRbacSessionProvider.overrideWith(
          () => _FixedDualRbacNotifier(session),
        ),
        if (fileActions != null)
          memberFileActionsProvider.overrideWithValue(fileActions),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProposeLedgerAdjustmentScreen(
          initialTransactionId: initialTransactionId,
        ),
      ),
    );
  }

  testWidgets('Full Desktop E2E flow: Picker -> Negative warning -> Valid amount -> Quick chip -> Deferred PDF upload -> Confirm -> History', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeLedgerRepository(
      ledgerItems: [eligibleTx, lockedPendingTx],
      historyItems: sampleHistory,
      currentFundBalance: 100000000,
    );
    final fakePicker = FakeMemberFileActions([
      SelectedMediaFile(
        'Bien_ban_doi_soat_2026.pdf',
        1024,
        () async => Uint8List.fromList('%PDF-1.4\n%%EOF'.codeUnits),
      ),
    ]);

    await tester.pumpWidget(buildTestApp(repo: repo, fileActions: fakePicker));
    await tester.pumpAndSettle();

    expect(find.text('Đề Xuất Bù Trừ Sổ Cái'), findsOneWidget);
    expect(find.byKey(const Key('open_ledger_picker_button')), findsOneWidget);

    // 1. Open picker -> locked transaction cannot be selected; eligible can
    await tester.tap(find.byKey(const Key('open_ledger_picker_button')));
    await tester.pumpAndSettle();

    expect(find.text('LDG00K9A2F8X7P4Q2'), findsOneWidget);
    expect(find.text('LDG00K8Z1C3V5N7M9'), findsOneWidget);
    expect(find.text('Đang có đề xuất chờ duyệt (Khóa chọn)'), findsOneWidget);

    await tester.tap(find.text('Chọn giao dịch').first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('selected_original_transaction_card')),
      findsOneWidget,
    );

    // 2. Test negative fund balance warning disables submit
    await tester.tap(find.byKey(const Key('dir_minus_button')));
    await tester.enterText(
      find.byKey(const Key('adjustment_amount_input')),
      '150000000',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('negative_balance_warning_banner')),
      findsOneWidget,
    );
    final desktopBtnDisabled = tester.widget<ElevatedButton>(
      find.byKey(const Key('submit_adjustment_desktop_button')),
    );
    expect(desktopBtnDisabled.onPressed, isNull);

    // 3. Switch to valid increase amount (+14.800.000) and check Vietnamese words
    await tester.tap(find.byKey(const Key('dir_plus_button')));
    await tester.enterText(
      find.byKey(const Key('adjustment_amount_input')),
      '14800000',
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Cộng (tăng quỹ) mười bốn triệu tám trăm nghìn đồng chẵn'),
      findsOneWidget,
    );

    // 4. Reason text + quick chip appends without overwriting
    await tester.ensureVisible(
      find.byKey(const Key('adjustment_reason_input')),
    );
    await tester.enterText(
      find.byKey(const Key('adjustment_reason_input')),
      'Kiểm tra sổ thu tiền mặt.',
    );
    await tester.ensureVisible(find.text('+ Sai sót số liệu đối soát'));
    await tester.tap(find.text('+ Sai sót số liệu đối soát'));
    await tester.pumpAndSettle();

    final reasonField = tester.widget<TextField>(
      find.byKey(const Key('adjustment_reason_input')),
    );
    expect(reasonField.controller!.text, contains('Kiểm tra sổ thu tiền mặt.'));
    expect(reasonField.controller!.text, contains('Điều chỉnh sai lệch số liệu'));

    // 5. Pick PDF file -> Deferred Upload (uploadCallCount must still be 0!)
    await tester.ensureVisible(
      find.byKey(const Key('evidence_dropzone_button')),
    );
    await tester.tap(find.byKey(const Key('evidence_dropzone_button')));
    await tester.pumpAndSettle();

    expect(find.text('Bien_ban_doi_soat_2026.pdf'), findsOneWidget);
    expect(repo.uploadCallCount, 0);

    // 6. Click submit -> Confirm Dialog -> Confirm triggers upload + propose
    await tester.ensureVisible(
      find.byKey(const Key('submit_adjustment_desktop_button')),
    );
    await tester.tap(find.byKey(const Key('submit_adjustment_desktop_button')));
    await tester.pumpAndSettle();

    expect(find.text('Xác Nhận Gửi Đề Xuất Bù Trừ'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('confirm_submit_adjustment_button')),
    );
    await tester.pumpAndSettle();

    expect(repo.uploadCallCount, 1);
    expect(repo.lastUploadedFilename, 'Bien_ban_doi_soat_2026.pdf');
    expect(repo.proposeCallCount, 1);
    expect(repo.lastProposedDto?.originalTransactionId, 'LDG00K9A2F8X7P4Q2');
    expect(repo.lastProposedDto?.proposedAdjustmentAmount, 14800000.0);
    expect(
      repo.lastProposedDto?.evidenceAttachmentUrl,
      '/api/v1/ledger/evidence/550e8400-e29b-41d4-a716-446655440000.pdf',
    );

    // Success Dialog shows generated LAR id & navigates to History
    expect(find.text('LAR00NEW123456789'), findsOneWidget);
    await tester.tap(find.text('Xem Lịch Sử'));
    await tester.pumpAndSettle();

    expect(find.text('Lịch Sử Đề Xuất Bù Trừ Sổ Cái'), findsOneWidget);
    expect(find.text('LAR00NEW123456789'), findsOneWidget);
    expect(find.textContaining('Chưa đính kèm biên bản xác nhận'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile 390x844 layout renders cleanly without overflow and shows sticky footer', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakeLedgerRepository(
      ledgerItems: [eligibleTx],
      historyItems: sampleHistory,
      currentFundBalance: 100000000,
    );

    await tester.pumpWidget(
      buildTestApp(
        repo: repo,
        initialTransactionId: 'LDG00K9A2F8X7P4Q2',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('submit_adjustment_mobile_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('selected_original_transaction_card')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Regular MEMBER sees RBAC warning banner and cannot submit', (tester) async {
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

    final repo = FakeLedgerRepository(
      ledgerItems: [eligibleTx],
      historyItems: sampleHistory,
    );

    await tester.pumpWidget(
      buildTestApp(
        repo: repo,
        session: memberSession,
        initialTransactionId: 'LDG00K9A2F8X7P4Q2',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ledger_rbac_warning_banner')), findsOneWidget);
    final btn = tester.widget<ElevatedButton>(
      find.byKey(const Key('submit_adjustment_desktop_button')),
    );
    expect(btn.onPressed, isNull);
  });
}
