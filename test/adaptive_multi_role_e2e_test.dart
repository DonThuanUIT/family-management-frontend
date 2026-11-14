import 'package:dio/dio.dart';
import 'package:familyfund_app/core/router/app_router.dart';
import 'package:familyfund_app/core/security/rbac_models.dart';
import 'package:familyfund_app/core/storage/secure_token_storage.dart';
import 'package:familyfund_app/features/audit/data/models/audit_log_models.dart';
import 'package:familyfund_app/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:familyfund_app/features/audit/domain/repositories/audit_repository.dart';
import 'package:familyfund_app/features/audit/presentation/widgets/diff_viewer_dialog.dart';
import 'package:familyfund_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:familyfund_app/features/auth/data/models/auth_models.dart';
import 'package:familyfund_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:familyfund_app/features/contribution/data/models/branch_recursive_contribution_models.dart';
import 'package:familyfund_app/features/contribution/presentation/widgets/branch_contribution_breakdown_bottom_sheet.dart';
import 'package:familyfund_app/features/event/data/datasources/event_remote_datasource.dart';
import 'package:familyfund_app/features/event/data/models/event_budget_models.dart';
import 'package:familyfund_app/features/event/data/models/event_models.dart';
import 'package:familyfund_app/features/event/data/repositories/event_repository_impl.dart';
import 'package:familyfund_app/features/event/domain/repositories/event_repository.dart';
import 'package:familyfund_app/features/event/presentation/providers/event_providers.dart';
import 'package:familyfund_app/features/event/presentation/widgets/create_event_sheet.dart';
import 'package:familyfund_app/features/event/presentation/widgets/edit_event_sheet.dart';
import 'package:familyfund_app/features/event/presentation/widgets/event_budget_hero_card.dart';
import 'package:familyfund_app/features/event/presentation/widgets/task_budget_breakdown_section.dart';
import 'package:familyfund_app/features/genealogy/data/models/branch_models.dart';
import 'package:familyfund_app/features/genealogy/presentation/providers/genealogy_providers.dart';
import 'package:familyfund_app/features/genealogy/presentation/widgets/branch_detail_sidebar.dart';
import 'package:familyfund_app/features/home/presentation/screens/home_screen.dart';
import 'package:familyfund_app/features/role/data/models/role_models.dart';
import 'package:familyfund_app/features/role/data/repositories/role_repository_impl.dart';
import 'package:familyfund_app/features/role/domain/repositories/role_repository.dart';
import 'package:familyfund_app/features/role/presentation/widgets/assign_role_bottom_sheet.dart';
import 'package:familyfund_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes matching backend V6__seed_demo_accounts_and_test_data.sql
// ---------------------------------------------------------------------------

class InMemorySecureTokenStorage extends SecureTokenStorage {
  final Map<String, String> _store = {};

  InMemorySecureTokenStorage({super.onSessionChanged})
      : super(const FlutterSecureStorage());

  @override
  Future<void> saveAccessToken(String token) async {
    _store['access_token'] = token;
    onSessionChanged?.call();
  }

  @override
  Future<String?> getAccessToken() async => _store['access_token'];

  @override
  Future<void> saveActiveClanId(String clanId) async {
    _store['active_clan_id'] = clanId;
    onSessionChanged?.call();
  }

  @override
  Future<String?> getActiveClanId() async => _store['active_clan_id'];

  @override
  Future<void> clearAll() async {
    _store.clear();
    onSessionChanged?.call();
  }
}

class FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  FakeAuthRemoteDataSource() : super(Dio());

  @override
  Future<AuthTokenResponseDto> login(LoginRequestDto request) async {
    final id = request.loginIdentifier.trim();
    final pass = request.password.trim();

    for (final demo in kDemoAccounts) {
      if (demo.identifier == id && demo.password == pass) {
        return AuthTokenResponseDto(
          accessToken: 'jwt_token_${demo.accountId}',
          refreshToken: 'refresh_${demo.accountId}',
          tokenType: 'Bearer',
          expiresIn: 3600,
          accountId: demo.accountId,
          phoneNumber: demo.identifier,
          email: '${demo.accountId.toLowerCase()}@gtvn.vn',
          fullName: demo.fullName,
          clanId: demo.clanId,
          memberId: demo.memberId,
          roles: demo.roles,
        );
      }
    }
    throw Exception('Sai số điện thoại hoặc mật khẩu');
  }
}

const _kE2eBranchTree = BranchTreeNodeDto(
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

const _kRootBranchUi = BranchUiDetail(
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

const _kChi2BranchUi = BranchUiDetail(
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
);

class _E2eRoleRepository implements RoleRepository {
  final RoleManagementOverviewModel _overview = const RoleManagementOverviewModel(
    clanId: 'CLAN_DEFAULT',
    branches: [
      BranchRoleOverviewModel(
        branchId: 'BR_ROOT',
        branchName: 'Chi Gốc (Đại Tôn)',
        generationLevel: 1,
        representativeMemberId: 'MEM_TRUONG_TOC',
        representativeFullName: 'Nguyễn Trọng Hoàng',
        representativeAccountId: 'ACC_TRUONG_TOC',
      ),
      BranchRoleOverviewModel(
        branchId: 'BR_CHI_2',
        branchName: 'Chi 2 - Nhánh Giáp',
        generationLevel: 2,
        representativeMemberId: 'MEM_TRUONG_CHI',
        representativeFullName: 'Nguyễn Văn An',
        representativeAccountId: 'ACC_TRUONG_CHI',
      ),
      BranchRoleOverviewModel(
        branchId: 'BR_CHI_3',
        branchName: 'Chi 3 - Nhánh Ất',
        generationLevel: 2,
      ),
    ],
    members: [
      MemberRoleOptionModel(
        memberId: 'MEM_TRUONG_TOC',
        fullName: 'Nguyễn Trọng Hoàng',
        branchId: 'BR_ROOT',
        branchName: 'Chi Gốc',
        hasActiveAccount: true,
        accountId: 'ACC_TRUONG_TOC',
      ),
      MemberRoleOptionModel(
        memberId: 'MEM_TRUONG_CHI',
        fullName: 'Nguyễn Văn An',
        branchId: 'BR_CHI_2',
        branchName: 'Chi 2',
        hasActiveAccount: true,
        accountId: 'ACC_TRUONG_CHI',
      ),
    ],
  );

  final List<AuditLogModel> _logs = [
    AuditLogModel(
      auditId: 'AUD_E2E_01',
      clanId: 'CLAN_DEFAULT',
      actorFullName: 'Nguyễn Trọng Hoàng',
      targetFullName: 'Nguyễn Văn An',
      actionType: 'ASSIGN',
      roleCode: 'ROLE_BRANCH_HEAD',
      roleDisplayName: 'Trưởng Chi / Nhánh',
      scopeType: 'BRANCH',
      scopeId: 'BR_CHI_2',
      scopeName: 'Chi 2 - Nhánh Giáp',
      description: 'Bổ nhiệm Trưởng Chi 2',
      createdAt: DateTime(2026, 11, 10, 9, 0),
    ),
  ];

  @override
  Future<RoleManagementOverviewModel> getOverview() async => _overview;

  @override
  Future<List<AuditLogModel>> getAuditLogs({
    String? memberId,
    String? scopeType,
    String? scopeId,
  }) async =>
      List.from(_logs);

  @override
  Future<RoleAssignmentResponseDto> assignRole(
    RoleAssignmentRequestDto request,
  ) async {
    return RoleAssignmentResponseDto(
      memberId: request.memberId,
      roleCode: request.roleCode,
      scopeType: request.scopeType,
      scopeId: request.scopeId,
      actionType: 'ASSIGN',
      message: 'Thành công',
    );
  }

  @override
  Future<RoleAssignmentResponseDto> revokeRole(
    RoleRevocationRequestDto request,
  ) async {
    return RoleAssignmentResponseDto(
      memberId: request.memberId,
      roleCode: request.roleCode,
      scopeType: request.scopeType,
      scopeId: request.scopeId,
      actionType: 'REVOKE',
      message: 'Thu hồi thành công',
    );
  }
}

class _E2eEventRepository implements EventRepository {
  @override
  Future<List<EventModel>> getEvents() async => EventRemoteDataSource.mockEvents;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _E2eAuditRepository implements AuditRepository {
  @override
  Future<AuditLogPageResponse> getAuditLogs(AuditLogFilter filter) async {
    return AuditLogPageResponse(
      items: [
        AuditLogItemModel(
          auditId: 'AUD_E2E_99',
          actionType: 'ROLE_ASSIGN',
          entityType: 'ROLE',
          entityId: 'BR_CHI_2',
          actorAccountId: 'ACC_TRUONG_TOC',
          actorFullName: 'Nguyễn Trọng Hoàng',
          description: 'Bổ nhiệm Nguyễn Văn An làm Trưởng Chi 2',
          createdAt: DateTime(2026, 11, 12, 10, 30),
          hasDiff: true,
        ),
      ],
      page: 0,
      size: 20,
      totalElements: 1,
      totalPages: 1,
    );
  }

  @override
  Future<AuditLogDetailModel> getAuditLogDetail(String auditId) async {
    return AuditLogDetailModel(
      auditId: auditId,
      actionType: 'ROLE_ASSIGN',
      entityType: 'ROLE',
      entityId: 'BR_CHI_2',
      actorAccountId: 'ACC_TRUONG_TOC',
      actorFullName: 'Nguyễn Trọng Hoàng',
      targetMemberFullName: 'Nguyễn Văn An',
      description: 'Bổ nhiệm Trưởng Chi 2',
      oldValue: {'roleCode': 'ROLE_MEMBER'},
      newValue: {'roleCode': 'ROLE_BRANCH_HEAD'},
      createdAt: DateTime(2026, 11, 12, 10, 30),
    );
  }
}

const _kE2eBudget = EventBudgetSummaryModel(
  eventId: 'EVT_2026_GIOTO',
  eventName: 'Đại Lễ Giỗ Tiền Tổ & Thượng Điền',
  eventStatus: 'RegistrationOpen',
  estimatedBudget: 150000000.0,
  totalAdvanceBudget: 110000000.0,
  totalAdvanceAmount: 40000000.0,
  totalActualExpenseAmount: 85000000.0,
  verifiedActualExpenseAmount: 80000000.0,
  unallocatedBudget: 40000000.0,
  remainingBudgetByAdvance: 110000000.0,
  remainingBudgetByActualExpense: 65000000.0,
  overrunAmount: 0.0,
  taskBudgetUtilizationPercent: 73.3,
  advanceUtilizationPercent: 26.7,
  actualExpenseUtilizationPercent: 56.7,
  isOverBudget: false,
  isAdvanceOverEstimated: false,
  isActualExpenseOverEstimated: false,
  isTaskBudgetOverEstimated: false,
  hasTaskOverBudget: false,
  warningLevel: 'NORMAL',
  warningMessages: [],
  totalTaskCount: 1,
  totalAdvanceVoucherCount: 2,
  totalSettlementVoucherCount: 5,
  needsExplanationVoucherCount: 0,
  taskBreakdowns: [
    TaskBudgetBreakdownModel(
      taskId: 'TSK-01',
      taskName: 'Lễ Vật Hương Hoa & Mâm Cỗ',
      taskStatus: 'Ongoing',
      assignedMemberId: 'MEM_TRUONG_CHI',
      assignedBranchId: 'BR_CHI_2',
      advanceBudget: 80000000.0,
      advanceAmount: 30000000.0,
      actualExpenseAmount: 55000000.0,
      verifiedActualExpenseAmount: 50000000.0,
      advanceVoucherCount: 2,
      settlementVoucherCount: 4,
      needsExplanationCount: 0,
      advanceVariance: 50000000.0,
      actualExpenseVariance: 25000000.0,
      isAdvanceOverTaskBudget: false,
      isActualExpenseOverTaskBudget: false,
      isOverTaskBudget: false,
    ),
  ],
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

Future<void> _pumpFrames(WidgetTester tester, [int ms = 300]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

void main() {
  group('1. Auth & Onboarding Adaptive E2E (Mobile 390x844 & Desktop 1440x900)', () {
    testWidgets('WelcomeScreen & RegisterCreatorScreen adapt cleanly on Mobile & Desktop',
        (WidgetTester tester) async {
      _setViewport(tester, const Size(390, 844));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialLocationProvider.overrideWithValue('/welcome')],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile Welcome: 1-column (split showcase banner hidden)
      expect(find.text('Gia Tộc Việt Nam'), findsOneWidget);
      expect(find.text('KHỞI NGUỒN GIA TỘC'), findsNothing);

      // Resize to Desktop -> Editorial Heritage Split-Screen shows showcase panel
      _setViewport(tester, const Size(1440, 900));
      await tester.pumpAndSettle();
      expect(find.text('KHỞI NGUỒN GIA TỘC'), findsOneWidget);

      // Tap Tạo cây gia phả mới -> RegisterCreatorScreen
      await tester.tap(find.text('Tạo cây gia phả mới'));
      await tester.pumpAndSettle();
      expect(find.text('Khởi Lập Dòng Họ'), findsOneWidget);

      // Desktop (>= 960): Clan card & Creator card are side by side
      final card1Desktop =
          tester.getTopLeft(find.text('1. Thông Tin Dòng Họ'));
      final card2Desktop =
          tester.getTopLeft(find.text('2. Thông Tin Trưởng Tộc'));
      expect(card2Desktop.dx, greaterThan(card1Desktop.dx + 100));
      expect((card2Desktop.dy - card1Desktop.dy).abs(), lessThan(4.0));

      // Mobile (< 960): cards stack vertically
      _setViewport(tester, const Size(390, 844));
      await tester.pumpAndSettle();
      final card1Mobile =
          tester.getTopLeft(find.text('1. Thông Tin Dòng Họ'));
      final card2Mobile =
          tester.getTopLeft(find.text('2. Thông Tin Trưởng Tộc'));
      expect(card2Mobile.dy, greaterThan(card1Mobile.dy + 100));
    });

    testWidgets('LoginScreen demo quick-picker & ForgotPasswordScreen 3-step flow',
        (WidgetTester tester) async {
      _setViewport(tester, const Size(390, 844));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialLocationProvider.overrideWithValue('/login')],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile hides showcase banner and renders demo picker without overflow
      expect(find.text('CỔNG ĐĂNG NHẬP GIA PHẢ'), findsNothing);
      expect(find.text('Trưởng Tộc'), findsOneWidget);
      expect(find.text('Trưởng Chi 2'), findsOneWidget);
      expect(find.text('Thành Viên'), findsOneWidget);

      // Select Trưởng Chi 2 chip -> identifier changes to 0902345678
      await tester.ensureVisible(find.text('Trưởng Chi 2'));
      await tester.tap(find.text('Trưởng Chi 2'));
      await tester.pumpAndSettle();
      expect(find.text('0902345678'), findsOneWidget);

      // Select Thành Viên chip -> identifier changes to 0903888999
      await tester.ensureVisible(find.text('Thành Viên'));
      await tester.tap(find.text('Thành Viên'));
      await tester.pumpAndSettle();
      expect(find.text('0903888999'), findsOneWidget);

      // Switch to Desktop -> showcase banner appears
      _setViewport(tester, const Size(1440, 900));
      await tester.pumpAndSettle();
      expect(find.text('CỔNG ĐĂNG NHẬP GIA PHẢ'), findsOneWidget);

      // Navigate to Forgot Password and complete 3 steps
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập Số Điện Thoại'), findsOneWidget);

      await tester.tap(find.text('Gửi Mã Xác Thực'));
      await _pumpFrames(tester, 700);
      expect(find.text('Nhập Mã Xác Thực OTP'), findsOneWidget);

      await tester.tap(find.text('Xác Nhận OTP'));
      await _pumpFrames(tester, 700);
      expect(find.text('Thiết Lập Mật Khẩu Mới'), findsOneWidget);

      await tester.tap(find.text('Hoàn Tất Đặt Lại Mật Khẩu'));
      await _pumpFrames(tester, 700);
      expect(find.text('Đăng Nhập Gia Tộc'), findsOneWidget);
    });
  });

  group('2. Multi-Role Live Login & RBAC Verification (Trưởng Tộc, Trưởng Chi 2, Thành Viên)', () {
    Future<void> verifyLoginAndRbacFlow(
      WidgetTester tester, {
      required Size viewport,
      required String roleChipLabel,
      required String expectedFullName,
      required bool expectClanHead,
      required bool expectCanManageRoot,
      required bool expectCanManageChi2,
    }) async {
      _setViewport(tester, viewport);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey('${roleChipLabel}_${viewport.width.toInt()}'),
          overrides: [
            initialLocationProvider.overrideWithValue('/login'),
            authRemoteDataSourceProvider.overrideWithValue(
              FakeAuthRemoteDataSource(),
            ),
            secureTokenStorageProvider.overrideWith(
              (ref) => InMemorySecureTokenStorage(
                onSessionChanged: () {
                  ref.read(privateSessionRevisionProvider.notifier).advance();
                },
              ),
            ),
            branchTreeProvider.overrideWith((ref) => Future.value(_kE2eBranchTree)),
            branchMembersProvider('BR_ROOT').overrideWith((ref) => Future.value([])),
            branchMembersProvider('BR_CHI_2').overrideWith(
              (ref) => Future.value(const [
                BranchMemberItem(
                  memberId: 'MEM_MAI_ANH',
                  fullName: 'Nguyễn Thị Mai Anh',
                  generation: 3,
                  roleInBranch: 'Thành viên',
                ),
              ]),
            ),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Pick role & tap Login button
      final chip = find.text(roleChipLabel);
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      final loginBtn = find.text('Đăng Nhập Vào Dòng Họ');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // 2. Verify HomeScreen loaded with logged-in user
      expect(find.byType(HomeScreen), findsOneWidget);
      if (roleChipLabel != 'Thành Viên') {
        expect(find.text(expectedFullName), findsWidgets);
      }

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      final authState = container.read(authStateProvider);
      final session = container.read(dualRbacSessionProvider);
      expect(authState.user?.fullName, expectedFullName);
      expect(session.fullName, expectedFullName);
      expect(session.isClanHead, expectClanHead);

      // 3. Check RBAC UI in BranchDetailSidebar for BR_ROOT & BR_CHI_2
      expect(
        session.canManageBranch(
          branchId: _kRootBranchUi.id,
          representativeId: _kRootBranchUi.representativeId,
        ),
        expectCanManageRoot,
      );
      expect(
        session.canManageBranch(
          branchId: _kChi2BranchUi.id,
          representativeId: _kChi2BranchUi.representativeId,
        ),
        expectCanManageChi2,
      );
    }

    testWidgets('Login Trưởng Tộc (0901234567) on Desktop (1440x900) & Mobile (390x844)',
        (WidgetTester tester) async {
      await verifyLoginAndRbacFlow(
        tester,
        viewport: const Size(1440, 900),
        roleChipLabel: 'Trưởng Tộc',
        expectedFullName: 'Nguyễn Trọng Hoàng',
        expectClanHead: true,
        expectCanManageRoot: true,
        expectCanManageChi2: true,
      );

      await verifyLoginAndRbacFlow(
        tester,
        viewport: const Size(390, 844),
        roleChipLabel: 'Trưởng Tộc',
        expectedFullName: 'Nguyễn Trọng Hoàng',
        expectClanHead: true,
        expectCanManageRoot: true,
        expectCanManageChi2: true,
      );
    });

    testWidgets('Login Trưởng Chi 2 (0902345678) scopes permissions to BR_CHI_2 on Desktop & Mobile',
        (WidgetTester tester) async {
      await verifyLoginAndRbacFlow(
        tester,
        viewport: const Size(1440, 900),
        roleChipLabel: 'Trưởng Chi 2',
        expectedFullName: 'Nguyễn Văn An',
        expectClanHead: false,
        expectCanManageRoot: false,
        expectCanManageChi2: true,
      );

      await verifyLoginAndRbacFlow(
        tester,
        viewport: const Size(390, 844),
        roleChipLabel: 'Trưởng Chi 2',
        expectedFullName: 'Nguyễn Văn An',
        expectClanHead: false,
        expectCanManageRoot: false,
        expectCanManageChi2: true,
      );
    });

    testWidgets('Login Thành Viên (0903888999) enforces read-only scope on Desktop & Mobile',
        (WidgetTester tester) async {
      await verifyLoginAndRbacFlow(
        tester,
        viewport: const Size(1440, 900),
        roleChipLabel: 'Thành Viên',
        expectedFullName: 'Nguyễn Thị Mai Anh',
        expectClanHead: false,
        expectCanManageRoot: false,
        expectCanManageChi2: false,
      );

      await verifyLoginAndRbacFlow(
        tester,
        viewport: const Size(390, 844),
        roleChipLabel: 'Thành Viên',
        expectedFullName: 'Nguyễn Thị Mai Anh',
        expectClanHead: false,
        expectCanManageRoot: false,
        expectCanManageChi2: false,
      );
    });

    testWidgets('BranchDetailSidebar enforces lock icons strictly across 3 personas',
        (WidgetTester tester) async {
      _setViewport(tester, const Size(420, 844));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Trưởng Chi 2 viewing Chi Gốc -> locked
      const branchHeadSession = DualRbacSession(
        accountId: 'ACC_TRUONG_CHI',
        memberId: 'MEM_TRUONG_CHI',
        fullName: 'Nguyễn Văn An',
        branchName: 'Chi 2 - Nhánh Giáp',
        managedBranchId: 'BR_CHI_2',
        globalRoles: {SystemRole.roleBranchHead, SystemRole.roleMember},
      );

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('branch_head_scope'),
          overrides: [
            dualRbacSessionProvider.overrideWith(
              () => _FixedDualRbacNotifier(branchHeadSession),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BranchDetailSidebar(
                branch: _kRootBranchUi,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsAtLeastNWidgets(3));
      expect(find.textContaining('Phạm vi chỉ đọc'), findsOneWidget);

      // Thành Viên viewing Chi 2 -> locked
      const memberSession = DualRbacSession(
        accountId: 'ACC_MAI_ANH',
        memberId: 'MEM_MAI_ANH',
        fullName: 'Nguyễn Thị Mai Anh',
        branchName: 'Chi 2 - Nhánh Giáp',
        managedBranchId: '',
        globalRoles: {SystemRole.roleMember},
      );

      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('member_scope'),
          overrides: [
            dualRbacSessionProvider.overrideWith(
              () => _FixedDualRbacNotifier(memberSession),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BranchDetailSidebar(
                branch: _kChi2BranchUi,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_outline), findsAtLeastNWidgets(3));
      await tester.ensureVisible(find.text('Thêm Thành Viên Vào Chi'));
      await tester.tap(find.text('Thêm Thành Viên Vào Chi'));
      await _pumpFrames(tester, 200);
      expect(
        find.textContaining('Bạn cần quyền Trưởng tộc hoặc Trưởng chi'),
        findsOneWidget,
      );
    });
  });

  group('3. Events & Budget Adaptive E2E (Mobile 390x844 & Desktop 1440x900)', () {
    testWidgets('/events adapts layout, CreateEventSheet, and EditEventSheet on Mobile & Desktop',
        (WidgetTester tester) async {
      _setViewport(tester, const Size(390, 844));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialLocationProvider.overrideWithValue('/events')],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      // --- Mobile (390x844) ---
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Tap FAB -> CreateEventSheet opens as BottomSheet (NOT Dialog)
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(CreateEventSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      // Close BottomSheet
      Navigator.of(tester.element(find.byType(CreateEventSheet))).pop();
      await tester.pumpAndSettle();

      // Tap EventCard -> EventDetailDialog -> tap Đổi Lịch Trình -> EditEventSheet opens as BottomSheet
      await tester.tap(find.text('Đại Lễ Giỗ Tiền Tổ & Thượng Điền'));
      await _pumpFrames(tester, 300);
      expect(find.text('Đổi Lịch Trình'), findsOneWidget);

      await tester.ensureVisible(find.text('Đổi Lịch Trình'));
      await tester.tap(find.text('Đổi Lịch Trình'));
      await _pumpFrames(tester, 300);
      expect(find.byType(EditEventSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      Navigator.of(tester.element(find.byType(EditEventSheet))).pop();
      await _pumpFrames(tester, 300);

      // --- Desktop (1440x900) ---
      _setViewport(tester, const Size(1440, 900));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.text('Tạo Lễ Mới'), findsOneWidget);

      // Tap Tạo Lễ Mới -> CreateEventSheet inside Dialog
      await tester.tap(find.text('Tạo Lễ Mới'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateEventSheet), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      Navigator.of(tester.element(find.byType(CreateEventSheet))).pop();
      await tester.pumpAndSettle();

      // Tap EventCard -> EventDetailDialog -> tap Đổi Lịch Trình -> EditEventSheet inside Dialog
      await tester.tap(find.text('Đại Lễ Giỗ Tiền Tổ & Thượng Điền'));
      await _pumpFrames(tester, 300);
      await tester.ensureVisible(find.text('Đổi Lịch Trình'));
      await tester.tap(find.text('Đổi Lịch Trình'));
      await _pumpFrames(tester, 300);
      expect(find.byType(EditEventSheet), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('/events/:id/budget switches between Mobile 1-col footer and Desktop 2-col 5:7',
        (WidgetTester tester) async {
      _setViewport(tester, const Size(390, 844));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider
                .overrideWithValue('/events/EVT_2026_GIOTO/budget'),
            eventBudgetSummaryProvider('EVT_2026_GIOTO')
                .overrideWith((ref) async => _kE2eBudget),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile: HeroCard stacked ABOVE BreakdownSection
      final heroMobile = tester.getTopLeft(find.byType(EventBudgetHeroCard));
      final breakdownMobile =
          tester.getTopLeft(find.byType(TaskBudgetBreakdownSection));
      expect(breakdownMobile.dy, greaterThan(heroMobile.dy + 100));
      expect(find.text('Quản Lý Phiếu Chi (US-07)'), findsOneWidget);

      // Desktop (1440x900): 2-col side-by-side 5:7
      _setViewport(tester, const Size(1440, 900));
      await tester.pumpAndSettle();

      final heroDesktop = tester.getTopLeft(find.byType(EventBudgetHeroCard));
      final breakdownDesktop =
          tester.getTopLeft(find.byType(TaskBudgetBreakdownSection));
      expect(breakdownDesktop.dx, greaterThan(heroDesktop.dx + 200));
      expect((breakdownDesktop.dy - heroDesktop.dy).abs(), lessThan(8.0));
    });
  });

  group('4. Roles, Contribution Breakdown & Audit Log Adaptive E2E (Mobile & Desktop)', () {
    testWidgets('/roles switches 3 tabs and opens AssignRoleBottomSheet as Sheet (Mobile) & Dialog (Desktop)',
        (WidgetTester tester) async {
      _setViewport(tester, const Size(390, 844));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue('/roles'),
            roleRepositoryProvider.overrideWithValue(_E2eRoleRepository()),
            eventRepositoryProvider.overrideWithValue(_E2eEventRepository()),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile: iterate all 3 tabs
      expect(find.text('Chi Gốc (Đại Tôn)'), findsOneWidget);
      await tester.tap(find.text('BTC Sự Kiện'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhật Ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trưởng Chi'));
      await tester.pumpAndSettle();

      // Open AssignRoleBottomSheet on Mobile -> BottomSheet (no Dialog)
      await tester.tap(find.text('Chỉ Định Quyền Mới'));
      await tester.pumpAndSettle();
      expect(find.byType(AssignRoleBottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      Navigator.of(tester.element(find.byType(AssignRoleBottomSheet))).pop();
      await tester.pumpAndSettle();

      // Switch to Desktop (1440x900)
      _setViewport(tester, const Size(1440, 900));
      await tester.pumpAndSettle();

      await tester.tap(find.text('BTC Sự Kiện'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhật Ký'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trưởng Chi'));
      await tester.pumpAndSettle();

      // Open AssignRoleBottomSheet on Desktop -> Centered Dialog
      await tester.tap(find.text('Chỉ Định Quyền Mới'));
      await tester.pumpAndSettle();
      expect(find.byType(AssignRoleBottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('BranchContributionBreakdownBottomSheet.show adapts BottomSheet vs Dialog + drill-down',
        (WidgetTester tester) async {
      const childBranch = BranchRecursiveContributionDto(
        branchId: 'BR_TUAN',
        branchName: 'Chi Bác Tuấn',
        generationLevel: 10,
        directTotalAmount: 15000000.0,
        descendantsTotalAmount: 70000000.0,
        totalRecursiveAmount: 85000000.0,
      );
      const summary = BranchRecursiveContributionDto(
        branchId: 'BR_PHUC',
        branchName: 'Nhánh Cụ Phúc',
        generationLevel: 9,
        directTotalAmount: 20000000.0,
        descendantsTotalAmount: 85000000.0,
        totalRecursiveAmount: 105000000.0,
        childBranches: [childBranch],
      );

      _setViewport(tester, const Size(390, 844));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => BranchContributionBreakdownBottomSheet.show(
                    context,
                    summary: summary,
                  ),
                  child: const Text('Open Breakdown'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mobile -> BottomSheet (no Dialog)
      await tester.tap(find.text('Open Breakdown'));
      await tester.pumpAndSettle();
      expect(find.byType(BranchContributionBreakdownBottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      // Drill-down and back
      await tester.tap(find.text('Chi Bác Tuấn'));
      await tester.pumpAndSettle();
      expect(find.text('Quay lại'), findsOneWidget);
      await tester.tap(find.text('Quay lại'));
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(BranchContributionBreakdownBottomSheet))).pop();
      await tester.pumpAndSettle();

      // Desktop (1440x900) -> Centered Dialog
      _setViewport(tester, const Size(1440, 900));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Breakdown'));
      await tester.pumpAndSettle();
      expect(find.byType(BranchContributionBreakdownBottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('/audit-logs switches between Mobile Card Stack + BottomSheet and Desktop Table + Dialog',
        (WidgetTester tester) async {
      _setViewport(tester, const Size(390, 844));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLocationProvider.overrideWithValue('/audit-logs'),
            auditRepositoryProvider.overrideWithValue(_E2eAuditRepository()),
          ],
          child: const FamilyFundApp(),
        ),
      );
      await _pumpFrames(tester, 200);

      // Mobile: Card Stack shown, table headers hidden
      expect(find.text('Xem So Sánh Chi Tiết (Diff)'), findsOneWidget);
      expect(find.text('THỜI ĐIỂM'), findsNothing);

      await tester.ensureVisible(find.text('Xem So Sánh Chi Tiết (Diff)'));
      await tester.tap(find.text('Xem So Sánh Chi Tiết (Diff)'));
      await _pumpFrames(tester, 200);
      expect(find.byType(DiffViewerDialog), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      Navigator.of(tester.element(find.byType(DiffViewerDialog))).pop();
      await _pumpFrames(tester, 200);

      // Desktop (1440x900): Table headers shown, DiffViewer opens in Dialog
      _setViewport(tester, const Size(1440, 900));
      await _pumpFrames(tester, 200);
      expect(find.text('THỜI ĐIỂM'), findsOneWidget);
      expect(find.text('NỘI DUNG TÓM TẮT'), findsOneWidget);

      await tester.tap(find.text('Xem Diff'));
      await _pumpFrames(tester, 200);
      expect(find.byType(DiffViewerDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}

class _FixedDualRbacNotifier extends DualRbacSessionNotifier {
  final DualRbacSession _fixed;
  _FixedDualRbacNotifier(this._fixed);

  @override
  DualRbacSession build() => _fixed;
}
