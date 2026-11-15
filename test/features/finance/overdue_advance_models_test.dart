import 'package:flutter_test/flutter_test.dart';
import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/finance/data/models/advance_voucher_models.dart';

void main() {
  group('AdvanceVoucherStatusEnum QuaHan tests (US-48)', () {
    test('fromCode parses QuaHan and Overdue correctly', () {
      expect(
        AdvanceVoucherStatusEnum.fromCode('QuaHan'),
        AdvanceVoucherStatusEnum.quaHan,
      );
      expect(
        AdvanceVoucherStatusEnum.fromCode('Overdue'),
        AdvanceVoucherStatusEnum.quaHan,
      );
    });

    test('displayName returns Quá hạn quyết toán', () {
      expect(
        AdvanceVoucherStatusEnum.quaHan.displayName,
        'Quá hạn quyết toán',
      );
    });

    test('badge styling provides warning alert styling for QuaHan', () {
      final status = AdvanceVoucherStatusEnum.quaHan;
      expect(status.badgeBackgroundColor, isNotNull);
      expect(status.badgeTextColor, isNotNull);
      expect(status.badgeBorderColor, isNotNull);
      expect(status.icon, isNotNull);
    });
  });

  group('AdvanceVoucherModel Overdue Helpers (US-48)', () {
    final pastDeadline = DateTime.now().subtract(const Duration(days: 5));
    final futureDeadline = DateTime.now().add(const Duration(days: 3));

    test('isOverdue returns true when status is QuaHan', () {
      final voucher = AdvanceVoucherModel(
        advanceVoucherId: 'ADV_OVERDUE_01',
        taskId: 'TASK_01',
        recipientMemberId: 'MEM_01',
        advanceAmount: 2000000,
        status: AdvanceVoucherStatusEnum.quaHan,
        receivedDate: DateTime.now().subtract(const Duration(days: 10)),
        settlementDeadline: pastDeadline,
        overdueAt: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now(),
      );

      expect(voucher.isOverdue, isTrue);
      expect(voucher.overdueDays, greaterThanOrEqualTo(4));
      expect(voucher.overdueDurationText, contains('Quá hạn'));
      expect(voucher.formattedOverdueAt, isNotEmpty);
    });

    test('isOverdue returns true when ChuaTatToan and settlementDeadline has passed', () {
      final voucher = AdvanceVoucherModel(
        advanceVoucherId: 'ADV_LATE_02',
        taskId: 'TASK_02',
        recipientMemberId: 'MEM_02',
        advanceAmount: 1500000,
        status: AdvanceVoucherStatusEnum.chuaTatToan,
        receivedDate: DateTime.now().subtract(const Duration(days: 7)),
        settlementDeadline: pastDeadline,
        createdAt: DateTime.now(),
      );

      expect(voucher.isOverdue, isTrue);
      expect(voucher.overdueDays, greaterThanOrEqualTo(4));
    });

    test('isOverdue returns false when deadline is in the future', () {
      final voucher = AdvanceVoucherModel(
        advanceVoucherId: 'ADV_ONTIME_03',
        taskId: 'TASK_03',
        recipientMemberId: 'MEM_03',
        advanceAmount: 1000000,
        status: AdvanceVoucherStatusEnum.chuaTatToan,
        receivedDate: DateTime.now(),
        settlementDeadline: futureDeadline,
        createdAt: DateTime.now(),
      );

      expect(voucher.isOverdue, isFalse);
      expect(voucher.overdueDays, 0);
      expect(voucher.overdueDurationText, isEmpty);
    });

    test('isOverdue returns false when voucher is settled or cancelled', () {
      final settledVoucher = AdvanceVoucherModel(
        advanceVoucherId: 'ADV_SETTLED_04',
        taskId: 'TASK_04',
        recipientMemberId: 'MEM_04',
        advanceAmount: 500000,
        status: AdvanceVoucherStatusEnum.daTatToan,
        receivedDate: DateTime.now().subtract(const Duration(days: 15)),
        settlementDeadline: pastDeadline,
        createdAt: DateTime.now(),
      );

      expect(settledVoucher.isOverdue, isFalse);
    });
  });

  group('OverdueScanSummaryModel & SendSettlementReminderRequestDto tests', () {
    test('OverdueScanSummaryModel fromJson maps correctly', () {
      final json = {
        'scannedCount': 15,
        'overdueTransitionedCount': 4,
        'notificationsSentCount': 10,
        'referenceTime': '2026-11-15T09:30:00.000Z',
      };

      final summary = OverdueScanSummaryModel.fromJson(json);

      expect(summary.scannedCount, 15);
      expect(summary.overdueTransitionedCount, 4);
      expect(summary.notificationsSentCount, 10);
      expect(summary.referenceTime.year, 2026);
    });

    test('SendSettlementReminderRequestDto serializes custom message', () {
      final dto = const SendSettlementReminderRequestDto(
        voucherId: 'ADV_001',
        customMessage: 'Đề nghị khẩn trương nộp chứng từ trước ngày 20/11',
      );

      final json = dto.toJson();
      expect(json['voucherId'], 'ADV_001');
      expect(json['customMessage'], 'Đề nghị khẩn trương nộp chứng từ trước ngày 20/11');
    });
  });

  group('DualRbacSession US-48 Permissions', () {
    const eventId = 'EVT_001';

    DualRbacSession createSession({
      required Set<SystemRole> globalRoles,
      Map<String, EventPermissionContext> eventRoles = const {},
    }) {
      return DualRbacSession(
        accountId: 'ACC_001',
        memberId: 'MEM_001',
        fullName: 'Nguyễn Văn Test',
        branchName: 'Chi 1',
        globalRoles: globalRoles,
        eventRolesByEventId: eventRoles,
      );
    }

    test('Clan Head and Admin have full view, urge, and scan permissions', () {
      final session = createSession(globalRoles: {SystemRole.roleClanHead});

      expect(session.canViewOverdueAdvanceList(eventId: eventId), isTrue);
      expect(session.canUrgeAdvanceSettlement(eventId: eventId), isTrue);
      expect(session.canTriggerManualOverdueScan(), isTrue);
    });

    test('Event Treasurer and BTC members can view and urge, but CANNOT trigger manual scan', () {
      final treasurerSession = createSession(
        globalRoles: {SystemRole.roleMember},
        eventRoles: {
          eventId: const EventPermissionContext(
            eventId: eventId,
            role: EventContextualRole.eventTreasurer,
            eventStatus: EventLifecycleStatus.ongoing,
          ),
        },
      );

      expect(treasurerSession.canViewOverdueAdvanceList(eventId: eventId), isTrue);
      expect(treasurerSession.canUrgeAdvanceSettlement(eventId: eventId), isTrue);
      expect(treasurerSession.canTriggerManualOverdueScan(), isFalse);

      final organizerMemberSession = createSession(
        globalRoles: {SystemRole.roleMember},
        eventRoles: {
          eventId: const EventPermissionContext(
            eventId: eventId,
            role: EventContextualRole.organizerMember,
            eventStatus: EventLifecycleStatus.ongoing,
          ),
        },
      );

      expect(organizerMemberSession.canViewOverdueAdvanceList(eventId: eventId), isTrue);
      expect(organizerMemberSession.canUrgeAdvanceSettlement(eventId: eventId), isTrue);
      expect(organizerMemberSession.canTriggerManualOverdueScan(), isFalse);
    });

    test('Regular member has NO view and NO urge permissions', () {
      final regularSession = createSession(globalRoles: {SystemRole.roleMember});

      expect(regularSession.canViewOverdueAdvanceList(eventId: eventId), isFalse);
      expect(regularSession.canUrgeAdvanceSettlement(eventId: eventId), isFalse);
      expect(regularSession.canTriggerManualOverdueScan(), isFalse);
    });

    test('Closed event revokes urge and manual scan permissions, but allows view', () {
      final session = createSession(globalRoles: {SystemRole.roleClanHead});

      expect(session.canViewOverdueAdvanceList(isClosed: true, eventId: eventId), isTrue);
      expect(session.canUrgeAdvanceSettlement(isClosed: true, eventId: eventId), isFalse);
      expect(session.canTriggerManualOverdueScan(isClosed: true), isFalse);
    });
  });
}
