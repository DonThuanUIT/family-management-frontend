import 'package:flutter/material.dart';

/// Danh mục thông báo cá nhân (US-39 & US-08)
enum NotificationCategoryEnum {
  event('Event', 'Sự Kiện', Icons.event_outlined, Color(0xFF0369A1), Color(0xFFE0F2FE)),
  task('Task', 'Công Việc', Icons.assignment_late_outlined, Color(0xFF8B1E1E), Color(0xFFFFDAD6)),
  finance('Finance', 'Tài Chính', Icons.account_balance_wallet_outlined, Color(0xFF006E2A), Color(0xFFE8F5E9));

  final String code;
  final String displayName;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;

  const NotificationCategoryEnum(
    this.code,
    this.displayName,
    this.icon,
    this.primaryColor,
    this.backgroundColor,
  );

  static NotificationCategoryEnum? fromCode(String? code) {
    if (code == null) return null;
    for (final c in NotificationCategoryEnum.values) {
      if (c.code.toLowerCase() == code.toLowerCase()) {
        return c;
      }
    }
    return null;
  }
}

/// DTO / Model Thông báo trong Hộp thư thông báo cá nhân
@immutable
class NotificationModel {
  final String notificationId;
  final String clanId;
  final NotificationCategoryEnum category;
  final String title;
  final String content;
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.clanId,
    required this.category,
    required this.title,
    required this.content,
    this.referenceType,
    this.referenceId,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  /// Kiểm tra xem thông báo này có phải cảnh báo tiến độ hạn chót (US-08)
  bool get isTaskDeadlineWarning {
    if (category != NotificationCategoryEnum.task) return false;
    final lowerTitle = title.toLowerCase();
    final lowerContent = content.toLowerCase();
    return lowerTitle.contains('cảnh báo tiến độ') ||
        lowerTitle.contains('tiến độ') ||
        lowerContent.contains('24 giờ') ||
        lowerContent.contains('hạn chót') ||
        lowerTitle.contains('nhắc nhở');
  }

  NotificationModel copyWith({
    String? notificationId,
    String? clanId,
    NotificationCategoryEnum? category,
    String? title,
    String? content,
    String? referenceType,
    String? referenceId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      clanId: clanId ?? this.clanId,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final catStr = json['category'] as String?;
    final category = NotificationCategoryEnum.fromCode(catStr) ?? NotificationCategoryEnum.task;

    DateTime createdAtDate = DateTime.now();
    if (json['createdAt'] != null) {
      createdAtDate = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

    DateTime? readAtDate;
    if (json['readAt'] != null) {
      readAtDate = DateTime.tryParse(json['readAt'].toString());
    }

    return NotificationModel(
      notificationId: (json['notificationId'] as String?) ?? '',
      clanId: (json['clanId'] as String?) ?? '',
      category: category,
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      isRead: (json['isRead'] as bool?) ?? false,
      readAt: readAtDate,
      createdAt: createdAtDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'clanId': clanId,
      'category': category.code,
      'title': title,
      'content': content,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'isRead': isRead,
      'readAt': readAt?.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}

/// DTO đếm số lượng thông báo chưa đọc theo danh mục (UnreadCountResponse)
@immutable
class UnreadCountModel {
  final int total;
  final int eventCount;
  final int taskCount;
  final int financeCount;

  const UnreadCountModel({
    this.total = 0,
    this.eventCount = 0,
    this.taskCount = 0,
    this.financeCount = 0,
  });

  bool get hasUnread => total > 0;
  bool get hasUnreadTasks => taskCount > 0;

  factory UnreadCountModel.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] as num?)?.toInt() ?? 0;
    int ev = 0;
    int tk = 0;
    int fn = 0;

    if (json['byCategory'] is Map) {
      final byCat = json['byCategory'] as Map<String, dynamic>;
      ev = (byCat['event'] ?? byCat['Event'] ?? byCat['eventCount'] as num?)?.toInt() ?? 0;
      tk = (byCat['task'] ?? byCat['Task'] ?? byCat['taskCount'] as num?)?.toInt() ?? 0;
      fn = (byCat['finance'] ?? byCat['Finance'] ?? byCat['financeCount'] as num?)?.toInt() ?? 0;
    } else {
      ev = ((json['eventCount'] ?? json['event'] ?? json['Event']) as num?)?.toInt() ?? 0;
      tk = ((json['taskCount'] ?? json['task'] ?? json['Task']) as num?)?.toInt() ?? 0;
      fn = ((json['financeCount'] ?? json['finance'] ?? json['Finance']) as num?)?.toInt() ?? 0;
    }

    return UnreadCountModel(
      total: total,
      eventCount: ev,
      taskCount: tk,
      financeCount: fn,
    );
  }
}
