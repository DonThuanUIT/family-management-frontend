import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/role_models.dart';
import '../../data/repositories/role_repository_impl.dart';
import '../../domain/repositories/role_repository.dart';

enum RoleManagementTab { branches, events, audit }

class RoleManagementState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final RoleManagementTab selectedTab;
  final RoleManagementOverviewModel? overview;
  final List<AuditLogModel> auditLogs;
  final String? selectedEventId;

  const RoleManagementState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.selectedTab = RoleManagementTab.branches,
    this.overview,
    this.auditLogs = const [],
    this.selectedEventId,
  });

  int get branchCount => overview?.branches.length ?? 0;
  int get appointedBranchCount =>
      overview?.branches.where((b) => b.hasRepresentative).length ?? 0;
  int get vacantBranchCount =>
      overview?.branches.where((b) => !b.hasRepresentative).length ?? 0;

  RoleManagementState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    RoleManagementTab? selectedTab,
    RoleManagementOverviewModel? overview,
    List<AuditLogModel>? auditLogs,
    String? selectedEventId,
  }) {
    return RoleManagementState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      selectedTab: selectedTab ?? this.selectedTab,
      overview: overview ?? this.overview,
      auditLogs: auditLogs ?? this.auditLogs,
      selectedEventId: selectedEventId ?? this.selectedEventId,
    );
  }
}

class RoleManagementNotifier extends Notifier<RoleManagementState> {
  RoleRepository get _repository => ref.read(roleRepositoryProvider);

  @override
  RoleManagementState build() {
    // Initial state with empty overview
    return const RoleManagementState();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final overview = await _repository.getOverview();
      final logs = await _repository.getAuditLogs();
      state = state.copyWith(
        isLoading: false,
        overview: overview,
        auditLogs: logs,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải dữ liệu phân quyền: ${e.toString()}',
      );
    }
  }

  void switchTab(RoleManagementTab tab) {
    state = state.copyWith(selectedTab: tab);
  }

  void selectEvent(String eventId) {
    state = state.copyWith(selectedEventId: eventId);
  }

  Future<bool> assignRole(RoleAssignmentRequestDto request) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.assignRole(request);
      final overview = await _repository.getOverview();
      final logs = await _repository.getAuditLogs();
      state = state.copyWith(
        isSubmitting: false,
        overview: overview,
        auditLogs: logs,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> revokeRole(RoleRevocationRequestDto request) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.revokeRole(request);
      final overview = await _repository.getOverview();
      final logs = await _repository.getAuditLogs();
      state = state.copyWith(
        isSubmitting: false,
        overview: overview,
        auditLogs: logs,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final roleManagementProvider =
    NotifierProvider<RoleManagementNotifier, RoleManagementState>(
  RoleManagementNotifier.new,
);
