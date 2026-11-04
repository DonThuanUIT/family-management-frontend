import 'package:familyfund_app/features/event/data/datasources/event_remote_datasource.dart';
import 'package:familyfund_app/features/event/data/models/event_models.dart';
import 'package:familyfund_app/features/event/data/repositories/event_repository_impl.dart';
import 'package:familyfund_app/features/event/domain/repositories/event_repository.dart';
import 'package:familyfund_app/features/role/data/models/role_models.dart';
import 'package:familyfund_app/features/role/data/repositories/role_repository_impl.dart';
import 'package:familyfund_app/features/role/domain/repositories/role_repository.dart';
import 'package:familyfund_app/features/role/presentation/screens/role_management_screen.dart';
import 'package:familyfund_app/features/role/presentation/widgets/assign_role_bottom_sheet.dart';
import 'package:familyfund_app/features/role/presentation/widgets/revoke_role_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRoleRepository implements RoleRepository {
  RoleManagementOverviewModel mockOverview;
  List<AuditLogModel> mockLogs;

  FakeRoleRepository({
    required this.mockOverview,
    required this.mockLogs,
  });

  @override
  Future<RoleManagementOverviewModel> getOverview() async {
    return mockOverview;
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs({
    String? memberId,
    String? scopeType,
    String? scopeId,
  }) async {
    return mockLogs;
  }

  @override
  Future<RoleAssignmentResponseDto> assignRole(RoleAssignmentRequestDto request) async {
    mockLogs.insert(
      0,
      AuditLogModel(
        auditId: 'AUD_TEST',
        clanId: 'CLAN_01',
        actorFullName: 'Trưởng Tộc',
        targetFullName: 'Nguyễn Văn Hùng',
        actionType: 'ASSIGN',
        roleCode: request.roleCode,
        roleDisplayName: request.roleCode,
        scopeType: request.scopeType,
        scopeId: request.scopeId,
        description: request.description,
        createdAt: DateTime.now(),
      ),
    );
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
  Future<RoleAssignmentResponseDto> revokeRole(RoleRevocationRequestDto request) async {
    mockLogs.insert(
      0,
      AuditLogModel(
        auditId: 'AUD_TEST_REVOKE',
        clanId: 'CLAN_01',
        actorFullName: 'Trưởng Tộc',
        targetFullName: 'Bác Nguyễn Trọng Khoa',
        actionType: 'REVOKE',
        roleCode: request.roleCode,
        roleDisplayName: request.roleCode,
        scopeType: request.scopeType,
        scopeId: request.scopeId,
        description: request.reason,
        createdAt: DateTime.now(),
      ),
    );
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

class FakeEventRepository implements EventRepository {
  @override
  Future<List<EventModel>> getEvents() async {
    return EventRemoteDataSource.mockEvents;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeRoleRepository fakeRoleRepo;
  late FakeEventRepository fakeEventRepo;

  setUp(() {
    fakeRoleRepo = FakeRoleRepository(
      mockOverview: const RoleManagementOverviewModel(
        clanId: 'CLAN_01',
        branches: [
          BranchRoleOverviewModel(
            branchId: 'b1',
            branchName: 'Chi 1 (Trưởng Nam)',
            generationLevel: 10,
            representativeMemberId: 'MEM_01',
            representativeFullName: 'Nguyễn Văn Bình',
            representativeAccountId: 'ACC_01',
          ),
          BranchRoleOverviewModel(
            branchId: 'b2',
            branchName: 'Chi 2 (Định Chi)',
            generationLevel: 11,
            representativeMemberId: null,
            representativeFullName: null,
            representativeAccountId: null,
          ),
        ],
        members: [
          MemberRoleOptionModel(
            memberId: 'MEM_01',
            fullName: 'Nguyễn Văn Bình',
            branchId: 'b1',
            branchName: 'Chi 1',
            hasActiveAccount: true,
            accountId: 'ACC_01',
          ),
          MemberRoleOptionModel(
            memberId: 'MEM_02',
            fullName: 'Nguyễn Văn Hùng',
            branchId: 'b2',
            branchName: 'Chi 2',
            hasActiveAccount: true,
            accountId: 'ACC_02',
          ),
          MemberRoleOptionModel(
            memberId: 'MEM_03',
            fullName: 'Nguyễn Văn Đức',
            branchId: 'b2',
            branchName: 'Chi 2',
            hasActiveAccount: false,
            accountId: null,
          ),
        ],
      ),
      mockLogs: [
        AuditLogModel(
          auditId: 'AUD_01',
          clanId: 'CLAN_01',
          actorFullName: 'Trưởng Tộc (Nguyễn Văn An)',
          targetFullName: 'Nguyễn Văn Bình',
          actionType: 'ASSIGN',
          roleCode: 'ROLE_BRANCH_HEAD',
          roleDisplayName: 'Trưởng Chi / Nhánh',
          scopeType: 'BRANCH',
          scopeId: 'b1',
          scopeName: 'Chi 1',
          description: 'Bổ nhiệm Trưởng chi',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    );
    fakeEventRepo = FakeEventRepository();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        roleRepositoryProvider.overrideWithValue(fakeRoleRepo),
        eventRepositoryProvider.overrideWithValue(fakeEventRepo),
      ],
      child: const MaterialApp(
        home: RoleManagementScreen(),
      ),
    );
  }

  group('RoleManagementScreen Widget Tests', () {
    testWidgets('renders App Bar, title and 3 Segmented Tabs', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('BAN TRỊ SỰ TÔNG MÔN'), findsOneWidget);
      expect(find.text('Phân Quyền & Chức Sự'), findsOneWidget);
      expect(find.text('Trưởng Chi'), findsOneWidget);
      expect(find.text('BTC Sự Kiện'), findsOneWidget);
      expect(find.text('Nhật Ký'), findsOneWidget);
    });

    testWidgets('renders Branch Tab with appointed and vacant branch cards', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Chi 1 (Trưởng Nam)'), findsOneWidget);
      expect(find.text('Đã Bổ Nhiệm'), findsOneWidget);
      expect(find.text('Nguyễn Văn Bình'), findsOneWidget);

      expect(find.text('Chi 2 (Định Chi)'), findsOneWidget);
      expect(find.text('Khuyết Trưởng Chi'), findsOneWidget);
      expect(find.text('Bổ Nhiệm'), findsOneWidget);
    });

    testWidgets('switches to Event Roles Tab and Audit Log Tab when tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap BTC Sự Kiện tab
      await tester.tap(find.text('BTC Sự Kiện'));
      await tester.pumpAndSettle();

      expect(find.text('CHỌN SỰ KIỆN PHÂN BỔ NHÂN SỰ:'), findsOneWidget);
      expect(find.text('Trưởng Ban Tổ Chức (Head)'), findsOneWidget);
      expect(find.text('Thủ Quỹ Sự Kiện (Treasurer)'), findsOneWidget);
      expect(find.text('Thành Viên Ban Tổ Chức'), findsOneWidget);

      // Tap Nhật Ký tab
      await tester.tap(find.text('Nhật Ký'));
      await tester.pumpAndSettle();

      expect(find.text('SỔ BỘ KIỂM TOÁN TÁC NGHIỆP'), findsOneWidget);
      expect(find.text('Chỉ Định Vai Trò'), findsOneWidget);
      expect(find.text('“Lý do: Bổ nhiệm Trưởng chi”'), findsOneWidget);
    });

    testWidgets('opens AssignRoleBottomSheet when Chỉ Định Quyền Mới is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chỉ Định Quyền Mới'));
      await tester.pumpAndSettle();

      expect(find.byType(AssignRoleBottomSheet), findsOneWidget);
      expect(find.text('Chỉ Định Quyền & Chức Sự'), findsOneWidget);
      expect(find.text('Cấp Chi Nhánh'), findsOneWidget);
      expect(find.text('Cấp Sự Kiện'), findsOneWidget);
      expect(find.text('Xác Nhận Chỉ Định'), findsOneWidget);
    });

    testWidgets('opens RevokeRoleDialog when revoke button is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final revokeBtn = find.byTooltip('Thu hồi vai trò Trưởng Chi');
      expect(revokeBtn, findsOneWidget);

      await tester.tap(revokeBtn);
      await tester.pumpAndSettle();

      expect(find.byType(RevokeRoleDialog), findsOneWidget);
      expect(find.text('Thu Hồi Vai Trò'), findsOneWidget);
      expect(find.text('Lý do thu hồi vào Sổ Bộ (Bắt buộc):'), findsOneWidget);
      expect(find.text('Thu Hồi Ngay'), findsOneWidget);
    });
  });
}
