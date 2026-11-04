import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/task_models.dart';

/// Datasource gọi trực tiếp REST API từ Spring Boot Backend (`com.familyfund.event.internal.controller.TaskController`).
/// Tuân thủ quy tắc 01 & 07: Không thêm fallback mock, không nuốt lỗi.
class TaskRemoteDataSource {
  final Dio _dio;

  const TaskRemoteDataSource(this._dio);

  /// Lấy danh sách công việc chuẩn bị của một sự kiện kèm bộ lọc tuỳ chọn.
  Future<List<TaskModel>> getTasks(
    String eventId, {
    TaskStatusEnum? status,
    String? assignedMemberId,
    String? assignedBranchId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) {
      queryParams['status'] = status.code;
    }
    if (assignedMemberId != null && assignedMemberId.trim().isNotEmpty) {
      queryParams['assignedMemberId'] = assignedMemberId.trim();
    }
    if (assignedBranchId != null && assignedBranchId.trim().isNotEmpty) {
      queryParams['assignedBranchId'] = assignedBranchId.trim();
    }

    final response = await _dio.get(
      '/events/$eventId/tasks',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final apiResponse = ApiResponse<List<dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as List<dynamic>,
    );

    if (apiResponse.data == null) {
      return [];
    }

    return apiResponse.data!
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Xem chi tiết một hạng mục công việc.
  Future<TaskModel> getTaskDetail(String eventId, String taskId) async {
    final response = await _dio.get('/events/$eventId/tasks/$taskId');

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as Map<String, dynamic>,
    );

    if (apiResponse.data == null) {
      throw Exception('Không có dữ liệu chi tiết công việc trả về từ máy chủ');
    }

    return TaskModel.fromJson(apiResponse.data!);
  }

  /// Khởi tạo một hạng mục công việc mới (`POST /api/v1/events/{id}/tasks`).
  Future<TaskModel> createTask(
    String eventId,
    CreateTaskRequestDto request,
  ) async {
    final response = await _dio.post(
      '/events/$eventId/tasks',
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as Map<String, dynamic>,
    );

    if (apiResponse.data == null) {
      throw Exception('Không nhận được dữ liệu công việc sau khi khởi tạo');
    }

    return TaskModel.fromJson(apiResponse.data!);
  }

  /// Phân công hoặc điều chuyển công việc (`POST /api/v1/events/{id}/tasks/{taskId}/assign`).
  Future<TaskModel> assignTask(
    String eventId,
    String taskId,
    AssignTaskRequestDto request,
  ) async {
    final response = await _dio.post(
      '/events/$eventId/tasks/$taskId/assign',
      data: request.toJson(),
    );

    final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => data as Map<String, dynamic>,
    );

    if (apiResponse.data == null) {
      throw Exception('Không nhận được dữ liệu công việc sau khi phân công');
    }

    return TaskModel.fromJson(apiResponse.data!);
  }
}

