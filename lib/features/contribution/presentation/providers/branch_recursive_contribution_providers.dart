import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/branch_recursive_contribution_models.dart';
import '../../data/repositories/contribution_repository_impl.dart';

/// Trạng thái bộ lọc và chế độ hiển thị đóng góp công đức trên Cây Phả Hệ
class TreeContributionFilterState {
  /// Cờ bật/tắt hiển thị số liệu đóng góp trên các nút nhánh cây phả hệ
  /// Mặc định: false (chỉ bật khi người dùng chọn xem công đức)
  final bool isContributionViewEnabled;

  /// ID sự kiện được chọn lọc (null = tất cả sự kiện)
  final String? selectedEventId;

  /// Tên sự kiện hiển thị
  final String? selectedEventName;

  /// Năm đóng góp được chọn lọc (null = tất cả niên khóa)
  final int? selectedYear;

  const TreeContributionFilterState({
    this.isContributionViewEnabled = false,
    this.selectedEventId,
    this.selectedEventName,
    this.selectedYear,
  });

  TreeContributionFilterState copyWith({
    bool? isContributionViewEnabled,
    String? selectedEventId,
    String? selectedEventName,
    int? selectedYear,
    bool clearEvent = false,
    bool clearYear = false,
  }) {
    return TreeContributionFilterState(
      isContributionViewEnabled:
          isContributionViewEnabled ?? this.isContributionViewEnabled,
      selectedEventId:
          clearEvent ? null : (selectedEventId ?? this.selectedEventId),
      selectedEventName:
          clearEvent ? null : (selectedEventName ?? this.selectedEventName),
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
    );
  }
}

class TreeContributionFilterNotifier
    extends Notifier<TreeContributionFilterState> {
  @override
  TreeContributionFilterState build() {
    return const TreeContributionFilterState(
      isContributionViewEnabled: false,
      selectedEventId: null,
      selectedEventName: null,
      selectedYear: null,
    );
  }

  void toggleContributionView() {
    state = state.copyWith(
      isContributionViewEnabled: !state.isContributionViewEnabled,
    );
  }

  void setContributionViewEnabled(bool enabled) {
    state = state.copyWith(isContributionViewEnabled: enabled);
  }

  void setEventFilter({required String? eventId, String? eventName}) {
    if (eventId == null || eventId.isEmpty) {
      state = state.copyWith(clearEvent: true);
    } else {
      state = state.copyWith(
        selectedEventId: eventId,
        selectedEventName: eventName ?? eventId,
      );
    }
  }

  void setYearFilter(int? year) {
    if (year == null || year <= 0) {
      state = state.copyWith(clearYear: true);
    } else {
      state = state.copyWith(selectedYear: year);
    }
  }

  void resetFilter() {
    state = const TreeContributionFilterState(
      isContributionViewEnabled: false,
      selectedEventId: null,
      selectedEventName: null,
      selectedYear: null,
    );
  }
}

final treeContributionFilterProvider =
    NotifierProvider<TreeContributionFilterNotifier, TreeContributionFilterState>(
  TreeContributionFilterNotifier.new,
);

/// Tham số tra cứu đóng góp đệ quy cho một chi/nhánh
class BranchContributionQueryParam {
  final String branchId;
  final String? eventId;
  final int? year;

  const BranchContributionQueryParam({
    required this.branchId,
    this.eventId,
    this.year,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchContributionQueryParam &&
          runtimeType == other.runtimeType &&
          branchId == other.branchId &&
          eventId == other.eventId &&
          year == other.year;

  @override
  int get hashCode => branchId.hashCode ^ eventId.hashCode ^ year.hashCode;
}

/// Provider tra cứu chi tiết phân rã đệ quy đóng góp của một nhánh (US-11)
final branchRecursiveContributionProvider = FutureProvider.family<
    BranchRecursiveContributionDto, BranchContributionQueryParam>(
  (ref, param) async {
    final repo = ref.watch(contributionRepositoryProvider);
    return repo.getRecursiveBranchContributionSummary(
      branchId: param.branchId,
      eventId: param.eventId,
      year: param.year,
    );
  },
);
