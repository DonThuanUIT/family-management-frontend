import 'package:flutter/material.dart';

import '../../data/models/event_models.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onAssignPersonnel;
  final VoidCallback onChangeStatus;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onAssignPersonnel,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isClosed = event.status == 'Closed' || event.status == 'Ended';
    final isRegistrationOpen = event.status == 'RegistrationOpen';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isClosed
              ? const Color(0xFFE5E0DB)
              : const Color(0xFFE8DFD8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isClosed ? 6 : 10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Card: Tags & Dual Calendar Box
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột thông tin tên & huy hiệu
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildCategoryTag(),
                              _buildStatusBadge(isRegistrationOpen, isClosed),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.eventName,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: isClosed
                                  ? const Color(0xFF4A3B32)
                                  : const Color(0xFF1F1610),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Hộp Lịch Kép Âm - Dương
                    _buildDualCalendarBox(isClosed),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF0EBE6)),

              // 2. Body Card: Location, Metrics, Personnel & Progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF8B1E1E),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.location,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF4A3B32),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Metrics Strip (3 ô số liệu)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEFE9E2)),
                      ),
                      child: Row(
                        children: [
                          _buildMetricColumn(
                            'Tham Gia',
                            event.registeredHouseholds > 0
                                ? '${event.registeredHouseholds} Hộ'
                                : 'Đang mở',
                          ),
                          _buildVerticalDivider(),
                          _buildMetricColumn(
                            'Quy Mô',
                            event.banquetTables > 0
                                ? '${event.banquetTables} Mâm'
                                : '300 Khách',
                          ),
                          _buildVerticalDivider(),
                          _buildMetricColumn(
                            'Dự Toán',
                            event.formattedBudgetMillion,
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ),

                    // Key Personnel (Trưởng BTC & Thủ Quỹ)
                    if (event.personnel.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (event.headOfOrganizer != null) ...[
                            const Icon(Icons.person_pin_circle_outlined,
                                size: 14, color: Color(0xFF7A1518)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'BTC: ${event.headOfOrganizer!.memberName ?? event.headOfOrganizer!.memberId}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5C4A42),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (event.eventTreasurer != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.account_balance_wallet_outlined,
                                size: 14, color: Color(0xFF0F766E)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Thủ quỹ: ${event.eventTreasurer!.memberName ?? event.eventTreasurer!.memberId}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5C4A42),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Preparation Progress Bar
                    if (event.totalTasks > 0 && !isClosed) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tiến độ chuẩn bị hậu cần',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7A6A60),
                            ),
                          ),
                          Text(
                            '${event.completedTasks}/${event.totalTasks} việc (${(event.taskProgress * 100).toInt()}%)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F1610),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: event.taskProgress,
                          backgroundColor: const Color(0xFFE8DFD8),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF8B1E1E),
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Footer Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                  border: Border(top: BorderSide(color: Color(0xFFF0EBE6))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD4C8BE)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Chi Tiết',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A3B32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Chỉ định nhân sự BTC',
                      onPressed: onAssignPersonnel,
                      icon: const Icon(Icons.group_outlined, size: 18),
                      color: const Color(0xFF5C4A42),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD4C8BE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onChangeStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A1518),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isClosed ? 'Xem Sổ Bộ' : 'Chuyển Bước →',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF3C7C7)),
      ),
      child: const Text(
        'Đại Lễ Trọng Điểm',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B1E1E),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOpen, bool isClosed) {
    Color bg = const Color(0xFFE8F5E9);
    Color text = const Color(0xFF2E7D32);
    String label = event.lifecycleStatus.displayName;

    if (isOpen) {
      bg = const Color(0xFFE8F5E9);
      text = const Color(0xFF1B5E20);
      label = 'Đang Mở Ghi Danh';
    } else if (event.status == 'Ongoing') {
      bg = const Color(0xFFE3F2FD);
      text = const Color(0xFF0D47A1);
      label = 'Đang Diễn Ra';
    } else if (isClosed) {
      bg = const Color(0xFFEEEEEE);
      text = const Color(0xFF616161);
      label = 'Đã Đóng Sổ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOpen) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: text,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualCalendarBox(bool isClosed) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isClosed
            ? const Color(0xFFF5F3F0)
            : const Color(0xFFFFF9ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isClosed
              ? const Color(0xFFE0DCD7)
              : const Color(0xFFF5DCB7),
        ),
      ),
      child: Column(
        children: [
          Text(
            event.eventDateLunar?.replaceAll('Âm Lịch', '').trim() ?? '10/03',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isClosed
                  ? const Color(0xFF6E5D53)
                  : const Color(0xFF7A1518),
            ),
          ),
          Text(
            'ÂM LỊCH',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isClosed
                  ? const Color(0xFF8A7A70)
                  : const Color(0xFFB8860B),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isClosed
                      ? const Color(0xFFE0DCD7)
                      : const Color(0xFFF0D5AC),
                  width: 0.8,
                ),
              ),
            ),
            child: Text(
              '${event.formattedSolarDayMonth} DL',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B584E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF8A7A70),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? const Color(0xFF7A1518)
                  : const Color(0xFF2B1810),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE5DDD5),
    );
  }
}
