import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/event/presentation/widgets/create_event_sheet.dart';
import 'package:familyfund_app/features/notification/data/models/notification_models.dart';
import 'package:familyfund_app/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:familyfund_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:familyfund_app/features/notification/presentation/providers/notification_providers.dart';
import 'package:familyfund_app/features/notification/presentation/widgets/notification_center_dialog.dart';
import 'package:familyfund_app/features/shared/presentation/widgets/heritage_nav_bar.dart';

class MockNotificationRepository implements NotificationRepository {
  List<NotificationModel> notifications;
  UnreadCountModel unreadCount;

  MockNotificationRepository({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  Future<List<NotificationModel>> getNotifications({
    NotificationCategoryEnum? category,
    bool? isRead,
    int page = 0,
    int size = 20,
  }) async {
    return notifications.where((n) {
      if (category != null && n.category != category) return false;
      if (isRead != null && n.isRead != isRead) return false;
      return true;
    }).toList();
  }

  @override
  Future<UnreadCountModel> getUnreadSummary() async {
    return unreadCount;
  }

  @override
  Future<NotificationModel> markAsRead(String notificationId) async {
    final idx = notifications.indexWhere((n) => n.notificationId == notificationId);
    if (idx != -1) {
      final updated = notifications[idx].copyWith(isRead: true);
      notifications[idx] = updated;
      unreadCount = UnreadCountModel(
        total: (unreadCount.total - 1).clamp(0, 999),
        taskCount: (unreadCount.taskCount - 1).clamp(0, 999),
        eventCount: unreadCount.eventCount,
        financeCount: unreadCount.financeCount,
      );
      return updated;
    }
    throw Exception('Notification not found');
  }

  @override
  Future<int> markAllAsRead({NotificationCategoryEnum? category}) async {
    int modified = 0;
    notifications = notifications.map((n) {
      if (category == null || n.category == category) {
        if (!n.isRead) modified++;
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    unreadCount = const UnreadCountModel(total: 0, taskCount: 0, eventCount: 0, financeCount: 0);
    return modified;
  }
}

class _MemberOnlyRbacNotifier extends DualRbacSessionNotifier {
  @override
  DualRbacSession build() {
    return const DualRbacSession(
      accountId: 'ACC_MEMBER',
      memberId: 'MEM_MAI_ANH',
      fullName: 'Nguyễn Thị Mai Anh',
      branchName: 'Chi 2 - Nhánh Giáp',
      managedBranchId: '',
      globalRoles: {SystemRole.roleMember},
      eventRolesByEventId: {},
    );
  }
}

void main() {
  group('Notification Models & Serialization Tests', () {
    test('NotificationModel serializes and deserializes correctly', () {
      final json = {
        'notificationId': 'notif-001',
        'clanId': 'clan-1',
        'title': 'Cảnh báo tiến độ: Mua sắm lễ vật dâng hương',
        'content': 'Công việc chỉ còn dưới 24 giờ trước hạn chót.',
        'category': 'Task',
        'referenceType': 'Task',
        'referenceId': 'T-001',
        'isRead': false,
        'createdAt': '2026-11-15T08:00:00Z',
      };

      final model = NotificationModel.fromJson(json);
      expect(model.notificationId, 'notif-001');
      expect(model.clanId, 'clan-1');
      expect(model.title, 'Cảnh báo tiến độ: Mua sắm lễ vật dâng hương');
      expect(model.content, 'Công việc chỉ còn dưới 24 giờ trước hạn chót.');
      expect(model.category, NotificationCategoryEnum.task);
      expect(model.isTaskDeadlineWarning, isTrue);
      expect(model.isRead, isFalse);

      final serialized = model.toJson();
      expect(serialized['notificationId'], 'notif-001');
      expect(serialized['category'], 'Task');
    });

    test('NotificationModel parses death anniversary reminder and exposes US-40 getters', () {
      final json = {
        'notificationId': 'notif-us40-001',
        'clanId': 'clan-1',
        'title': 'Nhắc nhở ngày giỗ: Cụ Lê Văn An (Đời thứ 3)',
        'content':
            'Sắp đến ngày giỗ Cụ Lê Văn An vào ngày 15/02 Âm lịch (Dương lịch: 23/03/2026).',
        'category': 'Event',
        'referenceType': 'DeathAnniversary',
        'referenceId': 'MEM-003',
        'isRead': false,
        'createdAt': '2026-11-15T08:00:00Z',
        'metadata': {
          'deceasedName': 'Cụ Lê Văn An',
          'deathDateSolar': '2026-03-23T08:30:00.000Z',
          'deathDateLunar': '15/02 Âm lịch',
          'location': 'Từ đường Chi 2, Xã Kim Liên',
          'suggestedBudget': 35000000.0,
          'description': 'Lễ tưởng niệm và cúng giỗ Cụ Lê Văn An.',
        },
      };

      final model = NotificationModel.fromJson(json);
      expect(model.isDeathAnniversaryReminder, isTrue);
      expect(model.deceasedName, 'Cụ Lê Văn An');
      expect(model.deathDateLunar, '15/02 Âm lịch');
      expect(model.deathDateSolar, DateTime.parse('2026-03-23T08:30:00.000Z'));
      expect(model.suggestedLocation, 'Từ đường Chi 2, Xã Kim Liên');
      expect(model.suggestedBudget, 35000000.0);
      expect(
          model.suggestedDescription, 'Lễ tưởng niệm và cúng giỗ Cụ Lê Văn An.');
    });

    test('UnreadCountModel parses count and provides hasUnread getter', () {
      final json = {
        'total': 3,
        'taskCount': 2,
        'eventCount': 1,
        'financeCount': 0,
      };

      final unread = UnreadCountModel.fromJson(json);
      expect(unread.total, 3);
      expect(unread.taskCount, 2);
      expect(unread.hasUnread, isTrue);

      const empty = UnreadCountModel(total: 0, taskCount: 0, eventCount: 0, financeCount: 0);
      expect(empty.hasUnread, isFalse);
    });

    test('NotificationCategoryEnum label and code mappings', () {
      expect(NotificationCategoryEnum.task.displayName, 'Công Việc');
      expect(NotificationCategoryEnum.task.code, 'Task');
      expect(NotificationCategoryEnum.event.displayName, 'Sự Kiện');
      expect(NotificationCategoryEnum.finance.displayName, 'Tài Chính');
    });
  });

  group('NotificationListNotifier & State Management Tests', () {
    late MockNotificationRepository mockRepo;
    late List<NotificationModel> initialList;

    setUp(() {
      initialList = [
        NotificationModel(
          notificationId: 'n1',
          clanId: 'c1',
          title: 'Cảnh báo tiến độ: Chuẩn bị văn tế',
          content: 'Còn 18 giờ đến hạn chót',
          category: NotificationCategoryEnum.task,
          referenceType: 'Task',
          referenceId: 'T-10',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          notificationId: 'n2',
          clanId: 'c1',
          title: 'Phân công nhiệm vụ mới',
          content: 'Trưởng ban đã giao việc',
          category: NotificationCategoryEnum.task,
          referenceType: 'Task',
          referenceId: 'T-11',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        NotificationModel(
          notificationId: 'n3',
          clanId: 'c1',
          title: 'Lễ Giỗ Tổ sắp diễn ra',
          content: 'Sự kiện diễn ra vào sáng mai',
          category: NotificationCategoryEnum.event,
          referenceType: 'Event',
          referenceId: 'E-01',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        ),
      ];

      mockRepo = MockNotificationRepository(
        notifications: initialList,
        unreadCount: const UnreadCountModel(total: 2, taskCount: 1, eventCount: 1, financeCount: 0),
      );
    });

    test('loadInitial loads notifications and unread summary', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(notificationListProvider.notifier);
      await notifier.loadInitial();
      final state = container.read(notificationListProvider);
      expect(state.notifications.length, 3);
      expect(state.unreadSummary.total, 2);
      expect(state.unreadSummary.taskCount, 1);
    });

    test('setCategory filters notifications accordingly', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(notificationListProvider.notifier);
      await notifier.loadInitial();

      notifier.setCategory(NotificationCategoryEnum.task);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final state = container.read(notificationListProvider);
      expect(state.selectedCategory, NotificationCategoryEnum.task);
      expect(state.notifications.every((n) => n.category == NotificationCategoryEnum.task), isTrue);
    });

    test('markAsRead updates item isRead and unread total', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(notificationListProvider.notifier);
      await notifier.loadInitial();

      await notifier.markAsRead('n1');
      final state = container.read(notificationListProvider);
      final item = state.notifications.firstWhere((n) => n.notificationId == 'n1');
      expect(item.isRead, isTrue);
      expect(state.unreadSummary.total, 1);
    });

    test('markAllAsRead marks all notifications read and resets total to 0', () async {
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(notificationListProvider.notifier);
      await notifier.loadInitial();

      await notifier.markAllAsRead();
      final state = container.read(notificationListProvider);
      expect(state.notifications.every((n) => n.isRead), isTrue);
      expect(state.unreadSummary.total, 0);
    });
  });

  group('NotificationCenterDialog Widget Tests', () {
    late MockNotificationRepository mockRepo;

    setUp(() {
      mockRepo = MockNotificationRepository(
        notifications: [
          NotificationModel(
            notificationId: 'n-warn',
            clanId: 'c1',
            title: 'Cảnh báo tiến độ: Mua sắm lễ vật dâng hương',
            content: 'Còn 16 giờ 30 phút trước hạn chót. Vui lòng cập nhật tiến độ.',
            category: NotificationCategoryEnum.task,
            referenceType: 'Task',
            referenceId: 'task-100',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
          NotificationModel(
            notificationId: 'n-normal',
            clanId: 'c1',
            title: 'Lễ Thượng Tiêu hoàn tất chuẩn bị',
            content: 'Ban hậu cần đã chuẩn bị xong.',
            category: NotificationCategoryEnum.event,
            referenceType: 'Event',
            referenceId: 'event-200',
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
        unreadCount: const UnreadCountModel(total: 1, taskCount: 1, eventCount: 0, financeCount: 0),
      );
    });

    testWidgets('Renders header, tabs, warning badge and mark-all-read button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenterDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header title
      expect(find.text('Trung Tâm Thông Báo Gia Tộc'), findsOneWidget);
      expect(find.text('Cảnh báo tiến độ công việc 24h & thông tri sự kiện'), findsOneWidget);

      // Tabs
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Công việc (Task)'), findsOneWidget);
      expect(find.text('Sự kiện'), findsOneWidget);
      expect(find.text('Tài chính'), findsOneWidget);

      // Warning card items
      expect(find.text('Cảnh báo tiến độ: Mua sắm lễ vật dâng hương'), findsOneWidget);
      expect(find.text('CẢNH BÁO 24H'), findsOneWidget);
      expect(find.text('Xem Công Việc'), findsOneWidget);

      // Unread only toggle switch
      expect(find.text('Chỉ chưa đọc:'), findsOneWidget);

      // Mark all read button
      expect(find.text('Đọc tất cả'), findsOneWidget);
    });

    testWidgets('Tapping "Đọc tất cả" marks unread items as read', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenterDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Đọc tất cả"
      final markAllBtn = find.text('Đọc tất cả');
      expect(markAllBtn, findsOneWidget);
      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      // Now all are read
      expect(mockRepo.notifications.every((n) => n.isRead), isTrue);
    });

    testWidgets('Renders death anniversary reminder with GIỖ CHẠP badge and quick action button', (tester) async {
      final anniversaryMockRepo = MockNotificationRepository(
        notifications: [
          NotificationModel(
            notificationId: 'notif-us40-01',
            clanId: 'c1',
            title: 'Nhắc nhở ngày giỗ: Cụ Lê Văn An',
            content:
                'Sắp đến ngày giỗ Cụ Lê Văn An vào ngày 15/02 Âm lịch (Dương lịch: 23/03/2026).',
            category: NotificationCategoryEnum.event,
            referenceType: 'DeathAnniversary',
            referenceId: 'MEM-003',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            metadata: {
              'deceasedName': 'Cụ Lê Văn An',
              'deathDateSolar': '2026-03-23T08:30:00.000Z',
              'deathDateLunar': '15/02 Âm lịch',
              'location': 'Từ đường Chi 2, Xã Kim Liên',
              'suggestedBudget': 35000000.0,
            },
          ),
        ],
        unreadCount: const UnreadCountModel(total: 1, taskCount: 0, eventCount: 1, financeCount: 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(anniversaryMockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenterDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge GIỖ CHẠP
      expect(find.text('GIỖ CHẠP'), findsOneWidget);
      // Nút Tạo sự kiện Đám giỗ
      expect(find.text('Tạo sự kiện Đám giỗ'), findsOneWidget);
      // Info box người mất & ngày giỗ
      expect(find.textContaining('Cụ Lê Văn An'), findsWidgets);
      expect(find.textContaining('15/02 Âm lịch'), findsWidgets);
    });

    testWidgets('Tapping "Tạo sự kiện Đám giỗ" opens CreateEventSheet with prefilled values and banner', (tester) async {
      final anniversaryMockRepo = MockNotificationRepository(
        notifications: [
          NotificationModel(
            notificationId: 'notif-us40-01',
            clanId: 'c1',
            title: 'Nhắc nhở ngày giỗ: Cụ Lê Văn An',
            content:
                'Sắp đến ngày giỗ Cụ Lê Văn An vào ngày 15/02 Âm lịch (Dương lịch: 23/03/2026).',
            category: NotificationCategoryEnum.event,
            referenceType: 'DeathAnniversary',
            referenceId: 'MEM-003',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            metadata: {
              'deceasedName': 'Cụ Lê Văn An',
              'deathDateSolar': '2026-03-23T08:30:00.000Z',
              'deathDateLunar': '15/02 Âm lịch',
              'location': 'Từ đường Chi 2, Xã Kim Liên',
              'suggestedBudget': 35000000.0,
            },
          ),
        ],
        unreadCount: const UnreadCountModel(total: 1, taskCount: 0, eventCount: 1, financeCount: 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(anniversaryMockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenterDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final createBtn = find.text('Tạo sự kiện Đám giỗ');
      expect(createBtn, findsOneWidget);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Form CreateEventSheet is opened
      expect(find.byType(CreateEventSheet), findsOneWidget);
      // Banner hiển thị
      expect(find.byKey(const Key('anniversary_prefill_banner')), findsOneWidget);
      expect(find.text('Tự động điền từ Thông báo Nhắc Ngày Giỗ'), findsOneWidget);
      // Nút xác nhận mang nhãn đúng
      expect(find.text('Xác Nhận & Tổ Chức Đám Giỗ'), findsOneWidget);
      // Giá trị điền sẵn
      expect(find.text('Lễ Đám Giỗ Cụ Lê Văn An'), findsOneWidget);
      expect(find.text('15/02 Âm lịch'), findsOneWidget);
      expect(find.text('Từ đường Chi 2, Xã Kim Liên'), findsOneWidget);
    });

    testWidgets('Non-admin / regular member cannot see "Tạo sự kiện Đám giỗ" button (RBAC Guard)', (tester) async {
      final anniversaryMockRepo = MockNotificationRepository(
        notifications: [
          NotificationModel(
            notificationId: 'notif-us40-01',
            clanId: 'c1',
            title: 'Nhắc nhở ngày giỗ: Cụ Lê Văn An',
            content:
                'Sắp đến ngày giỗ Cụ Lê Văn An vào ngày 15/02 Âm lịch (Dương lịch: 23/03/2026).',
            category: NotificationCategoryEnum.event,
            referenceType: 'DeathAnniversary',
            referenceId: 'MEM-003',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            metadata: {
              'deceasedName': 'Cụ Lê Văn An',
              'deathDateSolar': '2026-03-23T08:30:00.000Z',
              'deathDateLunar': '15/02 Âm lịch',
            },
          ),
        ],
        unreadCount: const UnreadCountModel(total: 1, taskCount: 0, eventCount: 1, financeCount: 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(anniversaryMockRepo),
            dualRbacSessionProvider.overrideWith(_MemberOnlyRbacNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationCenterDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Info is visible
      expect(find.text('GIỖ CHẠP'), findsOneWidget);
      expect(find.textContaining('Cụ Lê Văn An'), findsWidgets);
      // But the action button to create event is NOT shown
      expect(find.text('Tạo sự kiện Đám giỗ'), findsNothing);
      // Mark read is available
      expect(find.text('Đánh dấu đã đọc'), findsOneWidget);
    });
  });

  group('HeritageNavBar Integration Tests', () {
    testWidgets('Renders notification bell with unread badge count', (tester) async {
      final mockRepo = MockNotificationRepository(
        notifications: [],
        unreadCount: const UnreadCountModel(total: 4, taskCount: 2, eventCount: 1, financeCount: 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: HeritageNavBar(currentRoute: '/tasks'),
              body: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Notification Bell Icon exists
      expect(find.byTooltip('Trung tâm thông báo & Cảnh báo tiến độ'), findsOneWidget);
      // Unread badge count "4"
      expect(find.text('4'), findsOneWidget);
    });
  });
}
