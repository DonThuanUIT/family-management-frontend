import 'dart:typed_data';

import 'package:familyfund_app/features/event/data/models/event_models.dart';
import 'package:familyfund_app/features/event/data/repositories/event_repository_impl.dart';
import 'package:familyfund_app/features/event/domain/repositories/event_repository.dart';
import 'package:familyfund_app/features/event/presentation/widgets/create_event_sheet.dart';
import 'package:familyfund_app/features/event/presentation/widgets/event_registration_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDeadlineEventRepository implements EventRepository {
  @override
  Future<RegistrationModel?> getMyRegistration(String eventId) async => null;

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

EventModel _buildEvent({
  DateTime? deadline,
  int? maxCapacity,
  int currentAttendees = 0,
  int? remainingSlots,
}) {
  return EventModel(
    eventId: 'EVT_43',
    eventName: 'Giỗ Tổ 2026',
    eventDatetime: DateTime.now().add(const Duration(days: 10)),
    location: 'Từ Đường',
    status: 'RegistrationOpen',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    registrationDeadline: deadline,
    maxCapacity: maxCapacity,
    currentAttendees: currentAttendees,
    remainingSlots: remainingSlots,
  );
}

void main() {
  testWidgets(
    'US-43: Displays countdown timer and remaining slots when open within deadline & capacity',
    (tester) async {
      final event = _buildEvent(
        deadline: DateTime.now().add(const Duration(days: 2, hours: 3)),
        maxCapacity: 50,
        currentAttendees: 35,
        remainingSlots: 15,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRepositoryProvider
                .overrideWithValue(_FakeDeadlineEventRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EventRegistrationSection(event: event),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('registration_countdown_row')), findsOneWidget);
      expect(find.textContaining('Còn lại: 2 ngày'), findsOneWidget);
      expect(
        find.byKey(const Key('registration_remaining_slots_row')),
        findsOneWidget,
      );
      expect(find.text('Số chỗ còn lại: 15 / 50 chỗ'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Đăng Ký Tham Dự'),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'US-43: Disables registration when deadline has passed or capacity is full',
    (tester) async {
      final expiredEvent = _buildEvent(
        deadline: DateTime.now().subtract(const Duration(hours: 2)),
        maxCapacity: 50,
        currentAttendees: 50,
        remainingSlots: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRepositoryProvider
                .overrideWithValue(_FakeDeadlineEventRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EventRegistrationSection(event: expiredEvent),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Đã hết hạn đăng ký'), findsOneWidget);
      expect(find.text('Đã hết chỗ (0 / 50 chỗ)'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Đã Hết Hạn Đăng Ký'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'US-43: CreateEventSheet renders BTC deadline and max capacity configuration fields',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CreateEventSheet(),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('create_event_deadline_picker')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('create_event_max_capacity_input')),
        findsOneWidget,
      );
      expect(find.text('Hạn Chót Đăng Ký'), findsOneWidget);
      expect(find.text('Sức Chứa Tối Đa'), findsOneWidget);
    },
  );
}
