import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/event_providers.dart';
import '../widgets/event_budget_hero_card.dart';
import '../widgets/task_budget_breakdown_section.dart';

/// Bảng Điều Khiển Ngân Sách Sự Kiện (Event Budget Dashboard - US-37).
/// Hiển thị thanh tiến độ tiêu dùng ngân sách và banner cảnh báo màu đỏ khi vượt trần dự toán.
class EventBudgetDashboardScreen extends ConsumerWidget {
  final String eventId;

  const EventBudgetDashboardScreen({
    super.key,
    required this.eventId,
  });

  static const Color primaryColor = Color(0xFF8B1E1E); // Đỏ huyết dụ
  static const Color backgroundColor = Color(0xFFFAF9F6); // Trắng ngà
  static const Color subtextColor = Color(0xFF58413F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(eventBudgetSummaryProvider(eventId));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1C1A)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bảng Điều Khiển Ngân Sách',
              style: TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1A),
              ),
            ),
            budgetAsync.when(
              data: (budget) => Text(
                budget.eventName,
                style: const TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 11,
                  color: subtextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const Text(
                'Đang tải số liệu...',
                style: TextStyle(fontSize: 11, color: subtextColor),
              ),
              error: (_, _) => const Text(
                'Không thể tải sự kiện',
                style: TextStyle(fontSize: 11, color: Color(0xFFBA1A1A)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới số liệu',
            icon: const Icon(Icons.refresh, size: 20, color: subtextColor),
            onPressed: () => ref.invalidate(eventBudgetSummaryProvider(eventId)),
          ),
          IconButton(
            tooltip: 'Xuất Báo Cáo Ngân Sách (PDF/Excel)',
            icon: const Icon(Icons.file_download_outlined, size: 20, color: primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang khởi tạo trích xuất báo cáo đối soát ngân sách sự kiện...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: budgetAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor),
              SizedBox(height: 12),
              Text(
                'Đang tổng hợp ngân sách sự kiện...',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 13,
                  color: subtextColor,
                ),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42, color: Color(0xFFBA1A1A)),
                const SizedBox(height: 10),
                Text(
                  'Không thể tải dữ liệu ngân sách: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 13,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(eventBudgetSummaryProvider(eventId)),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Thử Lại'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                ),
              ],
            ),
          ),
        ),
        data: (budget) {
          final isDesktop = MediaQuery.sizeOf(context).width >= 960;

          final manageTasksButton = ElevatedButton.icon(
            onPressed: () {
              context.push('/events/$eventId/tasks');
            },
            icon: const Icon(Icons.assignment_outlined, size: 16),
            label: const Text(
              'Quản Lý Phiếu Chi (US-07)',
              style: TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          );

          final exportButton = OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang chuẩn bị file xuất báo cáo chi tiết...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16, color: primaryColor),
            label: const Text(
              'Xuất Báo Cáo',
              style: TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          if (isDesktop) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cột trái (5 phần): Thẻ Hero tổng quan & tác vụ nhanh
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EventBudgetHeroCard(budget: budget),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5DDD5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Tác Vụ Điều Hành Ngân Sách',
                                    style: TextStyle(
                                      fontFamily: 'Be Vietnam Pro',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1C1A),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: manageTasksButton),
                                      const SizedBox(width: 10),
                                      exportButton,
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Cột phải (7 phần): Phân rã chi tiết hạng mục chi tiêu
                      Expanded(
                        flex: 7,
                        child: TaskBudgetBreakdownSection(
                          eventId: eventId,
                          tasks: budget.taskBreakdowns,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Thẻ Hero Tổng Quan Ngân Sách Tích Hợp
                          EventBudgetHeroCard(budget: budget),

                          const SizedBox(height: 20),

                          // 2. Phân Rã Hạng Mục Chi Tiêu Dạng Accordion Thu Gọn
                          TaskBudgetBreakdownSection(
                            eventId: eventId,
                            tasks: budget.taskBreakdowns,
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // 3. Thanh Hành Động Chân Trang (Gọn gàng & An toàn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: const Border(top: BorderSide(color: Color(0xFFE5DDD5))),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(child: manageTasksButton),
                        const SizedBox(width: 10),
                        exportButton,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
