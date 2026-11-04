import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/features/auth/data/models/auth_models.dart';
import 'package:familyfund_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:familyfund_app/features/genealogy/data/models/branch_models.dart';
import 'package:familyfund_app/features/genealogy/presentation/providers/genealogy_providers.dart';
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

const kTestBranchTree = BranchTreeNodeDto(
  branchId: 'BR_ROOT',
  clanId: 'CLAN_DEFAULT',
  branchName: 'Chi Gốc (Đại Tôn)',
  clanName: 'Dòng Họ Nguyễn Việt Nam',
  generationLevel: 1,
  representativeId: 'MEM_TRUONG_TOC',
  representativeName: 'Nguyễn Trọng Hoàng',
  memberCount: 1,
  children: [
    BranchTreeNodeDto(
      branchId: 'BR_CHI_2',
      clanId: 'CLAN_DEFAULT',
      branchName: 'Chi 2 - Nhánh Giáp',
      clanName: 'Dòng Họ Nguyễn Việt Nam',
      generationLevel: 2,
      parentBranchId: 'BR_ROOT',
      representativeId: 'MEM_TRUONG_CHI',
      representativeName: 'Nguyễn Văn An',
      memberCount: 2,
      children: [],
    ),
  ],
);

const kTestChi2Members = [
  BranchMemberItem(
    memberId: 'MEM_TRUONG_CHI',
    fullName: 'Nguyễn Văn An',
    generation: 2,
    birthDeathInfo: 'Sinh 1978',
    roleInBranch: 'Trưởng Chi 2',
    isActivated: true,
  ),
  BranchMemberItem(
    memberId: 'MEM_MAI_ANH',
    fullName: 'Nguyễn Thị Mai Anh',
    generation: 3,
    birthDeathInfo: 'Sinh 1992',
    roleInBranch: 'Thành viên • Đời 3',
    gender: 'female',
    isActivated: true,
  ),
];

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
    'HomeScreen dynamically loads branch tree and real members from Backend API without seed data',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue('/home'),
            branchTreeProvider.overrideWith((ref) => Future.value(kTestBranchTree)),
            branchMembersProvider('BR_CHI_2').overrideWith((ref) => Future.value(kTestChi2Members)),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // 1. Kiểm tra danh tính người dùng và dòng họ trên Navbar
      expect(find.text('Nguyễn Trọng Hoàng'), findsWidgets);

      // 2. Kiểm tra Nhánh Gốc (Đời 1) và Chi Nhánh 2 từ Database xuất hiện
      expect(find.text('Chi Gốc (Đại Tôn)'), findsWidgets);
      expect(find.text('Chi 2 - Nhánh Giáp'), findsWidgets);

      // 3. Kiểm tra số lượng thành viên thực tế (1 người ở Chi Gốc, 2 người ở Chi 2)
      expect(find.text('1 Thành viên (Xem chi tiết →)'), findsOneWidget);
      expect(find.text('2 người'), findsOneWidget);

      // 4. Mở rộng cây phả hệ để xem các đời tiếp theo
      final expandButton = find.text('Hiện Đầy Đủ Cây (Tất Cả Đời)');
      expect(expandButton, findsOneWidget);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      expect(find.text('Thu Gọn Sơ Đồ'), findsOneWidget);

      // 5. Kiểm tra thành viên thực tế của Chi 2: Nguyễn Thị Mai Anh (Đời 3) xuất hiện
      expect(find.text('Nguyễn Thị Mai Anh'), findsOneWidget);
      expect(find.text('ĐỜI 3'), findsWidgets);
    },
  );

  testWidgets(
    'HomeScreen dynamically highlights Clan Head and pins position when logged in as Nguyen Trong Hoang',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue('/home'),
            branchTreeProvider.overrideWith((ref) => Future.value(kTestBranchTree)),
            branchMembersProvider('BR_CHI_2').overrideWith((ref) => Future.value(kTestChi2Members)),
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

      // 1. Kiểm tra Navbar hiển thị Dòng Họ Nguyễn và tên Trưởng tộc
      expect(find.text('DÒNG HỌ NGUYỄN VIỆT NAM'), findsOneWidget);
      expect(find.text('Nguyễn Trọng Hoàng'), findsWidgets);

      // 2. Kiểm tra Thẻ Cụ Khởi Tổ / Trưởng Tộc được tự động ghim huy hiệu "VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC"
      expect(find.text('★ VỊ TRÍ CỦA BẠN • TRƯỞNG TỘC'), findsWidgets);
      expect(find.text('● Đang quản trị'), findsOneWidget);

      // 3. Mở rộng toàn bộ cây để kiểm tra thành viên thực tế
      final expandButton = find.text('Hiện Đầy Đủ Cây (Tất Cả Đời)');
      expect(expandButton, findsOneWidget);
      await tester.tap(expandButton);
      await tester.pumpAndSettle();

      // 4. Kiểm tra thành viên thực tế của Chi 2: Nguyễn Thị Mai Anh
      expect(find.text('Nguyễn Thị Mai Anh'), findsOneWidget);
      expect(find.text('Chi 2 - Nhánh Giáp'), findsWidgets);
    },
  );
}
