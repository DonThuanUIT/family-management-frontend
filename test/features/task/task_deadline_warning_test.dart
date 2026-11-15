import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:familyfund_app/features/task/data/models/task_models.dart';
import 'package:familyfund_app/features/task/presentation/widgets/task_deadline_countdown_card.dart';
import 'package:familyfund_app/features/task/presentation/widgets/task_card.dart';

void main() {
  group('TaskModel Deadline Warning Logic (US-08)', () {
    test('isWithin24Hours returns true when deadline is between 0 and 24 hours from now', () {
      final taskSoon = TaskModel(
        taskId: 'T-SOON',
        eventId: 'EV-01',
        taskName: 'Mua mâm ngũ quả',
        status: TaskStatusEnum.inProgress,
        advanceBudget: 500000,
        deadline: DateTime.now().add(const Duration(hours: 12)),
        assignedMemberId: 'MEM-01',
        assignedMemberName: 'Nguyễn Văn A',
        createdBy: 'ADMIN',
      );

      expect(taskSoon.isWithin24Hours, isTrue);
      expect(taskSoon.remainingDuration?.inHours, 11);
    });

    test('isWithin24Hours returns false when deadline is more than 24 hours away', () {
      final taskFar = TaskModel(
        taskId: 'T-FAR',
        eventId: 'EV-01',
        taskName: 'Sơn sửa từ đường',
        status: TaskStatusEnum.inProgress,
        advanceBudget: 2000000,
        deadline: DateTime.now().add(const Duration(days: 3)),
        assignedMemberId: 'MEM-01',
        assignedMemberName: 'Nguyễn Văn A',
        createdBy: 'ADMIN',
      );

      expect(taskFar.isWithin24Hours, isFalse);
    });

    test('isWithin24Hours returns false when task is already completed', () {
      final taskDone = TaskModel(
        taskId: 'T-DONE',
        eventId: 'EV-01',
        taskName: 'Dọn dẹp sân đình',
        status: TaskStatusEnum.completed,
        advanceBudget: 300000,
        deadline: DateTime.now().add(const Duration(hours: 6)),
        assignedMemberId: 'MEM-01',
        assignedMemberName: 'Nguyễn Văn A',
        createdBy: 'ADMIN',
      );

      expect(taskDone.isWithin24Hours, isFalse);
    });

    test('isWithin24Hours returns false when deadline has passed (overdue)', () {
      final taskOverdue = TaskModel(
        taskId: 'T-OVERDUE',
        eventId: 'EV-01',
        taskName: 'Họp hội đồng gia tộc',
        status: TaskStatusEnum.inProgress,
        advanceBudget: 0,
        deadline: DateTime.now().subtract(const Duration(hours: 2)),
        assignedMemberId: 'MEM-01',
        assignedMemberName: 'Nguyễn Văn A',
        createdBy: 'ADMIN',
      );

      expect(taskOverdue.isWithin24Hours, isFalse);
    });
  });

  group('TaskDeadlineCountdownCard Widget Tests (Figma Screen 05)', () {
    testWidgets('Renders countdown boxes and automated warning banner', (tester) async {
      final deadline = DateTime.now().add(const Duration(hours: 18, minutes: 30));
      final task = TaskModel(
        taskId: 'T-05',
        eventId: 'EV-01',
        taskName: 'Chuẩn bị văn tế và sớ dâng hương',
        details: 'Cần viết xong sớ và xin ý kiến cụ Trưởng tộc trước buổi lễ chính.',
        status: TaskStatusEnum.inProgress,
        deadline: deadline,
        assignedMemberId: 'MEM-TU-TRUONG',
        assignedMemberName: 'Nguyễn Văn Anh',
        advanceBudget: 500000,
        createdBy: 'ADMIN',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TaskDeadlineCountdownCard(
                task: task,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Header title
      expect(find.text('Thời hạn hoàn tất'), findsOneWidget);

      // Countdown unit labels
      expect(find.text('NGÀY'), findsOneWidget);
      expect(find.text('GIỜ'), findsOneWidget);
      expect(find.text('PHÚT'), findsOneWidget);

      // Automated notice banner
      expect(
        find.textContaining('Tự động gửi thông báo kiểm tra tiến độ mỗi 24h'),
        findsOneWidget,
      );
    });
  });

  group('TaskCard 24h Warning Badge Integration (Stitch W4)', () {
    testWidgets('Displays "Còn 24h" amber badge when task deadline is within 24h', (tester) async {
      final taskWithin24 = TaskModel(
        taskId: 'T-WARN',
        eventId: 'EV-01',
        taskName: 'Thuê âm thanh ánh sáng',
        status: TaskStatusEnum.inProgress,
        advanceBudget: 1500000,
        deadline: DateTime.now().add(const Duration(hours: 8)),
        assignedMemberId: 'MEM-02',
        assignedMemberName: 'Trần Văn Bình',
        createdBy: 'ADMIN',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: taskWithin24,
              canManage: true,
              isClosed: false,
              onReassign: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Badge must appear
      expect(find.text('Còn 24h'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('Does not display "Còn 24h" badge when task deadline is far away', (tester) async {
      final taskFar = TaskModel(
        taskId: 'T-FAR',
        eventId: 'EV-01',
        taskName: 'Lên kế hoạch cúng rằm tháng 7',
        status: TaskStatusEnum.inProgress,
        advanceBudget: 500000,
        deadline: DateTime.now().add(const Duration(days: 10)),
        assignedMemberId: 'MEM-03',
        assignedMemberName: 'Lê Văn Cường',
        createdBy: 'ADMIN',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskCard(
              task: taskFar,
              canManage: true,
              isClosed: false,
              onReassign: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Còn 24h'), findsNothing);
    });
  });
}
