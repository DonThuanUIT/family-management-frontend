import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/files/member_file_actions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../data/datasources/ledger_remote_datasource.dart';
import '../../data/models/common_fund_disbursement_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../providers/ledger_adjustment_providers.dart';

/// Khối chi tiết thẩm định 1 Đề xuất chi Quỹ chung cho Trưởng tộc (US-60).
class DisbursementReviewDetailPanel extends ConsumerStatefulWidget {
  final CommonFundDisbursementModel request;
  final CommonFundBalanceModel balance;
  final ImmutableLedgerEntryModel? sealedEntry;
  final bool isLoadingLedgerDetail;

  const DisbursementReviewDetailPanel({
    super.key,
    required this.request,
    required this.balance,
    required this.sealedEntry,
    required this.isLoadingLedgerDetail,
  });

  @override
  ConsumerState<DisbursementReviewDetailPanel> createState() =>
      _DisbursementReviewDetailPanelState();
}

class _DisbursementReviewDetailPanelState
    extends ConsumerState<DisbursementReviewDetailPanel> {
  bool _downloadingEvidence = false;

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
              content: Text('Đã tải xuống chứng từ $fileName'),
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
            content: Text('Không thể mở chứng từ: ${formatLedgerFailure(e)}'),
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
    final bal = widget.balance;
    final sealed = widget.sealedEntry;

    final isPending =
        req.approvalStatus == CommonFundDisbursementStatusEnum.pending;
    final projectedBalance = bal.availableBalance - req.amount;
    final isOverdraft = isPending && projectedBalance < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // =====================================================================
        // CARD 1: HEADER & ĐỐI CHIẾU THÔNG TIN CHI + TÁC ĐỘNG QUỸ CHUNG
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
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: req.category.badgeBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: req.category.badgeBorderColor,
                          ),
                        ),
                        child: Text(
                          req.category.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: req.category.badgeTextColor,
                          ),
                        ),
                      ),
                    ],
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
              const SizedBox(height: 10),
              Text(
                req.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Người đề xuất: ${req.proposedByAccountId} • ${req.formattedCreatedAt}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF58413F)),
              ),
              const Divider(height: 24, color: Color(0xFFEFECE6)),

              // Highlighted Amount + Vietnamese Money Words
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
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
                        const Text(
                          'SỐ TIỀN XIN TRÍCH QUỸ CHUNG',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                            color: Color(0xFFBA1A1A),
                          ),
                        ),
                        Text(
                          '−${AppFormatters.formatVnd(req.amount)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBA1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bằng chữ: ${VietnameseMoneyConverter.toWords(req.amount)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBA1A1A),
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
                  final beneficiaryBox = _buildBeneficiaryBox(req);
                  final impactBox = _buildFundImpactBox(
                    req: req,
                    bal: bal,
                    sealed: sealed,
                    isPending: isPending,
                    isOverdraft: isOverdraft,
                    projectedBalance: projectedBalance,
                  );

                  if (sideBySide) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: beneficiaryBox),
                          const SizedBox(width: 12),
                          Expanded(child: impactBox),
                        ],
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      beneficiaryBox,
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
                  projectedBalance: projectedBalance,
                  hasAttachment: req.attachmentUrl != null &&
                      req.attachmentUrl!.trim().isNotEmpty,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // =====================================================================
        // CARD 2: MỤC ĐÍCH CHI & CHỨNG TỪ ĐÍNH KÈM
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
                'Mục Đích Chi & Hồ Sơ Đính Kèm',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1A),
                ),
              ),
              const SizedBox(height: 12),
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
                      '“${req.purpose}”',
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFF1A1C1A),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '— Người đề xuất: ${req.proposedByAccountId}',
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
              _buildAttachmentSection(req),
            ],
          ),
        ),

        // =====================================================================
        // CARD 3: KẾT QUẢ THẨM ĐỊNH (APPROVED SHA-256 HOẶC REJECTED)
        // =====================================================================
        if (req.approvalStatus == CommonFundDisbursementStatusEnum.approved) ...[
          const SizedBox(height: 16),
          _buildApprovedOutcomeCard(req, sealed),
        ] else if (req.approvalStatus ==
            CommonFundDisbursementStatusEnum.rejected) ...[
          const SizedBox(height: 16),
          _buildRejectedOutcomeCard(req),
        ],
      ],
    );
  }

  Widget _buildBeneficiaryBox(CommonFundDisbursementModel req) {
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
          const Text(
            '1. THÔNG TIN THỤ HƯỞNG',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF58413F),
            ),
          ),
          const SizedBox(height: 10),
          _MetricPairRow(
            label: 'Đơn vị / Cá nhân:',
            value: req.beneficiaryName ?? '—',
            valueColor: const Color(0xFF1A1C1A),
            isMonospace: false,
          ),
          if (req.beneficiaryMemberId != null &&
              req.beneficiaryMemberId!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _MetricPairRow(
              label: 'Mã thành viên:',
              value: req.beneficiaryMemberId!,
              valueColor: AppTheme.immutableLedgerTeal,
            ),
          ],
          const Divider(height: 20, color: Color(0xFFE6DFD8)),
          const _MetricPairRow(
            label: 'Loại bút toán ghi sổ:',
            value: 'CommonFundDisbursement',
            valueColor: Color(0xFF58413F),
          ),
        ],
      ),
    );
  }

  Widget _buildFundImpactBox({
    required CommonFundDisbursementModel req,
    required CommonFundBalanceModel bal,
    required ImmutableLedgerEntryModel? sealed,
    required bool isPending,
    required bool isOverdraft,
    required double projectedBalance,
  }) {
    final recordedBalance = sealed?.runningBalance ?? bal.availableBalance;
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
          const SizedBox(height: 10),
          _MetricPairRow(
            label: 'Quỹ khả dụng hiện tại:',
            value: AppFormatters.formatVnd(bal.availableBalance),
            valueColor: const Color(0xFF1A1C1A),
          ),
          const SizedBox(height: 6),
          _MetricPairRow(
            label: 'Khoản chi đề xuất:',
            value: '−${AppFormatters.formatVnd(req.amount)}',
            valueColor: const Color(0xFFBA1A1A),
          ),
          const Divider(height: 20, color: Color(0xFFE6DFD8)),
          _MetricPairRow(
            label: isPending ? 'Số dư Quỹ sau duyệt:' : 'Số dư Quỹ ghi nhận:',
            value: AppFormatters.formatVnd(
              isPending ? projectedBalance : recordedBalance,
            ),
            valueColor: isOverdraft
                ? const Color(0xFFBA1A1A)
                : AppTheme.immutableLedgerTeal,
            boldLabel: true,
            largeValue: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemChecks({
    required bool isOverdraft,
    required double projectedBalance,
    required bool hasAttachment,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOverdraft)
          Container(
            key: const Key('disbursement_review_overdraft_banner'),
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
                    'Số dư Quỹ chung không đủ (${AppFormatters.formatVnd(projectedBalance)}). Hệ thống khóa nút Ký duyệt; chỉ có thể Từ chối.',
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
                    'Số dư khả dụng đáp ứng khoản chi: Còn ${AppFormatters.formatVnd(projectedBalance)} sau duyệt.',
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
                hasAttachment ? const Color(0xFFFAF9F6) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasAttachment
                  ? const Color(0xFFE6DFD8)
                  : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasAttachment
                    ? Icons.attach_file_rounded
                    : Icons.info_outline_rounded,
                color: hasAttachment
                    ? AppTheme.immutableLedgerTeal
                    : AppTheme.secondaryGold,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasAttachment
                      ? 'Đã đính kèm chứng từ / dự toán: Trưởng tộc mở kiểm tra trước khi nhập mật khẩu ký duyệt.'
                      : 'Chưa có tệp chứng từ đính kèm: Cân nhắc yêu cầu bổ sung nếu khoản chi lớn cần dự toán.',
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

  Widget _buildAttachmentSection(CommonFundDisbursementModel req) {
    final url = req.attachmentUrl?.trim();
    if (url == null || url.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDFD8D0)),
        ),
        child: const Text(
          'Người đề xuất không đính kèm tài liệu chứng từ cho phiếu chi này.',
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
              key: const Key('disbursement_open_evidence_button'),
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
                _downloadingEvidence ? 'Đang tải...' : 'Xem / Tải chứng từ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

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
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1C1A)),
            ),
          ),
          IconButton(
            tooltip: 'Sao chép đường dẫn',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () =>
                _copyText(url, 'Đã sao chép đường dẫn chứng từ.'),
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedOutcomeCard(
    CommonFundDisbursementModel req,
    ImmutableLedgerEntryModel? sealed,
  ) {
    final txId = sealed?.transactionId ?? req.ledgerTransactionId;
    return Container(
      key: const Key('disbursement_sealed_ledger_card'),
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
                      'Đã Ký Duyệt & Ghi Sổ Cái Bất Biến (SHA-256)',
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
                if (txId != null && txId.isNotEmpty) ...[
                  _MetricPairRow(
                    label: 'Mã bút toán Sổ cái:',
                    value: txId,
                    valueColor: AppTheme.immutableLedgerTeal,
                  ),
                  const SizedBox(height: 6),
                ],
                _MetricPairRow(
                  label: 'Người ký duyệt:',
                  value: req.reviewedByAccountId ?? 'Trưởng tộc',
                  valueColor: const Color(0xFF1A1C1A),
                ),
                if (widget.isLoadingLedgerDetail && sealed == null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Đang tải chi tiết chữ ký băm SHA-256 từ Sổ cái...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF58413F),
                    ),
                  ),
                ] else if (sealed != null) ...[
                  const SizedBox(height: 6),
                  _MetricPairRow(
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

  Widget _buildRejectedOutcomeCard(CommonFundDisbursementModel req) {
    return Container(
      key: const Key('disbursement_rejected_card'),
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
                'Phiếu Đề Xuất Chi Đã Bị Từ Chối',
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

class _MetricPairRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isMonospace;
  final bool boldLabel;
  final bool largeValue;

  const _MetricPairRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isMonospace = true,
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
              fontFamily: isMonospace ? 'monospace' : null,
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
