import 'package:flutter/material.dart';

import '../../../../core/widgets/module_overview_card.dart';

/// Phân hệ 3: Phân công & Tiến độ Công việc (`features/task`).
class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePortalScaffold(
      moduleCode: 'MODULE 03 • TASK & ESCALATION ALERTS',
      title: 'Phân Công Hạng Mục Công Việc & Đôn Đốc Tự Động',
      subtitle:
          'Giao việc chuẩn bị sự kiện cho Chi/Nhánh hoặc cá nhân, kết hợp nhắc việc 24h và leo thang cảnh báo quá hạn 12h.',
      databaseTables: [
        'event_tasks',
        'task_progress_alerts',
      ],
      memberFeatures: [
        'Xem danh sách công việc được giao cho cá nhân hoặc Chi/Nhánh của mình (US-07).',
        'Cập nhật tiến độ thực hiện công việc và đính kèm ghi chú hoàn thành.',
        'Nhận thông báo nhắc việc tự động trước hạn 24 giờ (Reminder24H) qua FCM/App.',
      ],
      managementFeatures: [
        'Tạo và phân công hạng mục công việc linh hoạt cho từng Chi/Nhánh hoặc đích danh thành viên.',
        'Theo dõi bảng Kanban / Tiến độ tổng thể các hạng mục chuẩn bị sự kiện.',
        'Nhận cảnh báo leo thang tự động khi công việc quá hạn 12 giờ (OverdueAlert12H gửi tới Trưởng nhánh - US-08).',
      ],
      businessRuleNote:
          'Quy tắc E: Tiến trình ngầm quét bảng EVENT_TASK để gửi nhắc nhở trước hạn 24h '
          '(Reminder24H) cho người nhận việc và cảnh báo leo thang quá hạn 12h (OverdueAlert12H) cho ROLE_BRANCH_HEAD.',
    );
  }
}
