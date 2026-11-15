import '../../data/models/notification_models.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications({
    NotificationCategoryEnum? category,
    bool? isRead,
    int page = 0,
    int size = 20,
  });

  Future<UnreadCountModel> getUnreadSummary();

  Future<NotificationModel> markAsRead(String notificationId);

  Future<int> markAllAsRead({NotificationCategoryEnum? category});
}
