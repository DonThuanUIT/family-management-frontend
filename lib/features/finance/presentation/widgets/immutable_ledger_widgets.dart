import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/immutable_ledger_integrity_models.dart';
import '../../data/models/ledger_adjustment_models.dart';

/// Bảng màu chuẩn Warm Editorial Heritage cho từng loại giao dịch Sổ cái.
@immutable
class LedgerTypeBadgePalette {
  final Color background;
  final Color foreground;
  final Color border;

  const LedgerTypeBadgePalette({
    required this.background,
    required this.foreground,
    required this.border,
  });

  static LedgerTypeBadgePalette of(LedgerTransactionTypeEnum type) {
    switch (type) {
      case LedgerTransactionTypeEnum.surplusTransfer:
        return const LedgerTypeBadgePalette(
          background: Color(0xFFEDF7EE),
          foreground: Color(0xFF2E8B43),
          border: Color(0xFFB7DFC0),
        );
      case LedgerTransactionTypeEnum.commonFundDisbursement:
        return const LedgerTypeBadgePalette(
          background: Color(0xFFFEF2F2),
          foreground: Color(0xFFBA1A1A),
          border: Color(0xFFFECACA),
        );
      case LedgerTransactionTypeEnum.adjustmentTransaction:
        return const LedgerTypeBadgePalette(
          background: Color(0xFFFFFBEB),
          foreground: Color(0xFFB8860B),
          border: Color(0xFFFDE68A),
        );
      case LedgerTransactionTypeEnum.openingBalanceCarryForward:
        return const LedgerTypeBadgePalette(
          background: Color(0xFFF0EDEB),
          foreground: Color(0xFF54433E),
          border: Color(0xFFDFD8D0),
        );
    }
  }
}

/// Banner Warm Editorial Heritage đầu trang Sổ cái Quỹ chung bất biến (US-61 / US-62).
class ImmutableLedgerHeritageBanner extends StatelessWidget {
  final LedgerIntegrityReportModel? report;
  final int totalElements;
  final bool isAuditing;
  final VoidCallback onRunAudit;
  final bool canProposeAdjustment;
  final VoidCallback? onProposeAdjustment;
  final VoidCallback? onOpenAnnualAudit;

  const ImmutableLedgerHeritageBanner({
    super.key,
    required this.report,
    required this.totalElements,
    required this.isAuditing,
    required this.onRunAudit,
    this.canProposeAdjustment = false,
    this.onProposeAdjustment,
    this.onOpenAnnualAudit,
  });

  @override
  Widget build(BuildContext context) {
    final isBroken = report != null && !report!.valid;
    final verifiedCount = report?.verifiedEntries ?? totalElements;
    final totalCount = report?.totalEntries ?? totalElements;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBroken ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isBroken ? const Color(0xFFFECACA) : const Color(0xFF99F6E4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBroken ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
            size: 13,
            color: isBroken ? const Color(0xFFBA1A1A) : const Color(0xFF0F766E),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              isBroken
                  ? 'Cảnh báo • ${report!.brokenLinks.length} sai lệch SHA-256'
                  : 'Bất biến • $verifiedCount/$totalCount khối SHA-256',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color:
                    isBroken ? const Color(0xFFBA1A1A) : const Color(0xFF0F766E),
              ),
            ),
          ),
        ],
      ),
    );

    final proposeButton = canProposeAdjustment && onProposeAdjustment != null
        ? OutlinedButton.icon(
            onPressed: onProposeAdjustment,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text('Đề xuất bù trừ'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B1E1E),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF8B1E1E)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          )
        : null;

    final auditButton = ElevatedButton.icon(
      onPressed: isAuditing ? null : onRunAudit,
      icon: isAuditing
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.fact_check_outlined, size: 17),
      label: Text(isAuditing ? 'Đang kiểm toán...' : 'Kiểm toán chuỗi'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B1E1E),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF8B1E1E).withAlpha(150),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );

    final annualAuditButton = onOpenAnnualAudit != null
        ? OutlinedButton.icon(
            onPressed: onOpenAnnualAudit,
            icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
            label: const Text('Kiểm kê hằng năm'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F766E),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF0F766E)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          )
        : null;

    final actionsWrap = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ?annualAuditButton,
        ?proposeButton,
        auditButton,
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFDF8), Color(0xFFF7EFE1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD4A017).withAlpha(166),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C8B1E1E),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          final emblem = Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1E1E), Color(0xFF6B1414)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4A017), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E8B1E1E),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFFD4A017),
              size: 23,
            ),
          );

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Sổ Cái Quỹ Chung Bất Biến',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A1518),
                      letterSpacing: -0.3,
                    ),
                  ),
                  badge,
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                'Bảng lịch sử dòng tiền, số dư lũy kế tức thời & nhảy nhanh liên kết bù trừ • Đã loại bỏ hoàn toàn Sửa/Xóa.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF54433E),
                  height: 1.4,
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    emblem,
                    const SizedBox(width: 14),
                    Expanded(child: titleBlock),
                  ],
                ),
                const SizedBox(height: 14),
                actionsWrap,
              ],
            );
          }

          return Row(
            children: [
              emblem,
              const SizedBox(width: 16),
              Expanded(child: titleBlock),
              const SizedBox(width: 16),
              actionsWrap,
            ],
          );
        },
      ),
    );
  }
}

/// Dải đối chiếu Đầu kỳ → Biến động ròng → Cuối kỳ khi đang lọc theo khoảng thời gian (US-62).
class ImmutableLedgerPeriodReconciliationStrip extends StatelessWidget {
  final String periodLabel;
  final LedgerFlowSummaryModel summary;

  const ImmutableLedgerPeriodReconciliationStrip({
    super.key,
    required this.periodLabel,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final isNetPositive = summary.filteredNetAmount >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4A017).withAlpha(128),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Đối chiếu $periodLabel:',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A1518),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                  children: [
                    const TextSpan(text: 'Đầu kỳ: '),
                    TextSpan(
                      text: AppFormatters.formatVnd(
                        summary.openingBalanceBeforePeriod,
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '→',
                style: TextStyle(fontSize: 12, color: Color(0xFF78655C)),
              ),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                  children: [
                    const TextSpan(text: 'Biến động ròng: '),
                    TextSpan(
                      text: formatSignedLedgerVnd(summary.filteredNetAmount),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: isNetPositive
                            ? const Color(0xFF2E8B43)
                            : const Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                '→',
                style: TextStyle(fontSize: 12, color: Color(0xFF78655C)),
              ),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                  children: [
                    const TextSpan(text: 'Cuối kỳ: '),
                    TextSpan(
                      text: AppFormatters.formatVnd(
                        summary.closingBalanceAtPeriodEnd,
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tag liên kết nhảy nhanh hai chiều giữa Bút toán gốc ↔ Bút toán bù trừ (US-62).
class ImmutableLedgerQuickJumpTag extends StatelessWidget {
  final LedgerHistoryItemModel item;
  final Map<String, int> blockNumbersByTxId;
  final int? currentBlockNumber;
  final String sortDirection;
  final ValueChanged<String> onQuickJump;

  const ImmutableLedgerQuickJumpTag({
    super.key,
    required this.item,
    required this.blockNumbersByTxId,
    required this.currentBlockNumber,
    required this.sortDirection,
    required this.onQuickJump,
  });

  String _resolveArrow({
    required String targetTxId,
    required bool defaultGoingOlder,
  }) {
    final targetBlock = blockNumbersByTxId[targetTxId];
    bool goesOlder = defaultGoingOlder;
    if (currentBlockNumber != null && targetBlock != null) {
      goesOlder = targetBlock < currentBlockNumber!;
    }
    if (sortDirection.toUpperCase() == 'ASC') {
      return goesOlder ? '↑' : '↓';
    }
    return goesOlder ? '↓' : '↑';
  }

  @override
  Widget build(BuildContext context) {
    if (item.originalTransactionId != null &&
        item.originalTransactionId!.trim().isNotEmpty) {
      final targetId = item.originalTransactionId!.trim();
      final arrow = _resolveArrow(targetTxId: targetId, defaultGoingOlder: true);

      return Material(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () => onQuickJump(targetId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              '↳ Gốc: $targetId $arrow',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB8860B),
              ),
            ),
          ),
        ),
      );
    }

    if (item.hasAdjustments ||
        item.adjustmentCount > 0 ||
        item.adjustmentTransactions.isNotEmpty) {
      final hasChildId = item.adjustmentTransactions.isNotEmpty;
      final targetId =
          hasChildId ? item.adjustmentTransactions.first.transactionId : null;
      final arrow = targetId != null
          ? _resolveArrow(targetTxId: targetId, defaultGoingOlder: false)
          : (sortDirection.toUpperCase() == 'ASC' ? '↓' : '↑');
      final countLabel =
          item.adjustmentCount > 0 ? item.adjustmentCount : item.adjustmentTransactions.length;
      final labelText = targetId != null
          ? '⇄ Bù trừ ($countLabel): $targetId $arrow'
          : '⇄ Xem bù trừ ($countLabel) $arrow';

      return Material(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: () => onQuickJump(targetId ?? item.transactionId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              labelText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1E1E),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Banner cảnh báo bảo mật khi `verify-integrity` phát hiện `brokenLinks` (US-61).
class ImmutableLedgerBrokenAlertBanner extends StatelessWidget {
  final LedgerIntegrityReportModel report;
  final ValueChanged<String> onInspectBroken;

  const ImmutableLedgerBrokenAlertBanner({
    super.key,
    required this.report,
    required this.onInspectBroken,
  });

  @override
  Widget build(BuildContext context) {
    if (report.valid || report.brokenLinks.isEmpty) {
      return const SizedBox.shrink();
    }
    final firstBroken = report.brokenLinks.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 560;
          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cảnh báo bảo mật: Phát hiện ${report.brokenLinks.length} sai lệch chuỗi SHA-256',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBA1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Giao dịch ${firstBroken.transactionId} (khối #${firstBroken.chainIndex + 1}): ${firstBroken.reason}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF54433E),
                ),
              ),
            ],
          );

          final inspectBtn = ElevatedButton(
            onPressed: () => onInspectBroken(firstBroken.transactionId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text('Kiểm tra khối #${firstBroken.chainIndex + 1}'),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Color(0xFFBA1A1A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: textContent),
                  ],
                ),
                const SizedBox(height: 10),
                inspectBtn,
              ],
            );
          }

          return Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: Color(0xFFBA1A1A),
              ),
              const SizedBox(width: 10),
              Expanded(child: textContent),
              const SizedBox(width: 12),
              inspectBtn,
            ],
          );
        },
      ),
    );
  }
}

/// Dải 3 thẻ KPI tổng hợp dòng tiền trên Desktop hoặc 1 card thu gọn trên Mobile.
class ImmutableLedgerKpiSection extends StatelessWidget {
  final LedgerFlowSummaryModel summary;
  final int totalElements;
  final bool isDesktop;

  const ImmutableLedgerKpiSection({
    super.key,
    required this.summary,
    required this.totalElements,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final latestDateText = summary.latestTransactionAt != null
        ? 'Cập nhật ${AppFormatters.formatDate(summary.latestTransactionAt!.toLocal())}'
        : '$totalElements giao dịch trong sổ cái';

    if (!isDesktop) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6DFD8)),
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
                const Text(
                  'Số dư Quỹ hiện tại',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF54433E),
                  ),
                ),
                Text(
                  AppFormatters.formatVnd(summary.currentFundBalance),
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1810),
                  ),
                ),
              ],
            ),
            const Divider(height: 18, color: Color(0xFFF0EDEB)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thu kỳ lọc',
                        style:
                            TextStyle(fontSize: 11.5, color: Color(0xFF54433E)),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '+${AppFormatters.formatVnd(summary.filteredTotalInflow)}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E8B43),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi kỳ lọc',
                        style:
                            TextStyle(fontSize: 11.5, color: Color(0xFF54433E)),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '-${AppFormatters.formatVnd(summary.filteredTotalOutflow.abs())}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBA1A1A),
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
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 740;
        final cards = [
          _DesktopKpiCard(
            label: 'SỐ DƯ QUỸ HIỆN TẠI',
            value: AppFormatters.formatVnd(summary.currentFundBalance),
            valueColor: const Color(0xFF2B1810),
            subtitle: latestDateText,
            trailingBadge: totalElements > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Text(
                      'Khối #$totalElements',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  )
                : null,
          ),
          _DesktopKpiCard(
            label: 'TỔNG THU KỲ LỌC',
            value: '+${AppFormatters.formatVnd(summary.filteredTotalInflow)}',
            valueColor: const Color(0xFF2E8B43),
            subtitle: 'Từ thặng dư & bút toán bù trừ dương',
            dotColor: const Color(0xFF2E8B43),
          ),
          _DesktopKpiCard(
            label: 'TỔNG CHI KỲ LỌC',
            value:
                '-${AppFormatters.formatVnd(summary.filteredTotalOutflow.abs())}',
            valueColor: const Color(0xFFBA1A1A),
            subtitle: 'Khoản chi việc lớn & bù trừ âm',
            dotColor: const Color(0xFFBA1A1A),
          ),
        ];

        if (stackVertically) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _DesktopKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String subtitle;
  final Widget? trailingBadge;
  final Color? dotColor;

  const _DesktopKpiCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.subtitle,
    this.trailingBadge,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2B1810),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
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
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
              ?trailingBadge,
              if (dotColor != null)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF78655C),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bảng Desktop Sổ Cái Quỹ Chung (`SoLedgerUI`: Biến động + Số dư lũy kế tức thời + Tag nhảy nhanh + SHA-256).
class ImmutableLedgerDesktopTable extends StatelessWidget {
  final List<LedgerHistoryItemModel> items;
  final Map<String, int> blockNumbersByTxId;
  final int? Function(LedgerHistoryItemModel item, int index) resolveBlockNumber;
  final bool Function(String transactionId) isTransactionBroken;
  final String? selectedTransactionId;
  final String? highlightedTransactionId;
  final String sortDirection;
  final GlobalKey Function(String transactionId) rowKeyBuilder;
  final ValueChanged<LedgerHistoryItemModel> onSelectItem;
  final ValueChanged<String> onQuickJump;
  final ValueChanged<String> onCopyHash;

  const ImmutableLedgerDesktopTable({
    super.key,
    required this.items,
    required this.blockNumbersByTxId,
    required this.resolveBlockNumber,
    required this.isTransactionBroken,
    required this.selectedTransactionId,
    required this.highlightedTransactionId,
    required this.sortDirection,
    required this.rowKeyBuilder,
    required this.onSelectItem,
    required this.onQuickJump,
    required this.onCopyHash,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth > 930 ? constraints.maxWidth : 930.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                // Header #F0EDEB
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0EDEB),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE6DFD8)),
                      bottom: BorderSide(color: Color(0xFFE6DFD8)),
                    ),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 185,
                        child: Text(
                          'KHỐI & THỜI GIAN',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'NỘI DUNG & LIÊN KẾT',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 145,
                        child: Text(
                          'BIẾN ĐỘNG',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 155,
                        child: Text(
                          'SỐ DƯ LŨY KẾ',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 215,
                        child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            'NIÊM PHONG SHA-256',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Color(0xFF54433E),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Rows (Strictly Zero Edit / Delete actions)
                for (var i = 0; i < items.length; i++)
                  _DesktopLedgerRow(
                    key: rowKeyBuilder(items[i].transactionId),
                    item: items[i],
                    blockNumber: resolveBlockNumber(items[i], i),
                    blockNumbersByTxId: blockNumbersByTxId,
                    sortDirection: sortDirection,
                    isFirst: i == 0,
                    isLast: i == items.length - 1,
                    isBroken: isTransactionBroken(items[i].transactionId),
                    isSelected: selectedTransactionId == items[i].transactionId,
                    isHighlighted:
                        highlightedTransactionId == items[i].transactionId,
                    onTap: () => onSelectItem(items[i]),
                    onQuickJump: onQuickJump,
                    onCopyHash: () => onCopyHash(items[i].recordHash),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopLedgerRow extends StatelessWidget {
  final LedgerHistoryItemModel item;
  final int? blockNumber;
  final Map<String, int> blockNumbersByTxId;
  final String sortDirection;
  final bool isFirst;
  final bool isLast;
  final bool isBroken;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onTap;
  final ValueChanged<String> onQuickJump;
  final VoidCallback onCopyHash;

  const _DesktopLedgerRow({
    super.key,
    required this.item,
    required this.blockNumber,
    required this.blockNumbersByTxId,
    required this.sortDirection,
    required this.isFirst,
    required this.isLast,
    required this.isBroken,
    required this.isSelected,
    required this.isHighlighted,
    required this.onTap,
    required this.onQuickJump,
    required this.onCopyHash,
  });

  @override
  Widget build(BuildContext context) {
    final badgePalette = LedgerTypeBadgePalette.of(item.transactionType);
    final isPositive = item.amount >= 0;
    final chainColor =
        isBroken ? const Color(0xFFFECACA) : const Color(0xFF99F6E4);
    final dotFill =
        isBroken ? const Color(0xFFBA1A1A) : const Color(0xFF0F766E);
    final dotBg =
        isBroken ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final hasNetAdjustment =
        (item.hasAdjustments || item.adjustmentCount > 0) &&
            item.netAdjustedAmount != item.amount;

    final rowBg = isHighlighted
        ? const Color(0xFFFFFBEB)
        : (isSelected ? const Color(0x0A8B1E1E) : Colors.white);

    return Material(
      color: rowBg,
      child: InkWell(
        onTap: onTap,
        hoverColor: const Color(0xFFFAF7F2),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: isHighlighted
                  ? const BorderSide(color: Color(0xFFD4A017), width: 3.5)
                  : BorderSide.none,
              bottom: isLast
                  ? BorderSide.none
                  : const BorderSide(color: Color(0xFFF0EDEB)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Khối & Thời gian (DL + ÂL + Seamless hash-chain timeline)
                SizedBox(
                  width: 185,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 18,
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 2,
                                  color: isFirst
                                      ? Colors.transparent
                                      : chainColor,
                                ),
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: dotFill,
                                shape: BoxShape.circle,
                                border: Border.all(color: dotBg, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: chainColor,
                                    spreadRadius: 1.2,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 2,
                                  color: isLast
                                      ? Colors.transparent
                                      : chainColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (blockNumber != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5.5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAF9F6),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: const Color(0xFFE6DFD8),
                                        ),
                                      ),
                                      child: Text(
                                        '#$blockNumber',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2B1810),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      item.formattedSolarDate,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF54433E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.formattedLunarDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF78655C),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.transactionId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                      ),
                    ],
                  ),
                ),

                // 2. Nội dung & Tag Nhảy Nhanh
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 12, 10, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgePalette.background,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: badgePalette.border),
                              ),
                              child: Text(
                                item.transactionType.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: badgePalette.foreground,
                                ),
                              ),
                            ),
                            ImmutableLedgerQuickJumpTag(
                              item: item,
                              blockNumbersByTxId: blockNumbersByTxId,
                              currentBlockNumber: blockNumber,
                              sortDirection: sortDirection,
                              onQuickJump: onQuickJump,
                            ),
                          ],
                        ),
                        if (hasNetAdjustment) ...[
                          const SizedBox(height: 5),
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF78655C),
                              ),
                              children: [
                                const TextSpan(text: 'Ròng sau bù trừ: '),
                                TextSpan(
                                  text: formatSignedLedgerVnd(
                                    item.netAdjustedAmount,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 3. Biến động (Không bao giờ rớt chữ ₫)
                SizedBox(
                  width: 145,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          formatSignedLedgerVnd(item.amount),
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? const Color(0xFF2E8B43)
                                : const Color(0xFFBA1A1A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Số dư lũy kế tức thời (Cột riêng nổi bật)
                SizedBox(
                  width: 155,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            AppFormatters.formatVnd(item.runningBalance),
                            maxLines: 1,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                        ),
                        if (blockNumber != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Tại khối #$blockNumber',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF78655C),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 5. Niêm phong SHA-256 (ZERO Sửa / Xóa)
                SizedBox(
                  width: 215,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ImmutableSealPill(isBroken: isBroken),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                shortLedgerHashCompact(item.recordHash),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  color: Color(0xFF2B1810),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: onCopyHash,
                              tooltip: 'Sao chép mã băm SHA-256 đầy đủ',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 26,
                                minHeight: 26,
                              ),
                              icon: const Icon(
                                Icons.copy_rounded,
                                size: 13.5,
                                color: Color(0xFF54433E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '← ${shortLedgerHashCompact(item.previousHash)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight:
                                isBroken ? FontWeight.bold : FontWeight.normal,
                            color: isBroken
                                ? const Color(0xFFBA1A1A)
                                : const Color(0xFF78655C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ Mobile 3 tầng gọn gàng: Biến động & Số dư lũy kế 2 cột + Tag nhảy nhanh + SHA-256 (ZERO Sửa / Xóa).
class ImmutableLedgerMobileCard extends StatelessWidget {
  final LedgerHistoryItemModel item;
  final int? blockNumber;
  final Map<String, int> blockNumbersByTxId;
  final String sortDirection;
  final bool isBroken;
  final bool isHighlighted;
  final VoidCallback onTap;
  final ValueChanged<String> onQuickJump;
  final VoidCallback onCopyHash;

  const ImmutableLedgerMobileCard({
    super.key,
    required this.item,
    required this.blockNumber,
    required this.blockNumbersByTxId,
    required this.sortDirection,
    required this.isBroken,
    this.isHighlighted = false,
    required this.onTap,
    required this.onQuickJump,
    required this.onCopyHash,
  });

  @override
  Widget build(BuildContext context) {
    final badgePalette = LedgerTypeBadgePalette.of(item.transactionType);
    final isPositive = item.amount >= 0;
    final hasNetAdjustment =
        (item.hasAdjustments || item.adjustmentCount > 0) &&
            item.netAdjustedAmount != item.amount;

    return Card(
      margin: EdgeInsets.zero,
      color: isHighlighted ? const Color(0xFFFFFBEB) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          width: isHighlighted ? 1.8 : 1.0,
          color: isBroken
              ? const Color(0xFFFECACA)
              : (isHighlighted
                  ? const Color(0xFFD4A017)
                  : const Color(0xFFE6DFD8)),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Block + Type badge | Solar + Lunar Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (blockNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF9F6),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFE6DFD8)),
                            ),
                            child: Text(
                              '#$blockNumber',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B1810),
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgePalette.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: badgePalette.border),
                          ),
                          child: Text(
                            item.transactionType.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: badgePalette.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.formattedSolarDate,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF54433E),
                        ),
                      ),
                      Text(
                        '(${item.formattedLunarDate})',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF78655C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title & TX ID
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B1810),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.transactionId,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B1E1E),
                ),
              ),
              const SizedBox(height: 9),

              // 2-Column Biến động | Số dư lũy kế (Chống rớt chữ ₫)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFF0EDEB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Biến động',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF78655C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatSignedLedgerVnd(item.amount),
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isPositive
                                    ? const Color(0xFF2E8B43)
                                    : const Color(0xFFBA1A1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: const Color(0xFFE6DFD8),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Số dư lũy kế',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF78655C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              AppFormatters.formatVnd(item.runningBalance),
                              maxLines: 1,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B1810),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (item.originalTransactionId != null ||
                  item.hasAdjustments ||
                  item.adjustmentCount > 0 ||
                  hasNetAdjustment) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ImmutableLedgerQuickJumpTag(
                      item: item,
                      blockNumbersByTxId: blockNumbersByTxId,
                      currentBlockNumber: blockNumber,
                      sortDirection: sortDirection,
                      onQuickJump: onQuickJump,
                    ),
                    if (hasNetAdjustment)
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF78655C),
                          ),
                          children: [
                            const TextSpan(text: 'Ròng: '),
                            TextSpan(
                              text: formatSignedLedgerVnd(
                                item.netAdjustedAmount,
                              ),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B1810),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFF0EDEB)),
              ),

              // Bottom SHA-256 Strip (Zero Edit / Delete)
              Row(
                children: [
                  _ImmutableSealPill(isBroken: isBroken, compact: true),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shortLedgerHashCompact(item.recordHash),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Color(0xFF54433E),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onCopyHash,
                    tooltip: 'Sao chép SHA-256',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: Color(0xFF54433E),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Chi tiết ›',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B1E1E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImmutableSealPill extends StatelessWidget {
  final bool isBroken;
  final bool compact;

  const _ImmutableSealPill({
    required this.isBroken,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: isBroken ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isBroken ? const Color(0xFFFECACA) : const Color(0xFF99F6E4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBroken ? Icons.warning_amber_rounded : Icons.verified_user_outlined,
            size: compact ? 10.5 : 11.5,
            color: isBroken ? const Color(0xFFBA1A1A) : const Color(0xFF0F766E),
          ),
          const SizedBox(width: 4),
          Text(
            isBroken ? 'Sai lệch' : 'Bất biến',
            style: TextStyle(
              fontSize: compact ? 10.5 : 11,
              fontWeight: FontWeight.bold,
              color:
                  isBroken ? const Color(0xFFBA1A1A) : const Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
  }
}
