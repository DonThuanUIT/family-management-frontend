import 'package:familyfund_app/features/contribution/data/models/branch_recursive_contribution_models.dart';
import 'package:familyfund_app/features/contribution/presentation/providers/branch_recursive_contribution_providers.dart';
import 'package:familyfund_app/features/contribution/presentation/widgets/branch_contribution_breakdown_bottom_sheet.dart';
import 'package:familyfund_app/features/contribution/presentation/widgets/branch_contribution_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BranchRecursiveContributionDto Tests', () {
    test('Parse JSON with recursive child branches correctly', () {
      final json = {
        'branchId': 'BR_PHUC',
        'branchName': 'Nhánh Cụ Nguyễn Văn Phúc',
        'generationLevel': 9,
        'representativeName': 'Cụ Nguyễn Văn Phúc',
        'directTotalAmount': 20000000.0,
        'directCashAmount': 15000000.0,
        'directInKindAmount': 5000000.0,
        'descendantsTotalAmount': 128500000.0,
        'totalRecursiveAmount': 148500000.0,
        'totalRecursiveAmountInWords': 'Một trăm bốn mươi tám triệu năm trăm nghìn đồng',
        'directContributingMemberCount': 3,
        'directContributionCount': 4,
        'childBranches': [
          {
            'branchId': 'BR_TUAN',
            'branchName': 'Chi Bác Nguyễn Khắc Tuấn',
            'generationLevel': 10,
            'representativeName': 'Bác Tuấn',
            'directTotalAmount': 15000000.0,
            'descendantsTotalAmount': 70000000.0,
            'totalRecursiveAmount': 85000000.0,
            'childBranches': [],
          },
          {
            'branchId': 'BR_KHOA',
            'branchName': 'Chi Bác Nguyễn Trọng Khoa',
            'generationLevel': 10,
            'representativeName': 'Bác Khoa',
            'directTotalAmount': 10000000.0,
            'descendantsTotalAmount': 33500000.0,
            'totalRecursiveAmount': 43500000.0,
            'childBranches': [],
          }
        ]
      };

      final dto = BranchRecursiveContributionDto.fromJson(json);

      expect(dto.branchId, 'BR_PHUC');
      expect(dto.totalRecursiveAmount, 148500000.0);
      expect(dto.directTotalAmount, 20000000.0);
      expect(dto.descendantsTotalAmount, 128500000.0);
      expect(dto.childBranches.length, 2);
      expect(dto.childBranches[0].branchId, 'BR_TUAN');
      expect(dto.childBranches[0].totalRecursiveAmount, 85000000.0);

      // Percentage assertions
      expect(dto.directPercentage, closeTo(13.468, 0.01));
      expect(dto.descendantsPercentage, closeTo(86.531, 0.01));
      expect(dto.hasContribution, true);
      expect(dto.hasChildBranches, true);
    });

    test('Zero contribution branch handles percentages safely', () {
      const emptyDto = BranchRecursiveContributionDto(
        branchId: 'BR_EMPTY',
        branchName: 'Chi Chưa Đóng',
        totalRecursiveAmount: 0.0,
      );

      expect(emptyDto.directPercentage, 0.0);
      expect(emptyDto.descendantsPercentage, 0.0);
      expect(emptyDto.hasContribution, false);
      expect(emptyDto.hasChildBranches, false);
    });
  });

  group('TreeContributionFilterNotifier Tests', () {
    test('Defaults to disabled view and allows toggling', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(treeContributionFilterProvider);
      expect(initial.isContributionViewEnabled, false);

      container.read(treeContributionFilterProvider.notifier).toggleContributionView();
      expect(container.read(treeContributionFilterProvider).isContributionViewEnabled, true);

      container.read(treeContributionFilterProvider.notifier).setEventFilter(
            eventId: 'EVT_2026_01',
            eventName: 'Giỗ Tổ 2026',
          );
      final filtered = container.read(treeContributionFilterProvider);
      expect(filtered.selectedEventId, 'EVT_2026_01');
      expect(filtered.selectedEventName, 'Giỗ Tổ 2026');
    });
  });

  group('BranchContributionPill Widget Tests', () {
    testWidgets('Hidden when contribution view mode is disabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            treeContributionFilterProvider.overrideWith(
              () => _MockFilterNotifier(
                const TreeContributionFilterState(isContributionViewEnabled: false),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BranchContributionPill(
                branchId: 'BR_PHUC',
                branchName: 'Nhánh Cụ Phúc',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(BranchContributionPill), findsOneWidget);
      expect(find.text('CÔNG ĐỨC ĐỆ QUY'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('Renders muted badge when branch has 0đ contribution', (tester) async {
      const emptyDto = BranchRecursiveContributionDto(
        branchId: 'BR_EMPTY',
        branchName: 'Chi Chưa Đóng',
        totalRecursiveAmount: 0.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            treeContributionFilterProvider.overrideWith(
              () => _MockFilterNotifier(
                const TreeContributionFilterState(isContributionViewEnabled: true),
              ),
            ),
            branchRecursiveContributionProvider.overrideWith(
              (ref, param) async => emptyDto,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BranchContributionPill(
                branchId: 'BR_EMPTY',
                branchName: 'Chi Chưa Đóng',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Chưa ghi nhận cúng tiến'), findsOneWidget);
      expect(find.text('0đ'), findsOneWidget);
    });

    testWidgets('Renders rich contribution card when amount > 0', (tester) async {
      const summaryDto = BranchRecursiveContributionDto(
        branchId: 'BR_PHUC',
        branchName: 'Nhánh Cụ Nguyễn Văn Phúc',
        directTotalAmount: 20000000.0,
        descendantsTotalAmount: 128500000.0,
        totalRecursiveAmount: 148500000.0,
        directMemberCount: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            treeContributionFilterProvider.overrideWith(
              () => _MockFilterNotifier(
                const TreeContributionFilterState(
                  isContributionViewEnabled: true,
                  selectedEventName: 'Giỗ Tổ 2026',
                ),
              ),
            ),
            branchRecursiveContributionProvider.overrideWith(
              (ref, param) async => summaryDto,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BranchContributionPill(
                branchId: 'BR_PHUC',
                branchName: 'Nhánh Cụ Nguyễn Văn Phúc',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('CÔNG ĐỨC ĐỆ QUY'), findsOneWidget);
      expect(find.text('∑ Tổng cúng tiến:'), findsOneWidget);
      expect(find.text('Cơ cấu'), findsOneWidget);
    });
  });

  group('BranchContributionBreakdownBottomSheet Tests', () {
    testWidgets('Renders formula, breakdown items, and PDF button', (tester) async {
      const child1 = BranchRecursiveContributionDto(
        branchId: 'BR_TUAN',
        branchName: 'Chi Bác Tuấn',
        generationLevel: 10,
        directTotalAmount: 15000000.0,
        descendantsTotalAmount: 70000000.0,
        totalRecursiveAmount: 85000000.0,
      );

      const summaryDto = BranchRecursiveContributionDto(
        branchId: 'BR_PHUC',
        branchName: 'Nhánh Cụ Nguyễn Văn Phúc',
        generationLevel: 9,
        directTotalAmount: 20000000.0,
        descendantsTotalAmount: 85000000.0,
        totalRecursiveAmount: 105000000.0,
        childBranches: [child1],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BranchContributionBreakdownBottomSheet(
              initialSummary: summaryDto,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cơ Cấu Đệ Quy Cúng Tiến'), findsOneWidget);
      expect(find.text('Công thức tính tổng nhánh:'), findsOneWidget);
      expect(find.text('Phân Rã Đóng Góp Thành Phần'), findsOneWidget);
      expect(find.text('Chi Bác Tuấn'), findsOneWidget);
      expect(find.text('Trích Lục Sổ Vàng Nhánh Chi (PDF Dấu Đỏ)'), findsOneWidget);

      // Tap on Chi Bác Tuấn to drill down
      await tester.tap(find.text('Chi Bác Tuấn'));
      await tester.pumpAndSettle();

      // Breadcrumb should show "Quay lại"
      expect(find.text('Quay lại'), findsOneWidget);

      // Tap "Quay lại" to pop drill-down
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Nhánh Nhánh Cụ Nguyễn Văn Phúc (Đời 9)'), findsOneWidget);
    });
  });
}

class _MockFilterNotifier extends TreeContributionFilterNotifier {
  final TreeContributionFilterState _state;
  _MockFilterNotifier(this._state);

  @override
  TreeContributionFilterState build() => _state;
}
