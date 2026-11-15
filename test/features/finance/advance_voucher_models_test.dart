import 'package:flutter_test/flutter_test.dart';
import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/finance/data/models/advance_voucher_models.dart';

void main() {
  group('AdvanceVoucherStatusEnum tests', () {
    test('fromCode parses all standard backend statuses', () {
      expect(
        AdvanceVoucherStatusEnum.fromCode('ChoGiaoTien'),
        AdvanceVoucherStatusEnum.choGiaoTien,
      );
      expect(
        AdvanceVoucherStatusEnum.fromCode('ChuaTatToan'),
        AdvanceVoucherStatusEnum.chuaTatToan,
      );
      expect(
        AdvanceVoucherStatusEnum.fromCode('DaTatToan'),
        AdvanceVoucherStatusEnum.daTatToan,
      );
      expect(
        AdvanceVoucherStatusEnum.fromCode('DaHuy'),
        AdvanceVoucherStatusEnum.daHuy,
      );
    });

    test('fromCode defaults to choGiaoTien for unknown string', () {
      expect(
        AdvanceVoucherStatusEnum.fromCode('UNKNOWN_STATUS'),
        AdvanceVoucherStatusEnum.choGiaoTien,
      );
    });

    test('displayName returns Vietnamese text', () {
      expect(AdvanceVoucherStatusEnum.choGiaoTien.displayName, 'Chờ giao tiền');
      expect(AdvanceVoucherStatusEnum.chuaTatToan.displayName, 'Chưa tất toán');
      expect(AdvanceVoucherStatusEnum.daTatToan.displayName, 'Đã tất toán');
      expect(AdvanceVoucherStatusEnum.daHuy.displayName, 'Đã hủy');
    });

    test('badge styling colors and icons are provided', () {
      for (final status in AdvanceVoucherStatusEnum.values) {
        expect(status.badgeBackgroundColor, isNotNull);
        expect(status.badgeTextColor, isNotNull);
        expect(status.badgeBorderColor, isNotNull);
        expect(status.icon, isNotNull);
      }
    });
  });

  group('AdvanceVoucherModel serialization tests', () {
    final sampleJson = {
      'advanceVoucherId': 'ADV_001',
      'taskId': 'TASK_001',
      'recipientMemberId': 'MEM_001',
      'recipientMemberName': 'Nguyễn Văn A',
      'advanceAmount': 3500000,
      'status': 'ChoGiaoTien',
      'receivedDate': '2026-11-20T08:00:00.000Z',
      'settlementDeadline': '2026-11-25T18:00:00.000Z',
      'commitmentNotes': 'Mua đồ cúng và lễ vật bàn thờ chính',
      'disbursementNotes': null,
      'disbursedAt': null,
      'treasurerAccountId': null,
      'createdAt': '2026-11-15T09:00:00.000Z',
      'updatedAt': '2026-11-15T09:00:00.000Z',
    };

    test('fromJson deserializes properly', () {
      final model = AdvanceVoucherModel.fromJson(sampleJson);

      expect(model.advanceVoucherId, 'ADV_001');
      expect(model.taskId, 'TASK_001');
      expect(model.advanceAmount, 3500000);
      expect(model.status, AdvanceVoucherStatusEnum.choGiaoTien);
      expect(model.recipientMemberName, 'Nguyễn Văn A');
      expect(model.formattedAdvanceAmount, contains('3.500.000'));
      expect(model.isPendingDisbursement, isTrue);
      expect(model.isDisbursed, isFalse);
    });

    test('toJson produces equivalent map', () {
      final model = AdvanceVoucherModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['advanceVoucherId'], 'ADV_001');
      expect(json['taskId'], 'TASK_001');
      expect(json['advanceAmount'], 3500000);
      expect(json['status'], 'ChoGiaoTien');
    });

    test('disbursed voucher properties reflect ChuaTatToan status', () {
      final disbursedJson = Map<String, dynamic>.from(sampleJson)
        ..['status'] = 'ChuaTatToan'
        ..['disbursedAt'] = '2026-11-15T10:30:00.000Z'
        ..['treasurerAccountId'] = 'ACC_TREASURER'
        ..['disbursementNotes'] = 'Đã chuyển khoản VietQR';

      final model = AdvanceVoucherModel.fromJson(disbursedJson);

      expect(model.status, AdvanceVoucherStatusEnum.chuaTatToan);
      expect(model.isPendingDisbursement, isFalse);
      expect(model.isDisbursed, isTrue);
      expect(model.treasurerAccountId, 'ACC_TREASURER');
      expect(model.disbursementNotes, 'Đã chuyển khoản VietQR');
      expect(model.formattedDisbursedAt, isNotEmpty);
    });
  });

  group('CreateAdvanceVoucherRequestDto & ConfirmDisbursementRequestDto tests', () {
    test('CreateAdvanceVoucherRequestDto serializes to backend expected format', () {
      final dto = CreateAdvanceVoucherRequestDto(
        taskId: 'TASK_001',
        recipientMemberId: 'MEM_001',
        advanceAmount: 2000000,
        receivedDate: DateTime.parse('2026-11-18T00:00:00.000Z'),
        settlementDeadline: DateTime.parse('2026-11-22T00:00:00.000Z'),
        commitmentNotes: 'Cam kết thanh toán đúng hạn',
      );

      final json = dto.toJson();
      expect(json['taskId'], 'TASK_001');
      expect(json['recipientMemberId'], 'MEM_001');
      expect(json['advanceAmount'], 2000000);
      expect(json['receivedDate'], contains('2026-11-18'));
      expect(json['settlementDeadline'], contains('2026-11-22'));
      expect(json['commitmentNotes'], 'Cam kết thanh toán đúng hạn');
    });

    test('ConfirmDisbursementRequestDto serializes optional notes', () {
      final withNotes = ConfirmDisbursementRequestDto(
        notes: 'Tiền mặt đã giao tận tay tại nhà từ đường',
      );
      expect(withNotes.toJson()['notes'], 'Tiền mặt đã giao tận tay tại nhà từ đường');

      final withoutNotes = ConfirmDisbursementRequestDto();
      expect(withoutNotes.toJson()['notes'], isNull);
    });
  });

  group('DualRbacSession Advance Voucher Permissions', () {
    const eventId = 'EVT_001';

    DualRbacSession createSession({
      required Set<SystemRole> globalRoles,
      Map<String, EventPermissionContext> eventRoles = const {},
      String memberId = 'MEM_001',
    }) {
      return DualRbacSession(
        accountId: 'ACC_001',
        memberId: memberId,
        fullName: 'Nguyễn Văn Test',
        branchName: 'Chi 1',
        globalRoles: globalRoles,
        eventRolesByEventId: eventRoles,
      );
    }

    test('Clan Head and Admin have full create and disburse permissions', () {
      final clanHeadSession = createSession(globalRoles: {SystemRole.roleClanHead});
      expect(clanHeadSession.canCreateAdvanceVoucher(isClosed: false, eventId: eventId), isTrue);
      expect(clanHeadSession.canDisburseAdvanceVoucher(isClosed: false, eventId: eventId), isTrue);

      final adminSession = createSession(globalRoles: {SystemRole.roleAdmin});
      expect(adminSession.canCreateAdvanceVoucher(isClosed: false, eventId: eventId), isTrue);
      expect(adminSession.canDisburseAdvanceVoucher(isClosed: false, eventId: eventId), isTrue);
    });

    test('Event Treasurer can both create and disburse advance vouchers', () {
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

      expect(treasurerSession.canCreateAdvanceVoucher(isClosed: false, eventId: eventId), isTrue);
      expect(treasurerSession.canDisburseAdvanceVoucher(isClosed: false, eventId: eventId), isTrue);
    });

    test('HeadOfOrganizer and OrganizerMember can create, but CANNOT disburse', () {
      final headOfOrganizerSession = createSession(
        globalRoles: {SystemRole.roleMember},
        eventRoles: {
          eventId: const EventPermissionContext(
            eventId: eventId,
            role: EventContextualRole.headOfOrganizer,
            eventStatus: EventLifecycleStatus.ongoing,
          ),
        },
      );
      expect(headOfOrganizerSession.canCreateAdvanceVoucher(isClosed: false, eventId: eventId), isTrue);
      expect(headOfOrganizerSession.canDisburseAdvanceVoucher(isClosed: false, eventId: eventId), isFalse);

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
      expect(organizerMemberSession.canCreateAdvanceVoucher(isClosed: false, eventId: eventId), isTrue);
      expect(organizerMemberSession.canDisburseAdvanceVoucher(isClosed: false, eventId: eventId), isFalse);
    });

    test('Regular member has NO create and NO disburse permissions', () {
      final regularMemberSession = createSession(globalRoles: {SystemRole.roleMember});
      expect(regularMemberSession.canCreateAdvanceVoucher(isClosed: false, eventId: eventId), isFalse);
      expect(regularMemberSession.canDisburseAdvanceVoucher(isClosed: false, eventId: eventId), isFalse);
    });

    test('Closed event revokes all create and disburse permissions', () {
      final treasurerSession = createSession(
        globalRoles: {SystemRole.roleClanHead},
        eventRoles: {
          eventId: const EventPermissionContext(
            eventId: eventId,
            role: EventContextualRole.eventTreasurer,
            eventStatus: EventLifecycleStatus.closed,
          ),
        },
      );

      expect(
        treasurerSession.canCreateAdvanceVoucher(isClosed: true, eventId: eventId),
        isFalse,
      );
      expect(
        treasurerSession.canDisburseAdvanceVoucher(isClosed: true, eventId: eventId),
        isFalse,
      );
    });

    test('Fallback to personnel dynamic list if eventRolesByEventId is empty', () {
      final regularSession = createSession(
        memberId: 'MEM_USER_001',
        globalRoles: {SystemRole.roleMember},
      );

      final personnel = [
        {
          'memberId': 'MEM_USER_001',
          'eventRole': 'EventTreasurer',
          'isReadOnly': false,
        },
      ];

      expect(
        regularSession.canDisburseAdvanceVoucher(
          isClosed: false,
          eventId: eventId,
          personnel: personnel,
        ),
        isTrue,
      );

      final personnelOther = [
        {
          'memberId': 'MEM_OTHER',
          'eventRole': 'EventTreasurer',
          'isReadOnly': false,
        },
      ];

      expect(
        regularSession.canDisburseAdvanceVoucher(
          isClosed: false,
          eventId: eventId,
          personnel: personnelOther,
        ),
        isFalse,
      );
    });
  });
}
