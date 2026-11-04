import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

/// Trạng thái chính thức của một hạng mục công việc trong sự kiện (US-07).
/// Khớp với ràng buộc CHECK trong bảng cơ sở dữ liệu `event_tasks` và backend enum `TaskStatus`.
enum TaskStatusEnum {
  unassigned('Unassigned', 'Chưa giao'),
  inProgress('InProgress', 'Đang thực hiện'),
  completed('Completed', 'Đã hoàn thành'),
  overdue('Overdue', 'Quá hạn');

  final String code;
  final String displayName;

  const TaskStatusEnum(this.code, this.displayName);

  static TaskStatusEnum fromCode(String? code) {
    if (code == null) return TaskStatusEnum.unassigned;
    return TaskStatusEnum.values.firstWhere(
      (e) => e.code.toLowerCase() == code.toLowerCase(),
      orElse: () => TaskStatusEnum.unassigned,
    );
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case TaskStatusEnum.unassigned:
        return const Color(0xFFF3F4F6); // Neutral gray
      case TaskStatusEnum.inProgress:
        return const Color(0xFFEFF6FF); // Soft blue
      case TaskStatusEnum.completed:
        return const Color(0xFFECFDF5); // Soft green
      case TaskStatusEnum.overdue:
        return const Color(0xFFFEF2F2); // Soft red
    }
  }

  Color get badgeTextColor {
    switch (this) {
      case TaskStatusEnum.unassigned:
        return const Color(0xFF4B5563);
      case TaskStatusEnum.inProgress:
        return const Color(0xFF1D4ED8);
      case TaskStatusEnum.completed:
        return const Color(0xFF047857);
      case TaskStatusEnum.overdue:
        return AppTheme.primaryCrimson;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskStatusEnum.unassigned:
        return Icons.assignment_outlined;
      case TaskStatusEnum.inProgress:
        return Icons.pending_actions_outlined;
      case TaskStatusEnum.completed:
        return Icons.check_circle_outline;
      case TaskStatusEnum.overdue:
        return Icons.warning_amber_rounded;
    }
  }
}

/// DTO & Entity biểu diễn một công việc chuẩn bị cho sự kiện.
/// Tuân thủ quy tắc 05: Lưu trữ tiền tệ dưới dạng số nguyên `int` (đồng),
/// không dùng `double` để tránh sai số dấu phẩy động.
class TaskModel {
  final String taskId;
  final String eventId;
  final String taskName;
  final String? details;
  final int advanceBudget; // Đơn vị: VNĐ (int)
  final DateTime deadline;
  final TaskStatusEnum status;
  final String? assignedBranchId;
  final String? assignedBranchName;
  final String? assignedMemberId;
  final String? assignedMemberName;
  final String createdBy;

  const TaskModel({
    required this.taskId,
    required this.eventId,
    required this.taskName,
    this.details,
    required this.advanceBudget,
    required this.deadline,
    required this.status,
    this.assignedBranchId,
    this.assignedBranchName,
    this.assignedMemberId,
    this.assignedMemberName,
    required this.createdBy,
  });

  bool get hasAssignee =>
      (assignedMemberId != null && assignedMemberId!.trim().isNotEmpty) ||
      (assignedBranchId != null && assignedBranchId!.trim().isNotEmpty);

  String get assigneeDisplayName {
    if (assignedMemberName != null && assignedMemberName!.isNotEmpty) {
      if (assignedBranchName != null && assignedBranchName!.isNotEmpty) {
        return '$assignedMemberName ($assignedBranchName)';
      }
      return assignedMemberName!;
    }
    if (assignedBranchName != null && assignedBranchName!.isNotEmpty) {
      return assignedBranchName!;
    }
    return 'Chưa chỉ định';
  }

  String get formattedAdvanceBudget => AppFormatters.formatVnd(advanceBudget);

  String get formattedDeadline => AppFormatters.formatDateTime(deadline);

  String get formattedDeadlineDate => AppFormatters.formatDate(deadline);

  bool get isOverdue =>
      status == TaskStatusEnum.overdue ||
      (status != TaskStatusEnum.completed && deadline.isBefore(DateTime.now()));

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawBudget = json['advanceBudget'];
    int budgetInt = 0;
    if (rawBudget is num) {
      budgetInt = rawBudget.round();
    } else if (rawBudget is String) {
      budgetInt = (double.tryParse(rawBudget) ?? 0.0).round();
    }

    return TaskModel(
      taskId: json['taskId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      taskName: json['taskName'] as String? ?? '',
      details: json['details'] as String?,
      advanceBudget: budgetInt,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())?.toLocal() ??
              DateTime.now()
          : DateTime.now(),
      status: TaskStatusEnum.fromCode(json['status'] as String?),
      assignedBranchId: json['assignedBranchId'] as String?,
      assignedBranchName: json['assignedBranchName'] as String?,
      assignedMemberId: json['assignedMemberId'] as String?,
      assignedMemberName: json['assignedMemberName'] as String?,
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'eventId': eventId,
        'taskName': taskName,
        'details': details,
        'advanceBudget': advanceBudget,
        'deadline': deadline.toUtc().toIso8601String(),
        'status': status.code,
        'assignedBranchId': assignedBranchId,
        'assignedBranchName': assignedBranchName,
        'assignedMemberId': assignedMemberId,
        'assignedMemberName': assignedMemberName,
        'createdBy': createdBy,
      };

  TaskModel copyWith({
    String? taskId,
    String? eventId,
    String? taskName,
    String? details,
    int? advanceBudget,
    DateTime? deadline,
    TaskStatusEnum? status,
    String? assignedBranchId,
    String? assignedBranchName,
    String? assignedMemberId,
    String? assignedMemberName,
    String? createdBy,
  }) {
    return TaskModel(
      taskId: taskId ?? this.taskId,
      eventId: eventId ?? this.eventId,
      taskName: taskName ?? this.taskName,
      details: details ?? this.details,
      advanceBudget: advanceBudget ?? this.advanceBudget,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      assignedBranchId: assignedBranchId ?? this.assignedBranchId,
      assignedBranchName: assignedBranchName ?? this.assignedBranchName,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
      assignedMemberName: assignedMemberName ?? this.assignedMemberName,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

/// Request DTO tạo mới công việc cho sự kiện (`POST /api/v1/events/{id}/tasks`).
class CreateTaskRequestDto {
  final String taskName;
  final String? details;
  final int advanceBudget;
  final DateTime deadline;
  final String? assignedBranchId;
  final String? assignedMemberId;

  const CreateTaskRequestDto({
    required this.taskName,
    this.details,
    this.advanceBudget = 0,
    required this.deadline,
    this.assignedBranchId,
    this.assignedMemberId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'taskName': taskName.trim(),
      'advanceBudget': advanceBudget,
      'deadline': deadline.toUtc().toIso8601String(),
    };
    if (details != null && details!.trim().isNotEmpty) {
      map['details'] = details!.trim();
    }
    if (assignedBranchId != null && assignedBranchId!.trim().isNotEmpty) {
      map['assignedBranchId'] = assignedBranchId!.trim();
    }
    if (assignedMemberId != null && assignedMemberId!.trim().isNotEmpty) {
      map['assignedMemberId'] = assignedMemberId!.trim();
    }
    return map;
  }
}

/// Request DTO phân công hoặc gán lại công việc (`POST /api/v1/events/{id}/tasks/{taskId}/assign`).
class AssignTaskRequestDto {
  final String? assignedBranchId;
  final String? assignedMemberId;

  const AssignTaskRequestDto({
    this.assignedBranchId,
    this.assignedMemberId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (assignedBranchId != null && assignedBranchId!.trim().isNotEmpty) {
      map['assignedBranchId'] = assignedBranchId!.trim();
    }
    if (assignedMemberId != null && assignedMemberId!.trim().isNotEmpty) {
      map['assignedMemberId'] = assignedMemberId!.trim();
    }
    return map;
  }
}

