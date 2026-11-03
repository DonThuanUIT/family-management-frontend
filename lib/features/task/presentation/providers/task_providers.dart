import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/task_models.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/repositories/task_repository.dart';

/// State quản lý danh sách công việc chuẩn bị cho một sự kiện.
class TaskListState {
  final bool isLoading;
  final String? errorMessage;
  final List<TaskModel> tasks;
  final TaskStatusEnum? selectedStatus; // null nghĩa là 'Tất cả'
  final String searchQuery;

  const TaskListState({
    this.isLoading = false,
    this.errorMessage,
    this.tasks = const [],
    this.selectedStatus,
    this.searchQuery = '',
  });

  /// Danh sách công việc sau khi áp dụng bộ lọc trạng thái và tìm kiếm.
  List<TaskModel> get filteredTasks {
    return tasks.where((task) {
      if (selectedStatus != null && task.status != selectedStatus) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final nameMatch = task.taskName.toLowerCase().contains(query);
        final detailMatch =
            task.details?.toLowerCase().contains(query) ?? false;
        final assigneeMatch =
            task.assigneeDisplayName.toLowerCase().contains(query);
        if (!nameMatch && !detailMatch && !assigneeMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get totalCount => tasks.length;

  int get unassignedCount =>
      tasks.where((t) => t.status == TaskStatusEnum.unassigned).length;

  int get inProgressCount =>
      tasks.where((t) => t.status == TaskStatusEnum.inProgress).length;

  int get completedCount =>
      tasks.where((t) => t.status == TaskStatusEnum.completed).length;

  int get overdueCount =>
      tasks.where((t) => t.status == TaskStatusEnum.overdue).length;

  int get totalAdvanceBudget =>
      tasks.fold<int>(0, (sum, t) => sum + t.advanceBudget);

  TaskListState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<TaskModel>? tasks,
    TaskStatusEnum? selectedStatus,
    bool clearStatus = false,
    String? searchQuery,
  }) {
    return TaskListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      tasks: tasks ?? this.tasks,
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier quản lý danh sách công việc theo từng sự kiện (`eventId`).
class TaskListNotifier extends Notifier<TaskListState> {
  final String eventId;

  TaskListNotifier(this.eventId);

  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  @override
  TaskListState build() {
    Future.microtask(() => loadTasks(showLoading: true));
    return const TaskListState(isLoading: true);
  }

  /// Tải lại danh sách công việc từ backend.
  Future<void> loadTasks({bool showLoading = false}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final list = await _repository.getTasks(eventId);
      state = state.copyWith(
        isLoading: false,
        clearError: true,
        tasks: list,
      );
    } catch (e) {
      final message = e is Failure ? e.message : e.toString();
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
    }
  }

  /// Thay đổi bộ lọc trạng thái (null = Tất cả).
  void setStatusFilter(TaskStatusEnum? status) {
    state = state.copyWith(
      selectedStatus: status,
      clearStatus: status == null,
    );
  }

  /// Cập nhật từ khóa tìm kiếm.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Tạo công việc mới và cập nhật vào danh sách.
  Future<TaskModel> createTask(CreateTaskRequestDto request) async {
    final created = await _repository.createTask(eventId, request);
    // Tải lại danh sách từ server để đảm bảo thứ tự deadline ASC và trạng thái chuẩn xác
    await loadTasks();
    return created;
  }

  /// Gán lại người nhận việc và cập nhật danh sách.
  Future<TaskModel> assignTask(
    String taskId,
    AssignTaskRequestDto request,
  ) async {
    final updated = await _repository.assignTask(eventId, taskId, request);
    final updatedList =
        state.tasks.map((t) => t.taskId == taskId ? updated : t).toList();
    state = state.copyWith(tasks: updatedList);
    return updated;
  }
}

final taskListProvider =
    NotifierProvider.family<TaskListNotifier, TaskListState, String>(
  (eventId) => TaskListNotifier(eventId),
);
