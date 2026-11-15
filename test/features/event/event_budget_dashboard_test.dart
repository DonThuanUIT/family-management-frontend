import 'package:familyfund_app/features/event/data/models/event_budget_models.dart';
import 'package:familyfund_app/features/event/presentation/providers/event_providers.dart';
import 'package:familyfund_app/features/event/presentation/screens/event_budget_dashboard_screen.dart';
import 'package:familyfund_app/features/event/presentation/widgets/event_budget_hero_card.dart';
import 'package:familyfund_app/features/event/presentation/widgets/task_budget_breakdown_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const kMockOverBudget = EventBudgetSummaryModel(
    eventId: 'EVT_2026_GIOTO',
    eventName: 'Đại Lễ Giỗ Tổ 2026',
    eventStatus: 'RegistrationOpen',
    estimatedBudget: 250000000.0,
    totalAdvanceBudget: 230000000.0,
    totalAdvanceAmount: 50000000.0,
    totalActualExpenseAmount: 222500000.0,
    verifiedActualExpenseAmount: 185000000.0,
    unallocatedBudget: 20000000.0,
    remainingBudgetByAdvance: 200000000.0,
    remainingBudgetByActualExpense: 27500000.0,
    overrunAmount: 22500000.0,
    taskBudgetUtilizationPercent: 92.0,
    advanceUtilizationPercent: 20.0,
    actualExpenseUtilizationPercent: 89.0,
    isOverBudget: true,
    isAdvanceOverEstimated: false,
    isActualExpenseOverEstimated: true,
    isTaskBudgetOverEstimated: false,
    hasTaskOverBudget: true,
    warningLevel: 'CRITICAL',
    warningMessages: [
      'Tổng thực chi (222.500.000 đ) cộng tạm ứng đang lưu động đã vượt dự toán sự kiện (250.000.000 đ).',
    ],
    totalTaskCount: 2,
    totalAdvanceVoucherCount: 3,
    totalSettlementVoucherCount: 16,
    needsExplanationVoucherCount: 1,
    taskBreakdowns: [
      TaskBudgetBreakdownModel(
        taskId: 'TSK-01',
        taskName: 'Mâm Cỗ & Phục Vụ 120 Mâm',
        taskStatus: 'Ongoing',
        assignedMemberId: 'MEM_001',
        assignedBranchId: 'BR_CHI_1',
        advanceBudget: 100000000.0,
        advanceAmount: 35000000.0,
        actualExpenseAmount: 79800000.0,
        verifiedActualExpenseAmount: 75000000.0,
        advanceVoucherCount: 2,
        settlementVoucherCount: 12,
        needsExplanationCount: 1,
        advanceVariance: 65000000.0,
        actualExpenseVariance: 20200000.0,
        isAdvanceOverTaskBudget: false,
        isActualExpenseOverTaskBudget: false,
        isOverTaskBudget: true,
      ),
      TaskBudgetBreakdownModel(
        taskId: 'TSK-02',
        taskName: 'Âm Thanh Ánh Sáng & Rạp',
        taskStatus: 'Ongoing',
        assignedMemberId: 'MEM_002',
        assignedBranchId: 'BR_CHI_2',
        advanceBudget: 50000000.0,
        advanceAmount: 20000000.0,
        actualExpenseAmount: 28000000.0,
        verifiedActualExpenseAmount: 28000000.0,
        advanceVoucherCount: 1,
        settlementVoucherCount: 4,
        needsExplanationCount: 0,
        advanceVariance: 30000000.0,
        actualExpenseVariance: 22000000.0,
        isAdvanceOverTaskBudget: false,
        isActualExpenseOverTaskBudget: false,
        isOverTaskBudget: false,
      ),
    ],
  );

  const kMockSafeBudget = EventBudgetSummaryModel(
    eventId: 'EVT_2026_NHABIA',
    eventName: 'Khánh Thành Nhà Bia Tiên Liệt',
    eventStatus: 'RegistrationOpen',
    estimatedBudget: 100000000.0,
    totalAdvanceBudget: 80000000.0,
    totalAdvanceAmount: 20000000.0,
    totalActualExpenseAmount: 50000000.0,
    verifiedActualExpenseAmount: 50000000.0,
    unallocatedBudget: 20000000.0,
    remainingBudgetByAdvance: 80000000.0,
    remainingBudgetByActualExpense: 50000000.0,
    overrunAmount: 0.0,
    taskBudgetUtilizationPercent: 80.0,
    advanceUtilizationPercent: 20.0,
    actualExpenseUtilizationPercent: 50.0,
    isOverBudget: false,
    isAdvanceOverEstimated: false,
    isActualExpenseOverEstimated: false,
    isTaskBudgetOverEstimated: false,
    hasTaskOverBudget: false,
    warningLevel: 'NORMAL',
    warningMessages: [],
    totalTaskCount: 1,
    totalAdvanceVoucherCount: 1,
    totalSettlementVoucherCount: 2,
    needsExplanationVoucherCount: 0,
    taskBreakdowns: [
      TaskBudgetBreakdownModel(
        taskId: 'TSK-10',
        taskName: 'Đúc Bia Đá & Chạm Khắc',
        taskStatus: 'Ongoing',
        assignedMemberId: 'MEM_003',
        assignedBranchId: 'BR_CHI_1',
        advanceBudget: 80000000.0,
        advanceAmount: 20000000.0,
        actualExpenseAmount: 50000000.0,
        verifiedActualExpenseAmount: 50000000.0,
        advanceVoucherCount: 1,
        settlementVoucherCount: 2,
        needsExplanationCount: 0,
        advanceVariance: 60000000.0,
        actualExpenseVariance: 30000000.0,
        isAdvanceOverTaskBudget: false,
        isActualExpenseOverTaskBudget: false,
        isOverTaskBudget: false,
      ),
    ],
  );

  group('EventBudgetSummaryModel & TaskBudgetBreakdownModel Unit Tests', () {
    test('JSON serialization & calculations work correctly for over budget', () {
      final json = kMockOverBudget.toJson();
      final parsed = EventBudgetSummaryModel.fromJson(json);

      expect(parsed.eventId, 'EVT_2026_GIOTO');
      expect(parsed.isOverBudget, isTrue);
      expect(parsed.totalCommittedAmount, 272500000.0);
      expect(parsed.overrunAmount, 22500000.0);
      expect(parsed.totalUtilizationPercent, 109.0);
      expect(parsed.taskBreakdowns.length, 2);

      final task1 = parsed.taskBreakdowns.first;
      expect(task1.taskId, 'TSK-01');
      expect(task1.isOverTaskBudget, isTrue);
      expect(task1.totalCommitted, 114800000.0);
      expect(task1.alertCategory, 'CRITICAL');

      final task2 = parsed.taskBreakdowns[1];
      expect(task2.taskId, 'TSK-02');
      expect(task2.isOverTaskBudget, isFalse);
      expect(task2.alertCategory, 'WARNING'); // 48M / 50M = 96%
    });

    test('Safe budget handles netRemainingBudget and SAFE category', () {
      expect(kMockSafeBudget.isOverBudget, isFalse);
      expect(kMockSafeBudget.netRemainingBudget, 30000000.0);
      expect(kMockSafeBudget.totalUtilizationPercent, 70.0);
      expect(kMockSafeBudget.taskBreakdowns.first.alertCategory, 'SAFE');
    });
  });

  group('EventBudgetHeroCard Widget Tests', () {
    testWidgets('Renders Critical Red Warning when isOverBudget is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventBudgetHeroCard(budget: kMockOverBudget),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('VƯỢT DỰ TOÁN • CRITICAL'), findsOneWidget);
      expect(find.text('Vượt trần'), findsOneWidget);
      expect(find.textContaining('+22.500.000'), findsOneWidget);
      expect(find.text('Dự Toán Ban Đầu'), findsOneWidget);
      expect(find.text('Tạm Ứng Lưu Động'), findsOneWidget);
      expect(find.text('Thực Chi Đã Lập'), findsOneWidget);
      expect(find.textContaining('109.0%'), findsOneWidget);
    });

    testWidgets('Renders Safe State when isOverBudget is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EventBudgetHeroCard(budget: kMockSafeBudget),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('TRONG NGÂN SÁCH AN TOÀN'), findsOneWidget);
      expect(find.text('Dư khả dụng'), findsOneWidget);
      expect(find.textContaining('30.000.000'), findsOneWidget);
      expect(find.textContaining('70.0%'), findsOneWidget);
    });
  });

  group('TaskBudgetBreakdownSection Widget Tests', () {
    testWidgets('Renders filter chips and accordion expansion', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TaskBudgetBreakdownSection(
                  eventId: 'EVT_2026_GIOTO',
                  tasks: kMockOverBudget.taskBreakdowns,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and chips
      expect(find.text('Phân Rã Hạng Mục Chi Tiêu'), findsOneWidget);
      expect(find.text('Tất cả (2)'), findsOneWidget);
      expect(find.text('⚠️ Cần chú ý (2)'), findsOneWidget);
      expect(find.text('✅ An toàn (0)'), findsOneWidget);

      // Check task items
      expect(find.text('Mâm Cỗ & Phục Vụ 120 Mâm'), findsOneWidget);
      expect(find.text('Âm Thanh Ánh Sáng & Rạp'), findsOneWidget);
      expect(find.textContaining('VƯỢT TRẦN 114.8%'), findsOneWidget);

      // Tap on first task to expand
      await tester.tap(find.text('Mâm Cỗ & Phục Vụ 120 Mâm'));
      await tester.pumpAndSettle();

      // Expanded details
      expect(find.text('Tạm ứng đã cấp:'), findsOneWidget);
      expect(find.text('Thực chi đã lập:'), findsOneWidget);
      expect(find.text('Bội chi định mức:'), findsOneWidget);
      expect(find.text('Xem chi tiết công việc (US-07)'), findsOneWidget);
    });
  });

  group('EventBudgetDashboardScreen Full Screen Widget Tests', () {
    testWidgets('Renders complete dashboard with Hero Card and Task section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventBudgetSummaryProvider('EVT_2026_GIOTO')
                .overrideWith((ref) => Future.value(kMockOverBudget)),
          ],
          child: const MaterialApp(
            home: EventBudgetDashboardScreen(eventId: 'EVT_2026_GIOTO'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar
      expect(find.text('Bảng Điều Khiển Ngân Sách'), findsOneWidget);
      expect(find.text('Đại Lễ Giỗ Tổ 2026'), findsOneWidget);

      // Verify Hero card is present
      expect(find.byType(EventBudgetHeroCard), findsOneWidget);

      // Verify Task breakdown section is present
      expect(find.byType(TaskBudgetBreakdownSection), findsOneWidget);

      // Verify Sticky footer buttons
      expect(find.text('Quản Lý Phiếu Chi (US-07)'), findsOneWidget);
      expect(find.text('Xuất Báo Cáo'), findsOneWidget);
    });
  });
}
