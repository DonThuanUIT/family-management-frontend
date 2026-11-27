import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/files/member_file_actions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/adaptive_modal.dart';
import '../../data/datasources/ledger_remote_datasource.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../providers/ledger_adjustment_providers.dart';

/// Drawer / Modal xem lịch sử các Đề xuất bù trừ Sổ cái (`GET /api/v1/ledger/adjustments`).
class AdjustmentHistorySheet extends ConsumerWidget {
  const AdjustmentHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showAdaptiveSheetOrDialog<void>(
      context: context,
      maxDesktopWidth: 780,
      maxDesktopHeightFactor: 0.88,
      builder: (_) => const AdjustmentHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ledgerAdjustmentHistoryProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 820;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: isWide
              ? BorderRadius.circular(24)
              : const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE6DFD8))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lịch Sử Đề Xuất Bù Trừ Sổ Cái',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Theo dõi trạng thái phê duyệt từ Trưởng tộc',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF58413F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => ref
                        .read(ledgerAdjustmentHistoryProvider.notifier)
                        .loadHistory(showLoading: true),
                    icon: const Icon(Icons.refresh, color: Color(0xFF58413F)),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF1A1C1A)),
                  ),
                ],
              ),
            ),

            // Status filter chips
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab(
                      label: 'Tất cả (${state.items.length})',
                      selected: state.statusFilter == null,
                      onTap: () => ref
                          .read(ledgerAdjustmentHistoryProvider.notifier)
                          .setStatusFilter(null),
                    ),
                    ...LedgerAdjustmentStatusEnum.values.map((status) {
                      final count = state.items
                          .where((e) => e.approvalStatus == status)
                          .length;
                      final shortLabel = switch (status) {
                        LedgerAdjustmentStatusEnum.pending => 'Chờ duyệt',
                        LedgerAdjustmentStatusEnum.approved => 'Đã duyệt',
                        LedgerAdjustmentStatusEnum.rejected => 'Từ chối',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildTab(
                          label: '$shortLabel ($count)',
                          selected: state.statusFilter == status,
                          onTap: () => ref
                              .read(ledgerAdjustmentHistoryProvider.notifier)
                              .setStatusFilter(status),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE6DFD8)),

            // Body
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryCrimson,
                        ),
                      ),
                    )
                  : state.errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              state.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFBA1A1A)),
                            ),
                          ),
                        )
                      : state.filteredItems.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'Chưa có đề xuất bù trừ nào trong danh sách.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF58413F),
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.filteredItems.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) => _HistoryCard(
                                item: state.filteredItems[index],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF58413F),
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.primaryCrimson,
      backgroundColor: const Color(0xFFFAF9F6),
      side: BorderSide(
        color: selected ? AppTheme.primaryCrimson : const Color(0xFFE6DFD8),
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _HistoryCard extends ConsumerStatefulWidget {
  final LedgerAdjustmentRequestModel item;
  const _HistoryCard({required this.item});

  @override
  ConsumerState<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends ConsumerState<_HistoryCard> {
  bool _downloading = false;

  Future<void> _openOrDownloadEvidence(String url, String fileName) async {
    setState(() => _downloading = true);
    try {
      final bytes =
          await ref.read(ledgerRepositoryProvider).downloadEvidenceBytes(url);
      if (!mounted) return;
      final lower = fileName.toLowerCase();
      final isImage = lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png');
      final mime = lower.endsWith('.pdf')
          ? 'application/pdf'
          : (lower.endsWith('.png') ? 'image/png' : 'image/jpeg');

      if (isImage) {
        await showDialog<void>(
          context: context,
          builder: (dlgCtx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dlgCtx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: InteractiveViewer(
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(memberFileActionsProvider)
                            .save(bytes, fileName, mime);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 44),
                        backgroundColor: AppTheme.primaryCrimson,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Lưu về máy'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        final saved = await ref
            .read(memberFileActionsProvider)
            .save(bytes, fileName, mime);
        if (mounted && saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tải xuống biên bản $fileName'),
              backgroundColor: AppTheme.immutableLedgerTeal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở biên bản: ${formatLedgerFailure(e)}'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final amtColor = item.proposedAdjustmentAmount >= 0
        ? AppTheme.immutableLedgerTeal
        : const Color(0xFFBA1A1A);
    final internalFileName = LedgerRemoteDataSourceImpl
        .extractInternalEvidenceFilename(item.evidenceAttachmentUrl);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Text(
                  item.requestId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.approvalStatus.badgeBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: item.approvalStatus.badgeBorderColor),
                ),
                child: Text(
                  item.approvalStatus.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.approvalStatus.badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  'GD gốc: ${item.originalTransactionId} • ${item.formattedCreatedAt}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF58413F),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatSignedLedgerVnd(item.proposedAdjustmentAmount),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: amtColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text(
            item.adjustmentReason,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1C1A)),
          ),

          if (item.evidenceAttachmentUrl != null &&
              item.evidenceAttachmentUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            if (internalFileName != null)
              OutlinedButton.icon(
                onPressed: _downloading
                    ? null
                    : () => _openOrDownloadEvidence(
                          item.evidenceAttachmentUrl!,
                          internalFileName,
                        ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  foregroundColor: AppTheme.primaryCrimson,
                  side: const BorderSide(color: Color(0xFFE6DFD8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.attachment_rounded, size: 18),
                label: Text(
                  _downloading ? 'Đang tải biên bản...' : 'Xem / Tải biên bản',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Row(
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 16,
                    color: AppTheme.primaryCrimson,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SelectableText(
                      item.evidenceAttachmentUrl!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF58413F),
                      ),
                    ),
                  ),
                ],
              ),
          ],

          if (item.rejectionReason != null &&
              item.rejectionReason!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'Lý do từ chối của Trưởng tộc: ${item.rejectionReason}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF93000A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
