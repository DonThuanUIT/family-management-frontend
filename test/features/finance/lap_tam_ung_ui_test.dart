import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/finance/data/models/advance_voucher_models.dart';
import 'package:familyfund_app/features/finance/data/repositories/advance_voucher_repository_impl.dart';
import 'package:familyfund_app/features/finance/domain/repositories/advance_voucher_repository.dart';
import 'package:familyfund_app/features/finance/presentation/widgets/confirm_disbursement_dialog.dart';
import 'package:familyfund_app/features/finance/presentation/widgets/create_advance_voucher_sheet.dart';
import 'package:familyfund_app/features/finance/presentation/widgets/task_advance_vouchers_sheet.dart';
import 'package:familyfund_app/features/task/data/models/task_models.dart';
import 'package:familyfund_app/features/task/presentation/widgets/task_card.dart';

class _FixedDualRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _fixed;
  _FixedDualRbacNotifier(this._fixed);

  @override
  DualRbacSession build() => _fixed;
}

class FakeAdvanceVoucherRepository implements AdvanceVoucherRepository {
  final List<AdvanceVoucherModel> vouchers = [];
  bool createCalled = false;
  bool disburseCalled = false;

  @override
  Future<List<AdvanceVoucherModel>> getAdvanceVouchers({
    String? eventId,
    String? taskId,
    String? recipientMemberId,
    AdvanceVoucherStatusEnum? status,
  }) async {
    if (taskId != null) {
      return vouchers.where((v) => v.taskId == taskId).toList();
    }
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
    createCalled = true;
    final newVoucher = AdvanceVoucherModel(
      advanceVoucherId: 'ADV_NEW_001',
      taskId: request.taskId,
      recipientMemberId: request.recipientMemberId,
      recipientMemberName: 'Người Nhận Test',
      advanceAmount: request.advanceAmount,
      status: AdvanceVoucherStatusEnum.choGiaoTien,
      receivedDate: request.receivedDate,
      settlementDeadline: request.settlementDeadline,
      commitmentNotes: request.commitmentNotes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    vouchers.insert(0, newVoucher);
    return newVoucher;
  }

  @override
  Future<AdvanceVoucherModel> confirmDisbursement(
    String id,
    ConfirmDisbursementRequestDto request,
  ) async {
    disburseCalled = true;
    final index = vouchers.indexWhere((v) => v.advanceVoucherId == id);
    final current = vouchers[index];
    final updated = current.copyWith(
      status: AdvanceVoucherStatusEnum.chuaTatToan,
      disbursementNotes: request.notes,
      disbursedAt: DateTime.now(),
      treasurerAccountId: 'ACC_TREASURER',
    );
    vouchers[index] = updated;
    return updated;
  }
}

void main() {
  const eventId = 'EVT_001';
  final sampleTask = TaskModel(
    taskId: 'TASK_001',
    eventId: eventId,
    taskName: 'Mua mâm ngũ quả và trầu cau',
    status: TaskStatusEnum.inProgress,
    advanceBudget: 3500000,
    deadline: DateTime.now().add(const Duration(days: 2)),
    assignedMemberId: 'MEM_001',
    assignedMemberName: 'Nguyễn Văn Tuấn',
    createdBy: 'ADMIN',
  );

  final samplePendingVoucher = AdvanceVoucherModel(
    advanceVoucherId: 'ADV_001',
    taskId: sampleTask.taskId,
    recipientMemberId: 'MEM_001',
    recipientMemberName: 'Nguyễn Văn Tuấn',
    advanceAmount: 3500000,
    status: AdvanceVoucherStatusEnum.choGiaoTien,
    receivedDate: DateTime.now(),
    settlementDeadline: DateTime.now().add(const Duration(days: 3)),
    commitmentNotes: 'Dùng cho mâm cúng chính',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
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

  group('CreateAdvanceVoucherSheet (LapTamUngUI - AC-01)', () {
    testWidgets('pre-fills task information and budget suggestion',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAdvanceVoucherRepository();

      await tester.pumpWidget(
        createWidgetForTesting(
          repository: repo,
          child: CreateAdvanceVoucherSheet(task: sampleTask),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lập Phiếu Tạm Ứng Kinh Phí'), findsOneWidget);
      expect(find.textContaining('Mua mâm ngũ quả và trầu cau'), findsWidgets);
      expect(find.text('Nguyễn Văn Tuấn'), findsOneWidget);
      expect(find.textContaining('3.500.000'), findsWidgets);
      expect(find.text('Xác Nhận & Lập Phiếu Tạm Ứng'), findsOneWidget);
    });

    testWidgets('submitting form triggers createAdvanceVoucher in repository',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAdvanceVoucherRepository();

      await tester.pumpWidget(
        createWidgetForTesting(
          repository: repo,
          child: CreateAdvanceVoucherSheet(task: sampleTask),
        ),
      );
      await tester.pumpAndSettle();

      final notesFinder = find.byType(TextFormField).last;
      await tester.enterText(notesFinder, 'Cam kết mua đúng phẩm chất');
      await tester.pumpAndSettle();

      final submitBtn =
          find.widgetWithText(ElevatedButton, 'Xác Nhận & Lập Phiếu Tạm Ứng');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(repo.createCalled, isTrue);
      expect(repo.vouchers.length, 1);
      expect(repo.vouchers.first.advanceAmount, 3500000);
    });
  });

  group('ConfirmDisbursementDialog (AC-02 & AC-03)', () {
    testWidgets('shows voucher details and confirms disbursement',
        (tester) async {
      final repo = FakeAdvanceVoucherRepository()..vouchers.add(samplePendingVoucher);

      await tester.pumpWidget(
        createWidgetForTesting(
          repository: repo,
          child: ConfirmDisbursementDialog(voucher: samplePendingVoucher),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Xác Nhận Đã Giải Ngân'), findsWidgets);
      expect(find.text('ADV_001'), findsOneWidget);
      expect(find.textContaining('3.500.000'), findsWidgets);
      expect(find.text('Nguyễn Văn Tuấn'), findsOneWidget);

      final confirmBtn =
          find.widgetWithText(ElevatedButton, 'Xác Nhận Đã Giải Ngân');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(repo.disburseCalled, isTrue);
      expect(repo.vouchers.first.status, AdvanceVoucherStatusEnum.chuaTatToan);
    });
  });

  group('TaskAdvanceVouchersSheet & AdvanceVoucherCard RBAC tests', () {
    testWidgets('Treasurer sees "Xác Nhận Đã Giải Ngân" on pending voucher',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAdvanceVoucherRepository()..vouchers.add(samplePendingVoucher);
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
          child: TaskAdvanceVouchersSheet(task: sampleTask),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phiếu Tạm Ứng Kinh Phí'), findsOneWidget);
      expect(find.text('Lập Phiếu Tạm Ứng Mới'), findsOneWidget);
      expect(find.text('Xác Nhận Đã Giải Ngân'), findsOneWidget);
    });

    testWidgets('Regular member cannot see "Lập Phiếu" or "Xác Nhận Đã Giải Ngân"',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAdvanceVoucherRepository()..vouchers.add(samplePendingVoucher);
      final memberSession = createTestSession(
        globalRoles: {SystemRole.roleMember},
      );

      await tester.pumpWidget(
        createWidgetForTesting(
          repository: repo,
          session: memberSession,
          child: TaskAdvanceVouchersSheet(task: sampleTask),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phiếu Tạm Ứng Kinh Phí'), findsOneWidget);
      expect(find.text('Lập Phiếu Tạm Ứng Mới'), findsNothing);
      expect(find.text('Xác Nhận Đã Giải Ngân'), findsNothing);
    });
  });

  group('TaskCard integration tests', () {
    testWidgets('Treasurer sees "Giải ngân" button when task has pending disbursement',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAdvanceVoucherRepository()..vouchers.add(samplePendingVoucher);
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
          child: TaskCard(
            task: sampleTask,
            canManage: true,
            isClosed: false,
            onReassign: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('task_disburse_button')), findsOneWidget);
      expect(find.text('Giải ngân'), findsOneWidget);
    });

    testWidgets('Regular member does NOT see "Giải ngân" button on TaskCard',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = FakeAdvanceVoucherRepository()..vouchers.add(samplePendingVoucher);
      final memberSession = createTestSession(
        globalRoles: {SystemRole.roleMember},
      );

      await tester.pumpWidget(
        createWidgetForTesting(
          repository: repo,
          session: memberSession,
          child: TaskCard(
            task: sampleTask,
            canManage: false,
            isClosed: false,
            onReassign: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('task_disburse_button')), findsNothing);
    });
  });
}
