import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_models.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;

  const TaskRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<TaskModel>> getTasks(
    String eventId, {
    TaskStatusEnum? status,
    String? assignedMemberId,
    String? assignedBranchId,
  }) async {
    try {
      return await _remoteDataSource.getTasks(
        eventId,
        status: status,
        assignedMemberId: assignedMemberId,
        assignedBranchId: assignedBranchId,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TaskModel> getTaskDetail(String eventId, String taskId) async {
    try {
      return await _remoteDataSource.getTaskDetail(eventId, taskId);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TaskModel> createTask(
    String eventId,
    CreateTaskRequestDto request,
  ) async {
    try {
      return await _remoteDataSource.createTask(eventId, request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TaskModel> assignTask(
    String eventId,
    String taskId,
    AssignTaskRequestDto request,
  ) async {
    try {
      return await _remoteDataSource.assignTask(eventId, taskId, request);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      final message = (data['message'] as String?) ?? 'Lỗi từ máy chủ';
      final statusCode = e.response?.statusCode;

      if (statusCode == 403) {
        return ForbiddenFailure(message: message, statusCode: statusCode);
      }
      if (statusCode == 401) {
        return UnauthorizedFailure(message: message, statusCode: statusCode);
      }
      if (statusCode == 400) {
        return BusinessInvariantFailure(message: message, statusCode: statusCode);
      }
      return ServerFailure(message: message, statusCode: statusCode);
    }
    return const NetworkFailure();
  }
}

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TaskRemoteDataSource(dio);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final remoteDataSource = ref.watch(taskRemoteDataSourceProvider);
  return TaskRepositoryImpl(remoteDataSource);
});

