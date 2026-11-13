import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/features/auth/data/datasources/profile_remote_datasource.dart';
import 'package:familyfund_app/features/auth/data/models/auth_models.dart';
import 'package:familyfund_app/features/auth/data/models/profile_models.dart';
import 'package:familyfund_app/features/auth/presentation/providers/auth_state_provider.dart';
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

class FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  UserProfileDto currentProfile = UserProfileDto(
    accountId: 'ACC_TEST_01',
    memberId: 'MEM_TEST_01',
    clanId: 'CLAN_TEST_01',
    accountStatus: 'ACTIVE',
    roles: const ['TRUONG_NHANH'],
    phoneNumber: '0912345678',
    email: 'thanhvien@dongho.vn',
    address: '123 Đường Láng, Đống Đa, Hà Nội',
    fullName: 'Nguyễn Văn An',
    dateOfBirth: DateTime(1990, 5, 15),
    gender: 'MALE',
    generation: 4,
    branchId: 'BR_02',
    branchName: 'Chi 2 (Đông Kết)',
  );

  bool shouldThrowOnPassword = false;

  @override
  Future<UserProfileDto> getMyProfile() async {
    return currentProfile;
  }

  @override
  Future<UserProfileDto> updateContactProfile(
      UpdateContactProfileRequestDto request) async {
    currentProfile = currentProfile.copyWith(
      phoneNumber: request.phoneNumber,
      email: request.email,
      address: request.address,
    );
    return currentProfile;
  }

  @override
  Future<void> changePassword(ChangePasswordRequestDto request) async {
    if (shouldThrowOnPassword) {
      throw Exception('Mật khẩu hiện tại không chính xác');
    }
    if (request.newPassword != request.confirmPassword) {
      throw Exception('Xác nhận mật khẩu không khớp');
    }
  }
}

void main() {
  group('US-22 Profile Models Unit Tests', () {
    test('UserProfileDto json roundtrip correctly parses all fields', () {
      final json = {
        'accountId': 'ACC_01',
        'memberId': 'MEM_01',
        'clanId': 'CLAN_01',
        'accountStatus': 'ACTIVE',
        'roles': ['TRUONG_TOC', 'THANH_VIEN'],
        'phoneNumber': '0901234567',
        'email': 'truongtoc@gmail.com',
        'address': 'Từ đường dòng họ Nguyễn',
        'fullName': 'Nguyễn Trọng Hoàng',
        'dateOfBirth': '1965-10-20',
        'gender': 'MALE',
        'generation': 1,
        'branchId': 'BR_ROOT',
        'branchName': 'Chi Gốc (Đại Tôn)',
      };

      final dto = UserProfileDto.fromJson(json);
      expect(dto.accountId, 'ACC_01');
      expect(dto.phoneNumber, '0901234567');
      expect(dto.fullName, 'Nguyễn Trọng Hoàng');
      expect(dto.dateOfBirth, DateTime(1965, 10, 20));
      expect(dto.generation, 1);
      expect(dto.roles, contains('TRUONG_TOC'));

      final serialized = dto.toJson();
      expect(serialized['accountId'], 'ACC_01');
      expect(serialized['phoneNumber'], '0901234567');
      expect(serialized['fullName'], 'Nguyễn Trọng Hoàng');
    });

    test('UpdateContactProfileRequestDto json excludes immutable genealogy fields', () {
      const req = UpdateContactProfileRequestDto(
        phoneNumber: '0987654321',
        email: 'newemail@dongho.vn',
        address: 'Hà Nội',
      );

      final json = req.toJson();
      expect(json.containsKey('phoneNumber'), isTrue);
      expect(json.containsKey('email'), isTrue);
      expect(json.containsKey('address'), isTrue);
      // Chặn hoàn toàn các trường phả hệ khỏi payload
      expect(json.containsKey('fullName'), isFalse);
      expect(json.containsKey('dateOfBirth'), isFalse);
      expect(json.containsKey('generation'), isFalse);
    });

    test('ChangePasswordRequestDto serialization matches expected keys', () {
      const req = ChangePasswordRequestDto(
        currentPassword: 'oldPassword123',
        newPassword: 'newPassword456',
        confirmPassword: 'newPassword456',
      );

      final map = req.toJson();
      expect(map['currentPassword'], 'oldPassword123');
      expect(map['newPassword'], 'newPassword456');
      expect(map['confirmPassword'], 'newPassword456');
    });
  });

  group('US-22 MyProfileScreen Widget Tests', () {
    late FakeProfileRemoteDataSource fakeDataSource;

    setUp(() {
      fakeDataSource = FakeProfileRemoteDataSource();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          profileRemoteDataSourceProvider.overrideWithValue(fakeDataSource),
          authStateProvider.overrideWith(
            () => MockAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                user: AuthTokenResponseDto(
                  accessToken: 'mock-access-token',
                  refreshToken: 'mock-refresh-token',
                  tokenType: 'Bearer',
                  expiresIn: 3600,
                  accountId: 'ACC_TEST_01',
                  phoneNumber: '0912345678',
                  memberId: 'MEM_TEST_01',
                  clanId: 'CLAN_TEST_01',
                  fullName: 'Nguyễn Văn An',
                  roles: ['TRUONG_NHANH'],
                ),
              ),
            ),
          ),
          initialLocationProvider.overrideWithValue('/profile'),
        ],
        child: const FamilyFundApp(),
      );
    }

    testWidgets('Renders all 3 sections: Read-only Genealogy, Editable Contacts, Change Password',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tiêu đề & Header
      expect(find.text('Hồ Sơ Cá Nhân'), findsWidgets);
      expect(find.text('Nguyễn Văn An'), findsWidgets);
      expect(find.textContaining('Chi 2 (Đông Kết)'), findsWidgets);
      expect(find.textContaining('Đời thứ: 4'), findsWidgets);

      // Section 1: Phả hệ Read-only
      expect(find.text('Thông Tin Phả Hệ Nhân Khẩu'), findsOneWidget);
      expect(find.text('Read-only'), findsOneWidget);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Ngày sinh'), findsOneWidget);
      expect(find.text('15/05/1990'), findsOneWidget);
      expect(find.text('Giới tính'), findsOneWidget);
      expect(find.text('Nam'), findsOneWidget);
      expect(find.text('Đời thứ (Thế hệ)'), findsOneWidget);
      expect(find.text('Đời thứ 4'), findsOneWidget);

      // Section 2: Liên lạc có thể chỉnh sửa
      expect(find.text('Thông Tin Liên Lạc Cá Nhân'), findsOneWidget);
      expect(find.text('0912345678'), findsOneWidget);
      expect(find.text('thanhvien@dongho.vn'), findsWidgets);
      expect(find.text('123 Đường Láng, Đống Đa, Hà Nội'), findsOneWidget);
      expect(find.text('Lưu Thông Tin Liên Lạc'), findsOneWidget);

      // Section 3: Đổi mật khẩu
      expect(find.text('Đổi Mật Khẩu Đăng Nhập'), findsOneWidget);
      expect(find.text('Mật khẩu hiện tại *'), findsOneWidget);
      expect(find.text('Mật khẩu mới * (Tối thiểu 6 ký tự)'), findsOneWidget);
      expect(find.text('Xác nhận lại mật khẩu mới *'), findsOneWidget);
      expect(find.text('Cập Nhật Mật Khẩu'), findsOneWidget);
    });

    testWidgets('Updates contact information successfully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tìm trường SĐT và sửa thành SĐT mới
      final phoneField = find.widgetWithText(TextFormField, 'Số điện thoại liên lạc *');
      expect(phoneField, findsOneWidget);

      await tester.enterText(phoneField, '0988776655');

      // Bấm nút Lưu Thông Tin Liên Lạc
      final saveBtn = find.text('Lưu Thông Tin Liên Lạc');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Kiểm tra fakeDataSource đã cập nhật SĐT mới
      expect(fakeDataSource.currentProfile.phoneNumber, '0988776655');
      // SnackBar hiển thị thông báo thành công
      expect(find.text('Cập nhật thông tin liên lạc thành công.'), findsOneWidget);
    });

    testWidgets('Validates invalid phone number format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final phoneField = find.widgetWithText(TextFormField, 'Số điện thoại liên lạc *');
      await tester.enterText(phoneField, '12345'); // Không đúng định dạng 10 số bắt đầu bằng 0

      final saveBtn = find.text('Lưu Thông Tin Liên Lạc');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Số điện thoại không hợp lệ (cần 10 chữ số, bắt đầu bằng 0)'),
        findsOneWidget,
      );
    });

    testWidgets('Validates password mismatch and change password successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final currentPassField =
          find.widgetWithText(TextFormField, 'Mật khẩu hiện tại *');
      final newPassField =
          find.widgetWithText(TextFormField, 'Mật khẩu mới * (Tối thiểu 6 ký tự)');
      final confirmPassField =
          find.widgetWithText(TextFormField, 'Xác nhận lại mật khẩu mới *');
      final changePassBtn = find.text('Cập Nhật Mật Khẩu');

      await tester.ensureVisible(currentPassField);
      await tester.enterText(currentPassField, 'oldPass123');
      await tester.enterText(newPassField, 'newPass678');
      await tester.enterText(confirmPassField, 'mismatchPass');

      await tester.ensureVisible(changePassBtn);
      await tester.tap(changePassBtn);
      await tester.pumpAndSettle();

      // Báo lỗi không khớp
      expect(
        find.text('Mật khẩu xác nhận không khớp với mật khẩu mới'),
        findsOneWidget,
      );

      // Sửa lại cho khớp
      await tester.enterText(confirmPassField, 'newPass678');
      await tester.tap(changePassBtn);
      await tester.pumpAndSettle();

      expect(find.text('Đổi mật khẩu tài khoản thành công.'), findsOneWidget);
    });
  });
}
