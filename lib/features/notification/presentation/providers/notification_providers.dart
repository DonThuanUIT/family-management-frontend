import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification_models.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationListState {
  final bool isLoading;
  final String? errorMessage;
  final NotificationCategoryEnum? selectedCategory;
  final bool unreadOnly;
  final List<NotificationModel> notifications;
  final UnreadCountModel unreadSummary;

  const NotificationListState({
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory,
    this.unreadOnly = false,
    this.notifications = const [],
    this.unreadSummary = const UnreadCountModel(),
  });

  List<NotificationModel> get taskDeadlineWarnings =>
      notifications.where((n) => n.isTaskDeadlineWarning).toList();

  int get unreadTaskWarningsCount =>
      notifications.where((n) => n.isTaskDeadlineWarning && !n.isRead).length;

  NotificationListState copyWith({
    bool? isLoading,
    String? errorMessage,
    NotificationCategoryEnum? Function()? selectedCategory,
    bool? unreadOnly,
    List<NotificationModel>? notifications,
    UnreadCountModel? unreadSummary,
  }) {
    return NotificationListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      notifications: notifications ?? this.notifications,
      unreadSummary: unreadSummary ?? this.unreadSummary,
    );
  }
}

final notificationListProvider =
    NotifierProvider<NotificationListNotifier, NotificationListState>(() {
  return NotificationListNotifier();
});

class NotificationListNotifier extends Notifier<NotificationListState> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  NotificationListState build() {
    Future.microtask(() => loadInitial());
    return const NotificationListState();
  }

  Future<void> loadInitial() async {
    await Future.wait([
      fetchNotifications(),
      fetchUnreadCount(),
    ]);
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repo.getNotifications(
        category: state.selectedCategory,
        isRead: state.unreadOnly ? false : null,
      );
      state = state.copyWith(
        isLoading: false,
        notifications: items,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải danh sách thông báo: ${e.toString()}',
      );
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final summary = await _repo.getUnreadSummary();
      state = state.copyWith(unreadSummary: summary);
    } catch (_) {}
  }

  void setCategory(NotificationCategoryEnum? category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: () => category);
    fetchNotifications();
  }

  void setUnreadOnly(bool unreadOnly) {
    if (state.unreadOnly == unreadOnly) return;
    state = state.copyWith(unreadOnly: unreadOnly);
    fetchNotifications();
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final updated = await _repo.markAsRead(notificationId);
      final updatedList = state.notifications.map((n) {
        if (n.notificationId == notificationId) {
          return updated;
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updatedList,
      );
      await fetchUnreadCount();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _repo.markAllAsRead(category: state.selectedCategory);
      final updatedList = state.notifications.map((n) {
        if (state.selectedCategory == null || n.category == state.selectedCategory) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updatedList,
      );
      await fetchUnreadCount();
      return true;
    } catch (_) {
      return false;
    }
  }
}
