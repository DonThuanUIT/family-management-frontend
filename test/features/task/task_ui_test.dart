import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/event/data/models/event_models.dart';
import 'package:familyfund_app/features/event/data/repositories/event_repository_impl.dart';
import 'package:familyfund_app/features/event/domain/repositories/event_repository.dart';
import 'package:familyfund_app/features/task/data/models/task_models.dart';
import 'package:familyfund_app/features/task/data/repositories/task_repository_impl.dart';
import 'package:familyfund_app/features/task/domain/repositories/task_repository.dart';
import 'package:familyfund_app/features/task/presentation/screens/event_task_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTaskRepository implements TaskRepository {
  List<TaskModel> mockTasks;

  FakeTaskRepository({required this.mockTasks});

  @override
  Future<List<TaskModel>> getTasks(
    String eventId, {
    TaskStatusEnum? status,
    String? assignedMemberId,
    String? assignedBranchId,
  }) async {
    return mockTasks;
  }

  @override
  Future<TaskModel> getTaskDetail(String eventId, String taskId) async {
    return mockTasks.firstWhere((t) => t.taskId == taskId);
  }

  @override
  Future<TaskModel> createTask(String eventId, CreateTaskRequestDto request) async {
    final newTask = TaskModel(
      taskId: 'T-${mockTasks.length + 1}',
      eventId: eventId,
      taskName: request.taskName,
      details: request.details,
      advanceBudget: request.advanceBudget,
      deadline: request.deadline,
      status: (request.assignedMemberId != null || request.assignedBranchId != null)
          ? TaskStatusEnum.inProgress
          : TaskStatusEnum.unassigned,
      assignedMemberId: request.assignedMemberId,
      assignedBranchId: request.assignedBranchId,
      createdBy: 'USER-TEST',
    );
    mockTasks.add(newTask);
    return newTask;
  }

  @override
  Future<TaskModel> assignTask(
    String eventId,
    String taskId,
    AssignTaskRequestDto request,
  ) async {
    final index = mockTasks.indexWhere((t) => t.taskId == taskId);
    final old = mockTasks[index];
    final updated = old.copyWith(
      assignedMemberId: request.assignedMemberId,
      assignedBranchId: request.assignedBranchId,
      status: TaskStatusEnum.inProgress,
    );
    mockTasks[index] = updated;
    return updated;
  }
}

class FakeEventRepository implements EventRepository {
  final EventModel mockEvent;

  FakeEventRepository({required this.mockEvent});

  @override
  Future<List<EventModel>> getEvents() async => [mockEvent];

  @override
  Future<EventModel> getEventDetail(String eventId) async => mockEvent;

  @override
  Future<EventModel> createEvent(CreateEventRequestDto request) async => mockEvent;

  @override
  Future<EventModel> updateEvent(String eventId, UpdateEventRequestDto request) async => mockEvent;

  @override
  Future<EventModel> updateEventStatus(String eventId, String newStatus) async => mockEvent;

  @override
  Future<List<EventPersonnelModel>> assignPersonnel(
      String eventId, AssignPersonnelRequestDto request) async {
    return [EventPersonnelModel(memberId: request.memberId, eventRole: request.eventRole)];
  }

  @override
  Future<List<EventNotificationModel>> getEventNotifications(String eventId) async => [];
}

class FakeDualRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession customSession;

  FakeDualRbacNotifier(this.customSession);

  @override
  DualRbacSession build() => customSession;
}

void main() {
  final testTasks = [
    TaskModel(
      taskId: 'T-01',
      eventId: 'EV-01',
      taskName: 'Mua sắm lễ vật hương hoa',
      details: 'Liên hệ chợ đầu mối chuẩn bị hoa cúc vàng',
      advanceBudget: 3500000,
      deadline: DateTime.now().add(const Duration(days: 3)),
      status: TaskStatusEnum.inProgress,
      assignedMemberId: 'M-01',
      assignedMemberName: 'Nguyễn Văn Nam',
      createdBy: 'ADMIN',
    ),
    TaskModel(
      taskId: 'T-02',
      eventId: 'EV-01',
      taskName: 'Dựng rạp sân chính và bàn ghế',
      details: 'Dựng 10 gian rạp và 50 bộ bàn ghế',
      advanceBudget: 8000000,
      deadline: DateTime.now().subtract(const Duration(days: 1)),
      status: TaskStatusEnum.overdue,
      assignedBranchId: 'B-01',
      assignedBranchName: 'Chi Đệ Nhất',
      createdBy: 'ADMIN',
    ),
    TaskModel(
      taskId: 'T-03',
      eventId: 'EV-01',
      taskName: 'Soạn bài văn tế Tổ tiên',
      details: 'Đã hoàn thành duyệt bài cùng các cụ cao niên',
      advanceBudget: 500000,
      deadline: DateTime.now().subtract(const Duration(days: 2)),
      status: TaskStatusEnum.completed,
      assignedMemberId: 'M-02',
      assignedMemberName: 'Vũ Văn B',
      createdBy: 'ADMIN',
    ),
  ];

  final openEvent = EventModel(
    eventId: 'EV-01',
    eventName: 'Đại Lễ Giỗ Tổ Tiên Lạc',
    eventDatetime: DateTime(2026, 12, 1, 8, 0),
    status: 'Upcoming',
    estimatedBudget: 50000000,
    location: 'Từ Đường Vũ Tộc',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    personnel: const [
      EventPersonnelModel(
        memberId: 'USER-TEST',
        eventRole: 'HeadOfOrganizer',
      ),
    ],
  );

  final closedEvent = EventModel(
    eventId: 'EV-02',
    eventName: 'Lễ Hạ Điền Năm Ngoái',
    eventDatetime: DateTime(2025, 10, 1, 8, 0),
    status: 'Closed',
    estimatedBudget: 20000000,
    location: 'Từ Đường',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 10, 2),
    personnel: const [
      EventPersonnelModel(
        memberId: 'USER-TEST',
        eventRole: 'HeadOfOrganizer',
      ),
    ],
  );

  const testSession = DualRbacSession(
    accountId: 'ACC-1',
    memberId: 'USER-TEST',
    fullName: 'Trưởng Ban Tổ Chức',
    branchName: 'Chi Đệ Nhất',
    globalRoles: {SystemRole.roleClanHead},
  );

  testWidgets('EventTaskListScreen renders tasks, KPI cards, and status badges',
      (WidgetTester tester) async {
    final fakeTaskRepo = FakeTaskRepository(mockTasks: List.from(testTasks));
    final fakeEventRepo = FakeEventRepository(mockEvent: openEvent);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          eventRepositoryProvider.overrideWithValue(fakeEventRepo),
          dualRbacSessionProvider.overrideWith(() => FakeDualRbacNotifier(testSession)),
        ],
        child: const MaterialApp(
          home: EventTaskListScreen(eventId: 'EV-01'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Header & Event Information
    expect(find.text('Hạng Mục Công Việc Chuẩn Bị'), findsOneWidget);
    expect(find.text('Đại Lễ Giỗ Tổ Tiên Lạc'), findsOneWidget);

    // 2. Action buttons for authorized user in Open event
    expect(find.text('Tạo việc'), findsOneWidget);

    // 3. Task cards rendered
    expect(find.text('Mua sắm lễ vật hương hoa'), findsOneWidget);
    expect(find.text('Dựng rạp sân chính và bàn ghế'), findsOneWidget);
    expect(find.text('Soạn bài văn tế Tổ tiên'), findsOneWidget);

    // 4. Assignee badges
    expect(find.text('Nguyễn Văn Nam'), findsOneWidget);
    expect(find.text('Chi Đệ Nhất'), findsOneWidget);

    // 5. Advance budget display
    expect(find.textContaining('3.500.000'), findsWidgets);
    expect(find.textContaining('8.000.000'), findsWidgets);
  });

  testWidgets('EventTaskListScreen filters tasks by status tab',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeTaskRepo = FakeTaskRepository(mockTasks: List.from(testTasks));
    final fakeEventRepo = FakeEventRepository(mockEvent: openEvent);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          eventRepositoryProvider.overrideWithValue(fakeEventRepo),
          dualRbacSessionProvider.overrideWith(() => FakeDualRbacNotifier(testSession)),
        ],
        child: const MaterialApp(
          home: EventTaskListScreen(eventId: 'EV-01'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap filter "Quá hạn (1)"
    await tester.tap(find.text('Quá hạn (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Dựng rạp sân chính và bàn ghế'), findsOneWidget);
    expect(find.text('Mua sắm lễ vật hương hoa'), findsNothing);
    expect(find.text('Soạn bài văn tế Tổ tiên'), findsNothing);

    // Tap filter "Đã xong (1)"
    await tester.tap(find.text('Đã xong (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Soạn bài văn tế Tổ tiên'), findsOneWidget);
    expect(find.text('Dựng rạp sân chính và bàn ghế'), findsNothing);
  });

  testWidgets('EventTaskListScreen renders Closed banner and blocks creation when event is Closed',
      (WidgetTester tester) async {
    final fakeTaskRepo = FakeTaskRepository(mockTasks: List.from(testTasks));
    final fakeEventRepo = FakeEventRepository(mockEvent: closedEvent);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          eventRepositoryProvider.overrideWithValue(fakeEventRepo),
          dualRbacSessionProvider.overrideWith(() => FakeDualRbacNotifier(testSession)),
        ],
        child: const MaterialApp(
          home: EventTaskListScreen(eventId: 'EV-02'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Closed warning banner must be shown
    expect(find.text('Sự kiện đã kết thúc và khóa sổ (Closed)'), findsOneWidget);

    // 2. Create task floating button must NOT be rendered
    expect(find.text('Tạo việc'), findsNothing);
    expect(find.text('Tạo Công Việc'), findsNothing);
  });

  testWidgets('EventTaskListScreen renders Empty State when no tasks exist',
      (WidgetTester tester) async {
    final fakeTaskRepo = FakeTaskRepository(mockTasks: []);
    final fakeEventRepo = FakeEventRepository(mockEvent: openEvent);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(fakeTaskRepo),
          eventRepositoryProvider.overrideWithValue(fakeEventRepo),
          dualRbacSessionProvider.overrideWith(() => FakeDualRbacNotifier(testSession)),
        ],
        child: const MaterialApp(
          home: EventTaskListScreen(eventId: 'EV-01'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Chưa có hạng mục công việc nào'), findsOneWidget);
    expect(find.text('Tạo Công Việc Đầu Tiên'), findsOneWidget);
  });
}
