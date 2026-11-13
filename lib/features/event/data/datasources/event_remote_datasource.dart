import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/event_budget_models.dart';
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

  static final Map<String, RegistrationModel> _mockMyRegistrations = {
    'EVT_2026_GIOTO': const RegistrationModel(
      registrationId: 'REG_MOCK_01',
      eventId: 'EVT_2026_GIOTO',
      representativeMemberId: 'MEM_001',
      representativeMemberName: 'Đại diện hộ gia đình',
      totalAttendees: 4,
      vegetarianMeals: 1,
      savoryMeals: 3,
      transportationNotes: 'Xe 7 chỗ',
      status: 'Confirmed',
    ),
  };

  Future<RegistrationModel?> getMyRegistration(String eventId) async {
    try {
      final response = await _dio.get('events/$eventId/registrations/me');
      final apiResponse = ApiResponse<RegistrationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RegistrationModel.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        _mockMyRegistrations[eventId] = apiResponse.data!;
        return apiResponse.data;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      return _mockMyRegistrations[eventId];
    }
  }

  Future<RegistrationModel> registerAttendees(
    String eventId,
    RegisterAttendeesRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        'events/$eventId/registrations',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse<RegistrationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RegistrationModel.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        _mockMyRegistrations[eventId] = apiResponse.data!;
        return apiResponse.data!;
      }
      throw Exception('Không nhận được phản hồi đăng ký từ máy chủ');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message']?.toString() ??
            'Không thể đăng ký tham dự sự kiện';
        throw Exception(msg);
      }
      final mock = RegistrationModel(
        registrationId: 'REG_${DateTime.now().millisecondsSinceEpoch}',
        eventId: eventId,
        representativeMemberId: 'MEM_CURRENT',
        representativeMemberName: 'Đại diện hộ gia đình',
        totalAttendees: request.totalAttendees,
        vegetarianMeals: request.vegetarianMeals,
        savoryMeals: request.savoryMeals,
        dietaryRequirements: request.dietaryRequirements,
        transportationNotes: request.transportationNotes,
        status: 'Confirmed',
      );
      _mockMyRegistrations[eventId] = mock;
      return mock;
    }
  }

  Future<RegistrationModel> updateRegistration(
    String registrationId,
    UpdateRegistrationRequestDto request,
  ) async {
    try {
      final response = await _dio.put(
        'registrations/$registrationId',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse<RegistrationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RegistrationModel.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        _mockMyRegistrations[apiResponse.data!.eventId] = apiResponse.data!;
        return apiResponse.data!;
      }
      throw Exception('Không nhận được phản hồi cập nhật đăng ký');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message']?.toString() ??
            'Không thể cập nhật đăng ký tham dự';
        throw Exception(msg);
      }
      throw Exception('Không thể kết nối máy chủ để cập nhật đăng ký');
    }
  }

  Future<RegistrationModel> cancelRegistration(String registrationId) async {
    try {
      final response = await _dio.delete('registrations/$registrationId');
      final apiResponse = ApiResponse<RegistrationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RegistrationModel.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        _mockMyRegistrations[apiResponse.data!.eventId] = apiResponse.data!;
        return apiResponse.data!;
      }
      throw Exception('Không nhận được phản hồi hủy đăng ký');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message']?.toString() ??
            'Không thể hủy đăng ký tham dự';
        throw Exception(msg);
      }
      throw Exception('Không thể kết nối máy chủ để hủy đăng ký');
    }
  }

  /// Lấy bảng tổng hợp hậu cần tức thời cho BTC (US-42).
  Future<EventLogisticsSummaryModel> getEventRegistrationSummary(
    String eventId, {
    String? branchId,
  }) async {
    try {
      final response = await _dio.get(
        'events/$eventId/registration-summary',
        queryParameters: {
          if (branchId != null && branchId.trim().isNotEmpty)
            'branchId': branchId.trim(),
        },
      );
      final apiResponse = ApiResponse<EventLogisticsSummaryModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            EventLogisticsSummaryModel.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception('Không nhận được dữ liệu tổng hợp hậu cần');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data?['message']?.toString() ??
            'Không thể tải bảng tổng hợp hậu cần sự kiện';
        throw Exception(msg);
      }
      return _buildMockLogisticsSummary(eventId, branchId: branchId);
    }
  }

  /// Xuất file danh sách điểm danh & chia cỗ (.xlsx hoặc .csv) cho BTC (US-42).
  Future<Uint8List> exportEventRegistrationSummary(
    String eventId, {
    String? branchId,
    String format = 'xlsx',
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        'events/$eventId/registration-summary/export',
        queryParameters: {
          if (branchId != null && branchId.trim().isNotEmpty)
            'branchId': branchId.trim(),
          'format': format,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data != null) {
        return Uint8List.fromList(data);
      }
      throw Exception('Không nhận được nội dung file xuất danh sách');
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data is Map
            ? (e.response?.data['message']?.toString() ??
                'Không thể xuất danh sách hậu cần')
            : 'Không thể xuất danh sách hậu cần';
        throw Exception(msg);
      }
      throw Exception('Không thể kết nối máy chủ để xuất file danh sách');
    }
  }

  EventLogisticsSummaryModel _buildMockLogisticsSummary(
    String eventId, {
    String? branchId,
  }) {
    final event = _findMock(eventId);
    const branches = [
      LogisticsBranchOptionModel(branchId: 'BR_01', branchName: 'Chi Nhất'),
      LogisticsBranchOptionModel(branchId: 'BR_02', branchName: 'Chi Nhì'),
    ];
    final allItems = [
      HouseholdLogisticsItemModel(
        registrationId: 'REG_DEMO_01',
        representativeMemberId: 'MEM_01',
        representativeName: 'Nguyễn Văn An',
        branchId: 'BR_01',
        branchName: 'Chi Nhất',
        totalAttendees: 4,
        savoryMeals: 3,
        vegetarianMeals: 1,
        shuttleSeats: 2,
        dietaryRequirements: '1 suất chay trường',
        transportationNotes: 'Xe đưa đón 2 chỗ',
        status: 'Confirmed',
        registrationDate: DateTime.now(),
      ),
      HouseholdLogisticsItemModel(
        registrationId: 'REG_DEMO_02',
        representativeMemberId: 'MEM_02',
        representativeName: 'Nguyễn Thị Bình',
        branchId: 'BR_02',
        branchName: 'Chi Nhì',
        totalAttendees: 3,
        savoryMeals: 3,
        vegetarianMeals: 0,
        shuttleSeats: 3,
        transportationNotes: 'Xe chung 3 chỗ',
        status: 'Confirmed',
        registrationDate: DateTime.now(),
      ),
    ];

    final filtered = (branchId != null && branchId.isNotEmpty)
        ? allItems.where((i) => i.branchId == branchId).toList()
        : allItems;

    return EventLogisticsSummaryModel(
      eventId: eventId,
      eventName: event.eventName,
      branchId: branchId,
      branchName: branchId == null
          ? null
          : branches
              .where((b) => b.branchId == branchId)
              .map((b) => b.branchName)
              .firstOrNull,
      totalRegistrations: filtered.length,
      totalAttendees: filtered.fold(0, (sum, i) => sum + i.totalAttendees),
      totalSavoryMeals: filtered.fold(0, (sum, i) => sum + i.savoryMeals),
      totalVegetarianMeals:
          filtered.fold(0, (sum, i) => sum + i.vegetarianMeals),
      totalShuttleSeats: filtered.fold(0, (sum, i) => sum + i.shuttleSeats),
      availableBranches: branches,
      registrations: filtered,
    );
  }

  /// [US-37] Lấy báo cáo tổng hợp ngân sách sự kiện và cờ cảnh báo vượt trần dự toán
  Future<EventBudgetSummaryModel> getEventBudgetSummary(String eventId) async {
    try {
      final response = await _dio.get('/api/v1/events/$eventId/budget-summary');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            return EventBudgetSummaryModel.fromJson(data['data'] as Map<String, dynamic>);
          }
          return EventBudgetSummaryModel.fromJson(data);
        }
      }
    } catch (_) {
      // Fallback mock khi offline hoặc server chưa kết nối
    }
    return _buildMockBudgetSummary(eventId);
  }

  EventBudgetSummaryModel _buildMockBudgetSummary(String eventId) {
    return const EventBudgetSummaryModel(
      eventId: 'EVT_2026_GIOTO',
      eventName: 'Đại Lễ Giỗ Tổ 2026',
      eventStatus: 'RegistrationOpen',
      estimatedBudget: 250000000.0,
      totalAdvanceBudget: 230000000.0,
      totalAdvanceAmount: 50000000.0,
      totalActualExpenseAmount: 222500000.0,
      verifiedActualExpenseAmount: 185000000.0,
      unallocatedBudget: 20000000.0,
      remainingBudgetByAdvance: 200000000.0,
      remainingBudgetByActualExpense: 27500000.0,
      overrunAmount: 22500000.0,
      taskBudgetUtilizationPercent: 92.0,
      advanceUtilizationPercent: 20.0,
      actualExpenseUtilizationPercent: 89.0,
      isOverBudget: true,
      isAdvanceOverEstimated: false,
      isActualExpenseOverEstimated: true,
      isTaskBudgetOverEstimated: false,
      hasTaskOverBudget: true,
      warningLevel: 'CRITICAL',
      warningMessages: [
        'Tổng thực chi (222.500.000 đ) cộng tạm ứng đang lưu động đã vượt dự toán sự kiện (250.000.000 đ).',
        'Hạng mục "Mâm Cỗ & Phục Vụ 120 Mâm" giải ngân vượt trần định mức công việc.'
      ],
      totalTaskCount: 5,
      totalAdvanceVoucherCount: 4,
      totalSettlementVoucherCount: 18,
      needsExplanationVoucherCount: 1,
      taskBreakdowns: [
        TaskBudgetBreakdownModel(
          taskId: 'TSK-01',
          taskName: 'Mâm Cỗ & Phục Vụ 120 Mâm',
          taskStatus: 'Ongoing',
          assignedMemberId: 'MEM_001',
          assignedBranchId: 'BR_CHI_1',
          advanceBudget: 100000000.0,
          advanceAmount: 35000000.0,
          actualExpenseAmount: 79800000.0,
          verifiedActualExpenseAmount: 75000000.0,
          advanceVoucherCount: 2,
          settlementVoucherCount: 12,
          needsExplanationCount: 1,
          advanceVariance: 65000000.0,
          actualExpenseVariance: 20200000.0,
          isAdvanceOverTaskBudget: false,
          isActualExpenseOverTaskBudget: false,
          isOverTaskBudget: true,
        ),
        TaskBudgetBreakdownModel(
          taskId: 'TSK-02',
          taskName: 'Âm Thanh Ánh Sáng & Rạp',
          taskStatus: 'Ongoing',
          assignedMemberId: 'MEM_002',
          assignedBranchId: 'BR_CHI_2',
          advanceBudget: 50000000.0,
          advanceAmount: 20000000.0,
          actualExpenseAmount: 28000000.0,
          verifiedActualExpenseAmount: 28000000.0,
          advanceVoucherCount: 1,
          settlementVoucherCount: 4,
          needsExplanationCount: 0,
          advanceVariance: 30000000.0,
          actualExpenseVariance: 22000000.0,
          isAdvanceOverTaskBudget: false,
          isActualExpenseOverTaskBudget: false,
          isOverTaskBudget: false,
        ),
        TaskBudgetBreakdownModel(
          taskId: 'TSK-03',
          taskName: 'Nghi Lễ Tế Tổ & Văn Tế Chu Sa',
          taskStatus: 'Ongoing',
          assignedMemberId: 'MEM_003',
          assignedBranchId: 'BR_CHI_1',
          advanceBudget: 35000000.0,
          advanceAmount: 10000000.0,
          actualExpenseAmount: 15200000.0,
          verifiedActualExpenseAmount: 15200000.0,
          advanceVoucherCount: 1,
          settlementVoucherCount: 2,
          needsExplanationCount: 0,
          advanceVariance: 25000000.0,
          actualExpenseVariance: 19800000.0,
          isAdvanceOverTaskBudget: false,
          isActualExpenseOverTaskBudget: false,
          isOverTaskBudget: false,
        ),
        TaskBudgetBreakdownModel(
          taskId: 'TSK-04',
          taskName: 'Quà Trưởng Thượng & Học Bổng',
          taskStatus: 'Ongoing',
          assignedMemberId: 'MEM_004',
          assignedBranchId: 'BR_CHI_3',
          advanceBudget: 25000000.0,
          advanceAmount: 0.0,
          actualExpenseAmount: 15000000.0,
          verifiedActualExpenseAmount: 15000000.0,
          advanceVoucherCount: 0,
          settlementVoucherCount: 2,
          needsExplanationCount: 0,
          advanceVariance: 25000000.0,
          actualExpenseVariance: 10000000.0,
          isAdvanceOverTaskBudget: false,
          isActualExpenseOverTaskBudget: false,
          isOverTaskBudget: false,
        ),
        TaskBudgetBreakdownModel(
          taskId: 'TSK-05',
          taskName: 'Đội Xe Đón Chi Phái Xa',
          taskStatus: 'Ongoing',
          assignedMemberId: 'MEM_005',
          assignedBranchId: 'BR_CHI_2',
          advanceBudget: 20000000.0,
          advanceAmount: 0.0,
          actualExpenseAmount: 11000000.0,
          verifiedActualExpenseAmount: 11000000.0,
          advanceVoucherCount: 0,
          settlementVoucherCount: 1,
          needsExplanationCount: 0,
          advanceVariance: 20000000.0,
          actualExpenseVariance: 9000000.0,
          isAdvanceOverTaskBudget: false,
          isActualExpenseOverTaskBudget: false,
          isOverTaskBudget: false,
        ),
      ],
    );
  }
}

final eventRemoteDataSourceProvider = Provider<EventRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return EventRemoteDataSource(dio);
});
