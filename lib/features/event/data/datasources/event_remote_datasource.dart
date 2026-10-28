import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/event_models.dart';

class EventRemoteDataSource {
  final Dio _dio;

  EventRemoteDataSource(this._dio);

  // In-memory mock cache fallback để màn hình hiển thị hoàn mỹ ngay cả khi offline / chưa bật backend
  static List<EventModel> get mockEvents => _mockEvents;

  static final List<EventModel> _mockEvents = [
    EventModel(
      eventId: 'EVT_2026_GIOTO',
      eventName: 'Đại Lễ Giỗ Tiền Tổ & Thượng Điền',
      description: 'Giỗ tổ mùa xuân, dâng hương tiên liệt, tề tựu con cháu 6 chi phái.',
      eventDatetime: DateTime(2026, 4, 18, 8, 30),
      eventDateLunar: '10/03 Âm Lịch',
      location: 'Từ Đường Đại Tộc, Xã Kim Liên, Nam Đàn, Nghệ An',
      estimatedBudget: 65000000.0,
      status: 'RegistrationOpen',
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 1),
      registeredHouseholds: 148,
      banquetTables: 50,
      completedTasks: 18,
      totalTasks: 24,
      personnel: [
        const EventPersonnelModel(
          memberId: 'MEM_001',
          memberName: 'Ông Vũ Văn Thịnh',
          eventRole: 'HeadOfOrganizer',
        ),
        const EventPersonnelModel(
          memberId: 'MEM_002',
          memberName: 'Bà Vũ Thị Lan',
          eventRole: 'EventTreasurer',
        ),
      ],
    ),
    EventModel(
      eventId: 'EVT_2026_NHABIA',
      eventName: 'Khánh Thành Nhà Bia Tiên Liệt',
      description: 'Tôn tạo di tích, khánh thành công trình lưu danh tổ tiên.',
      eventDatetime: DateTime(2026, 8, 25, 9, 0),
      eventDateLunar: '20/07 Âm Lịch',
      location: 'Khu Lăng Mộ Tổ Phụ, Xã Kim Liên',
      estimatedBudget: 180000000.0,
      status: 'Ongoing',
      createdAt: DateTime(2026, 2, 10),
      updatedAt: DateTime(2026, 2, 10),
      registeredHouseholds: 85,
      banquetTables: 30,
      completedTasks: 8,
      totalTasks: 20,
      donatedAmount: 125500000.0,
      personnel: [
        const EventPersonnelModel(
          memberId: 'MEM_003',
          memberName: 'Ông Vũ Trọng Nghĩa',
          eventRole: 'HeadOfOrganizer',
        ),
      ],
    ),
    EventModel(
      eventId: 'EVT_2026_MUNGTHO',
      eventName: 'Lễ Mừng Thọ & Khen Thưởng Khuyến Học',
      description: 'Mừng thọ các cụ cao niên và trao học bổng cho con cháu đạt thành tích xuất sắc.',
      eventDatetime: DateTime(2026, 2, 22, 8, 0),
      eventDateLunar: '15/01 Âm Lịch',
      location: 'Nhà Văn Hóa Dòng Họ',
      estimatedBudget: 45000000.0,
      status: 'Closed',
      createdAt: DateTime(2026, 1, 5),
      updatedAt: DateTime(2026, 2, 23),
      closedAt: DateTime(2026, 2, 23),
      registeredHouseholds: 92,
      banquetTables: 25,
      completedTasks: 15,
      totalTasks: 15,
      donatedAmount: 42800000.0,
    ),
  ];

  static final List<EventNotificationModel> _mockNotifications = [
    EventNotificationModel(
      notificationId: 'NTF_01',
      eventId: 'EVT_2026_GIOTO',
      title: 'Mở đăng ký tham gia: Đại Lễ Giỗ Tiền Tổ',
      contentChanges: 'Sự kiện đã mở đăng ký tham gia cho toàn thể thành viên dòng họ.',
      sentTime: DateTime.now().subtract(const Duration(hours: 2)),
      triggeredBy: 'Trưởng Tộc',
    ),
    EventNotificationModel(
      notificationId: 'NTF_02',
      eventId: 'EVT_2026_GIOTO',
      title: 'Thông báo thay đổi lịch trình sự kiện: Đại Lễ Giỗ Tiền Tổ',
      contentChanges: 'Ngày giờ dương lịch: 17/04/2026 -> 18/04/2026; Địa điểm: Nhà thờ chi 1 -> Từ Đường Đại Tộc',
      sentTime: DateTime.now().subtract(const Duration(days: 1)),
      triggeredBy: 'Trưởng BTC',
    ),
  ];

  Future<List<EventModel>> getEvents() async {
    try {
      final response = await _dio.get('events');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List<dynamic>)
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _mockEvents;
    } on DioException {
      // Khi backend chưa chạy hoặc môi trường local, trả về danh sách mock chuẩn thiết kế
      return _mockEvents;
    }
  }

  Future<EventModel> getEventDetail(String eventId) async {
    try {
      final response = await _dio.get('events/$eventId');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => EventModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _findMock(eventId);
    } on DioException {
      return _findMock(eventId);
    }
  }

  Future<EventModel> createEvent(CreateEventRequestDto request) async {
    try {
      final response = await _dio.post(
        'events',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => EventModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        final created = apiResponse.data!;
        if (request.headOfOrganizerMemberId != null &&
            request.headOfOrganizerMemberId!.isNotEmpty) {
          try {
            await assignPersonnel(
              created.eventId,
              AssignPersonnelRequestDto(
                memberId: request.headOfOrganizerMemberId!,
                eventRole: 'HeadOfOrganizer',
              ),
            );
          } catch (_) {}
        }
        if (request.treasurerMemberId != null &&
            request.treasurerMemberId!.isNotEmpty) {
          try {
            await assignPersonnel(
              created.eventId,
              AssignPersonnelRequestDto(
                memberId: request.treasurerMemberId!,
                eventRole: 'EventTreasurer',
              ),
            );
          } catch (_) {}
        }
        _mockEvents.insert(0, created);
        return created;
      }
    } on DioException {
      // Fallback in-memory
    }

    // Tạo mock event và thêm vào đầu danh sách
    final newEvent = EventModel(
      eventId: 'EVT_${DateTime.now().millisecondsSinceEpoch}',
      eventName: request.eventName,
      description: request.description,
      eventDatetime: request.eventDatetime,
      eventDateLunar: request.eventDateLunar ?? 'Âm Lịch',
      location: request.location,
      estimatedBudget: request.estimatedBudget,
      status: 'Draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      registeredHouseholds: 0,
      banquetTables: 0,
      completedTasks: 0,
      totalTasks: 10,
      personnel: [
        if (request.headOfOrganizerMemberId != null)
          EventPersonnelModel(
            memberId: request.headOfOrganizerMemberId!,
            memberName: 'Trưởng Ban Tổ Chức',
            eventRole: 'HeadOfOrganizer',
          ),
        if (request.treasurerMemberId != null)
          EventPersonnelModel(
            memberId: request.treasurerMemberId!,
            memberName: 'Thủ Quỹ Sự Kiện',
            eventRole: 'EventTreasurer',
          ),
      ],
    );
    _mockEvents.insert(0, newEvent);
    return newEvent;
  }

  Future<EventModel> updateEvent(String eventId, UpdateEventRequestDto request) async {
    try {
      final response = await _dio.put(
        'events/$eventId',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => EventModel.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        _updateMock(apiResponse.data!);
        return apiResponse.data!;
      }
    } on DioException {
      // Fallback
    }

    final existing = _findMock(eventId);
    final updated = existing.copyWith(
      eventName: request.eventName,
      description: request.description,
      eventDatetime: request.eventDatetime,
      eventDateLunar: request.eventDateLunar,
      location: request.location,
      estimatedBudget: request.estimatedBudget,
    );
    _updateMock(updated);
    return updated;
  }

  Future<EventModel> updateEventStatus(String eventId, String newStatus) async {
    try {
      final response = await _dio.patch(
        'events/$eventId/status',
        data: {'newStatus': newStatus},
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => EventModel.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        _updateMock(apiResponse.data!);
        return apiResponse.data!;
      }
    } on DioException {
      // Fallback
    }

    final existing = _findMock(eventId);
    final updated = existing.copyWith(status: newStatus);
    _updateMock(updated);
    return updated;
  }

  Future<List<EventNotificationModel>> getEventNotifications(String eventId) async {
    try {
      final response = await _dio.get('events/$eventId/notifications');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List<dynamic>)
            .map((e) => EventNotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _mockNotifications;
    } on DioException {
      return _mockNotifications;
    }
  }

  Future<List<EventPersonnelModel>> assignPersonnel(
    String eventId,
    AssignPersonnelRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        'events/$eventId/personnel',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List<dynamic>)
            .map((e) => EventPersonnelModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (apiResponse.data != null) {
        final existing = _findMock(eventId);
        final updated = existing.copyWith(personnel: apiResponse.data!);
        _updateMock(updated);
        return apiResponse.data!;
      }
    } on DioException {
      // Fallback in-memory
    }

    final existing = _findMock(eventId);
    final currentList = List<EventPersonnelModel>.from(existing.personnel);
    final idx = currentList.indexWhere((p) => p.eventRole == request.eventRole);
    final newPersonnel = EventPersonnelModel(
      memberId: request.memberId,
      memberName: request.memberId == 'MEM_001'
          ? 'Ông Vũ Văn Thịnh'
          : (request.memberId == 'MEM_002' ? 'Bà Vũ Thị Lan' : 'Thành viên'),
      eventRole: request.eventRole,
    );
    if (idx != -1) {
      currentList[idx] = newPersonnel;
    } else {
      currentList.add(newPersonnel);
    }
    final updated = existing.copyWith(personnel: currentList);
    _updateMock(updated);
    return currentList;
  }

  EventModel _findMock(String eventId) {
    return _mockEvents.firstWhere(
      (e) => e.eventId == eventId,
      orElse: () => _mockEvents.first,
    );
  }

  void _updateMock(EventModel updated) {
    final idx = _mockEvents.indexWhere((e) => e.eventId == updated.eventId);
    if (idx != -1) {
      _mockEvents[idx] = updated;
    }
  }
}

final eventRemoteDataSourceProvider = Provider<EventRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return EventRemoteDataSource(dio);
});
