import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyfund_app/features/event/data/models/event_models.dart';
import 'package:familyfund_app/features/event/data/repositories/event_repository_impl.dart';
import 'package:familyfund_app/features/event/domain/repositories/event_repository.dart';
import 'package:familyfund_app/features/event/presentation/widgets/event_registration_section.dart';

class _FakeEventRepository implements EventRepository {
  RegistrationModel? myRegistration;
  bool updateCalled = false;
  bool cancelCalled = false;

  _FakeEventRepository({this.myRegistration});

  @override
  Future<RegistrationModel?> getMyRegistration(String eventId) async =>
      myRegistration;

  @override
  Future<RegistrationModel> updateRegistration(
    String registrationId,
    UpdateRegistrationRequestDto request,
  ) async {
    updateCalled = true;
    myRegistration = RegistrationModel(
      registrationId: registrationId,
      eventId: myRegistration?.eventId ?? 'EVT_1',
      representativeMemberId: 'MEM_1',
      representativeMemberName: 'Đại diện',
      totalAttendees: request.totalAttendees,
      vegetarianMeals: request.vegetarianMeals,
      savoryMeals: request.savoryMeals,
      status: 'Confirmed',
    );
    return myRegistration!;
  }

  @override
  Future<RegistrationModel> cancelRegistration(String registrationId) async {
    cancelCalled = true;
    myRegistration = RegistrationModel(
      registrationId: registrationId,
      eventId: myRegistration?.eventId ?? 'EVT_1',
      representativeMemberId: 'MEM_1',
      representativeMemberName: 'Đại diện',
      totalAttendees: myRegistration?.totalAttendees ?? 1,
      vegetarianMeals: 0,
      savoryMeals: 1,
      status: 'Cancelled',
    );
    return myRegistration!;
  }

  @override
  Future<List<EventPersonnelModel>> assignPersonnel(
    String eventId,
    AssignPersonnelRequestDto request,
  ) =>
      throw UnimplementedError();

  @override
  Future<EventModel> createEvent(CreateEventRequestDto request) =>
      throw UnimplementedError();

  @override
  Future<EventModel> getEventDetail(String eventId) =>
      throw UnimplementedError();

  @override
  Future<List<EventNotificationModel>> getEventNotifications(String eventId) =>
      throw UnimplementedError();

  @override
  Future<List<EventModel>> getEvents() => throw UnimplementedError();

  @override
  Future<RegistrationModel> registerAttendees(
    String eventId,
    RegisterAttendeesRequestDto request,
  ) =>
      throw UnimplementedError();

  @override
  Future<EventModel> updateEvent(String eventId, UpdateEventRequestDto request) =>
      throw UnimplementedError();

  @override
  Future<EventModel> updateEventStatus(String eventId, String newStatus) =>
      throw UnimplementedError();

  @override
  Future<EventLogisticsSummaryModel> getEventRegistrationSummary(
    String eventId, {
    String? branchId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> exportEventRegistrationSummary(
    String eventId, {
    String? branchId,
    String format = 'xlsx',
  }) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EventModel _buildEvent(String status) {
  return EventModel(
    eventId: 'EVT_1',
    eventName: 'Giỗ Tổ',
    eventDatetime: DateTime(2026, 4, 18, 8, 30),
    location: 'Từ Đường',
    estimatedBudget: 10000000,
    status: status,
    createdAt: DateTime(2026, 3, 1),
    updatedAt: DateTime(2026, 3, 1),
  );
}

void main() {
  testWidgets(
      'US-41: RegistrationOpen cho phép bấm Chỉnh sửa đăng ký & Hủy đăng ký',
      (tester) async {
    final fakeRepo = _FakeEventRepository(
      myRegistration: const RegistrationModel(
        registrationId: 'REG_1',
        eventId: 'EVT_1',
        representativeMemberId: 'MEM_1',
        representativeMemberName: 'Nguyễn Văn A',
        totalAttendees: 3,
        vegetarianMeals: 1,
        savoryMeals: 2,
        status: 'Confirmed',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EventRegistrationSection(event: _buildEvent('RegistrationOpen')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh sửa đăng ký'), findsOneWidget);
    expect(find.text('Hủy đăng ký'), findsOneWidget);

    await tester.tap(find.text('Chỉnh sửa đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu Thay Đổi'));
    await tester.pumpAndSettle();
    expect(fakeRepo.updateCalled, isTrue);

    await tester.tap(find.text('Hủy đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận hủy'));
    await tester.pumpAndSettle();
    expect(fakeRepo.cancelCalled, isTrue);
  });

  testWidgets(
      'US-41: RegistrationClosed tự động khóa nút và hiện thông báo liên hệ BTC',
      (tester) async {
    final fakeRepo = _FakeEventRepository(
      myRegistration: const RegistrationModel(
        registrationId: 'REG_1',
        eventId: 'EVT_1',
        representativeMemberId: 'MEM_1',
        representativeMemberName: 'Nguyễn Văn A',
        totalAttendees: 3,
        vegetarianMeals: 1,
        savoryMeals: 2,
        status: 'Confirmed',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EventRegistrationSection(
              event: _buildEvent('RegistrationClosed'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('liên hệ trực tiếp Ban tổ chức (BTC)'),
      findsOneWidget,
    );

    final editBtn = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Chỉnh sửa đăng ký'),
    );
    final cancelBtn = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Hủy đăng ký'),
    );
    expect(editBtn.onPressed, isNull);
    expect(cancelBtn.onPressed, isNull);
  });
}
