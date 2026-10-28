import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';
import '../models/event_models.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource _remoteDataSource;

  EventRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<EventModel>> getEvents() => _remoteDataSource.getEvents();

  @override
  Future<EventModel> getEventDetail(String eventId) =>
      _remoteDataSource.getEventDetail(eventId);

  @override
  Future<EventModel> createEvent(CreateEventRequestDto request) =>
      _remoteDataSource.createEvent(request);

  @override
  Future<EventModel> updateEvent(String eventId, UpdateEventRequestDto request) =>
      _remoteDataSource.updateEvent(eventId, request);

  @override
  Future<EventModel> updateEventStatus(String eventId, String newStatus) =>
      _remoteDataSource.updateEventStatus(eventId, newStatus);

  @override
  Future<List<EventPersonnelModel>> assignPersonnel(
    String eventId,
    AssignPersonnelRequestDto request,
  ) =>
      _remoteDataSource.assignPersonnel(eventId, request);

  @override
  Future<List<EventNotificationModel>> getEventNotifications(String eventId) =>
      _remoteDataSource.getEventNotifications(eventId);
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final remoteDataSource = ref.watch(eventRemoteDataSourceProvider);
  return EventRepositoryImpl(remoteDataSource);
});
