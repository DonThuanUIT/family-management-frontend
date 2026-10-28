import 'package:flutter/material.dart';

import '../../data/models/event_models.dart';
import 'assign_personnel_dialog.dart';
import 'edit_event_sheet.dart';
import 'event_notifications_dialog.dart';

class EventDetailDialog extends StatelessWidget {
  final EventModel event;

  const EventDetailDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBEBEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: Color(0xFF7A1518),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.eventName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mã sự kiện: ${event.eventId} • Trạng thái: ${event.lifecycleStatus.displayName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A7A70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Thông tin lịch trình
              _infoRow('Lịch Dương:',
                  '${event.formattedSolarTime} - ${event.formattedSolarDate}'),
              _infoRow('Lịch Âm:', event.eventDateLunar ?? 'Chưa ghi nhận'),
              _infoRow('Địa điểm:', event.location),
              _infoRow('Dự toán ngân sách:',
                  '${event.estimatedBudget.toStringAsFixed(0)} VND (${event.formattedBudgetMillion})'),
              if (event.description != null &&
                  event.description!.isNotEmpty)
                _infoRow('Ghi chú / Kế hoạch:', event.description!),

              const Divider(height: 24),

              // Ban Tổ Chức & Thủ Quỹ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Ban Tổ Chức & Thủ Quỹ (Contextual RBAC)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A1518),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => AssignPersonnelDialog(event: event),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 14),
                    label: const Text('Phân công',
                        style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (event.personnel.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F7F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Chưa có nhân sự nào được chỉ định cho sự kiện này.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A7A70)),
                  ),
                )
              else
                ...event.personnel.map(
                  (p) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEFE9E2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.memberName ?? p.memberId,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B1810),
                                ),
                              ),
                              Text(
                                'Mã thành viên: ${p.memberId}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF8A7A70),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFF5DCB7)),
                          ),
                          child: Text(
                            p.roleDisplayName,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7A1518),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) =>
                              EventNotificationsDialog(eventId: event.eventId),
                        );
                      },
                      icon: const Icon(Icons.notifications_active_outlined,
                          size: 16),
                      label: const Text('Thông Báo (US-22)',
                          style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => EditEventSheet(event: event),
                        );
                      },
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Đổi Lịch Trình',
                          style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A1518),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A6A60),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B1810),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
