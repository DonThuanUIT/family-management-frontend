import 'dart:typed_data';

import 'package:familyfund_app/features/event/data/models/event_models.dart';
import 'package:familyfund_app/features/event/data/repositories/event_repository_impl.dart';
import 'package:familyfund_app/features/event/domain/repositories/event_repository.dart';
import 'package:familyfund_app/features/event/presentation/screens/event_logistics_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLogisticsEventRepository implements EventRepository {
  String? lastBranchFilter;
  String? lastExportFormat;
  String? lastExportBranchFilter;

  static const _branches = [
    LogisticsBranchOptionModel(branchId: 'BR_01', branchName: 'Chi Nhất'),
    LogisticsBranchOptionModel(branchId: 'BR_02', branchName: 'Chi Nhì'),
  ];

  static final _items = [
    HouseholdLogisticsItemModel(
      registrationId: 'REG_01',
      representativeMemberId: 'MEM_01',
      representativeName: 'Nguyễn Văn An',
      branchId: 'BR_01',
      branchName: 'Chi Nhất',
      totalAttendees: 4,
      savoryMeals: 3,
      vegetarianMeals: 1,
      shuttleSeats: 2,
      dietaryRequirements: '1 ăn chay',
      transportationNotes: 'Xe 2 chỗ',
      status: 'Confirmed',
      registrationDate: DateTime(2026, 10, 1, 9, 0),
    ),
    HouseholdLogisticsItemModel(
      registrationId: 'REG_02',
      representativeMemberId: 'MEM_02',
      representativeName: 'Nguyễn Thị Bình',
      branchId: 'BR_02',
      branchName: 'Chi Nhì',
      totalAttendees: 5,
      savoryMeals: 4,
      vegetarianMeals: 1,
      shuttleSeats: 3,
      dietaryRequirements: null,
      transportationNotes: 'Xe 3 chỗ',
      status: 'Confirmed',
      registrationDate: DateTime(2026, 10, 2, 10, 30),
    ),
  ];

  @override
  Future<EventLogisticsSummaryModel> getEventRegistrationSummary(
    String eventId, {
    String? branchId,
  }) async {
    lastBranchFilter = branchId;
    final filtered = (branchId != null && branchId.isNotEmpty)
        ? _items.where((e) => e.branchId == branchId).toList()
        : _items;

    return EventLogisticsSummaryModel(
      eventId: eventId,
      eventName: 'Giỗ Tổ Dòng Họ 2026',
      branchId: branchId,
      branchName: branchId == null
          ? null
          : _branches
              .where((b) => b.branchId == branchId)
              .map((b) => b.branchName)
              .firstOrNull,
      totalRegistrations: filtered.length,
      totalAttendees: filtered.fold(0, (s, i) => s + i.totalAttendees),
      totalSavoryMeals: filtered.fold(0, (s, i) => s + i.savoryMeals),
      totalVegetarianMeals: filtered.fold(0, (s, i) => s + i.vegetarianMeals),
      totalShuttleSeats: filtered.fold(0, (s, i) => s + i.shuttleSeats),
      availableBranches: _branches,
      registrations: filtered,
    );
  }

  @override
  Future<Uint8List> exportEventRegistrationSummary(
    String eventId, {
    String? branchId,
    String format = 'xlsx',
  }) async {
    lastExportBranchFilter = branchId;
    lastExportFormat = format;
    return Uint8List.fromList([80, 75, 3, 4]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'EventLogisticsDashboardScreen displays real-time KPIs, filters by branch, and exports list',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeLogisticsEventRepository();
      String? savedFileName;
      String? savedExt;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: EventLogisticsDashboardScreen(
              eventId: 'EVT_42',
              onSaveFile: (bytes, fileName, ext, mimeType) async {
                savedFileName = fileName;
                savedExt = ext;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 5 KPI cards for all branches
      expect(
        find.descendant(
          of: find.byKey(const Key('kpi_total_registrations')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('kpi_total_attendees')),
          matching: find.text('9'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('kpi_total_savory_meals')),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('kpi_total_vegetarian_meals')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('kpi_total_shuttle_seats')),
          matching: find.text('5'),
        ),
        findsOneWidget,
      );
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('Nguyễn Thị Bình'), findsOneWidget);

      // Filter by Chi Nhất (BR_01)
      await tester.tap(find.byKey(const Key('logistics_branch_filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chi Nhất').last);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastBranchFilter, 'BR_01');
      expect(
        find.descendant(
          of: find.byKey(const Key('kpi_total_registrations')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('kpi_total_attendees')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('Nguyễn Thị Bình'), findsNothing);

      // Tap Export button
      await tester.tap(find.byKey(const Key('export_logistics_excel_button')));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastExportFormat, 'xlsx');
      expect(fakeRepo.lastExportBranchFilter, 'BR_01');
      expect(savedFileName, 'danh_sach_diem_danh_chia_co_EVT_42_BR_01');
      expect(savedExt, 'xlsx');
      expect(
        find.textContaining('Đã xuất danh sách điểm danh & chia cỗ'),
        findsOneWidget,
      );
    },
  );
}
