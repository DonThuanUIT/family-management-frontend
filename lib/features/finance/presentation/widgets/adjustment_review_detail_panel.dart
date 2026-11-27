import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/files/member_file_actions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../data/datasources/ledger_remote_datasource.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../providers/ledger_adjustment_providers.dart';

/// Khối chi tiết thẩm định 1 Đề xuất bù trừ Sổ cái (US-59).
class AdjustmentReviewDetailPanel extends ConsumerStatefulWidget {
  final LedgerAdjustmentRequestModel request;
  final LedgerHistoryItemModel? originalTransaction;
  final bool isLoadingOriginal;
  final ImmutableLedgerEntryModel? sealedEntry;
  final double currentFundBalance;

  const AdjustmentReviewDetailPanel({
    super.key,
    required this.request,
    required this.originalTransaction,
    required this.isLoadingOriginal,
    required this.sealedEntry,
    required this.currentFundBalance,
  });

  @override
  ConsumerState<AdjustmentReviewDetailPanel> createState() =>
      _AdjustmentReviewDetailPanelState();
}

class _AdjustmentReviewDetailPanelState
    extends ConsumerState<AdjustmentReviewDetailPanel> {
  bool _downloadingEvidence = false;

  String _spokenWords(double signedAmount) {
    if (signedAmount == 0) return 'Không đồng chẵn';
    final absWords = VietnameseMoneyConverter.toWords(signedAmount.abs());
    final cleanAbs = absWords.isNotEmpty
        ? '${absWords[0].toLowerCase()}${absWords.substring(1)}'
        : 'không đồng chẵn';
    return signedAmount > 0
        ? 'Cộng (tăng quỹ) $cleanAbs'
        : 'Trừ (giảm quỹ) $cleanAbs';
  }

  Future<void> _copyText(String value, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: AppTheme.immutableLedgerTeal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openOrDownloadEvidence(String url, String fileName) async {
    setState(() => _downloadingEvidence = true);
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
      if (mounted) setState(() => _downloadingEvidence = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final orig = widget.originalTransaction;
    final sealed = widget.sealedEntry;

    final isPending = req.approvalStatus == LedgerAdjustmentStatusEnum.pending;
    final projectedFundBalance =
        widget.currentFundBalance + req.proposedAdjustmentAmount;
    final isOverdraft = isPending && projectedFundBalance < 0;

    final amtColor = req.proposedAdjustmentAmount >= 0
        ? AppTheme.immutableLedgerTeal
        : const Color(0xFFBA1A1A);
    final wordsBg = req.proposedAdjustmentAmount >= 0
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFEF2F2);
    final wordsBorder = req.proposedAdjustmentAmount >= 0
        ? const Color(0xFF99F6E4)
        : const Color(0xFFFECACA);

    final typeMeta = req.originalTransactionType;
    final baseNetForOriginal =
        orig?.netAdjustedAmount ?? req.originalTransactionAmount;
    final effectiveOriginalAfter = isPending
        ? baseNetForOriginal + req.proposedAdjustmentAmount
        : (orig?.netAdjustedAmount ??
            (req.originalTransactionAmount + req.proposedAdjustmentAmount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // =====================================================================
        // CARD 1: HEADER & ĐỐI CHIẾU SỐ LIỆU 2 TẦNG
        // =====================================================================
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE6DFD8)),
                    ),
                    child: Text(
                      req.requestId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: req.approvalStatus.badgeBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: req.approvalStatus.badgeBorderColor,
                      ),
                    ),
                    child: Text(
                      req.approvalStatus.displayName,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: req.approvalStatus.badgeTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Người lập: ${req.proposedByAccountId} • ${req.formattedCreatedAt}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF58413F)),
              ),
              const Divider(height: 24, color: Color(0xFFEFECE6)),

              // Highlighted Amount + Vietnamese Money Words
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: wordsBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: wordsBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text(
                          'KHOẢN BÙ TRỪ ĐỀ XUẤT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                            color: amtColor,
                          ),
                        ),
                        Text(
                          formatSignedLedgerVnd(req.proposedAdjustmentAmount),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: amtColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bằng chữ: ${_spokenWords(req.proposedAdjustmentAmount)}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: amtColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Responsive 2-column comparison via LayoutBuilder
              LayoutBuilder(
                builder: (context, constraints) {
                  final sideBySide = constraints.maxWidth >= 600;
                  final origBox = _buildOriginalEntryBox(
                    typeMeta: typeMeta,
                    req: req,
                    orig: orig,
                    effectiveOriginalAfter: effectiveOriginalAfter,
                  );
                  final impactBox = _buildFundImpactBox(
                    req: req,
                    sealed: sealed,
                    isPending: isPending,
                    isOverdraft: isOverdraft,
                    projectedFundBalance: projectedFundBalance,
                    amtColor: amtColor,
                  );

                  if (sideBySide) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: origBox),
                          const SizedBox(width: 12),
                          Expanded(child: impactBox),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      origBox,
                      const SizedBox(height: 12),
                      impactBox,
                    ],
                  );
                },
              ),

              if (isPending) ...[
                const SizedBox(height: 14),
                _buildSystemChecks(
                  isOverdraft: isOverdraft,
                  projectedFundBalance: projectedFundBalance,
                  hasEvidence: req.evidenceAttachmentUrl != null &&
                      req.evidenceAttachmentUrl!.trim().isNotEmpty,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // =====================================================================
        // CARD 2: GIẢI TRÌNH & BIÊN BẢN ĐÍNH KÈM
        // =====================================================================
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Giải Trình & Biên Bản Đính Kèm',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1A),
                ),
              ),
              const SizedBox(height: 12),

              // Editorial quote block for reason
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                  border: Border(
                    left: BorderSide(color: AppTheme.secondaryGold, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '“${req.adjustmentReason}”',
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFF1A1C1A),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— Người lập: ${req.proposedByAccountId}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF58413F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _buildEvidenceSection(req),
            ],
          ),
        ),

        // =====================================================================
        // CARD 3: OUTCOME (APPROVED SHA-256 SEAL OR REJECTED REASON)
        // =====================================================================
        if (req.approvalStatus == LedgerAdjustmentStatusEnum.approved) ...[
          const SizedBox(height: 16),
          _buildApprovedOutcomeCard(req, sealed),
        ] else if (req.approvalStatus ==
            LedgerAdjustmentStatusEnum.rejected) ...[
          const SizedBox(height: 16),
          _buildRejectedOutcomeCard(req),
        ],
      ],
    );
  }

  Widget _buildOriginalEntryBox({
    required LedgerTransactionTypeEnum typeMeta,
    required LedgerAdjustmentRequestModel req,
    required LedgerHistoryItemModel? orig,
    required double effectiveOriginalAfter,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(14),
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
              const Text(
                '1. GIAO DỊCH GỐC',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF58413F),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeMeta.badgeBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: typeMeta.badgeBorderColor),
                ),
                child: Text(
                  typeMeta.displayName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: typeMeta.badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            orig != null
                ? '${req.originalTransactionId} • ${orig.formattedSolarDate} (${orig.formattedLunarDate})'
                : req.originalTransactionId,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1A),
            ),
          ),
          const SizedBox(height: 6),
          if (widget.isLoadingOriginal && orig == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Đang tải diễn giải bút toán gốc...',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF58413F),
                ),
              ),
            )
          else if (orig != null)
            Text(
              orig.description,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF1A1C1A),
                height: 1.4,
              ),
            ),
          const Divider(height: 20, color: Color(0xFFE6DFD8)),
          _ComparisonMetricRow(
            label: 'Số tiền gốc:',
            value: formatSignedLedgerVnd(req.originalTransactionAmount),
            valueColor: const Color(0xFF1A1C1A),
          ),
          const SizedBox(height: 4),
          _ComparisonMetricRow(
            label: 'Hiệu lực sau bù trừ:',
            value: formatSignedLedgerVnd(effectiveOriginalAfter),
            valueColor: const Color(0xFF1A1C1A),
          ),
        ],
      ),
    );
  }

  Widget _buildFundImpactBox({
    required LedgerAdjustmentRequestModel req,
    required ImmutableLedgerEntryModel? sealed,
    required bool isPending,
    required bool isOverdraft,
    required double projectedFundBalance,
    required Color amtColor,
  }) {
    final afterBalance = isPending
        ? projectedFundBalance
        : (sealed?.runningBalance ?? widget.currentFundBalance);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOverdraft ? const Color(0xFFFFF8F8) : const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isOverdraft ? const Color(0xFFBA1A1A) : const Color(0xFFE6DFD8),
          width: isOverdraft ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                '2. TÁC ĐỘNG QUỸ CHUNG',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF58413F),
                ),
              ),
              Text(
                'Chính xác từng đồng',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF58413F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ComparisonMetricRow(
            label: 'Số dư Quỹ hiện tại:',
            value: AppFormatters.formatVnd(widget.currentFundBalance),
            valueColor: const Color(0xFF1A1C1A),
          ),
          const SizedBox(height: 6),
          _ComparisonMetricRow(
            label: 'Điều chỉnh đề xuất:',
            value: formatSignedLedgerVnd(req.proposedAdjustmentAmount),
            valueColor: amtColor,
          ),
          const Divider(height: 20, color: Color(0xFFE6DFD8)),
          _ComparisonMetricRow(
            label: isPending ? 'Số dư Quỹ sau duyệt:' : 'Số dư Quỹ ghi nhận:',
            value: AppFormatters.formatVnd(afterBalance),
            valueColor:
                isOverdraft ? const Color(0xFFBA1A1A) : AppTheme.immutableLedgerTeal,
            boldLabel: true,
            largeValue: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemChecks({
    required bool isOverdraft,
    required double projectedFundBalance,
    required bool hasEvidence,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOverdraft)
          Container(
            key: const Key('review_overdraft_warning_banner'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBA1A1A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFBA1A1A),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Số dư Quỹ chung sau bù trừ sẽ bị âm (${AppFormatters.formatVnd(projectedFundBalance)}). Hệ thống khóa nút Phê duyệt theo quy tắc Sổ cái bất biến.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF93000A),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.immutableLedgerTeal,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Số dư Quỹ chung sau duyệt hợp lệ: Còn ${AppFormatters.formatVnd(projectedFundBalance)} (≥ 0 ₫).',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.immutableLedgerTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                hasEvidence ? const Color(0xFFFAF9F6) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasEvidence
                  ? const Color(0xFFE6DFD8)
                  : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasEvidence
                    ? Icons.attach_file_rounded
                    : Icons.info_outline_rounded,
                color: hasEvidence
                    ? AppTheme.immutableLedgerTeal
                    : AppTheme.secondaryGold,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasEvidence
                      ? 'Đã đính kèm biên bản chứng từ: Trưởng tộc vui lòng mở xem trước khi phê duyệt.'
                      : 'Chưa có biên bản đính kèm: Cân nhắc yêu cầu Thủ quỹ bổ sung nếu cần chứng từ đối chiếu.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF58413F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceSection(LedgerAdjustmentRequestModel req) {
    final url = req.evidenceAttachmentUrl?.trim();
    if (url == null || url.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDFD8D0)),
        ),
        child: const Text(
          'Thủ quỹ không đính kèm tệp biên bản cho đề xuất này.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF58413F)),
        ),
      );
    }

    final internalFileName =
        LedgerRemoteDataSourceImpl.extractInternalEvidenceFilename(url);
    if (internalFileName != null) {
      final isPdf = internalFileName.toLowerCase().endsWith('.pdf');
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6DFD8)),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isPdf
                        ? const Color(0xFFFDF2F2)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPdf
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Icon(
                    isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                    color: isPdf
                        ? AppTheme.primaryCrimson
                        : AppTheme.secondaryGold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        internalFileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kho lưu trữ bảo mật nội bộ (Private Storage)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.immutableLedgerTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              key: const Key('review_open_evidence_button'),
              onPressed: _downloadingEvidence
                  ? null
                  : () => _openOrDownloadEvidence(url, internalFileName),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 46),
                foregroundColor: AppTheme.primaryCrimson,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.primaryCrimson),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _downloadingEvidence
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.visibility_outlined, size: 18),
              label: Text(
                _downloadingEvidence ? 'Đang tải...' : 'Xem / Tải biên bản',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // External URL
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.link_rounded,
            color: AppTheme.primaryCrimson,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              url,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1C1A),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sao chép đường dẫn',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () =>
                _copyText(url, 'Đã sao chép đường dẫn biên bản.'),
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedOutcomeCard(
    LedgerAdjustmentRequestModel req,
    ImmutableLedgerEntryModel? sealed,
  ) {
    return Container(
      key: const Key('sealed_ledger_entry_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: AppTheme.immutableLedgerTeal,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Đã Ghi Bút Toán Sổ Cái Bất Biến (SHA-256)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.immutableLedgerTeal,
                      ),
                    ),
                  ),
                ],
              ),
              if (req.formattedReviewedAt != null)
                Text(
                  req.formattedReviewedAt!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF58413F),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sealed != null) ...[
                  _ComparisonMetricRow(
                    label: 'Mã bút toán mới:',
                    value: sealed.transactionId,
                    valueColor: AppTheme.immutableLedgerTeal,
                  ),
                  const SizedBox(height: 6),
                ],
                _ComparisonMetricRow(
                  label: 'Người phê duyệt:',
                  value: req.reviewedByAccountId ?? 'Trưởng tộc',
                  valueColor: const Color(0xFF1A1C1A),
                ),
                if (sealed != null) ...[
                  const SizedBox(height: 6),
                  _ComparisonMetricRow(
                    label: 'Số dư Quỹ sau ghi sổ:',
                    value: AppFormatters.formatVnd(sealed.runningBalance),
                    valueColor: const Color(0xFF1A1C1A),
                  ),
                  const Divider(height: 20, color: Color(0xFFEFECE6)),
                  const Text(
                    'Diễn giải trên Sổ cái:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF58413F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sealed.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                  if (sealed.recordHash.trim().isNotEmpty) ...[
                    const Divider(height: 20, color: Color(0xFFEFECE6)),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mã băm niêm phong (SHA-256 record_hash):',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF58413F),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _copyText(
                            sealed.recordHash,
                            'Đã sao chép mã băm SHA-256.',
                          ),
                          child: const Text(
                            'Sao chép',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.immutableLedgerTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE6DFD8)),
                      ),
                      child: SelectableText(
                        sealed.recordHash,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF1A1C1A),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedOutcomeCard(LedgerAdjustmentRequestModel req) {
    return Container(
      key: const Key('rejected_outcome_card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text(
                'Đề Xuất Đã Bị Từ Chối',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBA1A1A),
                ),
              ),
              if (req.formattedReviewedAt != null)
                Text(
                  req.formattedReviewedAt!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF58413F),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Người xử lý: ${req.reviewedByAccountId ?? 'Trưởng tộc'} • Không phát sinh bút toán trên Sổ cái.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF58413F)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              'Lý do từ chối: ${req.rejectionReason ?? ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF93000A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool boldLabel;
  final bool largeValue;

  const _ComparisonMetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.boldLabel = false,
    this.largeValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: boldLabel ? FontWeight.bold : FontWeight.normal,
              color: boldLabel
                  ? const Color(0xFF1A1C1A)
                  : const Color(0xFF58413F),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: largeValue ? 15.5 : 13.5,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
