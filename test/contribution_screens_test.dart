import 'package:familyfund_app/core/theme/app_theme.dart';
import 'package:familyfund_app/features/contribution/presentation/screens/clan_asset_inventory_screen.dart';
import 'package:familyfund_app/features/contribution/presentation/screens/receive_contribution_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders ReceiveContributionScreen with stats and transactions',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReceiveContributionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Banners
    expect(find.text('Bàn Tiếp Nhận Đóng Góp & Sổ Cái'), findsOneWidget);
    expect(find.text('Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026'), findsOneWidget);
    expect(find.text('Lập Phiếu Đóng Góp Mới'), findsOneWidget);

    // Verify Stat Cards
    expect(find.text('TỔNG THU TIỀN MẶT / CK'), findsOneWidget);
    expect(find.text('HIỆN VẬT CÚNG TIẾN (QUY ĐỔI)'), findsOneWidget);

    // Verify sample transactions
    expect(find.text('PT-20261102-09482'), findsOneWidget);
    expect(find.text('Đôi lục bình gốm Bát Tràng men lam cổ (1.0 đôi)'),
        findsOneWidget);
  });

  testWidgets('renders ClanAssetInventoryScreen and displays assets',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ClanAssetInventoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Kho Bảo Vật & Di Sản Dòng Họ'), findsOneWidget);
    expect(find.text('TỔNG SỐ BẢO VẬT'), findsOneWidget);
    expect(find.text('TỔNG GIÁ TRỊ QUY ĐỔI ƯỚC TÍNH'), findsOneWidget);

    // Verify sample assets in the list
    expect(find.text('Bộ đỉnh đồng tam sự chạm khắc song long'), findsOneWidget);
  });

  testWidgets(
      'ClanAssetInventoryScreen displays consumed and returned in-kind history',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ClanAssetInventoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 4 overview cards
    expect(find.text('ĐÃ TIÊU HAO & HOÀN TRẢ'), findsOneWidget);

    // Verify Tab 3 exists
    final tab3Finder = find.textContaining('Nhật Ký Đã Tiêu Hao & Hoàn Trả');
    expect(tab3Finder, findsOneWidget);

    // Switch to Tab 3
    await tester.tap(tab3Finder);
    await tester.pumpAndSettle();

    // Verify audit banner text
    expect(find.textContaining('Lưu Trữ Lịch Sử Vĩnh Viễn'), findsOneWidget);

    // Verify sample consumed and returned items exist in Tab 3
    expect(find.textContaining('10 Mâm xôi gấc & gà trống thiến tế tổ'),
        findsOneWidget);
    expect(find.text('ĐÃ TIÊU HAO CHO CỖ BÀN'), findsOneWidget);
    expect(find.text('ĐÃ HOÀN TRẢ GIA CHỦ'), findsOneWidget);
  });
}
