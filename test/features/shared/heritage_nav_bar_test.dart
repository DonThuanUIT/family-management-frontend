import 'package:familyfund_app/features/shared/presentation/widgets/heritage_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildNavBar({required String currentRoute}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          appBar: HeritageNavBar(currentRoute: currentRoute),
          body: const SizedBox.expand(),
        ),
      ),
    );
  }

  testWidgets('HeritageNavBar renders all 5 nav options without clipping on 1280px desktop',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildNavBar(currentRoute: '/clan-invites'));
    await tester.pumpAndSettle();

    // Verify all 5 nav items are visible and rendered
    expect(find.text('Sổ Cái Tài Chính'), findsOneWidget);
    expect(find.text('Kho Bảo Vật'), findsOneWidget);
    expect(find.text('Sự Kiện Giỗ Tổ'), findsOneWidget);
    expect(find.text('Cây Phả Hệ'), findsOneWidget);
    expect(find.text('Cấp Mã Mời'), findsOneWidget);

    // Verify Niêm Phong 2026 is visible
    expect(find.text('Niêm Phong 2026'), findsOneWidget);
  });

  testWidgets('HeritageNavBar adapts cleanly on 1150px laptop without covering Cấp Mã Mời',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1150, 750);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildNavBar(currentRoute: '/clan-invites'));
    await tester.pumpAndSettle();

    // All 5 options are present
    expect(find.text('Sổ Cái Tài Chính'), findsOneWidget);
    expect(find.text('Kho Bảo Vật'), findsOneWidget);
    expect(find.text('Sự Kiện Giỗ Tổ'), findsOneWidget);
    expect(find.text('Cây Phả Hệ'), findsOneWidget);
    expect(find.text('Cấp Mã Mời'), findsOneWidget);

    // Verify no RenderFlex overflow
    expect(tester.takeException(), isNull);
  });

  testWidgets('HeritageNavBar uses short labels smoothly on 1000px tablet viewport',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 750);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildNavBar(currentRoute: '/clan-invites'));
    await tester.pumpAndSettle();

    // Uses short labels on < 1100px
    expect(find.text('Sổ Cái'), findsOneWidget);
    expect(find.text('Bảo Vật'), findsOneWidget);
    expect(find.text('Sự Kiện'), findsOneWidget);
    expect(find.text('Phả Hệ'), findsOneWidget);
    expect(find.text('Mã Mời'), findsOneWidget);

    // Verify compact verified badge
    expect(find.text('2026'), findsOneWidget);

    // Verify no RenderFlex overflow
    expect(tester.takeException(), isNull);
  });

  testWidgets('HeritageNavBar on mobile 390px hides top nav items for bottom nav bar',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: const HeritageNavBar(currentRoute: '/clan-invites'),
            bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/clan-invites'),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // On mobile top bar: Brand + Profile avatar only
    expect(find.text('FamilyFund'), findsOneWidget);
    // Bottom bar has Mã Mời
    expect(find.text('Mã Mời'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
