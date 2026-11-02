import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/features/genealogy/presentation/screens/edit_root_branch_screen.dart';
import 'package:familyfund_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'EditRootBranchScreen renders correctly with form fields and Task #16 elements',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue('/branches/root/edit'),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra màn hình xuất hiện
      expect(find.byType(EditRootBranchScreen), findsOneWidget);

      // Kiểm tra tiêu đề và huy hiệu Thủy tổ Đời 1
      expect(find.text('Biểu Mẫu Chỉnh Sửa Nhánh Gốc'), findsOneWidget);
      expect(find.text('CỤ KHỞI TỔ • ĐỜI 1'), findsOneWidget);
      expect(find.text('Đặc Tính Cấu Trúc Bất Biến'), findsOneWidget);

      // Kiểm tra các trường dữ liệu
      expect(find.text('Tên Nhánh Gốc'), findsOneWidget);
      expect(find.text('Mã Khởi Tổ / Người Đại Diện'), findsOneWidget);
      expect(find.text('Lược Sử & Ghi Chú Từ Đường'), findsOneWidget);

      // Kiểm tra nút hành động
      final saveButton = find.text('Lưu Thay Đổi Nhánh Gốc');
      expect(saveButton, findsOneWidget);
      expect(find.text('Hủy Bỏ'), findsOneWidget);

      // Kiểm tra validation khi xóa trống tên nhánh gốc và bấm Lưu
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(3));

      // Xóa tên nhánh gốc
      await tester.enterText(textFields.at(0), '');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Tên nhánh gốc không được để trống'), findsOneWidget);
    },
  );
}
