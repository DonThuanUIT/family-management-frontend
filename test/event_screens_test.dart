import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/features/event/presentation/screens/event_list_screen.dart';
import 'package:familyfund_app/features/event/presentation/widgets/create_event_sheet.dart';
import 'package:familyfund_app/features/shared/presentation/widgets/heritage_nav_bar.dart';
import 'package:familyfund_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'EventListScreen renders HeritageNavBar, hero KPI bar, search bar and event cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/events'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Navigation & Clan Header
    expect(find.byType(EventListScreen), findsOneWidget);
    expect(find.byType(HeritageNavBar), findsOneWidget);
    expect(find.text('Sổ Cái'), findsWidgets);
    expect(find.text('Bảo Vật'), findsWidgets);
    expect(find.text('TỘC SỰ & TẾ LỄ'), findsOneWidget);
    expect(find.text('Vũ Tộc Tiên Lạc'), findsOneWidget);

    // 2. Hero KPI metrics
    expect(find.text('Kế Hoạch Tế Sự Niên Khóa'), findsOneWidget);
    expect(find.text('Đang Mở'), findsOneWidget);
    expect(find.text('Dự Toán'), findsWidgets);
    expect(find.text('Tỷ Lệ Tự Tựu'), findsOneWidget);

    // 3. Search & Quick Action Bar
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tạo Lễ Mới'), findsOneWidget);
    expect(find.textContaining('Tất cả'), findsOneWidget);
    expect(find.text('Đang mở ghi danh'), findsOneWidget);

    // 4. Events Feed
    expect(find.text('Đại Lễ Giỗ Tiền Tổ & Thượng Điền'), findsOneWidget);
    expect(find.text('Khánh Thành Nhà Bia Tiên Liệt'), findsOneWidget);
    expect(find.text('Lễ Mừng Thọ & Khen Thưởng Khuyến Học'), findsOneWidget);

    // 5. Dual Calendar (Lịch Âm + Dương)
    expect(find.text('10/03'), findsOneWidget);
    expect(find.text('ÂM LỊCH'), findsWidgets);

    // 6. Collapsible Charter
    expect(find.text('Tộc Ước Điều 7: Về Tế Lễ Tông Môn'), findsOneWidget);
  });

  testWidgets('EventListScreen filters events when status tab is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/events'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on "Đang mở ghi danh" tab
    await tester.tap(find.text('Đang mở ghi danh'));
    await tester.pumpAndSettle();

    // Only "Đại Lễ Giỗ Tiền Tổ" should be visible
    expect(find.text('Đại Lễ Giỗ Tiền Tổ & Thượng Điền'), findsOneWidget);
    expect(find.text('Khánh Thành Nhà Bia Tiên Liệt'), findsNothing);
    expect(find.text('Lễ Mừng Thọ & Khen Thưởng Khuyến Học'), findsNothing);

    // Tap on "Đang diễn ra" tab
    await tester.tap(find.text('Đang diễn ra'));
    await tester.pumpAndSettle();

    expect(find.text('Khánh Thành Nhà Bia Tiên Liệt'), findsOneWidget);
    expect(find.text('Đại Lễ Giỗ Tiền Tổ & Thượng Điền'), findsNothing);

    // Tap back to "Tất cả"
    await tester.tap(find.textContaining('Tất cả'));
    await tester.pumpAndSettle();

    expect(find.text('Đại Lễ Giỗ Tiền Tổ & Thượng Điền'), findsOneWidget);
    expect(find.text('Khánh Thành Nhà Bia Tiên Liệt'), findsOneWidget);
  });

  testWidgets('EventListScreen opens CreateEventSheet when button is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/events'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Tạo Lễ Mới" button
    await tester.tap(find.text('Tạo Lễ Mới'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateEventSheet), findsOneWidget);
    expect(find.text('Khởi Điển Kế Hoạch Tế Sự'), findsOneWidget);
    expect(find.text('Tên Điển Lễ / Sự Kiện *'), findsOneWidget);
    expect(find.text('Ngày Dương *'), findsOneWidget);
    expect(find.text('Giờ Khai Lễ *'), findsOneWidget);
    expect(find.text('Địa Điểm Tổ Chức *'), findsOneWidget);
    expect(find.text('Ban Hành & Lưu Kế Hoạch'), findsOneWidget);
  });

  testWidgets(
      'EventListScreen opens EventNotificationsDialog when notification bell is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/events'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Thông báo sự kiện'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Thông Báo Tộc Sự Đã Phát'), findsOneWidget);
    expect(
      find.text('Lịch sử phát tin đến bà con dòng họ (US-22)'),
      findsOneWidget,
    );
  });

  testWidgets('EventListScreen opens EventDetailDialog when event card is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/events'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đại Lễ Giỗ Tiền Tổ & Thượng Điền'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Mã sự kiện: EVT_2026_GIOTO • Trạng thái: Đang mở đăng ký'),
      findsOneWidget,
    );
    expect(
      find.text('Ban Tổ Chức & Thủ Quỹ (Contextual RBAC)'),
      findsOneWidget,
    );
    expect(find.text('Đổi Lịch Trình'), findsOneWidget);
    expect(find.text('Thông Báo (US-22)'), findsOneWidget);
  });

  testWidgets(
      'EventListScreen opens AssignPersonnelDialog when group icon is tapped',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/events'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Chỉ định nhân sự BTC').first);
    await tester.pumpAndSettle();

    expect(find.text('Phân Định Nhân Sự Tế Sự'), findsOneWidget);
    expect(find.text('Trưởng Ban Tổ Chức (Tối đa 1)'), findsOneWidget);
    expect(find.text('Thủ Quỹ Sự Kiện (Tối đa 1)'), findsOneWidget);
    expect(find.text('Lưu Chỉ Định'), findsOneWidget);
  });

  testWidgets(
      'EventListScreen adapts layout between Mobile (390x844) and Desktop (1440x900)',
      (WidgetTester tester) async {
    // 1. Mobile viewport (390x844)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/events'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // 2. Desktop viewport (1440x900)
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Sự Kiện Giỗ Tổ'), findsOneWidget);

    // Tap Tạo Lễ Mới on Desktop -> opens centered Dialog instead of BottomSheet
    await tester.tap(find.text('Tạo Lễ Mới'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(CreateEventSheet), findsOneWidget);
  });
}
