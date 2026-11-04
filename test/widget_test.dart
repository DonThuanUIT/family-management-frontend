import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/features/home/presentation/screens/home_screen.dart';
import 'package:familyfund_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'FamilyFundApp renders Welcome screen by default with all auth options',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue('/welcome'),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gia Tộc Việt Nam'), findsOneWidget);
      expect(find.text('Tạo cây gia phả mới'), findsOneWidget);
      expect(find.text('Nhập mã gia phả dòng họ'), findsOneWidget);
      expect(find.text('Đăng nhập ngay'), findsOneWidget);
      expect(find.text('Trang nghiêm • Kế thừa • Muôn đời thịnh vượng'),
          findsOneWidget);
    },
  );

  testWidgets(
    'FamilyFundApp renders HomeScreen with HeritageNavBar for authenticated users',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue('/home'),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Sổ Cái'), findsWidgets);
      expect(find.text('Bảo Vật'), findsWidgets);
    },
  );
}
