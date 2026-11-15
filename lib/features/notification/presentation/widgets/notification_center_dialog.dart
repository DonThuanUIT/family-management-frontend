import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/notification_models.dart';
import '../providers/notification_providers.dart';

/// Modal Trung Tâm Thông Báo Cảnh Báo Tiến Độ (US-08 & US-39)
class NotificationCenterDialog extends ConsumerStatefulWidget {
  const NotificationCenterDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const NotificationCenterDialog(),
    );
  }

  @override
  ConsumerState<NotificationCenterDialog> createState() =>
      _NotificationCenterDialogState();
}

class _NotificationCenterDialogState
    extends ConsumerState<NotificationCenterDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);
    final notifier = ref.read(notificationListProvider.notifier);

    return Dialog(
      backgroundColor: const Color(0xFFFCF9F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 620,
          maxHeight: 700,
        ),
        child: Column(
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppTheme.primaryCrimson,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trung Tâm Thông Báo Gia Tộc',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Cảnh báo tiến độ công việc 24h & thông tri sự kiện',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: state.notifications.any((n) => !n.isRead)
                        ? () => notifier.markAllAsRead()
                        : null,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text(
                      'Đọc tất cả',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryCrimson,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    color: const Color(0xFF54433E),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEBE6E0)),

            // 2. Category Tabs & Unread Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF9F7F4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          label: 'Tất cả',
                          count: state.notifications.length,
                          isSelected: state.selectedCategory == null,
                          onTap: () => notifier.setCategory(null),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'Công việc (Task)',
                          count: state.notifications
                              .where((n) =>
                                  n.category == NotificationCategoryEnum.task)
                              .length,
                          isSelected: state.selectedCategory ==
                              NotificationCategoryEnum.task,
                          highlightColor: AppTheme.primaryCrimson,
                          onTap: () => notifier
                              .setCategory(NotificationCategoryEnum.task),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'Sự kiện',
                          count: state.notifications
                              .where((n) =>
                                  n.category == NotificationCategoryEnum.event)
                              .length,
                          isSelected: state.selectedCategory ==
                              NotificationCategoryEnum.event,
                          onTap: () => notifier
                              .setCategory(NotificationCategoryEnum.event),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip(
                          label: 'Tài chính',
                          count: state.notifications
                              .where((n) =>
                                  n.category ==
                                  NotificationCategoryEnum.finance)
                              .length,
                          isSelected: state.selectedCategory ==
                              NotificationCategoryEnum.finance,
                          onTap: () => notifier
                              .setCategory(NotificationCategoryEnum.finance),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt,
                              size: 13, color: Color(0xFFB45309)),
                          const SizedBox(width: 4),
                          Text(
                            'Tự động nhắc nhở trước hạn chót 24h',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Chỉ chưa đọc:',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF54433E),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Switch(
                            value: state.unreadOnly,
                            onChanged: (val) => notifier.setUnreadOnly(val),
                            activeThumbColor: AppTheme.primaryCrimson,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEBE6E0)),

            // 3. Notification List
            Expanded(
              child: state.isLoading && state.notifications.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryCrimson,
                      ),
                    )
                  : state.notifications.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_outlined,
                                size: 48,
                                color: Color(0xFFDAC1BA),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Hiện không có thông báo nào trong mục này.',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF54433E),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.notifications.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = state.notifications[index];
                            return _buildNotificationCard(
                                context, item, notifier);
                          },
                        ),
            ),

            // 4. Footer Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F7F4),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Color(0xFFEBE6E0))),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_outlined,
                      size: 14, color: Color(0xFF006E2A)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hệ thống kiểm toán & thông báo bất biến FamilyFund Heritage 2026',
                      style: TextStyle(fontSize: 11, color: Color(0xFF756864)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? highlightColor,
  }) {
    final activeColor = highlightColor ?? const Color(0xFF8F482F);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFDAC1BA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF54433E),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(50)
                    : const Color(0xFFF0EDEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF54433E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel item,
    NotificationListNotifier notifier,
  ) {
    final isDeadlineWarning = item.isTaskDeadlineWarning;
    final timeFormat = DateFormat('HH:mm • dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : const Color(0xFFFFF9F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDeadlineWarning
              ? const Color(0xFFE57373)
              : (item.isRead
                  ? const Color(0xFFE6DFD8)
                  : const Color(0xFFFFCDD2)),
          width: isDeadlineWarning ? 1.4 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Badge + Status + Timestamp
          Row(
            children: [
              if (isDeadlineWarning)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBA1A1A)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm_on, size: 12, color: Color(0xFFBA1A1A)),
                      SizedBox(width: 4),
                      Text(
                        'CẢNH BÁO 24H',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.category.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.category.icon,
                          size: 12, color: item.category.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        item.category.displayName,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: item.category.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryCrimson,
                    shape: BoxShape.circle,
                  ),
                ),
              const Spacer(),
              Text(
                timeFormat.format(item.createdAt),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  color: Color(0xFF8A7A70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            item.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
              color: isDeadlineWarning
                  ? const Color(0xFF8B1E1E)
                  : const Color(0xFF1C1C1A),
            ),
          ),
          const SizedBox(height: 4),

          // Content
          Text(
            item.content,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF54433E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (item.category == NotificationCategoryEnum.task) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/events');
                  },
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text(
                    'Xem Công Việc',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeadlineWarning
                        ? AppTheme.primaryCrimson
                        : const Color(0xFF8F482F),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!item.isRead)
                OutlinedButton(
                  onPressed: () => notifier.markAsRead(item.notificationId),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDAC1BA)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Đánh dấu đã đọc',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF54433E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
