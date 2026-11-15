import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../event/data/models/event_models.dart';
import '../../../task/data/models/task_models.dart';
import '../providers/advance_voucher_providers.dart';
import 'advance_voucher_card.dart';
import 'create_advance_voucher_sheet.dart';

/// Trang / Bottom Sheet hiển thị danh sách các phiếu tạm ứng của một công việc (US-46).
class TaskAdvanceVouchersSheet extends ConsumerWidget {
  final TaskModel task;
  final EventModel? event;

  const TaskAdvanceVouchersSheet({
    super.key,
    required this.task,
    this.event,
  });

  static Future<void> show(
    BuildContext context, {
    required TaskModel task,
    EventModel? event,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskAdvanceVouchersSheet(task: task, event: event),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskAdvanceVouchersProvider(task.taskId));
    final session = ref.watch(dualRbacSessionProvider);
    final isClosed = event?.isClosed ?? false;
    final canCreate = session.canCreateAdvanceVoucher(
      isClosed: isClosed,
      personnel: event?.personnel,
      eventId: task.eventId,
    );

    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: isDesktop ? 600 : double.infinity,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phiếu Tạm Ứng Kinh Phí',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F1610),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.taskName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B5E55),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPI Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E4DF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã giải ngân:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B5E55)),
                    ),
                    Text(
                      AppFormatters.formatVnd(state.totalDisbursedAmount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Định mức công việc:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B5E55)),
                    ),
                    Text(
                      task.formattedAdvanceBudget,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppTheme.primaryCrimson,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action bar: Button Lập phiếu tạm ứng mới
          if (canCreate && !isClosed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await CreateAdvanceVoucherSheet.show(
                      context,
                      task: task,
                    );
                  },
                  icon: const Icon(Icons.add_card_outlined, size: 16),
                  label: const Text('Lập Phiếu Tạm Ứng Mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCrimson,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

          // Danh sách phiếu
          Expanded(
            child: state.isLoading && state.vouchers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.vouchers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Chưa có phiếu tạm ứng nào cho hạng mục này',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF6B5E55),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.vouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = state.vouchers[index];
                          return AdvanceVoucherCard(
                            voucher: voucher,
                            isClosed: isClosed,
                            personnel: event?.personnel,
                            eventId: task.eventId,
                            onDisbursed: () {
                              ref
                                  .read(taskAdvanceVouchersProvider(task.taskId)
                                      .notifier)
                                  .loadVouchers();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
