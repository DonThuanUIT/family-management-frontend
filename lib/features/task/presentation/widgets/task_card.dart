import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../finance/data/models/advance_voucher_models.dart';
import '../../../finance/presentation/providers/advance_voucher_providers.dart';
import '../../../finance/presentation/widgets/confirm_disbursement_dialog.dart';
import '../../../finance/presentation/widgets/create_advance_voucher_sheet.dart';
import '../../../finance/presentation/widgets/task_advance_vouchers_sheet.dart';
import '../../data/models/task_models.dart';
import 'task_deadline_countdown_card.dart';

/// Thẻ hiển thị một hạng mục công việc chuẩn bị cho sự kiện (US-07, US-08, US-46, US-47).
/// Hỗ trợ cả môi trường có ProviderScope (Riverpod toàn phần) lẫn môi trường widget test thuần túy.
class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool canManage;
  final bool isClosed;
  final VoidCallback onReassign;

  const TaskCard({
    super.key,
    required this.task,
    required this.canManage,
    required this.isClosed,
    required this.onReassign,
  });

  @override
  Widget build(BuildContext context) {
    bool hasScope = true;
    try {
      ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      hasScope = false;
    }

    if (!hasScope) {
      return _TaskCardView(
        task: task,
        canManage: canManage,
        isClosed: isClosed,
        onReassign: onReassign,
        advanceState: const TaskAdvanceVouchersState(),
        canCreateAdvance: false,
        canDisburseAdvance: false,
      );
    }

    return Consumer(
      builder: (context, ref, _) {
        final advanceState = ref.watch(taskAdvanceVouchersProvider(task.taskId));
        final session = ref.watch(dualRbacSessionProvider);
        final canCreateAdvance = session.canCreateAdvanceVoucher(
          isClosed: isClosed,
          eventId: task.eventId,
        );
        final canDisburseAdvance = session.canDisburseAdvanceVoucher(
          isClosed: isClosed,
          eventId: task.eventId,
        );

        return _TaskCardView(
          task: task,
          canManage: canManage,
          isClosed: isClosed,
          onReassign: onReassign,
          advanceState: advanceState,
          canCreateAdvance: canCreateAdvance,
          canDisburseAdvance: canDisburseAdvance,
          onDisburse: (voucher) {
            ConfirmDisbursementDialog.show(
              context,
              voucher: voucher,
            );
          },
        );
      },
    );
  }
}

class _TaskCardView extends StatelessWidget {
  final TaskModel task;
  final bool canManage;
  final bool isClosed;
  final VoidCallback onReassign;
  final TaskAdvanceVouchersState advanceState;
  final bool canCreateAdvance;
  final bool canDisburseAdvance;
  final ValueChanged<AdvanceVoucherModel>? onDisburse;

  const _TaskCardView({
    required this.task,
    required this.canManage,
    required this.isClosed,
    required this.onReassign,
    required this.advanceState,
    required this.canCreateAdvance,
    required this.canDisburseAdvance,
    this.onDisburse,
  });

  void _showCountdownDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TaskDeadlineCountdownCard(task: task),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = task.status;
    final isCompleted = status == TaskStatusEnum.completed;
    final isOverdue = task.isOverdue;
    final isOverdue12H = task.isOverdue12Hours;

    return Container(
      decoration: BoxDecoration(
        color: isOverdue12H ? const Color(0xFFFFF1F0) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue12H
              ? const Color(0xFFFCA5A5)
              : (isOverdue ? Colors.red.shade200 : const Color(0xFFE8E4DF)),
          width: (isOverdue12H || isOverdue) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdue12H
                ? const Color(0xFFBA1A1A).withAlpha(15)
                : Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (isOverdue12H)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  color: const Color(0xFFBA1A1A),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isOverdue12H ? 16 : 14,
                10,
                14,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header: Tên việc + Huy hiệu trạng thái
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.taskName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F1610),
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (task.isOverdue12Hours) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBA1A1A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.overdueDurationText,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (task.isWithin24Hours) ...[
                            InkWell(
                              onTap: () => _showCountdownDialog(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 12,
                                      color: Color(0xFFB45309),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Còn 24h',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: status.badgeBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    status.icon,
                                    size: 12,
                                    color: status.badgeTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: status.badgeTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (task.details != null &&
                          task.details!.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          task.details!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B5E55),
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Thông số chi tiết (Hạn chót, Tạm ứng, Phụ trách)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F8F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEFEBE6)),
                        ),
                        child: Column(
                          children: [
                            // Hạn chót
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule,
                                        size: 13, color: Color(0xFF8A7A70)),
                                    SizedBox(width: 5),
                                    Text(
                                      'Hạn chót:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B5E55),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    task.formattedDeadline,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isOverdue
                                          ? AppTheme.primaryCrimson
                                          : const Color(0xFF1F1610),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Tạm ứng dự kiến & Trạng thái phiếu (US-46)
                            InkWell(
                              onTap: () {
                                TaskAdvanceVouchersSheet.show(context,
                                    task: task);
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        advanceState.totalDisbursedAmount > 0
                                            ? Icons.paid_outlined
                                            : (advanceState
                                                    .hasPendingDisbursement
                                                ? Icons.hourglass_top_rounded
                                                : Icons.request_quote_outlined),
                                        size: 13,
                                        color: advanceState
                                                    .totalDisbursedAmount >
                                                0
                                            ? const Color(0xFF047857)
                                            : (advanceState
                                                    .hasPendingDisbursement
                                                ? const Color(0xFFB45309)
                                                : const Color(0xFF8A7A70)),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        advanceState.totalDisbursedAmount > 0
                                            ? 'Đã tạm ứng:'
                                            : (advanceState
                                                    .hasPendingDisbursement
                                                ? 'Chờ giải ngân:'
                                                : 'Tạm ứng:'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: advanceState
                                                      .totalDisbursedAmount >
                                                  0
                                              ? const Color(0xFF047857)
                                              : (advanceState
                                                      .hasPendingDisbursement
                                                  ? const Color(0xFFB45309)
                                                  : const Color(0xFF6B5E55)),
                                          fontWeight: (advanceState
                                                          .totalDisbursedAmount >
                                                      0 ||
                                                  advanceState
                                                      .hasPendingDisbursement)
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      advanceState.totalDisbursedAmount > 0
                                          ? AppFormatters.formatVnd(
                                              advanceState.totalDisbursedAmount)
                                          : (advanceState.hasPendingDisbursement
                                              ? AppFormatters.formatVnd(
                                                  advanceState
                                                      .latestPendingVoucher!
                                                      .advanceAmount)
                                              : task.formattedAdvanceBudget),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            advanceState.totalDisbursedAmount >
                                                    0
                                                ? const Color(0xFF047857)
                                                : (advanceState
                                                        .hasPendingDisbursement
                                                    ? const Color(0xFFB45309)
                                                    : AppTheme.primaryCrimson),
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(height: 1, thickness: 0.5),
                            ),

                            // Người nhận việc
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.person_pin_outlined,
                                        size: 13, color: Color(0xFF8A7A70)),
                                    SizedBox(width: 5),
                                    Text(
                                      'Phụ trách:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B5E55),
                                      ),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: task.hasAssignee
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 8,
                                              backgroundColor: AppTheme
                                                  .primaryCrimson
                                                  .withAlpha(25),
                                              child: Text(
                                                task.assigneeDisplayName
                                                        .isNotEmpty
                                                    ? task.assigneeDisplayName
                                                        .characters.first
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppTheme.primaryCrimson,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                task.assigneeDisplayName,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1F1610),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          'Chưa chỉ định',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // [US-47] Stitch W4 Alert Notice Box: Báo động vượt cấp lên Trưởng chi
                      if (task.isOverdue12Hours) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFCA5A5),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.report_problem_rounded,
                                color: Color(0xFFBA1A1A),
                                size: 14,
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ĐÃ BÁO ĐỘNG VƯỢT CẤP LÊN TRƯỞNG CHI',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF410002),
                                      ),
                                    ),
                                    SizedBox(height: 1),
                                    Text(
                                      'Hệ thống đã tự động ghi vết cảnh báo và gửi tới Trưởng chi quản lý.',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: Color(0xFF93000A),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Footer Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mã: ${task.taskId}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Color(0xFF8A7A70),
                        ),
                      ),

                      // Action buttons
                      if (isCompleted)
                        const Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF047857), size: 15),
                            SizedBox(width: 4),
                            Text(
                              'Đã nghiệm thu',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        )
                      else
                        Flexible(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Nút Giải ngân (dành riêng cho Thủ quỹ khi có phiếu tạm ứng chờ giải ngân)
                              if (advanceState.hasPendingDisbursement &&
                                  canDisburseAdvance &&
                                  !isClosed)
                                ElevatedButton.icon(
                                  key: const Key('task_disburse_button'),
                                  onPressed: () {
                                    onDisburse?.call(
                                        advanceState.latestPendingVoucher!);
                                  },
                                  icon: const Icon(Icons.payments_outlined,
                                      size: 13),
                                  label: const Text(
                                    'Giải ngân',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF047857),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    minimumSize: const Size(0, 32),
                                    elevation: 0.5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                              // Nút Lập phiếu tạm ứng (khi chưa có phiếu và có quyền)
                              else if (canCreateAdvance &&
                                  !isClosed &&
                                  advanceState.vouchers.isEmpty)
                                OutlinedButton.icon(
                                  key: const Key('task_create_advance_button'),
                                  onPressed: () {
                                    CreateAdvanceVoucherSheet.show(
                                      context,
                                      task: task,
                                    );
                                  },
                                  icon: const Icon(Icons.receipt_long_rounded,
                                      size: 13),
                                  label: const Text(
                                    'Tạm ứng',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFB45309),
                                    side: const BorderSide(
                                      color: Color(0xFFD97706),
                                      width: 1,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),

                              if (canManage)
                                OutlinedButton.icon(
                                  onPressed: isClosed ? null : onReassign,
                                  icon: Icon(
                                    task.hasAssignee
                                        ? Icons.sync_alt
                                        : Icons.person_add_alt,
                                    size: 13,
                                  ),
                                  label: Text(
                                    task.hasAssignee
                                        ? 'Phân công lại'
                                        : 'Gán người nhận',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryCrimson,
                                    side: BorderSide(
                                      color: isClosed
                                          ? Colors.grey.shade300
                                          : AppTheme.primaryCrimson
                                              .withAlpha(120),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
