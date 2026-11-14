import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/adaptive_modal.dart';
import '../../data/models/role_models.dart';
import '../providers/role_providers.dart';

class AuditLogTab extends ConsumerWidget {
  const AuditLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(roleManagementProvider);
    final logs = roleState.auditLogs;
    final isDesktop = isDesktopViewport(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: isDesktop ? 16 : 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: Color(0xFF735C00)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'SỔ BỘ KIỂM TOÁN TÁC NGHIỆP',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Color(0xFF735C00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B873F),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Thời gian thực',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF58413F),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (roleState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF6A020A)),
            ),
          )
        else if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: const Text(
              'Chưa có lượt tác nghiệp nào được ghi nhận vào Sổ Bộ.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8B716E)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEEEB)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildTimelineItem(log);
              },
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(AuditLogModel log) {
    final isAssign = log.isAssign;
    final dotColor = isAssign ? const Color(0xFF1B873F) : const Color(0xFFBA1A1A);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicator
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 10),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: dotColor.withAlpha(60),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),

        // Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            isAssign
                                ? Icons.add_moderator
                                : Icons.remove_moderator,
                            size: 13,
                            color: dotColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isAssign ? 'Chỉ Định Vai Trò' : 'Thu Hồi Vai Trò',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: dotColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      log.formattedCreatedAt,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF8B716E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF1A1C1A),
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(
                        text: log.actorFullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: isAssign ? ' đã chỉ định ' : ' đã thu hồi vai trò ',
                      ),
                      TextSpan(
                        text: log.roleDisplayName.isNotEmpty
                            ? log.roleDisplayName
                            : log.roleCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A020A),
                        ),
                      ),
                      const TextSpan(text: ' của '),
                      TextSpan(
                        text: log.targetFullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (log.scopeName != null && log.scopeName!.isNotEmpty) ...[
                        const TextSpan(text: ' tại '),
                        TextSpan(
                          text: log.scopeName!,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF735C00),
                          ),
                        ),
                      ],
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),

                if (log.description != null && log.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE9E8E5)),
                    ),
                    child: Text(
                      '“Lý do: ${log.description!}”',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF58413F),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
