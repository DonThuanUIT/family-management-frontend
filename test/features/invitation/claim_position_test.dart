import 'package:familyfund_app/features/auth/presentation/screens/login_screen.dart';
import 'package:familyfund_app/features/invitation/data/models/position_link_models.dart';
import 'package:familyfund_app/features/invitation/data/repositories/position_link_repository_impl.dart';
import 'package:familyfund_app/features/invitation/domain/repositories/position_link_repository.dart';
import 'package:familyfund_app/features/invitation/presentation/providers/claim_position_provider.dart';
import 'package:familyfund_app/features/invitation/presentation/widgets/position_link_quick_claim_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockPositionLinkRepo implements PositionLinkRepository {
  bool shouldFailLookup = false;
  bool shouldFailClaim = false;

  @override
  Future<CreateVirtualMemberResponseDto> createVirtualMember({
    required String branchId,
    required CreateVirtualMemberRequestDto request,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PositionLinkItemModel>> getIssuedPositionLinks() async {
    return [];
  }

  @override
  Future<PositionLinkPreviewDto> getPositionLinkPreview(
      String inviteCode) async {
    if (shouldFailLookup) {
      throw Exception('Mã liên kết không hợp lệ hoặc đã hết hạn');
    }
    return PositionLinkPreviewDto(
      inviteCode: inviteCode,
      clanId: 'LE',
      clanName: 'Dòng Họ Lê',
      branchId: 'chi-2',
      branchName: 'Chi 2',
      memberId: 'MEM-002',
      fullName: 'Lê Thu Trang',
      generation: 5,
      expiresAt: '2026-03-28T00:00:00Z',
      issuedBy: 'Lê Văn Hùng',
    );
  }

  @override
  Future<ClaimPositionResponseDto> claimPosition({
    required String inviteCode,
    required ClaimPositionRequestDto request,
  }) async {
    if (shouldFailClaim) {
      throw Exception('Số điện thoại đã được đăng ký trong hệ thống');
    }
    return ClaimPositionResponseDto(
      accountId: 'ACC-002',
      phoneNumber: request.phoneNumber,
      email: request.email,
      accountStatus: 'Active',
      roles: const ['ROLE_MEMBER'],
      memberId: 'MEM-002',
      fullName: 'Lê Thu Trang',
      generation: 5,
      branchId: 'chi-2',
      branchName: 'Chi 2',
      clanId: 'LE',
      clanName: 'Dòng Họ Lê',
      inviteCode: inviteCode,
      linkedAt: '2026-03-14T10:00:00Z',
    );
  }
}

void main() {
  group('US-19: Position Link Claim DTO Tests', () {
    test('PositionLinkPreviewDto deserializes from JSON correctly', () {
      final json = {
        'inviteCode': 'LE-CHI2-DOI5-7731',
        'clanId': 'LE',
        'clanName': 'Dòng Họ Lê',
        'branchId': 'chi-2',
        'branchName': 'Chi 2',
        'memberId': 'MEM-002',
        'fullName': 'Lê Thu Trang',
        'generation': 5,
        'expiresAt': '2026-03-28T00:00:00Z',
        'issuedBy': 'Lê Văn Hùng',
      };

      final dto = PositionLinkPreviewDto.fromJson(json);
      expect(dto.inviteCode, 'LE-CHI2-DOI5-7731');
      expect(dto.clanId, 'LE');
      expect(dto.clanName, 'Dòng Họ Lê');
      expect(dto.branchId, 'chi-2');
      expect(dto.branchName, 'Chi 2');
      expect(dto.fullName, 'Lê Thu Trang');
      expect(dto.generation, 5);
      expect(dto.issuedBy, 'Lê Văn Hùng');
    });

    test('ClaimPositionRequestDto serializes to JSON correctly', () {
      const dto = ClaimPositionRequestDto(
        phoneNumber: '0912345678',
        password: 'Password@123',
        email: 'trang@example.com',
      );

      final json = dto.toJson();
      expect(json['phoneNumber'], '0912345678');
      expect(json['password'], 'Password@123');
      expect(json['email'], 'trang@example.com');
    });

    test('ClaimPositionResponseDto deserializes from JSON correctly', () {
      final json = {
        'accountId': 'ACC-002',
        'phoneNumber': '0912345678',
        'email': 'trang@example.com',
        'accountStatus': 'Active',
        'roles': ['ROLE_MEMBER'],
        'memberId': 'MEM-002',
        'fullName': 'Lê Thu Trang',
        'generation': 5,
        'branchId': 'chi-2',
        'branchName': 'Chi 2',
        'clanId': 'LE',
        'clanName': 'Dòng Họ Lê',
        'inviteCode': 'LE-CHI2-DOI5-7731',
        'linkedAt': '2026-03-14T10:00:00Z',
      };

      final dto = ClaimPositionResponseDto.fromJson(json);
      expect(dto.accountId, 'ACC-002');
      expect(dto.phoneNumber, '0912345678');
      expect(dto.fullName, 'Lê Thu Trang');
      expect(dto.roles, contains('ROLE_MEMBER'));
      expect(dto.accountStatus, 'Active');
      expect(dto.branchName, 'Chi 2');
    });
  });

  group('US-19: ClaimPositionNotifier State Tests', () {
    late MockPositionLinkRepo mockRepo;

    setUp(() {
      mockRepo = MockPositionLinkRepo();
    });

    test('lookupCode succeeds and updates state', () async {
      final container = ProviderContainer(
        overrides: [
          positionLinkRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(claimPositionProvider.notifier);

      expect(container.read(claimPositionProvider).preview, isNull);

      await notifier.lookupCode('LE-CHI2-DOI5-7731');

      final state = container.read(claimPositionProvider);
      expect(state.preview, isNotNull);
      expect(state.preview?.fullName, 'Lê Thu Trang');
      expect(state.preview?.branchName, 'Chi 2');
      expect(state.isValidCode, isTrue);
    });

    test('lookupCode fails and sets previewError', () async {
      mockRepo.shouldFailLookup = true;
      final container = ProviderContainer(
        overrides: [
          positionLinkRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(claimPositionProvider.notifier);

      await notifier.lookupCode('INVALID-CODE');

      final state = container.read(claimPositionProvider);
      expect(state.preview, isNull);
      expect(state.previewError, contains('Mã liên kết không hợp lệ'));
      expect(state.isValidCode, isFalse);
    });

    test('claim succeeds and transitions to success state', () async {
      final container = ProviderContainer(
        overrides: [
          positionLinkRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(claimPositionProvider.notifier);
      await notifier.lookupCode('LE-CHI2-DOI5-7731');

      final success = await notifier.claim(
        phoneNumber: '0912345678',
        password: 'Password123',
      );

      expect(success, isTrue);
      final state = container.read(claimPositionProvider);
      expect(state.claimSuccess, isNotNull);
      expect(state.claimSuccess?.accountStatus, 'Active');
      expect(state.claimError, isNull);
    });

    test('claim fails and sets claimError', () async {
      mockRepo.shouldFailClaim = true;
      final container = ProviderContainer(
        overrides: [
          positionLinkRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(claimPositionProvider.notifier);
      await notifier.lookupCode('LE-CHI2-DOI5-7731');

      final success = await notifier.claim(
        phoneNumber: '0912345678',
        password: 'Password123',
      );

      expect(success, isFalse);
      final state = container.read(claimPositionProvider);
      expect(state.claimSuccess, isNull);
      expect(state.claimError, contains('Số điện thoại đã được đăng ký'));
    });
  });

  group('US-19: PositionLinkQuickClaimCard UI Tests', () {
    late MockPositionLinkRepo mockRepo;

    setUp(() {
      mockRepo = MockPositionLinkRepo();
    });

    testWidgets('renders quick claim card and looks up position code',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionLinkRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PositionLinkQuickClaimCard(
                  initialCode: 'LE-CHI2-DOI5-7731',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và input mã vị trí
      expect(find.text('Mã liên kết vị trí gia phả'), findsOneWidget);
      expect(find.text('BẮT BUỘC'), findsOneWidget);
      expect(find.text('LE-CHI2-DOI5-7731'), findsOneWidget);

      // Thẻ thông tin vị trí đã được gán sẵn
      expect(find.text('Họ và tên con cháu (Đã định vị)'), findsOneWidget);
      expect(find.text('Lê Thu Trang'), findsOneWidget);
      expect(find.textContaining('Chi 2'), findsWidgets);

      // Các trường nhập tài khoản
      expect(find.text('Số điện thoại'), findsOneWidget);
      expect(find.text('Mật khẩu tài khoản'), findsOneWidget);
      expect(find.text('Xác Nhận & Gia Nhập Cây Phả Hệ'), findsOneWidget);
    });

    testWidgets('filling credentials and pressing submit triggers claim flow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool successCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionLinkRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PositionLinkQuickClaimCard(
                  initialCode: 'LE-CHI2-DOI5-7731',
                  onSuccess: () {
                    successCalled = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Nhập số điện thoại (TextFormField thứ 2 sau code)
      final phoneField = find.byType(TextFormField).at(1);
      await tester.enterText(phoneField, '0988776655');

      // Nhập mật khẩu (TextFormField thứ 3)
      final passField = find.byType(TextFormField).at(2);
      await tester.enterText(passField, 'Secret123');

      // Bấm nút Xác Nhận & Gia Nhập Cây Phả Hệ
      final submitBtn = find.byType(ElevatedButton);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Kiểm tra callback thành công được gọi
      expect(successCalled, isTrue);
    });
  });

  group('US-19: LoginScreen Responsive & Tab Switcher Tests', () {
    late MockPositionLinkRepo mockRepo;

    setUp(() {
      mockRepo = MockPositionLinkRepo();
    });

    testWidgets('Desktop viewport (1280x900) renders Stitch W1 2-column layout',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionLinkRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(initialTabIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Bên trái: Editorial panel
      expect(find.text('Gìn giữ cội nguồn, minh bạch tài chính gia tộc'), findsOneWidget);
      expect(find.text('Trưởng Tộc Lê Phúc Khang'), findsOneWidget);

      // Bên phải: Segmented tab switcher
      expect(find.text('Gia Nhập Bằng Mã Mời'), findsOneWidget);
      expect(find.text('Đăng Nhập Mật Khẩu'), findsOneWidget);

      // Đang ở tab 0 (Gia nhập bằng mã mời)
      expect(find.text('Mã liên kết vị trí gia phả'), findsOneWidget);

      // Chuyển sang Tab 1: Đăng nhập mật khẩu
      final loginTab = find.text('Đăng Nhập Mật Khẩu');
      await tester.tap(loginTab);
      await tester.pumpAndSettle();

      // Kiểm tra các trường đăng nhập truyền thống
      expect(find.text('Đăng Nhập Gia Tộc'), findsOneWidget);
      expect(find.text('Số điện thoại hoặc Email *'), findsOneWidget);
      expect(find.text('Mật khẩu *'), findsOneWidget);
      expect(find.text('Đăng Nhập Vào Dòng Họ'), findsOneWidget);
    });

    testWidgets('Mobile viewport (390x844) renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionLinkRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(initialTabIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trên mobile, cả 2 tab hiển thị vừa vặn không bị RenderFlex overflow
      expect(find.text('Gia Nhập Bằng Mã Mời'), findsOneWidget);
      expect(find.text('Đăng Nhập Mật Khẩu'), findsOneWidget);
      expect(find.text('Mã liên kết vị trí gia phả'), findsOneWidget);

      // Chuyển sang Tab Đăng Nhập
      final loginTab = find.text('Đăng Nhập Mật Khẩu');
      await tester.tap(loginTab);
      await tester.pumpAndSettle();

      expect(find.text('Đăng Nhập Gia Tộc'), findsOneWidget);
    });
  });
}
