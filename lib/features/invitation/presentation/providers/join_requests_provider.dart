import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../../genealogy/data/models/branch_models.dart';
import '../../data/models/join_request_management_models.dart';
import '../../data/repositories/join_request_repository_impl.dart';
import '../../domain/repositories/join_request_repository.dart';

class JoinRequestsState {
  final bool isLoading;
  final bool isActionLoading;
  final String? actionRequestId;
  final String? errorMessage;
  final String? successMessage;
  final List<JoinRequestResponseDto> requests;
  final List<JoinRequestResponseDto> allLoadedRequests;
  final JoinRequestResponseDto? selectedRequest;
  final JoinRequestApprovalStatus? statusFilter;
  final String? branchFilter;
  final String searchQuery;
  final List<FlattenedBranchOption> branchOptions;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int totalCount;

  const JoinRequestsState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.actionRequestId,
    this.errorMessage,
    this.successMessage,
    this.requests = const [],
    this.allLoadedRequests = const [],
    this.selectedRequest,
    this.statusFilter,
    this.branchFilter,
    this.searchQuery = '',
    this.branchOptions = const [],
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.totalCount = 0,
  });

  JoinRequestsState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    String? actionRequestId,
    String? errorMessage,
    String? successMessage,
    List<JoinRequestResponseDto>? requests,
    List<JoinRequestResponseDto>? allLoadedRequests,
    JoinRequestResponseDto? selectedRequest,
    JoinRequestApprovalStatus? statusFilter,
    bool clearStatusFilter = false,
    String? branchFilter,
    bool clearBranchFilter = false,
    String? searchQuery,
    List<FlattenedBranchOption>? branchOptions,
    int? pendingCount,
    int? approvedCount,
    int? rejectedCount,
    int? totalCount,
  }) {
    return JoinRequestsState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      actionRequestId: actionRequestId,
      errorMessage: errorMessage,
      successMessage: successMessage,
      requests: requests ?? this.requests,
      allLoadedRequests: allLoadedRequests ?? this.allLoadedRequests,
      selectedRequest: selectedRequest ?? this.selectedRequest,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      branchFilter: clearBranchFilter ? null : (branchFilter ?? this.branchFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      branchOptions: branchOptions ?? this.branchOptions,
      pendingCount: pendingCount ?? this.pendingCount,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class JoinRequestsNotifier extends Notifier<JoinRequestsState> {
  late final JoinRequestRepository _repository;

  @override
  JoinRequestsState build() {
    _repository = ref.watch(joinRequestRepositoryProvider);
    return const JoinRequestsState();
  }

  /// Khởi tạo dữ liệu màn hình quản lý: Cây chi nhánh & danh sách đơn gia nhập
  Future<void> loadInitialData({String? initialBranchId}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
      branchFilter: initialBranchId,
    );

    try {
      // 1. Tải cây chi nhánh phả hệ để điền vào dropdown điều chuyển
      final branchOptions = <FlattenedBranchOption>[];
      try {
        final tree = await _repository.getBranchTree();
        _flattenBranchTree(tree, 0, branchOptions);
      } catch (_) {
        // Fallback default options if tree service fails
        branchOptions.addAll([
          const FlattenedBranchOption(
            branchId: 'BR_01',
            branchName: 'Chi Gốc (Đại Tôn)',
            generationLevel: 1,
            depth: 0,
          ),
          const FlattenedBranchOption(
            branchId: 'BR_02',
            branchName: 'Chi 2 - Nhánh Giáp',
            generationLevel: 2,
            depth: 1,
          ),
          const FlattenedBranchOption(
            branchId: 'BR_03',
            branchName: 'Chi 3 - Nhánh Ất',
            generationLevel: 2,
            depth: 1,
          ),
        ]);
      }

      // 2. Tải danh sách đơn gia nhập
      final pageData = await _repository.getJoinRequests(
        branchId: initialBranchId,
        page: 0,
        size: 50,
      );

      final all = pageData.content;
      final pending = all.where((r) => r.approvalStatus == JoinRequestApprovalStatus.pending).length;
      final approved = all.where((r) => r.approvalStatus == JoinRequestApprovalStatus.approved).length;
      final rejected = all.where((r) => r.approvalStatus == JoinRequestApprovalStatus.rejected).length;

      final displayed = _filterList(
        items: all,
        status: state.statusFilter,
        branchId: state.branchFilter,
        query: state.searchQuery,
      );

      state = state.copyWith(
        isLoading: false,
        allLoadedRequests: all,
        requests: displayed,
        branchOptions: branchOptions,
        pendingCount: pending,
        approvedCount: approved,
        rejectedCount: rejected,
        totalCount: all.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi khi tải dữ liệu đơn gia nhập: ${e.toString()}',
      );
    }
  }

  void _flattenBranchTree(
    BranchTreeNodeDto node,
    int depth,
    List<FlattenedBranchOption> list,
  ) {
    list.add(
      FlattenedBranchOption(
        branchId: node.branchId,
        branchName: node.branchName,
        generationLevel: node.generationLevel,
        representativeName: node.representativeName,
        depth: depth,
      ),
    );
    for (final child in node.children) {
      _flattenBranchTree(child, depth + 1, list);
    }
  }

  /// Lọc theo trạng thái đơn (Tất cả, Chờ duyệt, Đã duyệt, Đã từ chối)
  void setStatusFilter(JoinRequestApprovalStatus? status) {
    final displayed = _filterList(
      items: state.allLoadedRequests,
      status: status,
      branchId: state.branchFilter,
      query: state.searchQuery,
    );
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      requests: displayed,
    );
  }

  /// Lọc theo chi nhánh
  void setBranchFilter(String? branchId) {
    final displayed = _filterList(
      items: state.allLoadedRequests,
      status: state.statusFilter,
      branchId: branchId,
      query: state.searchQuery,
    );
    state = state.copyWith(
      branchFilter: branchId,
      clearBranchFilter: branchId == null || branchId.isEmpty,
      requests: displayed,
    );
  }

  /// Tìm kiếm theo từ khóa họ tên, SĐT, mã đơn, email
  void setSearchQuery(String query) {
    final displayed = _filterList(
      items: state.allLoadedRequests,
      status: state.statusFilter,
      branchId: state.branchFilter,
      query: query,
    );
    state = state.copyWith(
      searchQuery: query,
      requests: displayed,
    );
  }

  /// Chọn đơn để xem chi tiết
  void selectRequest(JoinRequestResponseDto? request) {
    state = state.copyWith(selectedRequest: request);
  }

  /// Phê duyệt đơn gia nhập
  Future<bool> approveRequest(
    String requestId, {
    String? targetBranchId,
    String? proposedNewBranchName,
  }) async {
    state = state.copyWith(
      isActionLoading: true,
      actionRequestId: requestId,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final reqDto = ApproveJoinRequestDto(
        targetBranchId: targetBranchId,
        proposedNewBranchName: proposedNewBranchName,
      );

      final updated = await _repository.approveJoinRequest(requestId, request: reqDto);

      // Cập nhật danh sách nội bộ
      final newAll = state.allLoadedRequests.map((item) {
        if (item.requestId == requestId) {
          return updated;
        }
        return item;
      }).toList();

      final pending = newAll.where((r) => r.approvalStatus == JoinRequestApprovalStatus.pending).length;
      final approved = newAll.where((r) => r.approvalStatus == JoinRequestApprovalStatus.approved).length;
      final rejected = newAll.where((r) => r.approvalStatus == JoinRequestApprovalStatus.rejected).length;

      final displayed = _filterList(
        items: newAll,
        status: state.statusFilter,
        branchId: state.branchFilter,
        query: state.searchQuery,
      );

      final selected = state.selectedRequest?.requestId == requestId ? updated : state.selectedRequest;

      state = state.copyWith(
        isActionLoading: false,
        actionRequestId: null,
        allLoadedRequests: newAll,
        requests: displayed,
        selectedRequest: selected,
        pendingCount: pending,
        approvedCount: approved,
        rejectedCount: rejected,
        totalCount: newAll.length,
        successMessage: 'Phê duyệt thành công! Thành viên "${updated.fullName}" đã được tiếp nhận vào gia phả.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionRequestId: null,
        errorMessage: 'Lỗi khi phê duyệt: ${e.toString().replaceAll("Exception: ", "")}',
      );
      return false;
    }
  }

  /// Từ chối đơn gia nhập kèm lý do bắt buộc
  Future<bool> rejectRequest(String requestId, String rejectionReason) async {
    if (rejectionReason.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng nhập lý do từ chối để thông báo cho ứng viên.',
      );
      return false;
    }

    state = state.copyWith(
      isActionLoading: true,
      actionRequestId: requestId,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final reqDto = RejectJoinRequestDto(rejectionReason: rejectionReason.trim());
      final updated = await _repository.rejectJoinRequest(requestId, reqDto);

      final newAll = state.allLoadedRequests.map((item) {
        if (item.requestId == requestId) {
          return updated;
        }
        return item;
      }).toList();

      final pending = newAll.where((r) => r.approvalStatus == JoinRequestApprovalStatus.pending).length;
      final approved = newAll.where((r) => r.approvalStatus == JoinRequestApprovalStatus.approved).length;
      final rejected = newAll.where((r) => r.approvalStatus == JoinRequestApprovalStatus.rejected).length;

      final displayed = _filterList(
        items: newAll,
        status: state.statusFilter,
        branchId: state.branchFilter,
        query: state.searchQuery,
      );

      final selected = state.selectedRequest?.requestId == requestId ? updated : state.selectedRequest;

      state = state.copyWith(
        isActionLoading: false,
        actionRequestId: null,
        allLoadedRequests: newAll,
        requests: displayed,
        selectedRequest: selected,
        pendingCount: pending,
        approvedCount: approved,
        rejectedCount: rejected,
        totalCount: newAll.length,
        successMessage: 'Đã từ chối yêu cầu gia nhập của "${updated.fullName}".',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        actionRequestId: null,
        errorMessage: 'Lỗi khi từ chối đơn: ${e.toString().replaceAll("Exception: ", "")}',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  List<JoinRequestResponseDto> _filterList({
    required List<JoinRequestResponseDto> items,
    required JoinRequestApprovalStatus? status,
    required String? branchId,
    required String query,
  }) {
    return items.where((item) {
      if (status != null && item.approvalStatus != status) {
        return false;
      }
      if (branchId != null && branchId.trim().isNotEmpty && item.targetBranchId != branchId.trim()) {
        return false;
      }
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchName = item.fullName.toLowerCase().contains(q);
        final matchPhone = (item.phoneNumber ?? '').toLowerCase().contains(q);
        final matchCode = item.requestId.toLowerCase().contains(q) || item.inviteCode.toLowerCase().contains(q);
        final matchBranch = (item.targetBranchName ?? '').toLowerCase().contains(q);
        if (!matchName && !matchPhone && !matchCode && !matchBranch) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}

final joinRequestsProvider =
    NotifierProvider<JoinRequestsNotifier, JoinRequestsState>(
  JoinRequestsNotifier.new,
);
