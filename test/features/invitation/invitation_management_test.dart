import 'package:familyfund_app/features/invitation/data/models/invitation_management_models.dart';
import 'package:familyfund_app/features/invitation/data/models/position_link_models.dart';
import 'package:familyfund_app/features/invitation/data/repositories/position_link_repository_impl.dart';
import 'package:familyfund_app/features/invitation/domain/repositories/position_link_repository.dart';
import 'package:familyfund_app/features/invitation/presentation/providers/position_link_providers.dart';
import 'package:familyfund_app/features/invitation/presentation/widgets/create_general_invite_dialog.dart';
import 'package:familyfund_app/features/invitation/presentation/widgets/extend_invite_dialog.dart';
import 'package:familyfund_app/features/invitation/presentation/widgets/issued_codes_mobile_list.dart';
import 'package:familyfund_app/features/invitation/presentation/widgets/issued_codes_table.dart';
import 'package:familyfund_app/features/invitation/presentation/widgets/revoke_invite_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockPositionLinkRepository implements PositionLinkRepository {
  List<PositionLinkItemModel> mockItems;

  MockPositionLinkRepository([List<PositionLinkItemModel>? initial])
      : mockItems = initial ??
            [
              PositionLinkItemModel(
                code: 'CHI2-DOI5-9821',
                branchId: 'chi-2',
                branchName: 'Chi 2',
                generation: 5,
                fullName: 'Lê Hữu Tuấn',
                issuedBy: 'Lê Văn Hùng (Trưởng Chi)',
                createdAt: DateTime(2026, 11, 1),
                isActivated: false,
                shareableUrl: 'https://familyfund.app/join?code=CHI2-DOI5-9821',
                maxUses: 1,
                usedCount: 0,
                expiresAt: DateTime.now().add(const Duration(days: 14)),
                isActive: true,
              ),
              PositionLinkItemModel(
                code: 'CHI2-GENERAL-88',
                branchId: 'chi-2',
                branchName: 'Chi 2',
                generation: 0,
                fullName: 'Mã Mời Nhánh Chi 2',
                issuedBy: 'Lê Văn Hùng',
                createdAt: DateTime(2026, 11, 5),
                isActivated: true,
                shareableUrl: 'https://familyfund.app/join?code=CHI2-GENERAL-88',
                maxUses: 10,
                usedCount: 10,
                expiresAt: DateTime.now().add(const Duration(days: 5)),
                isActive: true,
                inviteType: 'GeneralInviteCode',
              ),
              PositionLinkItemModel(
                code: 'CHI1-EXPIRED-01',
                branchId: 'chi-1',
                branchName: 'Chi 1',
                generation: 4,
                fullName: 'Lê Văn Minh',
                issuedBy: 'Lê Văn An',
                createdAt: DateTime(2026, 10, 1),
                isActivated: false,
                shareableUrl: 'https://familyfund.app/join?code=CHI1-EXPIRED-01',
                maxUses: 1,
                usedCount: 0,
                expiresAt: DateTime.now().subtract(const Duration(days: 2)),
                isActive: true,
              ),
              PositionLinkItemModel(
                code: 'REVOKED-CODE-99',
                branchId: 'chi-3',
                branchName: 'Chi 3',
                generation: 3,
                fullName: 'Lê Tuấn Tú',
                issuedBy: 'Lê Văn Cường',
                createdAt: DateTime(2026, 10, 10),
                isActivated: false,
                shareableUrl: 'https://familyfund.app/join?code=REVOKED-CODE-99',
                maxUses: 5,
                usedCount: 2,
                expiresAt: DateTime.now().add(const Duration(days: 20)),
                isActive: false,
              ),
            ];

  @override
  Future<CreateVirtualMemberResponseDto> createVirtualMember({
    required String branchId,
    required CreateVirtualMemberRequestDto request,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PositionLinkItemModel>> getIssuedPositionLinks() async {
    return List.from(mockItems);
  }

  @override
  Future<PositionLinkPreviewDto> getPositionLinkPreview(
      String inviteCode) async {
    throw UnimplementedError();
  }

  @override
  Future<ClaimPositionResponseDto> claimPosition({
    required String inviteCode,
    required ClaimPositionRequestDto request,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PositionLinkItemModel> createGeneralInvite(
      CreateGeneralInviteRequestDto request) async {
    final newItem = PositionLinkItemModel(
      code: 'GEN-${DateTime.now().millisecondsSinceEpoch % 10000}',
      branchId: request.targetBranchId ?? 'clan-root',
      branchName: request.targetBranchId != null ? 'Chi Cụ Thể' : 'Toàn Tộc',
      generation: 0,
      fullName: 'Mã Mời Chung Gia Phả',
      issuedBy: 'Trưởng Tộc',
      createdAt: DateTime.now(),
      isActivated: false,
      shareableUrl: 'https://familyfund.app/join?code=GEN-NEW',
      maxUses: request.maxUses,
      usedCount: 0,
      expiresAt: DateTime.now().add(Duration(days: request.validityDays)),
      isActive: true,
      inviteType: 'GeneralInviteCode',
    );
    mockItems.insert(0, newItem);
    return newItem;
  }

  @override
  Future<void> deactivateInvite(String inviteCode) async {
    final index = mockItems.indexWhere((i) => i.code == inviteCode);
    if (index != -1) {
      mockItems[index] = mockItems[index].copyWith(isActive: false);
    }
  }

  @override
  Future<PositionLinkItemModel> updateInvite(
      String inviteCode, UpdateInvitationRequestDto request) async {
    final index = mockItems.indexWhere((i) => i.code == inviteCode);
    if (index != -1) {
      final updated = mockItems[index].copyWith(
        isActive: request.isActive ?? mockItems[index].isActive,
        expiresAt: request.expiresAt ?? mockItems[index].expiresAt,
        maxUses: request.maxUses ?? mockItems[index].maxUses,
      );
      mockItems[index] = updated;
      return updated;
    }
    throw Exception('Invite not found');
  }

  @override
  Future<PositionLinkItemModel> regenerateInvite(String inviteCode,
      {UpdateInvitationRequestDto? request}) async {
    final index = mockItems.indexWhere((i) => i.code == inviteCode);
    final target = index != -1 ? mockItems[index] : mockItems.first;
    final replacement = target.copyWith(
      code: 'REGEN-9999',
      isActive: true,
      usedCount: 0,
      maxUses: request?.maxUses ?? target.maxUses,
      expiresAt: DateTime.now().add(Duration(days: request?.validityDays ?? 30)),
    );
    if (index != -1) {
      mockItems[index] = replacement;
    }
    return replacement;
  }
}

void main() {
  group('US-34 Invitation Management Unit & Model Tests', () {
    test('InvitationCodeStatus calculation matches lifecycle rules', () {
      final now = DateTime.now();

      // 1. Revoked (isActive == false)
      final revokedItem = PositionLinkItemModel(
        code: 'REV-01',
        branchId: 'b1',
        branchName: 'Branch 1',
        generation: 1,
        fullName: 'Test User',
        issuedBy: 'Admin',
        createdAt: now,
        isActivated: false,
        shareableUrl: 'url',
        maxUses: 10,
        usedCount: 1,
        isActive: false,
      );
      expect(revokedItem.status, InvitationCodeStatus.revoked);
      expect(revokedItem.isRevoked, isTrue);

      // 2. Used Up (usedCount >= maxUses)
      final usedUpItem = PositionLinkItemModel(
        code: 'USED-01',
        branchId: 'b1',
        branchName: 'Branch 1',
        generation: 1,
        fullName: 'Test User',
        issuedBy: 'Admin',
        createdAt: now,
        isActivated: true,
        shareableUrl: 'url',
        maxUses: 5,
        usedCount: 5,
        isActive: true,
      );
      expect(usedUpItem.status, InvitationCodeStatus.usedUp);
      expect(usedUpItem.isUsedUp, isTrue);

      // 3. Expired (expiresAt is before now)
      final expiredItem = PositionLinkItemModel(
        code: 'EXP-01',
        branchId: 'b1',
        branchName: 'Branch 1',
        generation: 1,
        fullName: 'Test User',
        issuedBy: 'Admin',
        createdAt: now,
        isActivated: false,
        shareableUrl: 'url',
        maxUses: 10,
        usedCount: 2,
        expiresAt: now.subtract(const Duration(days: 1)),
        isActive: true,
      );
      expect(expiredItem.status, InvitationCodeStatus.expired);
      expect(expiredItem.isExpired, isTrue);

      // 4. Active (isActive == true && usedCount < maxUses && not expired)
      final activeItem = PositionLinkItemModel(
        code: 'ACT-01',
        branchId: 'b1',
        branchName: 'Branch 1',
        generation: 1,
        fullName: 'Test User',
        issuedBy: 'Admin',
        createdAt: now,
        isActivated: false,
        shareableUrl: 'url',
        maxUses: 10,
        usedCount: 2,
        expiresAt: now.add(const Duration(days: 7)),
        isActive: true,
      );
      expect(activeItem.status, InvitationCodeStatus.active);
      expect(activeItem.isRevoked, isFalse);
      expect(activeItem.isExpired, isFalse);
      expect(activeItem.isUsedUp, isFalse);
    });

    test('CreateGeneralInviteRequestDto serializes correctly', () {
      const dto = CreateGeneralInviteRequestDto(
        targetBranchId: 'chi-2',
        maxUses: 25,
        validityDays: 14,
      );
      final json = dto.toJson();
      expect(json['targetBranchId'], 'chi-2');
      expect(json['maxUses'], 25);
      expect(json['validityDays'], 14);
    });

    test('UpdateInvitationRequestDto serializes correctly', () {
      final expiry = DateTime.utc(2026, 12, 31);
      final dto = UpdateInvitationRequestDto(
        isActive: true,
        validityDays: 30,
        maxUses: 50,
        expiresAt: expiry,
      );
      final json = dto.toJson();
      expect(json['isActive'], isTrue);
      expect(json['validityDays'], 30);
      expect(json['maxUses'], 50);
      expect(json['expiresAt'], '2026-12-31T00:00:00.000Z');
    });
  });

  group('ClanInvitesNotifier Actions Tests', () {
    late ProviderContainer container;
    late MockPositionLinkRepository mockRepo;

    setUp(() {
      mockRepo = MockPositionLinkRepository();
      container = ProviderContainer(
        overrides: [
          positionLinkRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('loadInitialData loads issued codes and calculates status counts', () async {
      final notifier = container.read(clanInvitesProvider.notifier);
      await notifier.loadInitialData();

      final state = container.read(clanInvitesProvider);
      expect(state.issuedCodes.length, 4);
      expect(state.activeCount, 1);
      expect(state.usedUpCount, 1);
      expect(state.expiredCount, 1);
      expect(state.revokedCount, 1);
    });

    test('deactivateInvite sets code to revoked', () async {
      final notifier = container.read(clanInvitesProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.deactivateInvite('CHI2-DOI5-9821');
      expect(success, isTrue);

      final state = container.read(clanInvitesProvider);
      final target = state.issuedCodes.firstWhere((i) => i.code == 'CHI2-DOI5-9821');
      expect(target.isActive, isFalse);
      expect(target.status, InvitationCodeStatus.revoked);
      expect(state.successMessage, contains('Đã thu hồi mã mời CHI2-DOI5-9821'));
    });

    test('extendInvite extends expiration and bumps max uses', () async {
      final notifier = container.read(clanInvitesProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.extendInvite(
        'CHI1-EXPIRED-01',
        additionalDays: 30,
        newMaxUses: 15,
      );
      expect(success, isTrue);

      final state = container.read(clanInvitesProvider);
      final target = state.issuedCodes.firstWhere((i) => i.code == 'CHI1-EXPIRED-01');
      expect(target.maxUses, 15);
      expect(target.isExpired, isFalse);
      expect(target.status, InvitationCodeStatus.active);
    });

    test('createGeneralInvite prepends new item to list', () async {
      final notifier = container.read(clanInvitesProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.createGeneralInvite(
        targetBranchId: 'chi-2',
        maxUses: 20,
        validityDays: 30,
      );
      expect(success, isTrue);

      final state = container.read(clanInvitesProvider);
      expect(state.issuedCodes.length, 5);
      expect(state.issuedCodes.first.maxUses, 20);
      expect(state.issuedCodes.first.inviteType, 'GeneralInviteCode');
    });

    test('regenerateInvite replaces revoked code with fresh active code', () async {
      final notifier = container.read(clanInvitesProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.regenerateInvite('REVOKED-CODE-99');
      expect(success, isTrue);

      final state = container.read(clanInvitesProvider);
      expect(state.issuedCodes.any((i) => i.code == 'REGEN-9999'), isTrue);
    });

    test('setCodeStatusFilter filters codes by selected status', () async {
      final notifier = container.read(clanInvitesProvider.notifier);
      await notifier.loadInitialData();

      notifier.setCodeStatusFilter(InvitationCodeStatus.usedUp);
      var state = container.read(clanInvitesProvider);
      expect(state.filteredCodes.length, 1);
      expect(state.filteredCodes.first.code, 'CHI2-GENERAL-88');

      notifier.setCodeStatusFilter(InvitationCodeStatus.active);
      state = container.read(clanInvitesProvider);
      expect(state.filteredCodes.length, 1);
      expect(state.filteredCodes.first.code, 'CHI2-DOI5-9821');

      notifier.setCodeStatusFilter(null);
      state = container.read(clanInvitesProvider);
      expect(state.filteredCodes.length, 4);
    });
  });

  group('US-34 Widget Tests: Table, Dialogs, Mobile Cards', () {
    testWidgets('IssuedCodesTable displays columns, usage fraction and action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockPositionLinkRepository();
      final items = await repo.getIssuedPositionLinks();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionLinkRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: IssuedCodesTable(items: items),
            ),
          ),
        ),
      );

      // Verify Column headers
      expect(find.text('MÃ MỜI'), findsOneWidget);
      expect(find.text('LOẠI MÃ'), findsOneWidget);
      expect(find.text('SỐ LƯỢT DÙNG (USED / MAX)'), findsOneWidget);
      expect(find.text('TRẠNG THÁI'), findsOneWidget);
      expect(find.text('THAO TÁC'), findsOneWidget);

      // Verify Usage Count Display
      expect(find.text('0 / 1 lượt'), findsNWidgets(2));
      expect(find.text('10 / 10 lượt'), findsOneWidget);
      expect(find.text('2 / 5 lượt'), findsOneWidget);

      // Verify Status Badges
      expect(find.text('Hoạt Động'), findsOneWidget);
      expect(find.text('Đã Dùng Hết'), findsOneWidget);
      expect(find.text('Hết Hạn'), findsOneWidget);
      expect(find.text('Đã Thu Hồi'), findsOneWidget);

      // Verify Action buttons (Gia Hạn, Thu Hồi)
      expect(find.text('Gia Hạn'), findsWidgets);
      expect(find.text('Thu Hồi'), findsOneWidget);
    });

    testWidgets('IssuedCodesMobileList renders cleanly on 390x844 with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockPositionLinkRepository();
      final items = await repo.getIssuedPositionLinks();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionLinkRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: IssuedCodesMobileList(items: items),
              ),
            ),
          ),
        ),
      );

      // Assert items render
      expect(find.text('CHI2-DOI5-9821'), findsOneWidget);
      expect(find.text('CHI2-GENERAL-88'), findsOneWidget);
      expect(find.text('Lê Hữu Tuấn'), findsOneWidget);

      // Usage text
      expect(find.text('0 / 1 lượt'), findsNWidgets(2));
      expect(find.text('10 / 10 lượt'), findsOneWidget);

      // Status badges
      expect(find.text('Hoạt Động'), findsOneWidget);
      expect(find.text('Đã Dùng Hết'), findsOneWidget);

      // No RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('RevokeInviteDialog opens and confirms deactivation',
        (tester) async {
      final repo = MockPositionLinkRepository();
      final items = await repo.getIssuedPositionLinks();
      final target = items.first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionLinkRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => RevokeInviteDialog.show(context, item: target),
                  child: const Text('Mở Modal Thu Hồi'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Modal Thu Hồi'));
      await tester.pumpAndSettle();

      expect(find.text('Thu Hồi Mã Mời Gia Phả'), findsOneWidget);
      expect(find.text(target.code), findsOneWidget);
      expect(find.text('Xác Nhận Thu Hồi'), findsOneWidget);

      await tester.tap(find.text('Xác Nhận Thu Hồi'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Thu Hồi Mã Mời Gia Phả'), findsNothing);
    });

    testWidgets('ExtendInviteDialog opens and confirms extension',
        (tester) async {
      final repo = MockPositionLinkRepository();
      final items = await repo.getIssuedPositionLinks();
      final target = items[1]; // used up code

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionLinkRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ExtendInviteDialog.show(context, item: target),
                  child: const Text('Mở Modal Gia Hạn'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Modal Gia Hạn'));
      await tester.pumpAndSettle();

      expect(find.text('Gia Hạn Mã Mời Gia Phả'), findsOneWidget);
      expect(find.text(target.code), findsOneWidget);
      expect(find.text('+30 ngày'), findsOneWidget);
      expect(find.text('+90 ngày'), findsOneWidget);
      expect(find.text('Xác Nhận Gia Hạn'), findsOneWidget);

      // Select +90 ngày
      await tester.tap(find.text('+90 ngày'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xác Nhận Gia Hạn'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Gia Hạn Mã Mời Gia Phả'), findsNothing);
    });

    testWidgets('CreateGeneralInviteDialog opens and creates invite',
        (tester) async {
      final repo = MockPositionLinkRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            positionLinkRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => CreateGeneralInviteDialog.show(context),
                  child: const Text('Mở Modal Tạo Mã Mới'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mở Modal Tạo Mã Mới'));
      await tester.pumpAndSettle();

      expect(find.text('Tạo Mã Mời Gia Phả Mới'), findsOneWidget);
      expect(find.text('50 lượt'), findsOneWidget);
      expect(find.text('14 ngày'), findsOneWidget);
      expect(find.text('Tạo Mã Mời Ngay'), findsOneWidget);

      // Select 50 lượt
      await tester.tap(find.text('50 lượt'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo Mã Mời Ngay'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.text('Tạo Mã Mời Gia Phả Mới'), findsNothing);
    });
  });
}
