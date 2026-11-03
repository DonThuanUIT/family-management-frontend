import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/features/auth/data/models/auth_models.dart';
import 'package:familyfund_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:familyfund_app/features/genealogy/presentation/screens/edit_root_branch_screen.dart';
import 'package:familyfund_app/features/home/presentation/screens/home_screen.dart';
import 'package:familyfund_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthNotifier extends AuthNotifier {
  final AuthState _initial;
  MockAuthNotifier(this._initial);

  @override
  AuthState build() => _initial;
}

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

  testWidgets(
    'HomeScreen renders 2 branch columns, aligns sub-generations, removes bottom switcher, and harmonizes identity',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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

      // 1. Kiểm tra danh tính người dùng trên Navbar đã đồng bộ thành Lê Hữu Tuấn (không còn Nguyễn Trọng Hoàng)
      expect(find.text('Lê Hữu Tuấn'), findsWidgets);
      expect(find.text('Nguyễn Trọng Hoàng'), findsNothing);

      // 2. Kiểm tra Cụ Khởi Tổ và 2 nhánh đời 2 xuất hiện
      expect(find.text('CỤ KHỞI TỔ • ĐỜI 1'), findsOneWidget);
      expect(find.text('Chi 1 (Trưởng Phái) • Đời 2'), findsOneWidget);
      expect(find.text('Chi 2 (Thứ Phái) • Đời 2'), findsWidgets);

      // 3. Kiểm tra hộp chuyển tuyến phẳng dưới đáy màn hình đã bị loại bỏ hoàn toàn
      expect(find.text('Tuyến Chi Trưởng (Cụ An)'), findsNothing);
      expect(find.text('Tuyến Chi Thứ (Cụ Bình)'), findsNothing);

      // 4. Mở rộng toàn bộ cây 5 đời
      final expandButton = find.text('Hiện Đầy Đủ Cây (5 Đời)');
      expect(expandButton, findsOneWidget);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      expect(find.text('Thu Gọn Sơ Đồ'), findsOneWidget);

      // 5. Kiểm tra các thế hệ đời 3, 4, 5 của Chi 1 xuất hiện
      expect(find.text('Bác Lê Tuấn Anh'), findsOneWidget);
      expect(find.text('Chú Lê Đình Khôi'), findsOneWidget);
      expect(find.text('Lê Hoàng Long'), findsOneWidget);

      // 6. Kiểm tra các thế hệ đời 3, 4, 5 của Chi 2 xuất hiện
      expect(find.text('Bác Lê Văn Hùng'), findsOneWidget);
      expect(find.text('Chú Lê Hữu Nam'), findsOneWidget);
      expect(find.text('VỊ TRÍ CỦA BẠN • ĐỜI 5'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen dynamically loads Nguyen Clan tree and highlights Clan Head when logged in as Nguyen Trong Hoang',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue('/home'),
            authStateProvider.overrideWith(
              () => MockAuthNotifier(
                const AuthState(
                  status: AuthStatus.authenticated,
                  user: AuthTokenResponseDto(
                    accessToken: 'mock_token',
                    refreshToken: 'mock_refresh',
                    tokenType: 'Bearer',
                    expiresIn: 86400,
                    accountId: 'ACC_TRUONG_TOC',
                    phoneNumber: '0901234567',
                    email: 'truongtoc@gtvn.vn',
                    fullName: 'Nguyễn Trọng Hoàng',
                    clanId: 'CLAN_DEFAULT',
                    memberId: 'MEM_TRUONG_TOC',
                    roles: ['ROLE_CLAN_HEAD', 'ROLE_MEMBER'],
                  ),
                ),
              ),
            ),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // 1. Kiểm tra Navbar và Toolbar hiển thị đúng Dòng Họ Nguyễn
      expect(find.text('DÒNG HỌ NGUYỄN VIỆT NAM'), findsOneWidget);
      expect(find.text('Nguyễn Trọng Hoàng'), findsWidgets);
      expect(find.text('Dòng Họ Nguyễn Việt Nam • Chi Gốc'), findsOneWidget);

      // 2. Kiểm tra Thẻ Cụ Khởi Tổ / Trưởng Tộc được tự động ghim huy hiệu "VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC"
      expect(find.text('★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC'), findsWidgets);
      expect(find.text('● Đang quản trị'), findsOneWidget);

      // 3. Kiểm tra thẻ con cháu Đời 5 không còn bị gán nhầm "VỊ TRÍ CỦA BẠN"
      expect(find.text('VỊ TRÍ CỦA BẠN • ĐỜI 5'), findsNothing);

      // 4. Mở rộng toàn bộ cây 5 đời của Dòng Họ Nguyễn
      final expandButton = find.text('Hiện Đầy Đủ Cây (5 Đời)');
      expect(expandButton, findsOneWidget);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // 5. Kiểm tra các thế hệ con cháu Dòng Họ Nguyễn xuất hiện
      expect(find.text('Nguyễn Thị Mai Anh'), findsOneWidget);
      expect(find.text('Nguyễn Hoàng Long'), findsOneWidget);
      expect(find.text('Bác Nguyễn Hữu Nam'), findsOneWidget);
      expect(find.text('Chú Nguyễn Hữu Đạt'), findsOneWidget);
    },
  );
}
