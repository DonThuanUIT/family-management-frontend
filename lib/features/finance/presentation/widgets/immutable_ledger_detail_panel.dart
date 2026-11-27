import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/immutable_ledger_integrity_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import 'immutable_ledger_widgets.dart';

/// Ngăn chi tiết giao dịch Sổ cái bất biến (dùng chung cho Drawer Desktop và BottomSheet Mobile).
/// Tuyệt đối không chứa bất kỳ nút Sửa hoặc Xóa nào; chỉ hiển thị chứng thực SHA-256,
/// liên kết hai chiều US-62 và nút Đề xuất bù trừ (US-15) theo đúng RBAC.
class ImmutableLedgerDetailPanel extends StatelessWidget {
  final LedgerHistoryItemModel? item;
  final int? blockNumber;
  final bool isLoading;
  final String? errorMessage;
  final LedgerBrokenLinkModel? brokenLink;
  final Map<String, int> blockNumbersByTxId;
  final bool canProposeAdjustment;
  final bool isBottomSheet;
  final VoidCallback onClose;
  final ValueChanged<String> onCopyHash;
  final ValueChanged<String> onJumpToTransaction;
  final ValueChanged<String> onProposeAdjustment;

  const ImmutableLedgerDetailPanel({
    super.key,
    required this.item,
    required this.blockNumber,
    required this.isLoading,
    required this.errorMessage,
    required this.brokenLink,
    required this.blockNumbersByTxId,
    required this.canProposeAdjustment,
    required this.isBottomSheet,
    required this.onClose,
    required this.onCopyHash,
    required this.onJumpToTransaction,
    required this.onProposeAdjustment,
  });

  @override
  Widget build(BuildContext context) {
    final current = item;
    if (current == null && isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF8B1E1E)),
        ),
      );
    }

    if (current == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 36,
                color: Color(0xFFBA1A1A),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage ?? 'Không tải được chi tiết bút toán.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF54433E)),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onClose,
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      );
    }

    final badgePalette = LedgerTypeBadgePalette.of(current.transactionType);
    final isBroken = brokenLink != null;
    final isPositive = current.amount >= 0;

    return Column(
      children: [
        // Warm #FFFDF8 Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF8),
            border: Border(bottom: BorderSide(color: Color(0xFFE6DFD8))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (blockNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE6DFD8)),
                            ),
                            child: Text(
                              'Khối #$blockNumber',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B1810),
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgePalette.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: badgePalette.border),
                          ),
                          child: Text(
                            current.transactionType.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgePalette.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current.transactionId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1E1E),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Đóng chi tiết',
                icon: const Icon(Icons.close, color: Color(0xFF54433E)),
              ),
            ],
          ),
        ),

        if (isLoading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: Color(0xFF8B1E1E),
            backgroundColor: Color(0xFFF0EDEB),
          ),

        // Scrollable body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  current.description,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1810),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatSignedLedgerVnd(current.amount),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? const Color(0xFF2E8B43)
                            : const Color(0xFFBA1A1A),
                      ),
                    ),
                    Text(
                      'Số dư lũy kế: ${AppFormatters.formatVnd(current.runningBalance)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF54433E),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFF0EDEB)),

                // Chứng thực chuỗi SHA-256
                _Sha256ProofCard(
                  previousHash: current.previousHash,
                  recordHash: current.recordHash,
                  isBroken: isBroken,
                  brokenReason: brokenLink?.reason,
                  onCopyHash: onCopyHash,
                ),
                const SizedBox(height: 16),

                // Thông tin kế toán 2 cột
                _AccountingInfoCard(item: current),

                if (current.originalTransaction != null ||
                    current.originalTransactionId != null) ...[
                  const SizedBox(height: 16),
                  _OriginalTransactionLinkCard(
                    original: current.originalTransaction,
                    fallbackTxId: current.originalTransactionId ?? '',
                    blockNumber: current.originalTransactionId != null
                        ? blockNumbersByTxId[current.originalTransactionId!]
                        : null,
                    onJump: onJumpToTransaction,
                  ),
                ],

                if (current.adjustmentTransactions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _AdjustmentLinksCard(
                    adjustments: current.adjustmentTransactions,
                    blockNumbersByTxId: blockNumbersByTxId,
                    onJump: onJumpToTransaction,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Calm Immutable Policy Footer (ZERO Sửa / Xóa)
        Container(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            isBottomSheet ? MediaQuery.of(context).padding.bottom + 14 : 14,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF9F6),
            border: Border(top: BorderSide(color: Color(0xFFE6DFD8))),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Sổ cái chỉ ghi nối — không thể Sửa hoặc Xóa. Mọi điều chỉnh được lập thành bút toán bù trừ mới.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF54433E),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildPolicyFooterAction(current),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyFooterAction(LedgerHistoryItemModel current) {
    if (canProposeAdjustment &&
        !current.isAdjustment &&
        !current.isLockedByPendingAdjustment) {
      return OutlinedButton(
        onPressed: () => onProposeAdjustment(current.transactionId),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF8B1E1E),
          side: const BorderSide(color: Color(0xFF8B1E1E)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
        child: const Text('Đề xuất bù trừ'),
      );
    }

    if (canProposeAdjustment && current.isLockedByPendingAdjustment) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Text(
          'Đang chờ duyệt bù trừ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB8860B),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.verified_user_outlined,
            size: 12,
            color: Color(0xFF0F766E),
          ),
          SizedBox(width: 5),
          Text(
            'Chỉ đọc',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sha256ProofCard extends StatelessWidget {
  final String previousHash;
  final String recordHash;
  final bool isBroken;
  final String? brokenReason;
  final ValueChanged<String> onCopyHash;

  const _Sha256ProofCard({
    required this.previousHash,
    required this.recordHash,
    required this.isBroken,
    this.brokenReason,
    required this.onCopyHash,
  });

  @override
  Widget build(BuildContext context) {
    final toneColor =
        isBroken ? const Color(0xFFBA1A1A) : const Color(0xFF0F766E);
    final bgColor =
        isBroken ? const Color(0x99FEF2F2) : const Color(0x99ECFDF5);
    final borderColor =
        isBroken ? const Color(0xFFFECACA) : const Color(0xFF99F6E4);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBroken
                        ? Icons.warning_amber_rounded
                        : Icons.verified_user_outlined,
                    size: 15,
                    color: toneColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Chứng thực chuỗi SHA-256',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: toneColor,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                isBroken ? 'Sai lệch băm!' : 'Khớp toàn vẹn',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: toneColor,
                ),
              ),
            ],
          ),
          if (isBroken && brokenReason != null && brokenReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              brokenReason!,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFFBA1A1A)),
            ),
          ],
          const SizedBox(height: 10),

          _HashBox(
            label: 'MÃ BĂM KHỐI TRƯỚC (previousHash)',
            hashValue: previousHash.isEmpty ? 'GENESIS' : previousHash,
            borderColor: const Color(0xFFE6DFD8),
            onCopy: () =>
                onCopyHash(previousHash.isEmpty ? 'GENESIS' : previousHash),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Text(
                isBroken ? '↓ Không khớp liên kết chuỗi' : '↓ Nối chuỗi hợp lệ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: toneColor,
                ),
              ),
            ),
          ),

          _HashBox(
            label: 'MÃ BĂM NIÊM PHONG (recordHash)',
            hashValue: recordHash,
            borderColor: borderColor,
            onCopy: () => onCopyHash(recordHash),
          ),
        ],
      ),
    );
  }
}

class _HashBox extends StatelessWidget {
  final String label;
  final String hashValue;
  final Color borderColor;
  final VoidCallback onCopy;

  const _HashBox({
    required this.label,
    required this.hashValue,
    required this.borderColor,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
              InkWell(
                onTap: onCopy,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Sao chép',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            hashValue,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11.5,
              color: Color(0xFF2B1810),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountingInfoCard extends StatelessWidget {
  final LedgerHistoryItemModel item;

  const _AccountingInfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final createdDateStr =
        '${AppFormatters.formatDateTime(item.createdAt.toLocal())} (${item.formattedLunarDate})';
    final categoryOrEvent = item.eventName?.trim().isNotEmpty == true
        ? item.eventName!
        : (item.disbursementTitle?.trim().isNotEmpty == true
            ? item.disbursementTitle!
            : item.transactionType.displayName);
    final createdBy = item.createdByName?.trim().isNotEmpty == true
        ? item.createdByName!
        : (item.createdByAccountId.isNotEmpty
            ? item.createdByAccountId
            : 'Hệ thống');
    final approvedBy = item.approvedByName?.trim().isNotEmpty == true
        ? item.approvedByName!
        : (item.approvedByAccountId.isNotEmpty
            ? item.approvedByAccountId
            : 'Trưởng tộc');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCell(label: 'Thời gian ghi sổ', value: createdDateStr),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCell(
                  label: 'Hạng mục / Sự kiện',
                  value: categoryOrEvent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCell(label: 'Người ghi nhận', value: createdBy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCell(label: 'Người phê duyệt', value: approvedBy),
              ),
            ],
          ),
          if (item.adjustmentReason != null &&
              item.adjustmentReason!.trim().isNotEmpty) ...[
            const Divider(height: 20, color: Color(0xFFE6DFD8)),
            _InfoCell(
              label: 'Lý do giải trình bù trừ',
              value: item.adjustmentReason!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF78655C)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B1810),
          ),
        ),
      ],
    );
  }
}

class _OriginalTransactionLinkCard extends StatelessWidget {
  final LinkedLedgerTransactionModel? original;
  final String fallbackTxId;
  final int? blockNumber;
  final ValueChanged<String> onJump;

  const _OriginalTransactionLinkCard({
    required this.original,
    required this.fallbackTxId,
    required this.blockNumber,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    final targetId = original?.transactionId ?? fallbackTxId;
    final prefix = blockNumber != null ? '#$blockNumber • ' : '';
    final title = original != null
        ? '$prefix${original!.description}'
        : '$prefix$targetId';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIÊN KẾT GIAO DỊCH GỐC',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Color(0xFFB8860B),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onJump(targetId),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            targetId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B1E1E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Xem ›',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB8860B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentLinksCard extends StatelessWidget {
  final List<LinkedLedgerTransactionModel> adjustments;
  final Map<String, int> blockNumbersByTxId;
  final ValueChanged<String> onJump;

  const _AdjustmentLinksCard({
    required this.adjustments,
    required this.blockNumbersByTxId,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BÚT TOÁN BÙ TRỪ LIÊN QUAN (${adjustments.length})',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Color(0xFF54433E),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < adjustments.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildAdjustmentItem(adjustments[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildAdjustmentItem(LinkedLedgerTransactionModel adj) {
    final blockNum = blockNumbersByTxId[adj.transactionId];
    final prefix = blockNum != null ? '#$blockNum • ' : '';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => onJump(adj.transactionId),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$prefix${adj.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatSignedLedgerVnd(adj.amount)} • ${adj.transactionId}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: adj.amount >= 0
                            ? const Color(0xFF2E8B43)
                            : const Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Xem ›',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B1E1E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
