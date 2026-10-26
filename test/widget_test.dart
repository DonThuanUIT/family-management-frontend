import 'package:familyfund_app/core/router/app_router.dart';
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
    'FamilyFundApp renders HomeScreen placeholder for authenticated users',
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

      expect(
        find.text('Khu Vực Thiết Kế Màn Hình Sau Đăng Nhập'),
        findsOneWidget,
      );
      expect(
        find.text('Dòng họ:'),
        findsOneWidget,
      );
      expect(
        find.text('Đăng Xuất Tài Khoản'),
        findsOneWidget,
      );
    },
  );
}
