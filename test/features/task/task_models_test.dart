import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/event/data/models/event_models.dart';
import 'package:familyfund_app/features/task/data/models/task_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskModel & TaskStatusEnum Unit Tests', () {
    test('TaskStatusEnum fromCode correctly parses all official backend statuses', () {
      expect(TaskStatusEnum.fromCode('Unassigned'), TaskStatusEnum.unassigned);
      expect(TaskStatusEnum.fromCode('InProgress'), TaskStatusEnum.inProgress);
      expect(TaskStatusEnum.fromCode('Completed'), TaskStatusEnum.completed);
      expect(TaskStatusEnum.fromCode('Overdue'), TaskStatusEnum.overdue);
      // Fallback
      expect(TaskStatusEnum.fromCode('UnknownValue'), TaskStatusEnum.unassigned);
      expect(TaskStatusEnum.fromCode(null), TaskStatusEnum.unassigned);
    });

    test('TaskModel parses JSON with advanceBudget as int, double, or null', () {
      final jsonWithInt = {
        'taskId': 'T-01',
        'eventId': 'EV-01',
        'taskName': 'Mua đồ lễ và hương hoa',
        'details': 'Liên hệ nhà vườn chuẩn bị hoa tươi',
        'advanceBudget': 5000000,
        'deadline': '2026-11-10T17:00:00.000Z',
        'status': 'InProgress',
        'assignedMemberId': 'M-001',
        'assignedMemberName': 'Nguyễn Văn An',
        'assignedBranchId': null,
        'assignedBranchName': null,
        'createdBy': 'ADMIN-01',
      };

      final task1 = TaskModel.fromJson(jsonWithInt);
      expect(task1.taskId, 'T-01');
      expect(task1.taskName, 'Mua đồ lễ và hương hoa');
      expect(task1.advanceBudget, 5000000);
      expect(task1.status, TaskStatusEnum.inProgress);
      expect(task1.hasAssignee, isTrue);
      expect(task1.assigneeDisplayName, 'Nguyễn Văn An');

      // JSON with double advanceBudget should round to int
      final jsonWithDouble = Map<String, dynamic>.from(jsonWithInt)
        ..['advanceBudget'] = 2500000.75;
      final task2 = TaskModel.fromJson(jsonWithDouble);
      expect(task2.advanceBudget, 2500001);

      // JSON with null advanceBudget defaults to 0
      final jsonWithNullBudget = Map<String, dynamic>.from(jsonWithInt)
        ..['advanceBudget'] = null;
      final task3 = TaskModel.fromJson(jsonWithNullBudget);
      expect(task3.advanceBudget, 0);
    });

    test('TaskModel formattedAdvanceBudget displays correctly formatted VND', () {
      final task = TaskModel(
        taskId: 'T-01',
        eventId: 'EV-01',
        taskName: 'Dựng rạp',
        advanceBudget: 15000000,
        deadline: DateTime.parse('2026-11-15T12:00:00'),
        status: TaskStatusEnum.inProgress,
        createdBy: 'ADMIN',
      );

      expect(task.formattedAdvanceBudget, contains('15.000.000'));
    });

    test('TaskModel branch assignment flags behave correctly', () {
      final branchTask = TaskModel(
        taskId: 'T-02',
        eventId: 'EV-01',
        taskName: 'Trực hậu cần bếp',
        advanceBudget: 3000000,
        deadline: DateTime.parse('2026-11-15T12:00:00'),
        assignedBranchId: 'B-02',
        assignedBranchName: 'Chi Đệ Nhị',
        status: TaskStatusEnum.inProgress,
        createdBy: 'ADMIN',
      );

      expect(branchTask.hasAssignee, isTrue);
      expect(branchTask.assigneeDisplayName, 'Chi Đệ Nhị');
    });
  });

  group('CreateTaskRequestDto & AssignTaskRequestDto DTO Tests', () {
    test('CreateTaskRequestDto serializes to valid backend JSON schema', () {
      final req = CreateTaskRequestDto(
        taskName: 'Chuẩn bị văn tế',
        details: 'Soạn thảo và duyệt bài tế Tổ',
        advanceBudget: 2000000,
        deadline: DateTime.utc(2026, 11, 25, 9, 0),
        assignedMemberId: 'M-101',
      );

      final json = req.toJson();
      expect(json['taskName'], 'Chuẩn bị văn tế');
      expect(json['details'], 'Soạn thảo và duyệt bài tế Tổ');
      expect(json['advanceBudget'], 2000000);
      expect(json['assignedMemberId'], 'M-101');
      expect(json.containsKey('assignedBranchId'), isFalse);
      expect(json['deadline'], startsWith('2026-11-25T09:00'));
    });

    test('AssignTaskRequestDto handles member vs branch assignment', () {
      const assignMember = AssignTaskRequestDto(assignedMemberId: 'M-99');
      expect(assignMember.toJson(), {
        'assignedMemberId': 'M-99',
      });

      const assignBranch = AssignTaskRequestDto(assignedBranchId: 'B-03');
      expect(assignBranch.toJson(), {
        'assignedBranchId': 'B-03',
      });
    });
  });

  group('RBAC DualRbacSession.canManageTasks Tests', () {
    test('Global Admin and Clan Head can always manage tasks if event is open', () {
      const adminSession = DualRbacSession(
        accountId: 'ACC-ADMIN',
        memberId: 'USER-ADMIN',
        fullName: 'Quản Trị Viên',
        branchName: 'Chi 1',
        globalRoles: {SystemRole.roleAdmin},
      );
      expect(
        adminSession.canManageTasks(isClosed: false, personnel: [], eventId: 'EV-1'),
        isTrue,
      );

      const clanHeadSession = DualRbacSession(
        accountId: 'ACC-CH',
        memberId: 'USER-CH',
        fullName: 'Trưởng Tộc',
        branchName: 'Chi 1',
        globalRoles: {SystemRole.roleClanHead},
      );
      expect(
        clanHeadSession.canManageTasks(isClosed: false, personnel: [], eventId: 'EV-1'),
        isTrue,
      );
    });

    test('Closed event blocks task management for all roles (Read-only guarantee)', () {
      const adminSession = DualRbacSession(
        accountId: 'ACC-ADMIN',
        memberId: 'USER-ADMIN',
        fullName: 'Quản Trị Viên',
        branchName: 'Chi 1',
        globalRoles: {SystemRole.roleAdmin},
      );
      expect(
        adminSession.canManageTasks(isClosed: true, personnel: [], eventId: 'EV-1'),
        isFalse,
      );
    });

    test('Event contextual roles: HeadOfOrganizer and OrganizerMember can manage tasks', () {
      const memberSession = DualRbacSession(
        accountId: 'ACC-MEMBER',
        memberId: 'USER-BTC',
        fullName: 'Thành viên BTC',
        branchName: 'Chi 2',
        globalRoles: {SystemRole.roleMember},
      );

      // Case 1: User is HeadOfOrganizer
      final headPersonnel = [
        const EventPersonnelModel(
          memberId: 'USER-BTC',
          memberName: 'Nguyễn Văn Trưởng',
          eventRole: 'HeadOfOrganizer',
        ),
      ];
      expect(
        memberSession.canManageTasks(isClosed: false, personnel: headPersonnel, eventId: 'EV-1'),
        isTrue,
      );

      // Case 2: User is OrganizerMember
      final memberPersonnel = [
        const EventPersonnelModel(
          memberId: 'USER-BTC',
          memberName: 'Nguyễn Văn BTC',
          eventRole: 'OrganizerMember',
        ),
      ];
      expect(
        memberSession.canManageTasks(isClosed: false, personnel: memberPersonnel, eventId: 'EV-1'),
        isTrue,
      );

      // Case 3: Regular member with no organizer role cannot manage tasks
      expect(
        memberSession.canManageTasks(isClosed: false, personnel: [], eventId: 'EV-1'),
        isFalse,
      );
    });
  });
}
