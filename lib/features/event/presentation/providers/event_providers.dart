import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/event_remote_datasource.dart';
import '../../data/models/event_models.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/repositories/event_repository.dart';

class EventListState {
  final bool isLoading;
  final String? errorMessage;
  final List<EventModel> events;
  final String selectedFilter; // 'all', 'open', 'ongoing', 'completed'
  final String searchQuery;

  const EventListState({
    this.isLoading = false,
    this.errorMessage,
    this.events = const [],
    this.selectedFilter = 'all',
    this.searchQuery = '',
  });

  List<EventModel> get filteredEvents {
    return events.where((event) {
      // 1. Lọc theo trạng thái
      if (selectedFilter == 'open' && event.status != 'RegistrationOpen') {
        return false;
      }
      if (selectedFilter == 'ongoing' && event.status != 'Ongoing') {
        return false;
      }
      if (selectedFilter == 'completed' &&
          event.status != 'Closed' &&
          event.status != 'Ended') {
        return false;
      }

      // 2. Lọc theo từ khóa tìm kiếm
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final nameMatch = event.eventName.toLowerCase().contains(q);
        final locMatch = event.location.toLowerCase().contains(q);
        final lunarMatch =
            event.eventDateLunar?.toLowerCase().contains(q) ?? false;
        if (!nameMatch && !locMatch && !lunarMatch) return false;
      }

      return true;
    }).toList();
  }

  // KPI Metrics
  int get openEventsCount =>
      events.where((e) => e.status == 'RegistrationOpen' || e.status == 'Ongoing').length;

  double get totalBudgetMillions {
    final sum = events.fold<double>(0.0, (acc, e) => acc + e.estimatedBudget);
    return sum / 1000000;
  }

  double get averageAttendanceRate => 94.8; // Baseline thống kê toàn dòng họ

  EventListState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<EventModel>? events,
    String? selectedFilter,
    String? searchQuery,
  }) {
    return EventListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      events: events ?? this.events,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class EventListNotifier extends Notifier<EventListState> {
  EventRepository get _repository => ref.read(eventRepositoryProvider);

  @override
  EventListState build() {
    return EventListState(
      isLoading: false,
      events: EventRemoteDataSource.mockEvents,
    );
  }

  Future<void> loadEvents({bool showLoading = false}) async {
    if (state.events.isEmpty || showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final list = await _repository.getEvents();
      state = state.copyWith(isLoading: false, events: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách sự kiện: ${e.toString()}',
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createEvent(CreateEventRequestDto request) async {
    try {
      final created = await _repository.createEvent(request);
      state = state.copyWith(events: [created, ...state.events]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStatus(String eventId, String newStatus) async {
    try {
      final updated = await _repository.updateEventStatus(eventId, newStatus);
      final list = state.events.map((e) => e.eventId == eventId ? updated : e).toList();
      state = state.copyWith(events: list);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> assignPersonnel(
      String eventId, AssignPersonnelRequestDto request) async {
    try {
      final personnel = await _repository.assignPersonnel(eventId, request);
      final list = state.events.map((e) {
        if (e.eventId == eventId) {
          return e.copyWith(personnel: personnel);
        }
        return e;
      }).toList();
      state = state.copyWith(events: list);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEvent(
      String eventId, UpdateEventRequestDto request) async {
    try {
      final updated = await _repository.updateEvent(eventId, request);
      final list =
          state.events.map((e) => e.eventId == eventId ? updated : e).toList();
      state = state.copyWith(events: list);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final eventListProvider =
    NotifierProvider<EventListNotifier, EventListState>(EventListNotifier.new);

final eventNotificationsProvider =
    FutureProvider.family<List<EventNotificationModel>, String>((ref, eventId) async {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.getEventNotifications(eventId);
});
