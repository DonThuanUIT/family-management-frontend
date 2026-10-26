import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginScreen renders all input fields and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/login'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đăng Nhập Gia Tộc'), findsOneWidget);
    expect(find.text('Số điện thoại hoặc Email *'), findsOneWidget);
    expect(find.text('Mật khẩu *'), findsOneWidget);
    expect(find.text('Đăng Nhập Vào Dòng Họ'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
  });

  testWidgets('InviteCodeScreen renders manual code input and QR trigger',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/invite-code'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thư Mời Gia Tộc'), findsOneWidget);
    expect(find.text('Nhập Mã Tham Gia Dòng Họ'), findsOneWidget);
    expect(find.text('Mã Gia Tộc (Bắt buộc) *'), findsOneWidget);
    expect(find.text('Quét mã QR Thư Mời Gia Tộc'), findsOneWidget);
    expect(find.text('Kiểm tra'), findsOneWidget);
  });

  testWidgets(
      'RegisterMemberScreen renders full name, phone, password and security assurance',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/register-member'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SỔ VÀNG GIA TỘC'), findsOneWidget);
    expect(find.text('Ghi Tên Vào Gia Phả'), findsWidgets);
    expect(find.text('Họ và tên khai sinh *'), findsOneWidget);
    expect(find.text('Số điện thoại liên lạc *'), findsOneWidget);
    expect(find.text('Mật khẩu bảo vệ tài khoản *'), findsOneWidget);
    expect(find.text('Nhập lại mật khẩu *'), findsOneWidget);
    expect(find.text('Hoàn tất đăng ký & Vào dòng họ'), findsOneWidget);
    expect(
      find.text(
          'Quyền bảo vệ danh dự & sự minh bạch của dòng họ được đảm bảo.'),
      findsOneWidget,
    );
  });

  testWidgets('RegisterCreatorScreen renders clan and creator fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLocationProvider.overrideWithValue('/register-creator'),
        ],
        child: const FamilyFundApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khởi Lập Dòng Họ'), findsOneWidget);
    expect(find.text('Quyền Hạn Trưởng Tộc (Clan Head)'), findsOneWidget);
    expect(find.text('1. Thông Tin Dòng Họ'), findsOneWidget);
    expect(find.text('2. Thông Tin Trưởng Tộc'), findsOneWidget);
    expect(find.text('Khởi Lập Dòng Họ & Mở Cây Gia Phả'), findsOneWidget);
  });
}
