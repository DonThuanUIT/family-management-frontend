import 'package:familyfund_app/features/invitation/data/models/position_link_models.dart';
import 'package:familyfund_app/features/invitation/data/repositories/position_link_repository_impl.dart';
import 'package:familyfund_app/features/invitation/domain/repositories/position_link_repository.dart';
import 'package:familyfund_app/features/invitation/presentation/screens/clan_invites_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockPositionLinkRepository implements PositionLinkRepository {
  List<PositionLinkItemModel> mockItems = [
    PositionLinkItemModel(
      code: 'LE-CHI2-DOI5-9821',
      branchId: 'chi-2',
      branchName: 'Chi 2',
      generation: 5,
      fullName: 'Lê Hữu Tuấn',
      issuedBy: 'Lê Văn Hùng (Trưởng Chi)',
      createdAt: DateTime(2026, 3, 12),
      isActivated: true,
      shareableUrl: 'https://familyfund.app/join?clan=LE&code=CHI2-DOI5-9821',
    ),
    PositionLinkItemModel(
      code: 'LE-CHI2-DOI5-7731',
      branchId: 'chi-2',
      branchName: 'Chi 2',
      generation: 5,
      fullName: 'Lê Thu Trang',
      issuedBy: 'Lê Văn Hùng',
      createdAt: DateTime(2026, 3, 14),
      isActivated: false,
      shareableUrl: 'https://familyfund.app/join?clan=LE&code=CHI2-DOI5-7731',
    ),
  ];

  @override
  Future<CreateVirtualMemberResponseDto> createVirtualMember({
    required String branchId,
    required CreateVirtualMemberRequestDto request,
  }) async {
    const newCode = 'LE-TEST-DOI5-1234';
    return const CreateVirtualMemberResponseDto(
      member: VirtualMemberDto(
        memberId: 'MEM-TEST',
        fullName: 'Thành viên Test',
        gender: 'Male',
        generation: 5,
        status: 'Living',
        branchId: 'chi-2',
        branchName: 'Chi 2',
        clanId: 'LE',
        isPlaceholder: true,
      ),
      positionLinkCode: PositionLinkCodeDto(
        inviteCode: newCode,
        clanId: 'LE',
        shareableUrl: 'https://familyfund.app/join?clan=LE&code=$newCode',
        targetBranchId: 'chi-2',
        targetMemberId: 'MEM-TEST',
      ),
    );
  }

  @override
  Future<List<PositionLinkItemModel>> getIssuedPositionLinks() async {
    return mockItems;
  }
}

void main() {
  testWidgets('ClanInvitesScreen renders desktop elements properly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockPositionLinkRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          positionLinkRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ClanInvitesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check header & titles
    expect(find.text('Cấp Mã Mời & Khởi Tạo Hồ Sơ Gia Phả'), findsOneWidget);
    expect(find.text('Tạo Mã Liên Kết Thành Viên Mới'), findsOneWidget);
    expect(find.text('CƠ CẤU VỊ TRÍ CÂY'), findsOneWidget);
    expect(find.text('Danh Sách Mã Liên Kết Đã Phát Hành'), findsOneWidget);

    // Check specific table row contents
    expect(find.text('LE-CHI2-DOI5-9821'), findsOneWidget);
    expect(find.text('Lê Hữu Tuấn'), findsWidgets);
    expect(find.text('✓ Đã Kích Hoạt'), findsWidgets);
    expect(find.text('Chờ Kích Hoạt'), findsWidgets);
  });

  testWidgets('ClanInvitesScreen renders mobile elements properly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockPositionLinkRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          positionLinkRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ClanInvitesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check mobile card list renders items
    expect(find.text('Cấp Mã Mời & Khởi Tạo Hồ Sơ Gia Phả'), findsOneWidget);
    expect(find.text('LE-CHI2-DOI5-9821'), findsOneWidget);
    expect(find.text('LE-CHI2-DOI5-7731'), findsOneWidget);
  });
}
