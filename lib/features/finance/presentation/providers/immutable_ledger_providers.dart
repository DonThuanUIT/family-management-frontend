import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/immutable_ledger_integrity_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../../domain/repositories/ledger_repository.dart';

/// Bộ lọc nhanh theo loại bút toán trên Sổ cái Quỹ chung (US-61 / US-62).
enum ImmutableLedgerFilter {
  all('Tất cả'),
  surplusTransfer('Chuyển thặng dư'),
  commonFundDisbursement('Chi quỹ chung'),
  adjustmentTransaction('Bút toán bù trừ'),
  hasAdjustments('Có bù trừ');

  final String label;
  const ImmutableLedgerFilter(this.label);

  LedgerTransactionTypeEnum? get transactionTypeFilter {
    switch (this) {
      case ImmutableLedgerFilter.surplusTransfer:
        return LedgerTransactionTypeEnum.surplusTransfer;
      case ImmutableLedgerFilter.commonFundDisbursement:
        return LedgerTransactionTypeEnum.commonFundDisbursement;
      case ImmutableLedgerFilter.adjustmentTransaction:
        return LedgerTransactionTypeEnum.adjustmentTransaction;
      case ImmutableLedgerFilter.all:
      case ImmutableLedgerFilter.hasAdjustments:
        return null;
    }
  }

  bool? get onlyWithAdjustmentsFilter {
    return this == ImmutableLedgerFilter.hasAdjustments ? true : null;
  }
}

/// Bộ lọc khoảng thời gian đối chiếu Sổ cái Quỹ chung (US-62).
enum ImmutableLedgerPeriod {
  all('Tất cả kỳ'),
  thisMonth('Tháng này'),
  thisQuarter('Quý này'),
  thisYear('Năm nay'),
  custom('Tùy chọn ngày...');

  final String label;
  const ImmutableLedgerPeriod(this.label);

  static String _formatApiDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  ({String? from, String? to}) resolveDateRange({
    DateTime? customFrom,
    DateTime? customTo,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    switch (this) {
      case ImmutableLedgerPeriod.all:
        return (from: null, to: null);
      case ImmutableLedgerPeriod.thisMonth:
        final start = DateTime(ref.year, ref.month, 1);
        final end = DateTime(ref.year, ref.month + 1, 0);
        return (from: _formatApiDate(start), to: _formatApiDate(end));
      case ImmutableLedgerPeriod.thisQuarter:
        final qStartMonth = ((ref.month - 1) ~/ 3) * 3 + 1;
        final start = DateTime(ref.year, qStartMonth, 1);
        final end = DateTime(ref.year, qStartMonth + 3, 0);
        return (from: _formatApiDate(start), to: _formatApiDate(end));
      case ImmutableLedgerPeriod.thisYear:
        final start = DateTime(ref.year, 1, 1);
        final end = DateTime(ref.year, 12, 31);
        return (from: _formatApiDate(start), to: _formatApiDate(end));
      case ImmutableLedgerPeriod.custom:
        if (customFrom == null && customTo == null) {
          return (from: null, to: null);
        }
        return (
          from: customFrom != null ? _formatApiDate(customFrom) : null,
          to: customTo != null ? _formatApiDate(customTo) : null,
        );
    }
  }

  String displayLabel({DateTime? customFrom, DateTime? customTo}) {
    if (this == ImmutableLedgerPeriod.custom &&
        customFrom != null &&
        customTo != null) {
      return '${AppFormatters.formatDate(customFrom)} – ${AppFormatters.formatDate(customTo)}';
    }
    return label;
  }
}

@immutable
class ImmutableLedgerState {
  final List<LedgerHistoryItemModel> items;
  final LedgerFlowSummaryModel summary;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final Map<String, int> blockNumbersByTxId;
  final String keyword;
  final ImmutableLedgerFilter filter;
  final ImmutableLedgerPeriod period;
  final DateTime? customFrom;
  final DateTime? customTo;
  final String sortDirection;
  final String? highlightedTransactionId;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final LedgerIntegrityReportModel? integrityReport;
  final bool isAuditing;
  final String? auditErrorMessage;
  final String? selectedTransactionId;
  final LedgerHistoryItemModel? selectedDetail;
  final bool isLoadingDetail;
  final String? detailErrorMessage;

  const ImmutableLedgerState({
    this.items = const [],
    this.summary = const LedgerFlowSummaryModel(currentFundBalance: 0),
    this.page = 0,
    this.size = 20,
    this.totalElements = 0,
    this.totalPages = 0,
    this.blockNumbersByTxId = const {},
    this.keyword = '',
    this.filter = ImmutableLedgerFilter.all,
    this.period = ImmutableLedgerPeriod.all,
    this.customFrom,
    this.customTo,
    this.sortDirection = 'DESC',
    this.highlightedTransactionId,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.integrityReport,
    this.isAuditing = false,
    this.auditErrorMessage,
    this.selectedTransactionId,
    this.selectedDetail,
    this.isLoadingDetail = false,
    this.detailErrorMessage,
  });

  bool get hasDateFilter =>
      period != ImmutableLedgerPeriod.all &&
      (period != ImmutableLedgerPeriod.custom ||
          customFrom != null ||
          customTo != null);

  int? blockNumberFor(LedgerHistoryItemModel item, int listIndex) {
    final mapped = blockNumbersByTxId[item.transactionId];
    if (mapped != null) return mapped;
    if (filter == ImmutableLedgerFilter.all &&
        keyword.trim().isEmpty &&
        !hasDateFilter) {
      final computed = sortDirection == 'ASC'
          ? (page * size + listIndex + 1)
          : (totalElements - (page * size + listIndex));
      return computed > 0 ? computed : null;
    }
    return null;
  }

  int? blockNumberForId(String transactionId) =>
      blockNumbersByTxId[transactionId];

  LedgerBrokenLinkModel? brokenLinkFor(String transactionId) {
    final report = integrityReport;
    if (report == null || report.valid) return null;
    for (final link in report.brokenLinks) {
      if (link.transactionId == transactionId) return link;
    }
    return null;
  }

  bool isTransactionBroken(String transactionId) =>
      brokenLinkFor(transactionId) != null;

  ImmutableLedgerState copyWith({
    List<LedgerHistoryItemModel>? items,
    LedgerFlowSummaryModel? summary,
    int? page,
    int? size,
    int? totalElements,
    int? totalPages,
    Map<String, int>? blockNumbersByTxId,
    String? keyword,
    ImmutableLedgerFilter? filter,
    ImmutableLedgerPeriod? period,
    DateTime? Function()? customFrom,
    DateTime? Function()? customTo,
    String? sortDirection,
    String? Function()? highlightedTransactionId,
    bool? isLoading,
    bool? isRefreshing,
    String? Function()? errorMessage,
    LedgerIntegrityReportModel? Function()? integrityReport,
    bool? isAuditing,
    String? Function()? auditErrorMessage,
    String? Function()? selectedTransactionId,
    LedgerHistoryItemModel? Function()? selectedDetail,
    bool? isLoadingDetail,
    String? Function()? detailErrorMessage,
  }) {
    return ImmutableLedgerState(
      items: items ?? this.items,
      summary: summary ?? this.summary,
      page: page ?? this.page,
      size: size ?? this.size,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      blockNumbersByTxId: blockNumbersByTxId ?? this.blockNumbersByTxId,
      keyword: keyword ?? this.keyword,
      filter: filter ?? this.filter,
      period: period ?? this.period,
      customFrom: customFrom != null ? customFrom() : this.customFrom,
      customTo: customTo != null ? customTo() : this.customTo,
      sortDirection: sortDirection ?? this.sortDirection,
      highlightedTransactionId: highlightedTransactionId != null
          ? highlightedTransactionId()
          : this.highlightedTransactionId,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      integrityReport:
          integrityReport != null ? integrityReport() : this.integrityReport,
      isAuditing: isAuditing ?? this.isAuditing,
      auditErrorMessage: auditErrorMessage != null
          ? auditErrorMessage()
          : this.auditErrorMessage,
      selectedTransactionId: selectedTransactionId != null
          ? selectedTransactionId()
          : this.selectedTransactionId,
      selectedDetail:
          selectedDetail != null ? selectedDetail() : this.selectedDetail,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      detailErrorMessage: detailErrorMessage != null
          ? detailErrorMessage()
          : this.detailErrorMessage,
    );
  }
}

class ImmutableLedgerNotifier extends Notifier<ImmutableLedgerState> {
  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  @override
  ImmutableLedgerState build() {
    return const ImmutableLedgerState();
  }

  Future<void> loadInitial({String? initialTransactionId}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: () => null,
    );

    LedgerHistoryPageModel? pageData;
    String? historyError;
    LedgerIntegrityReportModel? report;
    String? auditError;

    final range = state.period.resolveDateRange(
      customFrom: state.customFrom,
      customTo: state.customTo,
    );

    Future<void> fetchHistory() async {
      try {
        pageData = await _repository.searchLedgerHistory(
          keyword: state.keyword,
          transactionType: state.filter.transactionTypeFilter,
          onlyWithAdjustments: state.filter.onlyWithAdjustmentsFilter,
          sortDirection: state.sortDirection,
          from: range.from,
          to: range.to,
          page: 0,
          size: state.size,
        );
      } catch (e) {
        historyError = e.toString();
      }
    }

    Future<void> fetchIntegrity() async {
      try {
        report = await _repository.verifyLedgerIntegrity();
      } catch (e) {
        auditError = e.toString();
      }
    }

    await Future.wait([
      fetchHistory(),
      fetchIntegrity(),
    ]);

    if (!ref.mounted) return;

    if (pageData == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => historyError ?? 'Không thể tải Sổ cái Quỹ chung.',
        integrityReport: () => report ?? state.integrityReport,
        auditErrorMessage: () => auditError,
      );
      return;
    }

    final updatedBlocks = _mergeBlockNumbers(
      existing: state.blockNumbersByTxId,
      pageResult: pageData!,
      sortDirection: state.sortDirection,
      isUnfiltered: state.filter == ImmutableLedgerFilter.all &&
          state.keyword.trim().isEmpty &&
          !state.hasDateFilter,
    );

    state = state.copyWith(
      isLoading: false,
      items: pageData!.items,
      summary: pageData!.summary,
      page: pageData!.page,
      size: pageData!.size,
      totalElements: pageData!.totalElements,
      totalPages: pageData!.totalPages,
      blockNumbersByTxId: updatedBlocks,
      errorMessage: () => null,
      integrityReport: () => report ?? state.integrityReport,
      auditErrorMessage: () => auditError,
    );

    if (initialTransactionId != null &&
        initialTransactionId.trim().isNotEmpty) {
      await selectTransactionById(initialTransactionId.trim());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, errorMessage: () => null);
    await _fetchPage(targetPage: state.page, isRefresh: true);
  }

  Future<void> setFilter(ImmutableLedgerFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(
      filter: filter,
      isLoading: true,
      errorMessage: () => null,
    );
    await _fetchPage(targetPage: 0);
  }

  Future<void> setPeriod(
    ImmutableLedgerPeriod period, {
    DateTime? customFrom,
    DateTime? customTo,
  }) async {
    state = state.copyWith(
      period: period,
      customFrom: () =>
          period == ImmutableLedgerPeriod.custom ? customFrom : null,
      customTo: () => period == ImmutableLedgerPeriod.custom ? customTo : null,
      isLoading: true,
      errorMessage: () => null,
    );
    await _fetchPage(targetPage: 0);
  }

  Future<void> toggleSortDirection() async {
    final nextSort = state.sortDirection == 'DESC' ? 'ASC' : 'DESC';
    state = state.copyWith(
      sortDirection: nextSort,
      isLoading: true,
      errorMessage: () => null,
    );
    await _fetchPage(targetPage: 0);
  }

  Future<void> setKeyword(String keyword) async {
    final normalized = keyword.trim();
    if (state.keyword == normalized && state.items.isNotEmpty) return;
    state = state.copyWith(
      keyword: normalized,
      isLoading: true,
      errorMessage: () => null,
    );
    await _fetchPage(targetPage: 0);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      keyword: '',
      filter: ImmutableLedgerFilter.all,
      period: ImmutableLedgerPeriod.all,
      customFrom: () => null,
      customTo: () => null,
      isLoading: true,
      errorMessage: () => null,
    );
    await _fetchPage(targetPage: 0);
  }

  Future<void> goToPage(int targetPage) async {
    if (targetPage < 0) return;
    if (state.totalPages > 0 && targetPage >= state.totalPages) return;
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    await _fetchPage(targetPage: targetPage);
  }

  void setHighlightedTransaction(String? txId) {
    state = state.copyWith(highlightedTransactionId: () => txId);
  }

  Future<void> _fetchPage({
    required int targetPage,
    bool isRefresh = false,
  }) async {
    final range = state.period.resolveDateRange(
      customFrom: state.customFrom,
      customTo: state.customTo,
    );

    try {
      final result = await _repository.searchLedgerHistory(
        keyword: state.keyword,
        transactionType: state.filter.transactionTypeFilter,
        onlyWithAdjustments: state.filter.onlyWithAdjustmentsFilter,
        sortDirection: state.sortDirection,
        from: range.from,
        to: range.to,
        page: targetPage,
        size: state.size,
      );
      if (!ref.mounted) return;

      final isUnfiltered = state.filter == ImmutableLedgerFilter.all &&
          state.keyword.trim().isEmpty &&
          !state.hasDateFilter;
      final updatedBlocks = _mergeBlockNumbers(
        existing: state.blockNumbersByTxId,
        pageResult: result,
        sortDirection: state.sortDirection,
        isUnfiltered: isUnfiltered,
      );

      state = state.copyWith(
        isLoading: false,
        isRefreshing: isRefresh ? false : state.isRefreshing,
        items: result.items,
        summary: result.summary,
        page: result.page,
        size: result.size,
        totalElements: result.totalElements,
        totalPages: result.totalPages,
        blockNumbersByTxId: updatedBlocks,
        errorMessage: () => null,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<LedgerIntegrityReportModel?> runIntegrityAudit() async {
    if (state.isAuditing) return state.integrityReport;
    state = state.copyWith(
      isAuditing: true,
      auditErrorMessage: () => null,
    );
    try {
      final report = await _repository.verifyLedgerIntegrity();
      if (!ref.mounted) return report;
      state = state.copyWith(
        isAuditing: false,
        integrityReport: () => report,
        auditErrorMessage: () => null,
      );
      return report;
    } catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isAuditing: false,
        auditErrorMessage: () => e.toString(),
      );
      return null;
    }
  }

  Future<void> selectTransaction(LedgerHistoryItemModel item) async {
    state = state.copyWith(
      selectedTransactionId: () => item.transactionId,
      selectedDetail: () => item,
      isLoadingDetail: true,
      detailErrorMessage: () => null,
    );
    await _loadDetail(item.transactionId);
  }

  Future<void> selectTransactionById(String transactionId) async {
    final trimmed = transactionId.trim();
    if (trimmed.isEmpty) return;

    LedgerHistoryItemModel? cached;
    for (final item in state.items) {
      if (item.transactionId == trimmed) {
        cached = item;
        break;
      }
    }

    state = state.copyWith(
      selectedTransactionId: () => trimmed,
      selectedDetail: () => cached,
      isLoadingDetail: true,
      detailErrorMessage: () => null,
    );
    await _loadDetail(trimmed);
  }

  Future<void> _loadDetail(String transactionId) async {
    try {
      final detail = await _repository.getTransactionDetail(transactionId);
      if (!ref.mounted || state.selectedTransactionId != transactionId) return;
      state = state.copyWith(
        selectedDetail: () => detail,
        isLoadingDetail: false,
        detailErrorMessage: () => null,
      );
    } catch (e) {
      if (!ref.mounted || state.selectedTransactionId != transactionId) return;
      state = state.copyWith(
        isLoadingDetail: false,
        detailErrorMessage: () => e.toString(),
      );
    }
  }

  void clearSelection() {
    state = state.copyWith(
      selectedTransactionId: () => null,
      selectedDetail: () => null,
      isLoadingDetail: false,
      detailErrorMessage: () => null,
    );
  }

  Map<String, int> _mergeBlockNumbers({
    required Map<String, int> existing,
    required LedgerHistoryPageModel pageResult,
    required String sortDirection,
    required bool isUnfiltered,
  }) {
    if (!isUnfiltered) return existing;
    final next = Map<String, int>.from(existing);
    for (var i = 0; i < pageResult.items.length; i++) {
      final blockNum = sortDirection == 'ASC'
          ? (pageResult.page * pageResult.size + i + 1)
          : (pageResult.totalElements -
              (pageResult.page * pageResult.size + i));
      if (blockNum > 0) {
        next[pageResult.items[i].transactionId] = blockNum;
      }
    }
    return next;
  }
}

final immutableLedgerProvider = NotifierProvider.autoDispose<
    ImmutableLedgerNotifier, ImmutableLedgerState>(
  ImmutableLedgerNotifier.new,
);
