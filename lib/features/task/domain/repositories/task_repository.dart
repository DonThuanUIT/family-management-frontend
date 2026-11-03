import '../../data/models/task_models.dart';

/// Hợp đồng Repository của phân hệ Công việc & Phân công nhiệm vụ (US-07).
abstract interface class TaskRepository {
  /// Lấy danh sách công việc chuẩn bị cho sự kiện.
  Future<List<TaskModel>> getTasks(
    String eventId, {
    TaskStatusEnum? status,
    String? assignedMemberId,
    String? assignedBranchId,
  });

  /// Xem chi tiết một công việc.
  Future<TaskModel> getTaskDetail(String eventId, String taskId);

  /// Khởi tạo hạng mục công việc mới.
  Future<TaskModel> createTask(
    String eventId,
    CreateTaskRequestDto request,
  );

  /// Phân công hoặc gán lại công việc cho cá nhân/nhánh.
  Future<TaskModel> assignTask(
    String eventId,
    String taskId,
    AssignTaskRequestDto request,
  );
}

