import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/task_models.dart';

/// Thẻ cảnh báo tiến độ và đếm ngược thời hạn chót 24 giờ chuẩn Figma Screen 05 (US-08)
class TaskDeadlineCountdownCard extends StatefulWidget {
  final TaskModel task;

  const TaskDeadlineCountdownCard({
    super.key,
    required this.task,
  });

  @override
  State<TaskDeadlineCountdownCard> createState() =>
      _TaskDeadlineCountdownCardState();
}

class _TaskDeadlineCountdownCardState extends State<TaskDeadlineCountdownCard> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    // Cập nhật mỗi 30 giây để cập nhật phút/giờ chính xác
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _updateRemaining();
        });
      }
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = widget.task.deadline.difference(now);
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.status == TaskStatusEnum.completed;
    final isOverdue = widget.task.isOverdue;
    final isWithin24h = widget.task.isWithin24Hours;

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;

    return Container(
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFF4A0000) : const Color(0xFF650000),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Thời hạn hoàn tất
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    color: Color(0xFFFFD700),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Thời hạn hoàn tất',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                AppFormatters.formatDateTime(widget.task.deadline),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFE0B2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Countdown or Status Blocks
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF81C784), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Công việc đã hoàn thành đúng hạn',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else if (isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A).withAlpha(120),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ĐÃ TRỄ HẠN HOÀN THÀNH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Báo động vượt cấp đã được gửi tự động tới Ban tổ chức sự kiện.',
                          style: TextStyle(color: Color(0xFFFFCDD2), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // 3 Countdown Boxes (NGÀY • GIỜ • PHÚT)
            Row(
              children: [
                Expanded(
                  child: _buildCountdownBox(
                    value: days.toString().padLeft(2, '0'),
                    unit: 'NGÀY',
                    highlight: isWithin24h,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCountdownBox(
                    value: hours.toString().padLeft(2, '0'),
                    unit: 'GIỜ',
                    highlight: isWithin24h,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCountdownBox(
                    value: minutes.toString().padLeft(2, '0'),
                    unit: 'PHÚT',
                    highlight: isWithin24h,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // 3. Automated Alert Commitment Banner (Figma 05)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFFFD54F),
                  size: 16,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tự động gửi thông báo kiểm tra tiến độ mỗi 24h & báo động Trưởng ban nếu trễ hạn quá 12h.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFFFECB3),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBox({
    required String value,
    required String unit,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF8B0000)
            : Colors.black.withAlpha(35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? const Color(0xFFFF8A80) : Colors.white24,
          width: highlight ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFCDD2),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
