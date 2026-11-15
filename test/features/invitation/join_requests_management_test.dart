import 'package:familyfund_app/features/auth/data/models/auth_models.dart';
import 'package:familyfund_app/features/genealogy/data/models/branch_models.dart';
import 'package:familyfund_app/features/invitation/data/models/join_request_management_models.dart';
import 'package:familyfund_app/features/invitation/data/repositories/join_request_repository_impl.dart';
import 'package:familyfund_app/features/invitation/domain/repositories/join_request_repository.dart';
import 'package:familyfund_app/features/invitation/presentation/providers/join_requests_provider.dart';
import 'package:familyfund_app/features/invitation/presentation/screens/join_requests_management_screen.dart';
import 'package:familyfund_app/features/invitation/presentation/widgets/join_request_detail_dialog.dart';
import 'package:familyfund_app/features/invitation/presentation/widgets/reject_join_request_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockJoinRequestRepository implements JoinRequestRepository {
  List<JoinRequestResponseDto> mockRequests = [
    const JoinRequestResponseDto(
      requestId: 'REQ_01',
      accountId: 'ACC_01',
      clanId: 'CLAN_DEFAULT',
      inviteCode: '8K9P2X7N',
      fullName: 'Nguyễn Văn An',
      phoneNumber: '0987654321',
      email: 'an.nguyen@example.com',
      dateOfBirth: '1995-05-15',
      gender: 'Male',
      proposalType: ProposalType.existingBranchLeaf,
      targetBranchId: 'BR_01',
      targetBranchName: 'Chi Gốc (Đại Tôn)',
      proposedGeneration: 5,
      relationshipNote: 'Cháu nội cố cụ Nguyễn Văn Bình',
      approvalStatus: JoinRequestApprovalStatus.pending,
      createdAt: '2026-11-14T08:30:00Z',
    ),
    const JoinRequestResponseDto(
      requestId: 'REQ_02',
      accountId: 'ACC_02',
      clanId: 'CLAN_DEFAULT',
      inviteCode: '8K9P2X7N',
      fullName: 'Trần Thị Thu Thảo',
      phoneNumber: '0912345678',
      email: 'thao.tran@example.com',
      dateOfBirth: '1998-08-20',
      gender: 'Female',
      proposalType: ProposalType.newChildBranch,
      targetBranchId: 'BR_02',
      targetBranchName: 'Chi 2 - Nhánh Giáp',
      proposedNewBranchName: 'Chi Nhánh Sài Gòn',
      proposedGeneration: 6,
      relationshipNote: 'Con dâu mới nhập tịch họ Nguyễn',
      approvalStatus: JoinRequestApprovalStatus.pending,
      createdAt: '2026-11-14T09:15:00Z',
    ),
    const JoinRequestResponseDto(
      requestId: 'REQ_03',
      accountId: 'ACC_03',
      clanId: 'CLAN_DEFAULT',
      inviteCode: '7M4T9Q2L',
      fullName: 'Lê Hoàng Nam',
      phoneNumber: '0933221100',
      email: 'nam.le@example.com',
      dateOfBirth: '1992-03-10',
      gender: 'Male',
      proposalType: ProposalType.existingBranchLeaf,
      targetBranchId: 'BR_03',
      targetBranchName: 'Chi 3 - Nhánh Ất',
      proposedGeneration: 5,
      relationshipNote: 'Cháu ngoại dòng họ',
      approvalStatus: JoinRequestApprovalStatus.approved,
      reviewedByAccountId: 'ACC_HEAD',
      createdAt: '2026-11-13T14:20:00Z',
      reviewedAt: '2026-11-13T16:00:00Z',
    ),
    const JoinRequestResponseDto(
      requestId: 'REQ_04',
      accountId: 'ACC_04',
      clanId: 'CLAN_DEFAULT',
      inviteCode: '5X1R8Z3K',
      fullName: 'Phạm Gia Huy',
      phoneNumber: '0909112233',
      email: 'huy.pham@example.com',
      dateOfBirth: '2000-11-28',
      gender: 'Male',
      proposalType: ProposalType.existingBranchLeaf,
      targetBranchId: 'BR_01',
      targetBranchName: 'Chi Gốc (Đại Tôn)',
      proposedGeneration: 7,
      relationshipNote: 'Xin gia nhập tự do',
      approvalStatus: JoinRequestApprovalStatus.rejected,
      reviewedByAccountId: 'ACC_HEAD',
      rejectionReason: 'Thông tin nhân thân không khớp với gia phả',
      createdAt: '2026-11-12T10:00:00Z',
      reviewedAt: '2026-11-12T11:45:00Z',
    ),
  ];

  String? lastApprovedRequestId;
  ApproveJoinRequestDto? lastApproveDto;
  String? lastRejectedRequestId;
  RejectJoinRequestDto? lastRejectDto;

  @override
  Future<JoinRequestPageDto> getJoinRequests({
    JoinRequestApprovalStatus? status,
    String? branchId,
    int page = 0,
    int size = 20,
  }) async {
    var filtered = mockRequests;
    if (status != null) {
      filtered = filtered.where((r) => r.approvalStatus == status).toList();
    }
    if (branchId != null && branchId.trim().isNotEmpty) {
      filtered = filtered.where((r) => r.targetBranchId == branchId.trim()).toList();
    }

    return JoinRequestPageDto(
      content: filtered,
      totalElements: filtered.length,
      totalPages: 1,
      number: page,
      size: size,
    );
  }

  @override
  Future<JoinRequestResponseDto> approveJoinRequest(
    String requestId, {
    ApproveJoinRequestDto? request,
  }) async {
    lastApprovedRequestId = requestId;
    lastApproveDto = request;
    final item = mockRequests.firstWhere((r) => r.requestId == requestId);
    final updated = JoinRequestResponseDto(
      requestId: item.requestId,
      accountId: item.accountId,
      clanId: item.clanId,
      inviteCode: item.inviteCode,
      fullName: item.fullName,
      phoneNumber: item.phoneNumber,
      email: item.email,
      dateOfBirth: item.dateOfBirth,
      gender: item.gender,
      proposalType: item.proposalType,
      targetBranchId: request?.targetBranchId ?? item.targetBranchId,
      targetBranchName: request?.targetBranchId == 'BR_02' ? 'Chi 2 - Nhánh Giáp' : item.targetBranchName,
      proposedNewBranchName: request?.proposedNewBranchName ?? item.proposedNewBranchName,
      proposedGeneration: item.proposedGeneration,
      relationshipNote: item.relationshipNote,
      approvalStatus: JoinRequestApprovalStatus.approved,
      reviewedByAccountId: 'ACC_TEST_HEAD',
      reviewedAt: DateTime.now().toIso8601String(),
      createdAt: item.createdAt,
    );
    return updated;
  }

  @override
  Future<JoinRequestResponseDto> rejectJoinRequest(
    String requestId,
    RejectJoinRequestDto request,
  ) async {
    lastRejectedRequestId = requestId;
    lastRejectDto = request;
    final item = mockRequests.firstWhere((r) => r.requestId == requestId);
    final updated = JoinRequestResponseDto(
      requestId: item.requestId,
      accountId: item.accountId,
      clanId: item.clanId,
      inviteCode: item.inviteCode,
      fullName: item.fullName,
      phoneNumber: item.phoneNumber,
      email: item.email,
      dateOfBirth: item.dateOfBirth,
      gender: item.gender,
      proposalType: item.proposalType,
      targetBranchId: item.targetBranchId,
      targetBranchName: item.targetBranchName,
      proposedNewBranchName: item.proposedNewBranchName,
      proposedGeneration: item.proposedGeneration,
      relationshipNote: item.relationshipNote,
      approvalStatus: JoinRequestApprovalStatus.rejected,
      reviewedByAccountId: 'ACC_TEST_HEAD',
      rejectionReason: request.rejectionReason,
      reviewedAt: DateTime.now().toIso8601String(),
      createdAt: item.createdAt,
    );
    return updated;
  }

  @override
  Future<BranchTreeNodeDto> getBranchTree() async {
    return const BranchTreeNodeDto(
      branchId: 'BR_01',
      clanId: 'CLAN_DEFAULT',
      branchName: 'Chi Gốc (Đại Tôn)',
      clanName: 'Dòng Họ Nguyễn',
      generationLevel: 1,
      memberCount: 25,
      children: [
        BranchTreeNodeDto(
          branchId: 'BR_02',
          clanId: 'CLAN_DEFAULT',
          branchName: 'Chi 2 - Nhánh Giáp',
          clanName: 'Dòng Họ Nguyễn',
          generationLevel: 2,
          parentBranchId: 'BR_01',
          memberCount: 14,
        ),
        BranchTreeNodeDto(
          branchId: 'BR_03',
          clanId: 'CLAN_DEFAULT',
          branchName: 'Chi 3 - Nhánh Ất',
          clanName: 'Dòng Họ Nguyễn',
          generationLevel: 2,
          parentBranchId: 'BR_01',
          memberCount: 18,
        ),
      ],
    );
  }
}

Widget createTestApp({
  required Widget child,
  required MockJoinRequestRepository mockRepo,
}) {
  return ProviderScope(
    overrides: [
      joinRequestRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('US-33 DTO & Model Tests', () {
    test('ApproveJoinRequestDto serialization with branch override (AC-08)', () {
      const dto = ApproveJoinRequestDto(
        targetBranchId: 'BR_02',
        proposedNewBranchName: 'Chi Nhánh Đô Thành',
      );
      final json = dto.toJson();
      expect(json['targetBranchId'], 'BR_02');
      expect(json['proposedNewBranchName'], 'Chi Nhánh Đô Thành');

      const emptyDto = ApproveJoinRequestDto();
      expect(emptyDto.toJson().isEmpty, isTrue);
    });

    test('RejectJoinRequestDto serialization (AC-06)', () {
      const dto = RejectJoinRequestDto(
        rejectionReason: 'Thông tin nhân thân không khớp gia phả dòng họ',
      );
      final json = dto.toJson();
      expect(json['rejectionReason'], 'Thông tin nhân thân không khớp gia phả dòng họ');
    });

    test('FlattenedBranchOption formats depth indent properly', () {
      const root = FlattenedBranchOption(
        branchId: 'BR_01',
        branchName: 'Chi Gốc',
        generationLevel: 1,
        depth: 0,
      );
      expect(root.displayName, 'Chi Gốc (Đời 1)');

      const child = FlattenedBranchOption(
        branchId: 'BR_02',
        branchName: 'Chi 2',
        generationLevel: 2,
        depth: 1,
      );
      expect(child.displayName, '  └─ Chi 2 (Đời 2)');
    });
  });

  group('US-33 Provider & State Machine Tests', () {
    late MockJoinRequestRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockJoinRequestRepository();
      container = ProviderContainer(
        overrides: [
          joinRequestRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loads initial data, branch tree and computes correct KPI stats', () async {
      final notifier = container.read(joinRequestsProvider.notifier);
      await notifier.loadInitialData();

      final state = container.read(joinRequestsProvider);
      expect(state.isLoading, isFalse);
      expect(state.totalCount, 4);
      expect(state.pendingCount, 2);
      expect(state.approvedCount, 1);
      expect(state.rejectedCount, 1);
      expect(state.branchOptions.length, 3);
      expect(state.requests.length, 4);
    });

    test('filters list by status: Pending, Approved, Rejected and All', () async {
      final notifier = container.read(joinRequestsProvider.notifier);
      await notifier.loadInitialData();

      // Filter Pending
      notifier.setStatusFilter(JoinRequestApprovalStatus.pending);
      var state = container.read(joinRequestsProvider);
      expect(state.requests.length, 2);
      expect(state.requests.every((r) => r.approvalStatus == JoinRequestApprovalStatus.pending), isTrue);

      // Filter Approved
      notifier.setStatusFilter(JoinRequestApprovalStatus.approved);
      state = container.read(joinRequestsProvider);
      expect(state.requests.length, 1);
      expect(state.requests.first.requestId, 'REQ_03');

      // Filter Rejected
      notifier.setStatusFilter(JoinRequestApprovalStatus.rejected);
      state = container.read(joinRequestsProvider);
      expect(state.requests.length, 1);
      expect(state.requests.first.requestId, 'REQ_04');

      // Clear filter (All)
      notifier.setStatusFilter(null);
      state = container.read(joinRequestsProvider);
      expect(state.requests.length, 4);
    });

    test('searches requests by keyword across fullName, phoneNumber, requestId', () async {
      final notifier = container.read(joinRequestsProvider.notifier);
      await notifier.loadInitialData();

      // Search by name
      notifier.setSearchQuery('Thu Thảo');
      var state = container.read(joinRequestsProvider);
      expect(state.requests.length, 1);
      expect(state.requests.first.fullName, 'Trần Thị Thu Thảo');

      // Search by phone
      notifier.setSearchQuery('0987654321');
      state = container.read(joinRequestsProvider);
      expect(state.requests.length, 1);
      expect(state.requests.first.requestId, 'REQ_01');

      // Search by request ID
      notifier.setSearchQuery('REQ_04');
      state = container.read(joinRequestsProvider);
      expect(state.requests.length, 1);
      expect(state.requests.first.fullName, 'Phạm Gia Huy');
    });

    test('approves request with overridden branchId and updates state (AC-08)', () async {
      final notifier = container.read(joinRequestsProvider.notifier);
      await notifier.loadInitialData();

      final success = await notifier.approveRequest(
        'REQ_01',
        targetBranchId: 'BR_02',
      );

      expect(success, isTrue);
      expect(mockRepo.lastApprovedRequestId, 'REQ_01');
      expect(mockRepo.lastApproveDto?.targetBranchId, 'BR_02');

      final state = container.read(joinRequestsProvider);
      expect(state.pendingCount, 1);
      expect(state.approvedCount, 2);
      expect(state.successMessage, contains('Phê duyệt thành công'));

      final approvedItem = state.allLoadedRequests.firstWhere((r) => r.requestId == 'REQ_01');
      expect(approvedItem.approvalStatus, JoinRequestApprovalStatus.approved);
      expect(approvedItem.targetBranchId, 'BR_02');
    });

    test('rejects request with required reason and updates state (AC-06)', () async {
      final notifier = container.read(joinRequestsProvider.notifier);
      await notifier.loadInitialData();

      // Fails when reason is empty
      final failResult = await notifier.rejectRequest('REQ_01', '   ');
      expect(failResult, isFalse);
      expect(container.read(joinRequestsProvider).errorMessage, contains('nhập lý do từ chối'));

      // Succeeds with valid reason
      final success = await notifier.rejectRequest('REQ_01', 'Số điện thoại không phản hồi');
      expect(success, isTrue);
      expect(mockRepo.lastRejectedRequestId, 'REQ_01');
      expect(mockRepo.lastRejectDto?.rejectionReason, 'Số điện thoại không phản hồi');

      final state = container.read(joinRequestsProvider);
      expect(state.pendingCount, 1);
      expect(state.rejectedCount, 2);
      expect(state.successMessage, contains('Đã từ chối'));
    });
  });

  group('US-33 Widget & Screen Tests', () {
    late MockJoinRequestRepository mockRepo;

    setUp(() {
      mockRepo = MockJoinRequestRepository();
    });

    testWidgets('Renders JoinRequestsManagementScreen in Desktop mode without errors', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const JoinRequestsManagementScreen(),
          mockRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & badges
      expect(find.text('Quản Lý Đơn Xin Gia Nhập'), findsOneWidget);
      expect(find.text('HỆ THỐNG PHÊ CHUẨN GIA NHẬP PHẢ HỆ • DUAL-RBAC BẢO MẬT'), findsOneWidget);

      // Verify KPI cards
      expect(find.text('Chờ Phê Duyệt'), findsOneWidget);
      expect(find.text('Đã Phê Duyệt'), findsWidgets);
      expect(find.text('Đã Từ Chối'), findsWidgets);
      expect(find.text('Tổng Đơn Toàn Tộc'), findsOneWidget);

      // Verify Desktop Table headers & content
      expect(find.text('MÃ ĐƠN'), findsOneWidget);
      expect(find.text('ỨNG VIÊN XIN GIA NHẬP'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('Trần Thị Thu Thảo'), findsOneWidget);
    });

    testWidgets('Renders JoinRequestsManagementScreen in Mobile mode (390x844) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestApp(
          child: const JoinRequestsManagementScreen(),
          mockRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Mobile cards rendered
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('Chi Tiết & Đổi Nhánh'), findsWidgets);
      expect(find.text('Duyệt Đơn'), findsWidgets);
    });

    testWidgets('JoinRequestDetailDialog opens and allows branch override before approval (AC-08)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final request = mockRepo.mockRequests.first; // REQ_01: targetBranchId = BR_01

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => JoinRequestDetailDialog.show(ctx, request: request),
              child: const Text('Open Detail'),
            ),
          ),
          mockRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Tap to open dialog
      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      // Verify dialog contents
      expect(find.text('Đơn Xin Gia Nhập: REQ_01'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsOneWidget);
      expect(find.text('0987654321'), findsOneWidget);
      expect(find.text('Cháu nội cố cụ Nguyễn Văn Bình'), findsOneWidget);

      // Verify branch override dropdown
      final dropdown = find.byKey(const ValueKey('branch_override_dropdown'));
      expect(dropdown, findsOneWidget);

      // Tap dropdown to select branch BR_02
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select Chi 2 - Nhánh Giáp
      final branch2Item = find.text('  └─ Chi 2 - Nhánh Giáp (Đời 2)').last;
      await tester.tap(branch2Item);
      await tester.pumpAndSettle();

      // Notice badge "Đã đổi nhánh" appears
      expect(find.text('Đã đổi nhánh'), findsOneWidget);
      expect(find.text('Duyệt Vào Nhánh Mới'), findsOneWidget);

      // Tap "Duyệt Vào Nhánh Mới"
      await tester.tap(find.text('Duyệt Vào Nhánh Mới'));
      await tester.pumpAndSettle();

      // Dialog closed and repository called with overridden branchId
      expect(find.text('Đơn Xin Gia Nhập: REQ_01'), findsNothing);
      expect(mockRepo.lastApprovedRequestId, 'REQ_01');
      expect(mockRepo.lastApproveDto?.targetBranchId, 'BR_02');
    });

    testWidgets('RejectJoinRequestDialog validates non-empty reason and fills template chips (AC-06)', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final request = mockRepo.mockRequests.first;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => RejectJoinRequestDialog.show(ctx, request: request),
              child: const Text('Open Reject'),
            ),
          ),
          mockRepo: mockRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Reject'));
      await tester.pumpAndSettle();

      expect(find.text('Từ Chối Đơn Xin Gia Nhập'), findsOneWidget);

      // Tap template chip
      final chip = find.text('Thông tin nhân thân không khớp gia phả');
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Textfield should be populated with the template
      expect(find.text('Thông tin nhân thân không khớp gia phả'), findsNWidgets(2)); // chip + textfield

      // Tap "Xác Nhận Từ Chối"
      await tester.tap(find.text('Xác Nhận Từ Chối'));
      await tester.pumpAndSettle();

      // Dialog closed and repository called with reason
      expect(find.text('Từ Chối Đơn Xin Gia Nhập'), findsNothing);
      expect(mockRepo.lastRejectedRequestId, 'REQ_01');
      expect(mockRepo.lastRejectDto?.rejectionReason, 'Thông tin nhân thân không khớp gia phả');
    });
  });
}
