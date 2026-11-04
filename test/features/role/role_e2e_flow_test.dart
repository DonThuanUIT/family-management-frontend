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

class LiveSimulationRoleRepository implements RoleRepository {
  RoleManagementOverviewModel currentOverview;
  List<AuditLogModel> currentLogs;

  LiveSimulationRoleRepository({
    required this.currentOverview,
    required this.currentLogs,
  });

  @override
  Future<RoleManagementOverviewModel> getOverview() async {
    return currentOverview;
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs({
    String? memberId,
    String? scopeType,
    String? scopeId,
  }) async {
    return List.from(currentLogs);
  }

  @override
  Future<RoleAssignmentResponseDto> assignRole(
      RoleAssignmentRequestDto request) async {
    // 1. If branch assignment, update branch representative
    if (request.scopeType == 'BRANCH') {
      final updatedBranches = currentOverview.branches.map((b) {
        if (b.branchId == request.scopeId) {
          final member = currentOverview.members
              .firstWhere((m) => m.memberId == request.memberId);
          return BranchRoleOverviewModel(
            branchId: b.branchId,
            branchName: b.branchName,
            generationLevel: b.generationLevel,
            representativeMemberId: member.memberId,
            representativeFullName: member.fullName,
            representativeAccountId: member.accountId,
          );
        }
        return b;
      }).toList();

      currentOverview = RoleManagementOverviewModel(
        clanId: currentOverview.clanId,
        branches: updatedBranches,
        members: currentOverview.members,
      );
    }

    // 2. Insert audit log
    final member = currentOverview.members
        .firstWhere((m) => m.memberId == request.memberId);
    currentLogs.insert(
      0,
      AuditLogModel(
        auditId: 'AUD_${DateTime.now().millisecondsSinceEpoch}',
        clanId: currentOverview.clanId,
        actorFullName: 'Trưởng Tộc (Nguyễn Văn An)',
        targetMemberId: request.memberId,
        targetFullName: member.fullName,
        actionType: 'ASSIGN',
        roleCode: request.roleCode,
        roleDisplayName:
            AssignableRoleCode.fromCode(request.roleCode).displayName,
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
      message: 'Chỉ định vai trò thành công',
    );
  }

  @override
  Future<RoleAssignmentResponseDto> revokeRole(
      RoleRevocationRequestDto request) async {
    // 1. If branch revoke, clear representative
    if (request.scopeType == 'BRANCH') {
      final updatedBranches = currentOverview.branches.map((b) {
        if (b.branchId == request.scopeId) {
          return BranchRoleOverviewModel(
            branchId: b.branchId,
            branchName: b.branchName,
            generationLevel: b.generationLevel,
            representativeMemberId: null,
            representativeFullName: null,
            representativeAccountId: null,
          );
        }
        return b;
      }).toList();

      currentOverview = RoleManagementOverviewModel(
        clanId: currentOverview.clanId,
        branches: updatedBranches,
        members: currentOverview.members,
      );
    }

    // 2. Insert audit log
    currentLogs.insert(
      0,
      AuditLogModel(
        auditId: 'AUD_${DateTime.now().millisecondsSinceEpoch}',
        clanId: currentOverview.clanId,
        actorFullName: 'Trưởng Tộc (Nguyễn Văn An)',
        targetMemberId: request.memberId,
        targetFullName: 'Bác Nguyễn Trọng Khoa',
        actionType: 'REVOKE',
        roleCode: request.roleCode,
        roleDisplayName:
            AssignableRoleCode.fromCode(request.roleCode).displayName,
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
      message: 'Thu hồi vai trò thành công',
    );
  }
}

class LiveSimulationEventRepository implements EventRepository {
  List<EventModel> events = List.from(EventRemoteDataSource.mockEvents);

  @override
  Future<List<EventModel>> getEvents() async => events;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late LiveSimulationRoleRepository liveRoleRepo;
  late LiveSimulationEventRepository liveEventRepo;

  setUp(() {
    liveRoleRepo = LiveSimulationRoleRepository(
      currentOverview: const RoleManagementOverviewModel(
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
      currentLogs: [
        AuditLogModel(
          auditId: 'AUD_INIT',
          clanId: 'CLAN_01',
          actorFullName: 'Trưởng Tộc (Nguyễn Văn An)',
          targetFullName: 'Nguyễn Văn Bình',
          actionType: 'ASSIGN',
          roleCode: 'ROLE_BRANCH_HEAD',
          roleDisplayName: 'Trưởng Chi / Nhánh',
          scopeType: 'BRANCH',
          scopeId: 'b1',
          scopeName: 'Chi 1 (Trưởng Nam)',
          description: 'Phân công nhiệm kỳ 2024-2029',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );

    liveEventRepo = LiveSimulationEventRepository();
  });

  testWidgets(
      'FULL E2E LIVE USER JOURNEY: Appoint Branch Head, Block Inactive, Audit Log updates, and Revoke Event Role',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Launch App Screen
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          roleRepositoryProvider.overrideWithValue(liveRoleRepo),
          eventRepositoryProvider.overrideWithValue(liveEventRepo),
        ],
        child: const MaterialApp(
          home: RoleManagementScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Verify Initial Screen State
    expect(find.text('Phân Quyền & Chức Sự'), findsOneWidget);
    expect(find.text('Chi 1 (Trưởng Nam)'), findsOneWidget);
    expect(find.text('Đã Bổ Nhiệm'), findsOneWidget);
    expect(find.text('Chi 2 (Định Chi)'), findsOneWidget);
    expect(find.text('Khuyết Trưởng Chi'), findsOneWidget);

    // 3. Tap "+ Bổ Nhiệm" on Chi 2
    final boNhiemBtn = find.widgetWithText(ElevatedButton, 'Bổ Nhiệm');
    expect(boNhiemBtn, findsOneWidget);
    await tester.tap(boNhiemBtn);
    await tester.pumpAndSettle();

    // 4. Verify AssignRoleBottomSheet is open
    expect(find.byType(AssignRoleBottomSheet), findsOneWidget);
    expect(find.text('Chỉ Định Quyền & Chức Sự'), findsOneWidget);

    // 5. Test Negative Constraint: Try to select Inactive member (Nguyễn Văn Đức)
    final inactiveMemberTile = find.text('Nguyễn Văn Đức');
    expect(inactiveMemberTile, findsOneWidget);
    await tester.tap(inactiveMemberTile);
    await tester.pumpAndSettle();

    // Verify Error SnackBar shows up
    expect(
      find.text(
          'Thành viên chưa kích hoạt tài khoản! Vui lòng chọn thành viên có trạng thái Active.'),
      findsOneWidget,
    );

    // 6. Test Member Filter / Search: Type "Hùng"
    final searchInput = find.byType(TextField).first;
    await tester.enterText(searchInput, 'Hùng');
    await tester.pumpAndSettle();

    expect(
        find.descendant(
            of: find.byType(AssignRoleBottomSheet),
            matching: find.widgetWithText(InkWell, 'Nguyễn Văn Hùng')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(AssignRoleBottomSheet),
            matching: find.widgetWithText(InkWell, 'Nguyễn Văn Bình')),
        findsNothing);

    // 7. Select Active member (Nguyễn Văn Hùng)
    await tester.tap(find.text('Nguyễn Văn Hùng'));
    await tester.pumpAndSettle();

    // 8. Enter Assignment Reason
    final reasonInput = find.byType(TextField).last;
    await tester.enterText(
      reasonInput,
      'Bổ nhiệm Trưởng chi 2 theo biểu quyết đại hội',
    );
    await tester.pumpAndSettle();

    // 9. Submit Assignment
    final confirmAssignBtn =
        find.widgetWithText(ElevatedButton, 'Xác Nhận Chỉ Định');
    await tester.ensureVisible(confirmAssignBtn);
    await tester.tap(confirmAssignBtn);
    await tester.pumpAndSettle();

    // 10. Verify Bottom Sheet closed and Chi 2 is now Appointed!
    expect(find.byType(AssignRoleBottomSheet), findsNothing);

    // Chi 2 now shows representative Nguyễn Văn Hùng
    expect(find.text('Chi 2 (Định Chi)'), findsOneWidget);
    expect(find.text('Nguyễn Văn Hùng'), findsOneWidget);

    // 11. Switch to "Nhật Ký" Tab and verify Audit Log
    await tester.tap(find.text('Nhật Ký'));
    await tester.pumpAndSettle();

    expect(find.text('SỔ BỘ KIỂM TOÁN TÁC NGHIỆP'), findsOneWidget);
    expect(find.text('Chỉ Định Vai Trò'), findsNWidgets(2));
    expect(
      find.text('“Lý do: Bổ nhiệm Trưởng chi 2 theo biểu quyết đại hội”'),
      findsOneWidget,
    );

    // 12. Switch to "BTC Sự Kiện" Tab
    await tester.tap(find.text('BTC Sự Kiện'));
    await tester.pumpAndSettle();

    expect(find.text('CHỌN SỰ KIỆN PHÂN BỔ NHÂN SỰ:'), findsOneWidget);
    expect(find.text('Trưởng Ban Tổ Chức (Head)'), findsOneWidget);

    // 13. Revoke role in Event: Tap Revoke icon on Head of Organizer
    final revokeBtn = find.byTooltip('Thu hồi quyền hạn').first;
    await tester.tap(revokeBtn);
    await tester.pumpAndSettle();

    // 14. Verify RevokeRoleDialog is open
    expect(find.byType(RevokeRoleDialog), findsOneWidget);
    expect(find.text('Thu Hồi Vai Trò'), findsOneWidget);

    // 15. Tap "Thu Hồi Ngay"
    final confirmRevokeBtn =
        find.widgetWithText(ElevatedButton, 'Thu Hồi Ngay');
    await tester.tap(confirmRevokeBtn);
    await tester.pumpAndSettle();

    // 16. Verify dialog closed
    expect(find.byType(RevokeRoleDialog), findsNothing);

    // 17. Switch to "Nhật Ký" Tab again to verify the new REVOKE log entry
    await tester.tap(find.text('Nhật Ký'));
    await tester.pumpAndSettle();

    expect(find.text('Thu Hồi Vai Trò'), findsOneWidget);
    expect(
      find.text('“Lý do: Đã hoàn thành kỳ hạn phân công tế lễ”'),
      findsOneWidget,
    );
  });
}
