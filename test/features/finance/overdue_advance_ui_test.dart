import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/finance/data/models/advance_voucher_models.dart';
import 'package:familyfund_app/features/finance/data/repositories/advance_voucher_repository_impl.dart';
import 'package:familyfund_app/features/finance/domain/repositories/advance_voucher_repository.dart';
import 'package:familyfund_app/features/finance/presentation/screens/overdue_advance_vouchers_screen.dart';
import 'package:familyfund_app/features/finance/presentation/widgets/overdue_advance_alert_banner.dart';
import 'package:familyfund_app/features/finance/presentation/widgets/overdue_advance_card.dart';
import 'package:familyfund_app/features/finance/presentation/widgets/urge_settlement_dialog.dart';

class _FixedDualRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _fixed;
  _FixedDualRbacNotifier(this._fixed);

  @override
  DualRbacSession build() => _fixed;
}

class FakeAdvanceVoucherRepository implements AdvanceVoucherRepository {
  final List<AdvanceVoucherModel> vouchers = [];
  bool scanCalled = false;
  bool reminderCalled = false;

  @override
  Future<List<AdvanceVoucherModel>> getAdvanceVouchers({
    String? eventId,
    String? taskId,
    String? recipientMemberId,
    AdvanceVoucherStatusEnum? status,
  }) async {
    return vouchers;
  }

  @override
  Future<AdvanceVoucherModel> getAdvanceVoucherDetail(String id) async {
    return vouchers.firstWhere((v) => v.advanceVoucherId == id);
  }

  @override
  Future<AdvanceVoucherModel> createAdvanceVoucher(
    CreateAdvanceVoucherRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<AdvanceVoucherModel> confirmDisbursement(
    String id,
    ConfirmDisbursementRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<OverdueScanSummaryModel> scanOverdueVouchers() async {
    scanCalled = true;
    return OverdueScanSummaryModel(
      scannedCount: vouchers.length,
      overdueTransitionedCount: 1,
      notificationsSentCount: 2,
      referenceTime: DateTime.now(),
    );
  }

  @override
  Future<void> sendSettlementReminder(
    SendSettlementReminderRequestDto request,
  ) async {
    reminderCalled = true;
  }
}

void main() {
  const eventId = 'EVT_001';

  final sampleOverdueVoucher1 = AdvanceVoucherModel(
    advanceVoucherId: 'ADV_OVERDUE_01',
    taskId: 'TASK_001',
    taskName: 'Mua mâm ngũ quả và trầu cau',
    eventId: eventId,
    recipientMemberId: 'MEM_001',
    recipientMemberName: 'Nguyễn Văn Tuấn',
    advanceAmount: 3500000,
    status: AdvanceVoucherStatusEnum.quaHan,
    receivedDate: DateTime.now().subtract(const Duration(days: 10)),
    settlementDeadline: DateTime.now().subtract(const Duration(days: 5)),
    commitmentNotes: 'Dùng cho mâm cúng chính',
    overdueAt: DateTime.now().subtract(const Duration(days: 5)),
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  );

  final sampleOverdueVoucher2 = AdvanceVoucherModel(
    advanceVoucherId: 'ADV_OVERDUE_02',
    taskId: 'TASK_002',
    taskName: 'Thuê bàn ghế và dựng rạp',
    eventId: eventId,
    recipientMemberId: 'MEM_002',
    recipientMemberName: 'Trần Văn Hoàng',
    advanceAmount: 5000000,
    status: AdvanceVoucherStatusEnum.chuaTatToan,
    receivedDate: DateTime.now().subtract(const Duration(days: 6)),
    settlementDeadline: DateTime.now().subtract(const Duration(days: 2)),
    commitmentNotes: 'Rạp chính nhà từ đường',
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
  );

  DualRbacSession createTestSession({
    required Set<SystemRole> globalRoles,
    Map<String, EventPermissionContext> eventRoles = const {},
  }) {
    return DualRbacSession(
      accountId: 'ACC_001',
      memberId: 'MEM_001',
      fullName: 'Nguyễn Văn Tuấn',
      branchName: 'Chi 1',
      globalRoles: globalRoles,
      eventRolesByEventId: eventRoles,
    );
  }

  Widget createWidgetForTesting({
    required Widget child,
    required FakeAdvanceVoucherRepository repository,
    DualRbacSession? session,
  }) {
    return ProviderScope(
      overrides: [
        advanceVoucherRepositoryProvider.overrideWithValue(repository),
        if (session != null)
          dualRbacSessionProvider.overrideWith(
            () => _FixedDualRbacNotifier(session),
          ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('OverdueAdvanceVouchersScreen (US-48 AC-01 & AC-03)', () {
    testWidgets('renders KPI summary, list of overdue cards, and filters',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAdvanceVoucherRepository()
        ..vouchers.addAll([sampleOverdueVoucher1, sampleOverdueVoucher2]);

      final treasurerSession = createTestSession(
        globalRoles: {SystemRole.roleMember},
        eventRoles: {
          eventId: const EventPermissionContext(
            eventId: eventId,
            role: EventContextualRole.eventTreasurer,
            eventStatus: EventLifecycleStatus.ongoing,
          ),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            advanceVoucherRepositoryProvider.overrideWithValue(repo),
            dualRbacSessionProvider.overrideWith(
              () => _FixedDualRbacNotifier(treasurerSession),
            ),
          ],
          child: const MaterialApp(
            home: OverdueAdvanceVouchersScreen(eventId: eventId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Theo Dõi Tạm Ứng Quá Hạn'), findsOneWidget);
      expect(find.textContaining('8.500.000'), findsWidgets); // 3.5M + 5M
      expect(find.text('2 phiếu'), findsOneWidget);
      expect(find.text('2 người'), findsOneWidget);

      expect(find.text('Nguyễn Văn Tuấn'), findsOneWidget);
      expect(find.text('Trần Văn Hoàng'), findsOneWidget);
      expect(find.text('ADV_OVERDUE_01'), findsOneWidget);
      expect(find.text('ADV_OVERDUE_02'), findsOneWidget);
    });

    testWidgets('Admin sees manual scan button and tapping triggers scan',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAdvanceVoucherRepository()
        ..vouchers.add(sampleOverdueVoucher1);

      final adminSession = createTestSession(
        globalRoles: {SystemRole.roleAdmin},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            advanceVoucherRepositoryProvider.overrideWithValue(repo),
            dualRbacSessionProvider.overrideWith(
              () => _FixedDualRbacNotifier(adminSession),
            ),
          ],
          child: const MaterialApp(
            home: OverdueAdvanceVouchersScreen(eventId: eventId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scanBtn = find.byKey(const Key('manual_scan_button'));
      expect(scanBtn, findsOneWidget);

      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      expect(repo.scanCalled, isTrue);
      expect(find.textContaining('Quét hoàn tất'), findsOneWidget);
    });
  });

  group('OverdueAdvanceCard & UrgeSettlementDialog (AC-02)', () {
    testWidgets('clicking "Đôn Đốc Thu Hồi" opens dialog and confirms send',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAdvanceVoucherRepository()
        ..vouchers.add(sampleOverdueVoucher1);

      final treasurerSession = createTestSession(
        globalRoles: {SystemRole.roleMember},
        eventRoles: {
          eventId: const EventPermissionContext(
            eventId: eventId,
            role: EventContextualRole.eventTreasurer,
            eventStatus: EventLifecycleStatus.ongoing,
          ),
        },
      );

      await tester.pumpWidget(
        createWidgetForTesting(
          repository: repo,
          session: treasurerSession,
          child: OverdueAdvanceCard(voucher: sampleOverdueVoucher1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Đôn Đốc Thu Hồi'), findsOneWidget);

      final urgeBtn = find.byKey(const Key('urge_button_ADV_OVERDUE_01'));
      await tester.tap(urgeBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Đôn Đốc Quyết Toán Tạm Ứng'), findsOneWidget);
      expect(find.textContaining('Kính gửi anh/chị Nguyễn Văn Tuấn'), findsWidgets);

      final sendBtn =
          find.widgetWithText(ElevatedButton, 'Gửi Đôn Đốc Ngay');
      expect(sendBtn, findsOneWidget);

      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(repo.reminderCalled, isTrue);
      expect(find.textContaining('thành công'), findsOneWidget);
    });
  });

  group('OverdueAdvanceAlertBanner (AC-04)', () {
    testWidgets('BTC sees alert banner when overdue vouchers exist',
        (tester) async {
      final repo = FakeAdvanceVoucherRepository()
        ..vouchers.add(sampleOverdueVoucher1);

      final treasurerSession = createTestSession(
        globalRoles: {SystemRole.roleMember},
        eventRoles: {
          eventId: const EventPermissionContext(
            eventId: eventId,
            role: EventContextualRole.eventTreasurer,
            eventStatus: EventLifecycleStatus.ongoing,
          ),
        },
      );

      await tester.pumpWidget(
        createWidgetForTesting(
          repository: repo,
          session: treasurerSession,
          child: const OverdueAdvanceAlertBanner(eventId: eventId),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('CẢNH BÁO TẠM ỨNG QUÁ HẠN NỘP CHỨNG TỪ'),
        findsOneWidget,
      );
      expect(find.textContaining('3.500.000'), findsWidgets);
      expect(find.byKey(const Key('open_overdue_advances_button')), findsOneWidget);
    });

    testWidgets('Regular member does NOT see alert banner',
        (tester) async {
      final repo = FakeAdvanceVoucherRepository()
        ..vouchers.add(sampleOverdueVoucher1);

      final memberSession = createTestSession(
        globalRoles: {SystemRole.roleMember},
      );

      await tester.pumpWidget(
        createWidgetForTesting(
          repository: repo,
          session: memberSession,
          child: const OverdueAdvanceAlertBanner(eventId: eventId),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('CẢNH BÁO TẠM ỨNG QUÁ HẠN NỘP CHỨNG TỪ'),
        findsNothing,
      );
    });
  });
}
