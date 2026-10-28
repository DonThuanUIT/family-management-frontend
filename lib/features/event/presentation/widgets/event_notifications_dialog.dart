import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/event_providers.dart';

class EventNotificationsDialog extends ConsumerWidget {
  final String eventId;

  const EventNotificationsDialog({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(eventNotificationsProvider(eventId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFFB8860B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông Báo Tộc Sự Đã Phát',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                      Text(
                        'Lịch sử phát tin đến bà con dòng họ (US-22)',
                        style: TextStyle(
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
            const Divider(height: 20),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7A1518)),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Không thể tải thông báo: $err',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có thông báo nào được phát cho sự kiện này.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF8A7A70)),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7F4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEFE9E2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF7A1518),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (n.contentChanges != null &&
                                n.contentChanges!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                n.contentChanges!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF5C4A42),
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Người phát: ${n.triggeredBy ?? "Hệ thống"}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF8A7A70),
                                  ),
                                ),
                                Text(
                                  n.formattedSentTime,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF8A7A70),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
