import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/features/genealogy/data/models/branch_models.dart';
import 'package:familyfund_app/features/genealogy/presentation/providers/genealogy_providers.dart';
import 'package:familyfund_app/features/genealogy/presentation/widgets/branch_detail_sidebar.dart';
import 'package:familyfund_app/features/home/presentation/screens/home_screen.dart';
import 'package:familyfund_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockDualRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _initial;
  MockDualRbacNotifier(this._initial);

  @override
  DualRbacSession build() => _initial;
}

void main() {
  const rootBranch = BranchUiDetail(
    id: 'BR_ROOT',
    name: 'Chi Gốc (Đại Tôn)',
    badge: 'CỤ KHỞI TỔ • ĐỜI 1',
    code: 'BR_ROOT',
    representative: 'Nguyễn Trọng Hoàng',
    representativeSubtext: 'Trưởng Tộc • Đại diện Dòng họ',
    representativeId: 'MEM_TRUONG_TOC',
    memberCount: 10,
    activatedMemberCount: 10,
    fundAmount: '50.000.000 đ',
    description: 'Chi nhánh gốc khởi lập.',
    isRoot: true,
  );

  const chi2Branch = BranchUiDetail(
    id: 'BR_CHI_2',
    name: 'Chi 2 - Nhánh Giáp',
    badge: 'CHI ĐỜI 2',
    code: 'BR_CHI_2',
    representative: 'Nguyễn Văn An',
    representativeSubtext: 'Trưởng Chi 2 • Đời 2',
    representativeId: 'MEM_TRUONG_CHI',
    memberCount: 5,
    activatedMemberCount: 5,
    fundAmount: '12.000.000 đ',
    description: 'Chi nhánh thứ hai.',
    isRoot: false,
    members: [
      BranchMemberItem(
        memberId: 'MEM_TRUONG_CHI',
        fullName: 'Nguyễn Văn An',
        generation: 2,
        roleInBranch: 'Trưởng Chi 2',
        isActivated: true,
      ),
      BranchMemberItem(
        memberId: 'MEM_MAI_ANH',
        fullName: 'Nguyễn Thị Mai Anh',
        generation: 3,
        roleInBranch: 'Thành viên • Đời 3',
        isActivated: true,
      ),
    ],
  );

  const chi3Branch = BranchUiDetail(
    id: 'BR_CHI_3',
    name: 'Chi 3 - Nhánh Ất',
    badge: 'CHI ĐỜI 2',
    code: 'BR_CHI_3',
    representative: 'Nguyễn Văn Bình',
    representativeSubtext: 'Trưởng Chi 3 • Đời 2',
    representativeId: 'MEM_TRUONG_CHI_3',
    memberCount: 3,
    activatedMemberCount: 3,
    fundAmount: '5.000.000 đ',
    description: 'Chi nhánh thứ ba.',
    isRoot: false,
  );

  group('[US-23] Unit Tests: DualRbacSession.canManageBranch Scope Logic', () {
    test('ROLE_CLAN_HEAD has full management rights on all branches', () {
      const clanHeadSession = DualRbacSession(
        accountId: 'ACC_TRUONG_TOC',
        memberId: 'MEM_TRUONG_TOC',
        fullName: 'Nguyễn Trọng Hoàng',
        branchName: 'Chi Gốc (Đại Tôn)',
        globalRoles: {SystemRole.roleClanHead},
      );

      expect(
        clanHeadSession.canManageBranch(
          branchId: rootBranch.id,
          representativeId: rootBranch.representativeId,
        ),
        isTrue,
      );

      expect(
        clanHeadSession.canManageBranch(
          branchId: chi2Branch.id,
          representativeId: chi2Branch.representativeId,
        ),
        isTrue,
      );

      expect(
        clanHeadSession.getBranchActionDeniedReason(
          branchId: chi2Branch.id,
          representativeId: chi2Branch.representativeId,
        ),
        isNull,
      );
    });

    test('ROLE_BRANCH_HEAD only has rights within their assigned branch', () {
      const branchHeadSession = DualRbacSession(
        accountId: 'ACC_TRUONG_CHI',
        memberId: 'MEM_TRUONG_CHI',
        fullName: 'Nguyễn Văn An',
        branchName: 'Chi 2 - Nhánh Giáp',
        managedBranchId: 'BR_CHI_2',
        globalRoles: {SystemRole.roleBranchHead},
      );

      // 1. Quản lý Chi 2 (chi nhánh phụ trách) -> Cho phép
      expect(
        branchHeadSession.canManageBranch(
          branchId: chi2Branch.id,
          representativeId: chi2Branch.representativeId,
        ),
        isTrue,
      );
      expect(
        branchHeadSession.getBranchActionDeniedReason(
          branchId: chi2Branch.id,
          representativeId: chi2Branch.representativeId,
        ),
        isNull,
      );

      // 2. Thao tác trên Chi Gốc (ngoài phạm vi) -> Bị từ chối
      expect(
        branchHeadSession.canManageBranch(
          branchId: rootBranch.id,
          representativeId: rootBranch.representativeId,
        ),
        isFalse,
      );
      final deniedRootReason = branchHeadSession.getBranchActionDeniedReason(
        branchId: rootBranch.id,
        representativeId: rootBranch.representativeId,
        actionName: 'thêm thành viên',
      );
      expect(deniedRootReason, contains('ROLE_BRANCH_HEAD'));
      expect(deniedRootReason, contains('phạm vi chi nhánh bạn đại diện quản lý'));

      // 3. Thao tác trên Chi 3 (chi khác) -> Bị từ chối
      expect(
        branchHeadSession.canManageBranch(
          branchId: chi3Branch.id,
          representativeId: chi3Branch.representativeId,
        ),
        isFalse,
      );
    });

    test('ROLE_MEMBER has read-only access (cannot manage any branch)', () {
      const memberSession = DualRbacSession(
        accountId: 'ACC_MEMBER',
        memberId: 'MEM_MAI_ANH',
        fullName: 'Nguyễn Thị Mai Anh',
        branchName: 'Chi 2 - Nhánh Giáp',
        globalRoles: {SystemRole.roleMember},
      );

      expect(
        memberSession.canManageBranch(
          branchId: chi2Branch.id,
          representativeId: chi2Branch.representativeId,
        ),
        isFalse,
      );
      expect(
        memberSession.getBranchActionDeniedReason(
          branchId: chi2Branch.id,
          representativeId: chi2Branch.representativeId,
        ),
        contains('Bạn cần quyền Trưởng tộc hoặc Trưởng chi'),
      );
    });
  });

  const kClanHeadSession = DualRbacSession(
    accountId: 'ACC_TRUONG_TOC',
    memberId: 'MEM_TRUONG_TOC',
    fullName: 'Nguyễn Trọng Hoàng',
    branchName: 'Chi Gốc (Đại Tôn)',
    managedBranchId: 'BR_ROOT',
    globalRoles: {SystemRole.roleClanHead},
  );

  const kBranchHeadChi2Session = DualRbacSession(
    accountId: 'ACC_TRUONG_CHI',
    memberId: 'MEM_TRUONG_CHI',
    fullName: 'Nguyễn Văn An',
    branchName: 'Chi 2 - Nhánh Giáp',
    managedBranchId: 'BR_CHI_2',
    globalRoles: {SystemRole.roleBranchHead},
  );

  group('[US-23] Widget Tests: BranchDetailSidebar Action Buttons Guard', () {
    testWidgets(
      'Clan Head sees enabled action buttons on any branch without lock icons',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dualRbacSessionProvider.overrideWith(() => MockDualRbacNotifier(kClanHeadSession)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BranchDetailSidebar(
                  branch: chi2Branch,
                  onClose: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Kiểm tra 3 nút Thêm / Sửa / Điều chuyển xuất hiện
        expect(find.text('QUẢN TRỊ CHI NHÁNH:'), findsOneWidget);
        expect(find.text('Thêm Thành Viên Vào Chi'), findsOneWidget);
        expect(find.text('Chỉnh Sửa Thông Tin Chi'), findsOneWidget);
        expect(find.text('Điều Chuyển Thành Viên / Chi'), findsOneWidget);

        // 2. Không có biểu tượng ổ khóa
        expect(find.byIcon(Icons.lock_outline), findsNothing);

        // 3. Không có banner cảnh báo phạm vi
        expect(find.textContaining('Phạm vi chỉ đọc'), findsNothing);
      },
    );

    testWidgets(
      'Branch Head viewing OWN branch sees enabled buttons',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dualRbacSessionProvider.overrideWith(() => MockDualRbacNotifier(kBranchHeadChi2Session)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BranchDetailSidebar(
                  branch: chi2Branch,
                  onClose: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Nút sáng, không có icon ổ khóa
        expect(find.text('Thêm Thành Viên Vào Chi'), findsOneWidget);
        expect(find.text('Chỉnh Sửa Thông Tin Chi'), findsOneWidget);
        expect(find.text('Điều Chuyển Thành Viên / Chi'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsNothing);
        expect(find.textContaining('Phạm vi chỉ đọc'), findsNothing);
      },
    );

    testWidgets(
      'Branch Head viewing FOREIGN branch has buttons locked (disabled) with lock icon & alert banner',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dualRbacSessionProvider.overrideWith(() => MockDualRbacNotifier(kBranchHeadChi2Session)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BranchDetailSidebar(
                  branch: rootBranch, // Xem Chi Gốc (ngoài phạm vi của Trưởng Chi 2)
                  onClose: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Alert Banner cảnh báo phạm vi xuất hiện
        expect(
          find.textContaining('Phạm vi chỉ đọc: Bạn đang xem chi nhánh ngoài phạm vi phụ trách'),
          findsOneWidget,
        );

        // 2. Các nút thao tác ngoài phạm vi đều có icon ổ khóa
        expect(find.byIcon(Icons.lock_outline), findsAtLeastNWidgets(3));

        // 3. Nhấp vào nút bị khóa -> Hiển thị SnackBar giải thích lý do
        final addButton = find.text('Thêm Thành Viên Vào Chi');
        expect(addButton, findsOneWidget);
        await tester.tap(addButton);
        await tester.pump();

        expect(
          find.textContaining('Thao tác bị giới hạn: Bạn chỉ có quyền'),
          findsOneWidget,
        );
      },
    );
  });

  group('[US-23] Widget Tests: HomeScreen Live Role Simulation & Tree Interaction', () {
    const kMockBranchTree = BranchTreeNodeDto(
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

    testWidgets(
      'Switching persona to Branch Head 2 immediately locks root branch actions',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              initialLocationProvider.overrideWithValue('/home'),
              branchTreeProvider.overrideWith((ref) => Future.value(kMockBranchTree)),
              branchMembersProvider('BR_ROOT').overrideWith((ref) => Future.value([])),
              branchMembersProvider('BR_CHI_2').overrideWith((ref) => Future.value([])),
            ],
            child: const FamilyFundApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);

        // 1. Kiểm tra Demo Bar US-23 xuất hiện
        expect(find.text('GIẢ LẬP VAI TRÒ (US-23):'), findsOneWidget);
        final branchHeadChip = find.text('Trưởng Chi 2 (Chỉ quản lý Chi 2)');
        expect(branchHeadChip, findsOneWidget);

        // 2. Chuyển sang Trưởng Chi 2
        await tester.tap(branchHeadChip);
        await tester.pumpAndSettle();

        // 3. Khi đang xem Chi Gốc (mặc định), các nút trong Sidebar lập tức bị khóa và có ổ khóa
        expect(find.byIcon(Icons.lock_outline), findsWidgets);
        expect(find.textContaining('Phạm vi chỉ đọc'), findsOneWidget);
      },
    );
  });
}
