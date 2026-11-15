import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remote = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remote);
});

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remote;

  NotificationRepositoryImpl(this._remote);

  @override
  Future<List<NotificationModel>> getNotifications({
    NotificationCategoryEnum? category,
    bool? isRead,
    int page = 0,
    int size = 20,
  }) {
    return _remote.getNotifications(
      category: category,
      isRead: isRead,
      page: page,
      size: size,
    );
  }

  @override
  Future<UnreadCountModel> getUnreadSummary() {
    return _remote.getUnreadSummary();
  }

  @override
  Future<NotificationModel> markAsRead(String notificationId) {
    return _remote.markAsRead(notificationId);
  }

  @override
  Future<int> markAllAsRead({NotificationCategoryEnum? category}) {
    return _remote.markAllAsRead(category: category);
  }
}
