import '../../data/models/event_models.dart';

abstract class EventRepository {
  Future<List<EventModel>> getEvents();
  Future<EventModel> getEventDetail(String eventId);
  Future<EventModel> createEvent(CreateEventRequestDto request);
  Future<EventModel> updateEvent(String eventId, UpdateEventRequestDto request);
  Future<EventModel> updateEventStatus(String eventId, String newStatus);
  Future<List<EventPersonnelModel>> assignPersonnel(
      String eventId, AssignPersonnelRequestDto request);
  Future<List<EventNotificationModel>> getEventNotifications(String eventId);
}
