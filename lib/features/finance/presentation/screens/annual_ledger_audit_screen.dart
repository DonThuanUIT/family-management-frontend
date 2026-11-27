import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/files/member_file_actions.dart';
import '../../../../core/security/rbac_models.dart';
import '../../../../core/utils/formatters.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../data/datasources/ledger_remote_datasource.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../providers/ledger_annual_audit_providers.dart';
import '../widgets/adjustment_evidence_section.dart';
import '../widgets/ledger_annual_audit_widgets.dart';

/// Màn hình Biên Bản Kiểm Kê Quỹ Hằng Năm (`AnnualAuditUI`):
/// - Nhập số tiền thực tế đếm được (+ Bảng tính nhanh tùy chọn), đối chiếu trực tiếp với `running_balance`.
/// - Nếu khớp `0 ₫`: Trưởng tộc xác nhận chốt số dư đầu kỳ mới (`OpeningBalanceCarryForward`) niêm phong SHA-256.
/// - Nếu lệch `≠ 0 ₫`: tự động sinh Đề xuất bù trừ (US-15) và giữ sổ mở chờ phê duyệt (US-59).
class AnnualLedgerAuditScreen extends ConsumerStatefulWidget {
  final int? initialYear;

  const AnnualLedgerAuditScreen({
    super.key,
    this.initialYear,
  });

  @override
  ConsumerState<AnnualLedgerAuditScreen> createState() =>
      _AnnualLedgerAuditScreenState();
}

class _AnnualLedgerAuditScreenState
    extends ConsumerState<AnnualLedgerAuditScreen> {
  final TextEditingController _actualController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int _activeTab = 0; // 0 = Thực hiện kiểm kê, 1 = Lịch sử biên bản
  double? _actualBalance;
  String? _selectedReferenceTxId; // null = Tự động (bút toán mới nhất)

  EvidenceInputMode _evidenceMode = EvidenceInputMode.file;
  SelectedEvidenceFile? _selectedFile;
  String _evidenceUrl = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final canPerform =
          ref.read(dualRbacSessionProvider).canPerformAnnualLedgerAudit;
      await ref.read(ledgerAnnualAuditProvider.notifier).loadInitial(
            initialYear: widget.initialYear,
            canPerformAudit: canPerform,
          );
    });
  }

  @override
  void dispose() {
    _actualController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setActualAmount(double? amount) {
    setState(() {
      _actualBalance = amount;
      if (amount == null) {
        _actualController.text = '';
      } else {
        final formatted = formatVndDigitsWithDots(amount.round());
        _actualController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
    ref.read(ledgerAnnualAuditProvider.notifier).clearSubmitError();
  }

  void _onActualInputChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      if (digits.isEmpty) {
        _actualBalance = null;
      } else {
        _actualBalance = double.tryParse(digits);
      }
    });
    ref.read(ledgerAnnualAuditProvider.notifier).clearSubmitError();
  }

  Future<void> _handleConfirmAndSubmit(LedgerAnnualAuditState state) async {
    final actual = _actualBalance;
    if (actual == null || state.isPreFlightBlocked) return;

    if (_evidenceMode == EvidenceInputMode.url &&
        !AdjustmentEvidenceSection.isValidExternalUrl(_evidenceUrl)) {
      _showSnackBar(
        'Đường dẫn chứng từ không hợp lệ (chỉ hỗ trợ http:// hoặc https://).',
        isError: true,
      );
      return;
    }

    final effectiveRefId = _selectedReferenceTxId ??
        state.latestTransaction?.transactionId ??
        'bút toán mới nhất';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AnnualAuditConfirmDialog(
        auditYear: state.selectedYear,
        systemBalance: state.systemBalance,
        actualBalance: actual,
        referenceTransactionId: effectiveRefId,
      ),
    );
    if (!mounted || confirmed != true) return;

    final canPerform =
        ref.read(dualRbacSessionProvider).canPerformAnnualLedgerAudit;
    final created = await ref
        .read(ledgerAnnualAuditProvider.notifier)
        .submitAudit(
          actualBalance: actual,
          referenceTransactionId: _selectedReferenceTxId,
          notes: _notesController.text,
          evidenceFile:
              _evidenceMode == EvidenceInputMode.file ? _selectedFile : null,
          evidenceUrl:
              _evidenceMode == EvidenceInputMode.url ? _evidenceUrl : null,
          canPerformAudit: canPerform,
        );
    if (!mounted || created == null) return;

    if (created.isMatched) {
      _showSnackBar(
        'Đã chốt kiểm kê năm ${created.auditYear} khớp số dư & niêm phong đầu kỳ ${created.nextPeriodYear}.',
      );
    } else {
      _showSnackBar(
        'Phát hiện lệch ${formatSignedLedgerVnd(created.discrepancyAmount)} — Đã tự động tạo đề xuất ${created.adjustmentRequestId ?? ''}.',
      );
    }
  }

  Future<void> _handleDownloadEvidence(String url) async {
    final fileName =
        LedgerRemoteDataSourceImpl.extractInternalEvidenceFilename(url);
    if (fileName == null) {
      _showSnackBar('Đường dẫn tham chiếu ngoài: $url');
      return;
    }
    try {
      final bytes = await ref
          .read(ledgerAnnualAuditProvider.notifier)
          .downloadAuditEvidence(url);
      if (!mounted) return;
      final mime = fileName.toLowerCase().endsWith('.pdf')
          ? 'application/pdf'
          : (fileName.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg');
      await ref.read(memberFileActionsProvider).save(bytes, fileName, mime);
      if (!mounted) return;
      _showSnackBar('Đã tải tệp chứng từ $fileName.');
    } on Failure catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Không thể tải tệp chứng từ.', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFBA1A1A) : const Color(0xFF2B1810),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ledgerAnnualAuditProvider);
    final session = ref.watch(dualRbacSessionProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 860;
    final canPerformAudit = session.canPerformAnnualLedgerAudit;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: isDesktop
          ? const HeritageNavBar(currentRoute: '/contributions')
          : _buildMobileAppBar(state),
      body: RefreshIndicator(
        color: const Color(0xFF8B1E1E),
        onRefresh: () => ref
            .read(ledgerAnnualAuditProvider.notifier)
            .refresh(canPerformAudit: canPerformAudit),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader(state, isDesktop),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 12,
                  vertical: isDesktop ? 20 : 12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _buildBody(state, canPerformAudit, isDesktop),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(LedgerAnnualAuditState state) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2B1810),
      elevation: 0,
      surfaceTintColor: Colors.white,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE6DFD8)),
      ),
      title: const Text(
        'Biên Bản Kiểm Kê Quỹ',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2B1810),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Center(
            child: _buildYearSelector(state, compact: true),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeader(LedgerAnnualAuditState state, bool isDesktop) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6DFD8))),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 12,
        vertical: isDesktop ? 16 : 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => context.push('/finance/ledger'),
                              child: const Text(
                                'Sổ Cái Quỹ Chung (SHA-256)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF78655C),
                                ),
                              ),
                            ),
                            const Text(
                              '  /  ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF78655C),
                              ),
                            ),
                            const Text(
                              'Kiểm Kê Quỹ Hằng Năm',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B1E1E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Biên Bản Kiểm Kê Quỹ Hằng Năm',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Kỳ kiểm kê:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF54433E),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildYearSelector(state, compact: false),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TabChip(
                        key: const Key('annual_audit_tab_form'),
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Thực hiện kiểm kê',
                        selected: _activeTab == 0,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                      _TabChip(
                        key: const Key('annual_audit_tab_history'),
                        icon: Icons.history_edu_outlined,
                        label: 'Lịch sử biên bản (${state.audits.length})',
                        selected: _activeTab == 1,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                    ],
                  ),
                  if (isDesktop) _buildPreFlightStrip(state),
                ],
              ),
              if (!isDesktop) ...[
                const SizedBox(height: 10),
                _buildPreFlightStrip(state),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelector(
    LedgerAnnualAuditState state, {
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDFD8D0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          key: const Key('annual_audit_year_dropdown'),
          value: state.selectedYear,
          isDense: true,
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF8B1E1E),
          ),
          items: [
            for (final y in state.availableYears)
              DropdownMenuItem<int>(
                value: y,
                child: Text('Năm $y'),
              ),
          ],
          onChanged: (year) {
            if (year == null) return;
            ref.read(ledgerAnnualAuditProvider.notifier).setSelectedYear(year);
          },
        ),
      ),
    );
  }

  Widget _buildPreFlightStrip(LedgerAnnualAuditState state) {
    final totalEntries =
        state.integrityReport?.totalEntries ?? state.totalLedgerEntries;
    final verifiedEntries =
        state.integrityReport?.verifiedEntries ?? state.totalLedgerEntries;
    final brokenCount = state.integrityReport?.brokenLinks.length ?? 0;

    return AnnualAuditPreFlightStrip(
      isShaValid: state.isShaValid,
      verifiedEntries: verifiedEntries,
      totalEntries: totalEntries,
      brokenLinksCount: brokenCount,
      pendingAdjustmentCount: state.pendingAdjustmentCount,
      pendingDisbursementCount: state.pendingDisbursementCount,
      selectedYear: state.selectedYear,
      matchedForYear: state.matchedAuditForSelectedYear,
    );
  }

  Widget _buildBody(
    LedgerAnnualAuditState state,
    bool canPerformAudit,
    bool isDesktop,
  ) {
    if (state.isLoadingInitial) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF8B1E1E)),
              SizedBox(height: 12),
              Text(
                'Đang đối soát số dư Sổ cái & chuỗi SHA-256...',
                style: TextStyle(fontSize: 13, color: Color(0xFF54433E)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline,
                size: 32, color: Color(0xFFBA1A1A)),
            const SizedBox(height: 8),
            Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBA1A1A),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(ledgerAnnualAuditProvider.notifier)
                  .refresh(canPerformAudit: canPerformAudit),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E1E),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_activeTab == 1) {
      return AnnualAuditHistoryList(
        audits: state.filteredAudits,
        totalCount: state.audits.length,
        availableYears: state.availableYears,
        filterYear: state.historyFilterYear,
        filterStatus: state.historyFilterStatus,
        onFilterYearChanged: (year) => ref
            .read(ledgerAnnualAuditProvider.notifier)
            .setHistoryFilterYear(year),
        onFilterStatusChanged: (st) => ref
            .read(ledgerAnnualAuditProvider.notifier)
            .setHistoryFilterStatus(st),
        onSelectAudit: (audit) => showDialog<void>(
          context: context,
          builder: (_) => AnnualAuditDetailDialog(
            record: audit,
            onOpenLedgerTransaction: (txId) => context.push(
              '/finance/ledger?transactionId=${Uri.encodeComponent(txId)}',
            ),
            onOpenAdjustmentReview: (reqId) => context.push(
              '/finance/ledger/review-adjustments?requestId=${Uri.encodeComponent(reqId)}',
            ),
            onDownloadEvidence: _handleDownloadEvidence,
          ),
        ),
      );
    }

    // Tab 1: Thực hiện kiểm kê
    if (!canPerformAudit) {
      return AnnualAuditMemberReadOnlyCard(
        systemBalance: state.systemBalance,
        latestTransaction: state.latestTransaction,
        totalAuditsCount: state.audits.length,
        onViewHistory: () => setState(() => _activeTab = 1),
      );
    }

    final matched = state.matchedAuditForSelectedYear;
    if (matched != null) {
      return AnnualAuditSealedReceiptCard(
        record: matched,
        onViewHistory: () => setState(() => _activeTab = 1),
        onOpenOnLedger: () {
          final txId = matched.closingTransactionId;
          if (txId != null && txId.isNotEmpty) {
            context.push(
              '/finance/ledger?transactionId=${Uri.encodeComponent(txId)}',
            );
          } else {
            context.push('/finance/ledger');
          }
        },
        onDownloadEvidence: _handleDownloadEvidence,
      );
    }

    if (state.lastSubmittedAudit != null &&
        state.lastSubmittedAudit!.auditYear == state.selectedYear &&
        !state.lastSubmittedAudit!.isMatched) {
      final submitted = state.lastSubmittedAudit!;
      return AnnualAuditDiscrepancyResultCard(
        record: submitted,
        onAuditAgain: () => ref
            .read(ledgerAnnualAuditProvider.notifier)
            .clearLastSubmittedAudit(),
        onViewHistory: () => setState(() => _activeTab = 1),
        onOpenReviewAdjustment: () {
          final reqId = submitted.adjustmentRequestId;
          if (reqId != null && reqId.isNotEmpty) {
            context.push(
              '/finance/ledger/review-adjustments?requestId=${Uri.encodeComponent(reqId)}',
            );
          } else {
            context.push('/finance/ledger/review-adjustments');
          }
        },
      );
    }

    final leftColumn = _buildAuditInputColumn(state);
    final rightColumn = AnnualAuditReconcilePanel(
      selectedYear: state.selectedYear,
      systemBalance: state.systemBalance,
      actualBalance: _actualBalance,
      totalEntries: state.totalLedgerEntries,
      latestTransaction: state.latestTransaction,
      isPreFlightBlocked: state.isPreFlightBlocked,
      isSubmitting: state.isSubmitting,
      isUploadingEvidence: state.isUploadingEvidence,
      submitErrorMessage: state.submitErrorMessage,
      onConfirmPressed: () => _handleConfirmAndSubmit(state),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnualAuditPreFlightBlockerBanner(
          isShaValid: state.isShaValid,
          brokenLinksCount: state.integrityReport?.brokenLinks.length ?? 0,
          pendingAdjustmentCount: state.pendingAdjustmentCount,
          pendingDisbursementCount: state.pendingDisbursementCount,
          onOpenLedger: () => context.push('/finance/ledger'),
          onOpenReviewAdjustments: () =>
              context.push('/finance/ledger/review-adjustments'),
          onOpenReviewDisbursements: () =>
              context.push('/finance/disbursements/review'),
        ),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 13, child: leftColumn),
              const SizedBox(width: 18),
              Expanded(flex: 10, child: rightColumn),
            ],
          )
        else ...[
          leftColumn,
          const SizedBox(height: 16),
          rightColumn,
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAuditInputColumn(LedgerAnnualAuditState state) {
    final diff =
        _actualBalance == null ? null : _actualBalance! - state.systemBalance;
    final showRefSelector = diff != null && diff.abs() >= 0.005;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Primary Counted Balance Input
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6DFD8)),
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
                    '1. Số tiền thực tế đếm được (VNĐ) *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2B1810),
                    ),
                  ),
                  Text(
                    'Tiền mặt két + Số dư tài khoản quỹ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF78655C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('annual_audit_actual_input'),
                controller: _actualController,
                keyboardType: TextInputType.number,
                inputFormatters: const [VietnameseThousandDotFormatter()],
                onChanged: _onActualInputChanged,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B1810),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập tổng số tiền thực kiểm...',
                  hintStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9C8B82),
                  ),
                  suffixText: '₫',
                  suffixStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B1E1E),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAF9F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFDFD8D0), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFDFD8D0), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF8B1E1E), width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Điền nhanh:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF78655C),
                    ),
                  ),
                  ActionChip(
                    key: const Key('annual_audit_fill_matched_chip'),
                    label: Text(
                      '= Sổ cái (${AppFormatters.formatVnd(state.systemBalance)})',
                    ),
                    labelStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B1E1E),
                    ),
                    backgroundColor: const Color(0xFFF5EBE6),
                    side: const BorderSide(color: Color(0xFFEBD5CC)),
                    onPressed: () => _setActualAmount(state.systemBalance),
                  ),
                  if (_actualBalance != null)
                    ActionChip(
                      label: const Text('Xóa'),
                      labelStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF54433E),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFDFD8D0)),
                      onPressed: () => _setActualAmount(null),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Collapsible Quick Cash + Bank Calculator
        AnnualAuditQuickCalculatorAccordion(
          onApplyTotal: (total) {
            _setActualAmount(total);
            _showSnackBar(
              'Đã áp dụng ${AppFormatters.formatVnd(total)} vào Số tiền thực tế đếm được.',
            );
          },
        ),

        // 3. Conditional Reference Transaction Selector when Discrepant
        if (showRefSelector && state.recentTransactions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bút toán gốc đối chiếu cho Đề xuất bù trừ US-15',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Khi có độ lệch, hệ thống mặc định gắn đề xuất bù trừ vào bút toán mới nhất hoặc bút toán bạn chỉ định:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78655C)),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  key: const Key('annual_audit_ref_tx_dropdown'),
                  initialValue: _selectedReferenceTxId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B1810),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'Tự động — Bút toán mới nhất (${state.latestTransaction?.transactionId ?? '—'})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final tx in state.recentTransactions)
                      DropdownMenuItem<String?>(
                        value: tx.transactionId,
                        child: Text(
                          '${tx.transactionId} — ${tx.transactionType.displayName} (${formatSignedLedgerVnd(tx.amount)} • ${tx.formattedSolarDate})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedReferenceTxId = val),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // 4. Notes & Evidence Attachment
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '2. Ghi chú biên bản kiểm kê (Tùy chọn)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B1810),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('annual_audit_notes_input'),
                controller: _notesController,
                maxLines: 3,
                maxLength: 2000,
                style: const TextStyle(fontSize: 13, color: Color(0xFF2B1810)),
                decoration: InputDecoration(
                  hintText:
                      'Ghi rõ nơi kiểm đếm (két sắt từ đường / sao kê ngân hàng) hoặc nguyên nhân chênh lệch nếu có...',
                  filled: true,
                  fillColor: const Color(0xFFFAF9F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                  ),
                ),
              ),
              AdjustmentEvidenceSection(
                mode: _evidenceMode,
                selectedFile: _selectedFile,
                evidenceUrl: _evidenceUrl,
                onModeChanged: (m) => setState(() => _evidenceMode = m),
                onFileChanged: (f) => setState(() => _selectedFile = f),
                onUrlChanged: (u) => setState(() => _evidenceUrl = u),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF8B1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  selected ? const Color(0xFF8B1E1E) : const Color(0xFFE6DFD8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : const Color(0xFF54433E),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF54433E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
