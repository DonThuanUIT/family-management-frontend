import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../data/models/immutable_ledger_integrity_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../providers/immutable_ledger_providers.dart';
import '../widgets/immutable_ledger_detail_panel.dart';
import '../widgets/immutable_ledger_widgets.dart';

/// Màn hình Sổ Cái Quỹ Chung Bất Biến (`SoLedgerUI`, US-61 / US-62):
/// - Bảng lịch sử dòng tiền kèm cột `Biến động` & `Số dư lũy kế` tức thời.
/// - Tag liên kết nhảy nhanh giữa bút toán gốc ↔ bút toán bù trừ (tự cuộn + highlight).
/// - Lọc khoảng ngày (`from`/`to`), đảo chiều sắp xếp (`DESC`/`ASC`), lịch Dương + Âm lịch.
/// - Tuyệt đối không có nút Sửa / Xóa ở mọi vai trò; kiểm toán trực tiếp SHA-256.
class ImmutableLedgerScreen extends ConsumerStatefulWidget {
  final String? initialTransactionId;

  const ImmutableLedgerScreen({
    super.key,
    this.initialTransactionId,
  });

  @override
  ConsumerState<ImmutableLedgerScreen> createState() =>
      _ImmutableLedgerScreenState();
}

class _ImmutableLedgerScreenState extends ConsumerState<ImmutableLedgerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, GlobalKey> _rowKeys = {};
  Timer? _searchDebounce;
  Timer? _highlightTimer;
  bool _mobileSheetOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(immutableLedgerProvider.notifier)
          .loadInitial(initialTransactionId: widget.initialTransactionId);
      if (!mounted) return;
      final isDesktop = MediaQuery.of(context).size.width >= 860;
      if (!isDesktop &&
          widget.initialTransactionId != null &&
          widget.initialTransactionId!.trim().isNotEmpty) {
        _openMobileDetailSheet();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _highlightTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  GlobalKey _rowKeyFor(String txId) =>
      _rowKeys.putIfAbsent(txId, () => GlobalKey());

  void _onSearchChanged(String raw) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(immutableLedgerProvider.notifier).setKeyword(raw);
    });
    setState(() {});
  }

  Future<void> _onPeriodSelected(ImmutableLedgerPeriod? chosen) async {
    if (chosen == null) return;
    final notifier = ref.read(immutableLedgerProvider.notifier);
    if (chosen == ImmutableLedgerPeriod.custom) {
      final current = ref.read(immutableLedgerProvider);
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialDateRange: current.customFrom != null && current.customTo != null
            ? DateTimeRange(start: current.customFrom!, end: current.customTo!)
            : null,
        helpText: 'Chọn khoảng thời gian đối chiếu Sổ cái',
        saveText: 'Áp dụng',
      );
      if (!mounted || picked == null) return;
      await notifier.setPeriod(
        ImmutableLedgerPeriod.custom,
        customFrom: picked.start,
        customTo: picked.end,
      );
      return;
    }
    await notifier.setPeriod(chosen);
  }

  Future<void> _copyHash(String hash) async {
    await Clipboard.setData(ClipboardData(text: hash));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép SHA-256: ${shortLedgerHashCompact(hash)}'),
        backgroundColor: const Color(0xFF2B1810),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleRunAudit() async {
    final notifier = ref.read(immutableLedgerProvider.notifier);
    final report = await notifier.runIntegrityAudit();
    if (!mounted) return;
    final state = ref.read(immutableLedgerProvider);

    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.auditErrorMessage ??
                'Không thể kiểm toán chuỗi SHA-256 lúc này.',
          ),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          report.valid
              ? 'Kiểm toán thành công: ${report.verifiedEntries}/${report.totalEntries} khối khớp chuỗi SHA-256.'
              : 'Cảnh báo: Phát hiện ${report.brokenLinks.length} sai lệch chuỗi SHA-256!',
        ),
        backgroundColor:
            report.valid ? const Color(0xFF0F766E) : const Color(0xFFBA1A1A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSelectItem(LedgerHistoryItemModel item, bool isDesktop) {
    ref.read(immutableLedgerProvider.notifier).selectTransaction(item);
    if (!isDesktop && !_mobileSheetOpen) {
      _openMobileDetailSheet();
    }
  }

  void _handleInspectTxId(String txId, bool isDesktop) {
    ref.read(immutableLedgerProvider.notifier).selectTransactionById(txId);
    if (!isDesktop && !_mobileSheetOpen) {
      _openMobileDetailSheet();
    }
  }

  Future<void> _handleQuickJump(String targetTxId, bool isDesktop) async {
    final targetKey = _rowKeys[targetTxId];
    final targetContext = targetKey?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      ref
          .read(immutableLedgerProvider.notifier)
          .setHighlightedTransaction(targetTxId);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 2100), () {
        if (mounted) {
          ref
              .read(immutableLedgerProvider.notifier)
              .setHighlightedTransaction(null);
        }
      });

      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.45,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Đã nhảy tới bút toán $targetTxId'),
            backgroundColor: const Color(0xFF2B1810),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }

    _handleInspectTxId(targetTxId, isDesktop);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Bút toán $targetTxId nằm ngoài bộ lọc hiện tại — đã mở thẳng chi tiết.',
          ),
          backgroundColor: const Color(0xFF2B1810),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _handleProposeAdjustment(String transactionId, {bool fromSheet = false}) {
    final encoded = Uri.encodeComponent(transactionId);
    if (fromSheet && _mobileSheetOpen) {
      Navigator.of(context).pop();
    }
    context.push('/finance/ledger/propose-adjustment?transactionId=$encoded');
  }

  void _openMobileDetailSheet() {
    _mobileSheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final ledgerState = sheetRef.watch(immutableLedgerProvider);
            final session = sheetRef.watch(dualRbacSessionProvider);
            final detail = ledgerState.selectedDetail;
            final txId = detail?.transactionId ??
                ledgerState.selectedTransactionId ??
                '';
            final canPropose = detail != null &&
                session.canProposeLedgerAdjustment(eventId: detail.eventId);

            return FractionallySizedBox(
              heightFactor: 0.88,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Material(
                  color: Colors.white,
                  child: ImmutableLedgerDetailPanel(
                    item: detail,
                    blockNumber: txId.isNotEmpty
                        ? ledgerState.blockNumberForId(txId)
                        : null,
                    isLoading: ledgerState.isLoadingDetail,
                    errorMessage: ledgerState.detailErrorMessage,
                    brokenLink: txId.isNotEmpty
                        ? ledgerState.brokenLinkFor(txId)
                        : null,
                    blockNumbersByTxId: ledgerState.blockNumbersByTxId,
                    canProposeAdjustment: canPropose,
                    isBottomSheet: true,
                    onClose: () => Navigator.of(sheetCtx).pop(),
                    onCopyHash: _copyHash,
                    onJumpToTransaction: (targetId) => sheetRef
                        .read(immutableLedgerProvider.notifier)
                        .selectTransactionById(targetId),
                    onProposeAdjustment: (id) =>
                        _handleProposeAdjustment(id, fromSheet: true),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _mobileSheetOpen = false;
      if (mounted) {
        ref.read(immutableLedgerProvider.notifier).clearSelection();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(immutableLedgerProvider);
    final session = ref.watch(dualRbacSessionProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 860;
    final canProposeBanner = session.canAccessLedgerAdjustmentProposal;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: isDesktop
          ? const HeritageNavBar(currentRoute: '/contributions')
          : _buildMobileAppBar(state),
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF8B1E1E),
            onRefresh: () =>
                ref.read(immutableLedgerProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 12,
                vertical: isDesktop ? 20 : 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isDesktop) ...[
                        ImmutableLedgerHeritageBanner(
                          report: state.integrityReport,
                          totalElements: state.totalElements,
                          isAuditing: state.isAuditing,
                          onRunAudit: _handleRunAudit,
                          canProposeAdjustment: canProposeBanner,
                          onProposeAdjustment: () =>
                              context.push('/finance/ledger/propose-adjustment'),
                          onOpenAnnualAudit: () =>
                              context.push('/finance/ledger/annual-audit'),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('/finance/ledger/annual-audit'),
                            icon: const Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 16,
                            ),
                            label: const Text('Kiểm kê hằng năm'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F766E),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF0F766E)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (state.integrityReport != null &&
                          !state.integrityReport!.valid) ...[
                        ImmutableLedgerBrokenAlertBanner(
                          report: state.integrityReport!,
                          onInspectBroken: (txId) =>
                              _handleInspectTxId(txId, isDesktop),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ImmutableLedgerKpiSection(
                        summary: state.summary,
                        totalElements: state.totalElements,
                        isDesktop: isDesktop,
                      ),
                      if (state.hasDateFilter) ...[
                        const SizedBox(height: 12),
                        ImmutableLedgerPeriodReconciliationStrip(
                          periodLabel: state.period.displayLabel(
                            customFrom: state.customFrom,
                            customTo: state.customTo,
                          ),
                          summary: state.summary,
                        ),
                      ],
                      SizedBox(height: isDesktop ? 16 : 12),
                      if (isDesktop)
                        _buildDesktopLedgerCard(state)
                      else
                        _buildMobileLedgerSection(state),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Slide-over inspection drawer on Desktop
          if (isDesktop && state.selectedTransactionId != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () =>
                    ref.read(immutableLedgerProvider.notifier).clearSelection(),
                child: Container(
                  color: const Color(0x592B1810),
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 456,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.92,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(color: Color(0xFFE6DFD8)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x2E2B1810),
                            blurRadius: 28,
                            offset: Offset(-8, 0),
                          ),
                        ],
                      ),
                      child: ImmutableLedgerDetailPanel(
                        item: state.selectedDetail,
                        blockNumber: state.selectedTransactionId != null
                            ? state.blockNumberForId(
                                state.selectedTransactionId!,
                              )
                            : null,
                        isLoading: state.isLoadingDetail,
                        errorMessage: state.detailErrorMessage,
                        brokenLink: state.selectedTransactionId != null
                            ? state.brokenLinkFor(state.selectedTransactionId!)
                            : null,
                        blockNumbersByTxId: state.blockNumbersByTxId,
                        canProposeAdjustment: state.selectedDetail != null &&
                            session.canProposeLedgerAdjustment(
                              eventId: state.selectedDetail!.eventId,
                            ),
                        isBottomSheet: false,
                        onClose: () => ref
                            .read(immutableLedgerProvider.notifier)
                            .clearSelection(),
                        onCopyHash: _copyHash,
                        onJumpToTransaction: (txId) => ref
                            .read(immutableLedgerProvider.notifier)
                            .selectTransactionById(txId),
                        onProposeAdjustment: _handleProposeAdjustment,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(ImmutableLedgerState state) {
    final isBroken =
        state.integrityReport != null && !state.integrityReport!.valid;
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2B1810),
      elevation: 0,
      surfaceTintColor: Colors.white,
      shape: const Border(
        bottom: BorderSide(color: Color(0xFFE6DFD8)),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sổ Cái Quỹ Chung',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B1810),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color:
                  isBroken ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isBroken
                    ? const Color(0xFFFECACA)
                    : const Color(0xFF99F6E4),
              ),
            ),
            child: Text(
              isBroken ? 'Cảnh báo SHA-256' : 'Bất biến • SHA-256',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isBroken
                    ? const Color(0xFFBA1A1A)
                    : const Color(0xFF0F766E),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: TextButton.icon(
            onPressed: state.isAuditing ? null : _handleRunAudit,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E1E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: state.isAuditing
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.fact_check_outlined, size: 14),
            label: Text(state.isAuditing ? 'Đang kiểm...' : 'Kiểm toán'),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLedgerCard(ImmutableLedgerState state) {
    final verifiedCount =
        state.integrityReport?.verifiedEntries ?? state.totalElements;
    final totalCount =
        state.integrityReport?.totalEntries ?? state.totalElements;
    final isBroken =
        state.integrityReport != null && !state.integrityReport!.valid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2B1810),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Integrated 2-Row Card Toolbar (Title + Period + Sort + Search + Type Chips)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Lịch sử dòng tiền niêm phong',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EDEB),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${state.totalElements} bút toán',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF54433E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildPeriodDropdown(state),
                        _buildSortToggleButton(state),
                        SizedBox(
                          width: 245,
                          child: _buildSearchField(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFilterChipsWrap(state),
              ],
            ),
          ),

          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF8B1E1E)),
              ),
            )
          else if (state.errorMessage != null)
            _buildErrorBox(state.errorMessage!)
          else if (state.items.isEmpty)
            _buildEmptyBox(state)
          else
            ImmutableLedgerDesktopTable(
              items: state.items,
              blockNumbersByTxId: state.blockNumbersByTxId,
              resolveBlockNumber: state.blockNumberFor,
              isTransactionBroken: state.isTransactionBroken,
              selectedTransactionId: state.selectedTransactionId,
              highlightedTransactionId: state.highlightedTransactionId,
              sortDirection: state.sortDirection,
              rowKeyBuilder: _rowKeyFor,
              onSelectItem: (item) => _handleSelectItem(item, true),
              onQuickJump: (txId) => _handleQuickJump(txId, true),
              onCopyHash: _copyHash,
            ),

          if (state.totalPages > 1) _buildPaginationBar(state),

          // Calm Immutable Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF9F6),
              border: Border(top: BorderSide(color: Color(0xFFE6DFD8))),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Color(0xFF0F766E),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Bấm vào từng dòng để xem chứng thực SHA-256 64 ký tự • Tuyệt đối không có Sửa/Xóa.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                      ),
                    ),
                  ],
                ),
                Text(
                  isBroken
                      ? 'Cảnh báo • ${state.integrityReport!.brokenLinks.length} sai lệch SHA-256'
                      : 'Toàn vẹn • $verifiedCount/$totalCount khối SHA-256',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isBroken
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFF78655C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLedgerSection(ImmutableLedgerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _buildPeriodDropdown(state, compact: true)),
            const SizedBox(width: 8),
            _buildSortToggleButton(state, compact: true),
          ],
        ),
        const SizedBox(height: 8),
        _buildSearchField(),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ImmutableLedgerFilter.values
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildSingleFilterChip(f, state.filter == f),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B1E1E)),
            ),
          )
        else if (state.errorMessage != null)
          _buildErrorBox(state.errorMessage!)
        else if (state.items.isEmpty)
          _buildEmptyBox(state)
        else ...[
          for (var i = 0; i < state.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            ImmutableLedgerMobileCard(
              key: _rowKeyFor(state.items[i].transactionId),
              item: state.items[i],
              blockNumber: state.blockNumberFor(state.items[i], i),
              blockNumbersByTxId: state.blockNumbersByTxId,
              sortDirection: state.sortDirection,
              isBroken: state.isTransactionBroken(state.items[i].transactionId),
              isHighlighted:
                  state.highlightedTransactionId == state.items[i].transactionId,
              onTap: () => _handleSelectItem(state.items[i], false),
              onQuickJump: (txId) => _handleQuickJump(txId, false),
              onCopyHash: () => _copyHash(state.items[i].recordHash),
            ),
          ],
          if (state.totalPages > 1) ...[
            const SizedBox(height: 12),
            _buildPaginationBar(state),
          ],
        ],
      ],
    );
  }

  Widget _buildPeriodDropdown(
    ImmutableLedgerState state, {
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: state.hasDateFilter
              ? const Color(0xFF8B1E1E)
              : const Color(0xFFE6DFD8),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ImmutableLedgerPeriod>(
          value: state.period,
          isDense: true,
          isExpanded: compact,
          icon: const Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: Color(0xFF54433E),
          ),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B1810),
          ),
          items: ImmutableLedgerPeriod.values
              .map(
                (p) => DropdownMenuItem<ImmutableLedgerPeriod>(
                  value: p,
                  child: Text(
                    p == state.period
                        ? p.displayLabel(
                            customFrom: state.customFrom,
                            customTo: state.customTo,
                          )
                        : p.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _onPeriodSelected,
        ),
      ),
    );
  }

  Widget _buildSortToggleButton(
    ImmutableLedgerState state, {
    bool compact = false,
  }) {
    final isDesc = state.sortDirection == 'DESC';
    return OutlinedButton(
      onPressed: () =>
          ref.read(immutableLedgerProvider.notifier).toggleSortDirection(),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF54433E),
        backgroundColor: const Color(0xFFFAF9F6),
        side: const BorderSide(color: Color(0xFFE6DFD8)),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 9 : 11,
        ),
        minimumSize: const Size(0, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      child: Text(isDesc ? 'Mới nhất ↓' : 'Cũ nhất ↑'),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      onSubmitted: (val) {
        _searchDebounce?.cancel();
        ref.read(immutableLedgerProvider.notifier).setKeyword(val);
      },
      style: const TextStyle(fontSize: 13, color: Color(0xFF2B1810)),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFFAF9F6),
        hintText: 'Tìm mã GD, nội dung, SHA-256...',
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF78655C)),
        prefixIcon: const Icon(
          Icons.search,
          size: 18,
          color: Color(0xFF78655C),
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _searchDebounce?.cancel();
                  ref.read(immutableLedgerProvider.notifier).setKeyword('');
                  setState(() {});
                },
                icon: const Icon(Icons.close, size: 16),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE6DFD8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFF8B1E1E)),
        ),
      ),
    );
  }

  Widget _buildFilterChipsWrap(ImmutableLedgerState state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ImmutableLedgerFilter.values
          .map((f) => _buildSingleFilterChip(f, state.filter == f))
          .toList(),
    );
  }

  Widget _buildSingleFilterChip(ImmutableLedgerFilter filter, bool isSelected) {
    return FilterChip(
      label: Text(filter.label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) =>
          ref.read(immutableLedgerProvider.notifier).setFilter(filter),
      selectedColor: const Color(0xFF8B1E1E),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF8B1E1E) : const Color(0xFFE6DFD8),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF54433E),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  Widget _buildPaginationBar(ImmutableLedgerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0EDEB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trang ${state.page + 1} / ${state.totalPages}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF54433E),
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: state.page > 0
                    ? () => ref
                        .read(immutableLedgerProvider.notifier)
                        .goToPage(state.page - 1)
                    : null,
                child: const Text('Trước'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: state.page + 1 < state.totalPages
                    ? () => ref
                        .read(immutableLedgerProvider.notifier)
                        .goToPage(state.page + 1)
                    : null,
                child: const Text('Sau'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 36,
            color: Color(0xFFBA1A1A),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF54433E)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () =>
                ref.read(immutableLedgerProvider.notifier).refresh(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E1E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(ImmutableLedgerState state) {
    final hasFilter = state.filter != ImmutableLedgerFilter.all ||
        state.keyword.trim().isNotEmpty ||
        state.hasDateFilter;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      child: Column(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 36,
            color: Color(0xFF0F766E),
          ),
          const SizedBox(height: 10),
          Text(
            hasFilter
                ? 'Không tìm thấy bút toán phù hợp bộ lọc'
                : 'Sổ cái Quỹ chung chưa có giao dịch nào',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B1810),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                _searchDebounce?.cancel();
                ref.read(immutableLedgerProvider.notifier).clearFilters();
                setState(() {});
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B1E1E),
                side: const BorderSide(color: Color(0xFFE6DFD8)),
              ),
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ],
      ),
    );
  }
}
