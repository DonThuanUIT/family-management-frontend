import 'package:flutter/material.dart';

import '../../../../core/widgets/module_overview_card.dart';

/// Phân hệ 2: Sự kiện, Đăng ký hộ gia đình & Nhân sự (`features/event`).
class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePortalScaffold(
      moduleCode: 'MODULE 02 • EVENT & CONTEXTUAL RBAC',
      title: 'Sự Kiện Dòng Họ, Đăng Ký Hộ Gia Đình & Nhân Sự BTC',
      subtitle:
          'Quản lý vòng đời sự kiện (Draft -> RegistrationOpen -> Ongoing -> Closed) và phân quyền động theo ngữ cảnh (EVENT_PERSONNEL).',
      databaseTables: [
        'events',
        'event_personnel',
        'family_registrations',
        'registration_member_details',
        'event_notifications',
      ],
      memberFeatures: [
        'Xem lịch giỗ tổ, chạp mã, lễ hội truyền thống (kèm ngày Âm lịch & Dương lịch).',
        'Đăng ký tham gia theo hộ gia đình: số suất ăn chay/mặn, nhu cầu phương tiện đi lại (US-06).',
        'Điểm danh QR / xác nhận tham gia thực tế cho các thành viên trong hộ.',
        'Nhận thông báo tức thời khi lịch trình hoặc địa điểm sự kiện thay đổi.',
      ],
      managementFeatures: [
        'Khởi tạo kế hoạch sự kiện và dự toán ngân sách (estimated_budget).',
        'Bổ nhiệm Ban Tổ Chức theo sự kiện: HeadOfOrganizer, EventTreasurer, OrganizerMember.',
        'Thống kê tổng số suất ăn chay/mặn và danh sách hộ gia đình đăng ký.',
        'Khóa sổ sự kiện (Closed) -> Tự động chuyển toàn bộ quyền EVENT_PERSONNEL sang chế độ Chỉ đọc (is_read_only = true).',
      ],
      businessRuleNote:
          'Quy tắc B & C: Khi sự kiện chuyển sang trạng thái Closed, toàn bộ quyền động trong '
          'EVENT_PERSONNEL tự động khóa chỉ đọc. Chặn khóa sổ nếu còn khoản quyết toán NeedsExplanation.',
    );
  }
}
