import 'package:familyfund_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'FamilyFundApp renders Genealogy screen and switches between Member and Management portals',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Cây Gia Phả Đa Cấp, Hồ Sơ Thành Viên & Lời Mời'),
        findsOneWidget,
      );
      expect(
        find.text('Đang xem: Thành viên / Con cháu'),
        findsOneWidget,
      );

      // Chuyển sang phân hệ Quản trị / Trưởng tộc & BTC
      await tester.tap(find.text('Quản trị / BTC'));
      await tester.pumpAndSettle();

      expect(
        find.text('Đang xem: Quản trị / Trưởng tộc & BTC'),
        findsOneWidget,
      );
    },
  );
}
