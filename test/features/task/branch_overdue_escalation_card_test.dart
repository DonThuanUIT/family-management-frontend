import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/event/data/models/event_models.dart';
import 'package:familyfund_app/features/event/data/repositories/event_repository_impl.dart';
import 'package:familyfund_app/features/event/domain/repositories/event_repository.dart';
import 'package:familyfund_app/features/task/data/models/task_models.dart';
import 'package:familyfund_app/features/task/data/repositories/task_repository_impl.dart';
import 'package:familyfund_app/features/task/domain/repositories/task_repository.dart';
import 'package:familyfund_app/features/task/presentation/screens/event_task_list_screen.dart';
import 'package:familyfund_app/features/task/presentation/widgets/branch_overdue_escalation_card.dart';

class FakeTaskRepo implements TaskRepository {
  final List<TaskModel> tasks;

  FakeTaskRepo(this.tasks);

  @override
  Future<List<TaskModel>> getTasks(
    String eventId, {
    TaskStatusEnum? status,
    String? assignedMemberId,
    String? assignedBranchId,
  }) async {
    return tasks;
  }

  @override
  Future<TaskModel> getTaskDetail(String eventId, String taskId) async {
    return tasks.firstWhere((t) => t.taskId == taskId);
  }

  @override
  Future<TaskModel> createTask(
      String eventId, CreateTaskRequestDto request) async {
    throw UnimplementedError();
  }

  @override
  Future<TaskModel> assignTask(
      String eventId, String taskId, AssignTaskRequestDto request) async {
    throw UnimplementedError();
  }
}

class FakeEventRepo implements EventRepository {
  final EventModel event;

  FakeEventRepo(this.event);

  @override
  Future<List<EventModel>> getEvents() async => [event];

  @override
  Future<EventModel> getEventDetail(String eventId) async => event;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession customSession;

  FakeRbacNotifier(this.customSession);

  @override
  DualRbacSession build() => customSession;
}

void main() {
  final overdueTask1 = TaskModel(
    taskId: 'TSK-01',
    eventId: 'EVT-01',
    taskName: 'Chuẩn bị bài tế văn & trang phục khánh tiết',
    details: 'Hoàn thiện bản thảo văn tế',
    advanceBudget: 1500000,
    deadline: DateTime.now().subtract(const Duration(hours: 14)),
    status: TaskStatusEnum.inProgress,
    assignedBranchId: 'BR_CHI_2',
    assignedBranchName: 'Chi 2 - Nhánh Giáp',
    assignedMemberId: 'MEM_01',
    assignedMemberName: 'Nguyễn Văn Em',
    createdBy: 'ADMIN',
  );

  final overdueTask2 = TaskModel(
    taskId: 'TSK-02',
    eventId: 'EVT-01',
    taskName: 'Mua sắm lễ vật tam sinh',
    advanceBudget: 3000000,
    deadline: DateTime.now().subtract(const Duration(hours: 16)),
    status: TaskStatusEnum.inProgress,
    assignedBranchId: 'BR_CHI_2',
    assignedBranchName: 'Chi 2 - Nhánh Giáp',
    assignedMemberId: 'MEM_02',
    assignedMemberName: 'Trần Văn Bình',
    createdBy: 'ADMIN',
  );

  final testEvent = EventModel(
    eventId: 'EVT-01',
    eventName: 'Lễ Giỗ Tổ 2026',
    eventDatetime: DateTime(2026, 12, 1, 8, 0),
    status: 'Upcoming',
    estimatedBudget: 50000000,
    location: 'Từ Đường',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('BranchOverdueEscalationCard Widget Tests (US-47)', () {
    testWidgets('Renders emergency header, branch name, and task items with badges',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BranchOverdueEscalationCard(
                overdueTasks: [overdueTask1, overdueTask2],
                branchName: 'Chi 2 - Nhánh Giáp',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header & Badge
      expect(find.text('BÁO ĐỘNG VƯỢT CẤP (12H)'), findsOneWidget);
      expect(find.text('Cảnh Báo Quá Hạn Thuộc Chi 2 - Nhánh Giáp'), findsOneWidget);
      expect(find.text('2 việc trễ'), findsOneWidget);

      // 2. Task names & overdue badges
      expect(find.text('Chuẩn bị bài tế văn & trang phục khánh tiết'), findsOneWidget);
      expect(find.text('Mua sắm lễ vật tam sinh'), findsOneWidget);
      expect(find.text('Trễ 14h'), findsOneWidget);
      expect(find.text('Trễ 16h'), findsOneWidget);

      // 3. Action buttons
      expect(find.text('Đôn đốc ngay'), findsNWidgets(2));
    });

    testWidgets('Tapping "Đôn đốc ngay" displays Nudge dialog and sends notification',
        (tester) async {
      TaskModel? nudgedTask;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BranchOverdueEscalationCard(
                overdueTasks: [overdueTask1],
                branchName: 'Chi 2 - Nhánh Giáp',
                onNudge: (t) => nudgedTask = t,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Đôn đốc ngay"
      await tester.tap(find.text('Đôn đốc ngay'));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Đôn Đốc Tiến Độ'), findsOneWidget);
      expect(find.textContaining('Kính gửi Nguyễn Văn Em'), findsOneWidget);

      // Confirm send
      await tester.tap(find.text('Gửi Đôn Đốc'));
      await tester.pumpAndSettle();

      // Callback invoked and SnackBar displayed
      expect(nudgedTask, equals(overdueTask1));
      expect(
        find.text('Đã gửi thông báo đôn đốc thành công tới Nguyễn Văn Em!'),
        findsOneWidget,
      );
    });
  });

  group('RBAC Visibility Matrix for BranchOverdueEscalationCard (US-47)', () {
    testWidgets('Trưởng chi (ROLE_BRANCH_HEAD) sees escalation card for their branch',
        (tester) async {
      const branchHeadSession = DualRbacSession(
        accountId: 'ACC_BH',
        memberId: 'MEM_BH',
        fullName: 'Nguyễn Văn An',
        branchName: 'Chi 2 - Nhánh Giáp',
        managedBranchId: 'BR_CHI_2',
        globalRoles: {SystemRole.roleBranchHead, SystemRole.roleMember},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWithValue(FakeTaskRepo([overdueTask1])),
            eventRepositoryProvider.overrideWithValue(FakeEventRepo(testEvent)),
            dualRbacSessionProvider
                .overrideWith(() => FakeRbacNotifier(branchHeadSession)),
          ],
          child: const MaterialApp(
            home: EventTaskListScreen(eventId: 'EVT-01'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card is displayed for Trưởng chi
      expect(find.byType(BranchOverdueEscalationCard), findsOneWidget);
      expect(find.text('BÁO ĐỘNG VƯỢT CẤP (12H)'), findsOneWidget);
    });

    testWidgets('Thành viên con cháu (ROLE_MEMBER) NEVER sees the emergency escalation card',
        (tester) async {
      const memberSession = DualRbacSession(
        accountId: 'ACC_MEM',
        memberId: 'MEM_CON_CHAU',
        fullName: 'Nguyễn Thị Mai Anh',
        branchName: 'Chi 2 - Nhánh Giáp',
        managedBranchId: null,
        globalRoles: {SystemRole.roleMember},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWithValue(FakeTaskRepo([overdueTask1])),
            eventRepositoryProvider.overrideWithValue(FakeEventRepo(testEvent)),
            dualRbacSessionProvider
                .overrideWith(() => FakeRbacNotifier(memberSession)),
          ],
          child: const MaterialApp(
            home: EventTaskListScreen(eventId: 'EVT-01'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card is strictly hidden for regular members
      expect(find.byType(BranchOverdueEscalationCard), findsNothing);
      expect(find.text('BÁO ĐỘNG VƯỢT CẤP (12H)'), findsNothing);
    });

    testWidgets('Trưởng chi of another branch (e.g. BR_CHI_3) does not see card for BR_CHI_2 tasks',
        (tester) async {
      const otherBranchHeadSession = DualRbacSession(
        accountId: 'ACC_BH_OTHER',
        memberId: 'MEM_BH_OTHER',
        fullName: 'Lê Văn Khang',
        branchName: 'Chi 3 - Nhánh Ất',
        managedBranchId: 'BR_CHI_3',
        globalRoles: {SystemRole.roleBranchHead, SystemRole.roleMember},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWithValue(FakeTaskRepo([overdueTask1])),
            eventRepositoryProvider.overrideWithValue(FakeEventRepo(testEvent)),
            dualRbacSessionProvider
                .overrideWith(() => FakeRbacNotifier(otherBranchHeadSession)),
          ],
          child: const MaterialApp(
            home: EventTaskListScreen(eventId: 'EVT-01'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No overdue tasks belonging to Chi 3 -> Card is not shown
      expect(find.byType(BranchOverdueEscalationCard), findsNothing);
    });
  });
}
