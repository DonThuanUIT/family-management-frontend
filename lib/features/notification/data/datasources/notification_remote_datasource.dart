import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/notification_models.dart';

abstract class NotificationRemoteDataSource {
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

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return NotificationRemoteDataSourceImpl(dio);
});

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio _dio;

  NotificationRemoteDataSourceImpl(this._dio);

  // Danh sách mẫu thực tế phục vụ kiểm thử và offline
  static final List<NotificationModel> _mockNotifications = [
    NotificationModel(
      notificationId: 'NTF-US40-001',
      clanId: 'VN-LE-2026',
      category: NotificationCategoryEnum.event,
      title: 'Nhắc nhở ngày giỗ: Cụ Lê Văn An (Đời thứ 3, Chi 2)',
      content:
          'Sắp đến ngày giỗ Cụ Lê Văn An vào ngày 15/02 Âm lịch (Dương lịch: 23/03/2026). Ban tổ chức có thể bấm tạo sự kiện để con cháu đăng ký tham dự và chuẩn bị kế hoạch tế tự chu tất.',
      referenceType: 'DeathAnniversary',
      referenceId: 'MEM-DEC-003',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      metadata: {
        'deceasedName': 'Cụ Lê Văn An',
        'deathDateSolar': '2026-03-23T08:30:00.000Z',
        'deathDateLunar': '15/02 Âm lịch (Bính Ngọ)',
        'location': 'Từ đường Chi 2, Xã Kim Liên',
        'suggestedBudget': 35000000.0,
        'description':
            'Lễ tưởng niệm và cúng giỗ Cụ Lê Văn An (Đời thứ 3, Chi 2). Con cháu tề tựu dâng hương tưởng nhớ công đức tiền nhân.',
        'isDeathAnniversary': true,
      },
    ),
    NotificationModel(
      notificationId: 'NTF-US47-001',
      clanId: 'VN-LE-2026',
      category: NotificationCategoryEnum.task,
      title: 'Cảnh báo quá hạn 12h: Chuẩn bị bài tế văn & trang phục khánh tiết',
      content:
          'Hạng mục [TSK-02] thuộc sự kiện [Lễ Giỗ Tổ 2026] do Chi 1 (Tiểu ban nghi lễ) phụ trách đã quá hạn 14 giờ 0 phút (Hạn chót: 18:00 • 13/03/2026). Hệ thống đã kích hoạt báo động khẩn cấp gửi Trưởng chi để đôn đốc xử lý.',
      referenceType: 'Task',
      referenceId: 'TSK-02',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      metadata: {
        'alertLevel': 'OverdueAlert12H',
        'isOverdue12H': true,
        'taskId': 'TSK-02',
        'eventId': 'EVT_2026_GIOTO',
        'taskName': 'Chuẩn bị bài tế văn & trang phục khánh tiết',
        'assignedBranchId': 'BR_CHI_1',
        'assignedBranchName': 'Chi 1',
        'overdueHours': 14,
      },
    ),
    NotificationModel(
      notificationId: 'NTF-US08-001',
      clanId: 'VN-LE-2026',
      category: NotificationCategoryEnum.task,
      title: 'Cảnh báo tiến độ: Mua sắm hoa quả & hương lễ tam sinh',
      content:
          'Công việc [TSK-01] thuộc sự kiện [Lễ Giỗ Tổ 2026] chỉ còn lại 18 giờ 45 phút trước hạn chót (17:00 • 14/03/2026). Vui lòng hoàn tất mua sắm và nộp minh chứng đối soát.',
      referenceType: 'Task',
      referenceId: 'TSK-01',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    NotificationModel(
      notificationId: 'NTF-US08-002',
      clanId: 'VN-LE-2026',
      category: NotificationCategoryEnum.task,
      title: 'Cảnh báo tiến độ: Chuẩn bị bài tế văn & trang phục khánh tiết',
      content:
          'Hạng mục [TSK-02] đã sắp đến hạn chót 24 giờ. Tiểu ban nghi lễ Chi 1 cần kiểm tra và báo cáo tiến độ chuẩn bị bài văn tế.',
      referenceType: 'Task',
      referenceId: 'TSK-02',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    NotificationModel(
      notificationId: 'NTF-EVT-003',
      clanId: 'VN-LE-2026',
      category: NotificationCategoryEnum.event,
      title: 'Lễ Giỗ Tổ Dòng Họ Lê 2026: Đã mở đăng ký trực tuyến',
      content:
          'Ban tổ chức đã mở cổng đăng ký tham dự lễ giỗ tổ từ ngày 15/12 Âm lịch tại Nhà Thờ Tổ Nam Trung.',
      referenceType: 'Event',
      referenceId: 'EVT-01',
      isRead: true,
      readAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    NotificationModel(
      notificationId: 'NTF-FIN-004',
      clanId: 'VN-LE-2026',
      category: NotificationCategoryEnum.finance,
      title: 'Đã giải ngân tạm ứng: 2.000.000 đ cho Mua hoa quả',
      content:
          'Thủ quỹ đã hoàn tất chuyển khoản VietQR tạm ứng cho hạng mục mua sắm hoa quả của Chi 2.',
      referenceType: 'AdvanceVoucher',
      referenceId: 'PC-2026-14',
      isRead: true,
      readAt: DateTime.now().subtract(const Duration(hours: 12)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<NotificationModel>> getNotifications({
    NotificationCategoryEnum? category,
    bool? isRead,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (category != null) {
        queryParams['category'] = category.code;
      }
      if (isRead != null) {
        queryParams['isRead'] = isRead;
      }

      final response = await _dio.get(
        'notifications',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final innerData = data['data'];
        List<dynamic> items = [];
        if (innerData is Map<String, dynamic> && innerData['content'] is List) {
          items = innerData['content'] as List<dynamic>;
        } else if (innerData is List) {
          items = innerData;
        }

        return items
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return _filterMock(category: category, isRead: isRead);
    } catch (_) {
      // Fallback mock danh sách thông báo mẫu
      return _filterMock(category: category, isRead: isRead);
    }
  }

  @override
  Future<UnreadCountModel> getUnreadSummary() async {
    try {
      final response = await _dio.get('notifications/unread-count');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return UnreadCountModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return _calculateMockUnread();
    } catch (_) {
      return _calculateMockUnread();
    }
  }

  @override
  Future<NotificationModel> markAsRead(String notificationId) async {
    try {
      final response = await _dio.patch('notifications/$notificationId/read');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return NotificationModel.fromJson(data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}

    // Cập nhật trên mock
    final index = _mockNotifications.indexWhere((n) => n.notificationId == notificationId);
    if (index != -1) {
      final updated = _mockNotifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      _mockNotifications[index] = updated;
      return updated;
    }
    throw Exception('Thông báo không tồn tại');
  }

  @override
  Future<int> markAllAsRead({NotificationCategoryEnum? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) {
        queryParams['category'] = category.code;
      }
      final response = await _dio.patch(
        'notifications/read-all',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['data'] is Map &&
          data['data']['markedCount'] != null) {
        return (data['data']['markedCount'] as num).toInt();
      }
    } catch (_) {}

    int count = 0;
    for (int i = 0; i < _mockNotifications.length; i++) {
      final n = _mockNotifications[i];
      if (!n.isRead && (category == null || n.category == category)) {
        _mockNotifications[i] = n.copyWith(isRead: true, readAt: DateTime.now());
        count++;
      }
    }
    return count;
  }

  List<NotificationModel> _filterMock({
    NotificationCategoryEnum? category,
    bool? isRead,
  }) {
    return _mockNotifications.where((n) {
      if (category != null && n.category != category) return false;
      if (isRead != null && n.isRead != isRead) return false;
      return true;
    }).toList();
  }

  UnreadCountModel _calculateMockUnread() {
    int total = 0;
    int ev = 0;
    int tk = 0;
    int fn = 0;

    for (final n in _mockNotifications) {
      if (!n.isRead) {
        total++;
        if (n.category == NotificationCategoryEnum.event) ev++;
        if (n.category == NotificationCategoryEnum.task) tk++;
        if (n.category == NotificationCategoryEnum.finance) fn++;
      }
    }

    return UnreadCountModel(
      total: total,
      eventCount: ev,
      taskCount: tk,
      financeCount: fn,
    );
  }
}
