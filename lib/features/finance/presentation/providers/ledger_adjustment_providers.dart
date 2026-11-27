import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../../domain/repositories/ledger_repository.dart';

String formatLedgerFailure(Object error) {
  if (error is Failure) {
    return error.message;
  }
  return error.toString().replaceFirst('Exception: ', '');
}

class LedgerPickerState {
  final bool isLoading;
  final String? errorMessage;
  final List<LedgerHistoryItemModel> items;
  final LedgerFlowSummaryModel? summary;
  final String keyword;
  final LedgerTransactionTypeEnum? selectedType;
  final int page;
  final int totalPages;

  const LedgerPickerState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.summary,
    this.keyword = '',
    this.selectedType,
    this.page = 0,
    this.totalPages = 0,
  });

  double get currentFundBalance => summary?.currentFundBalance ?? 0.0;

  LedgerPickerState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<LedgerHistoryItemModel>? items,
    LedgerFlowSummaryModel? summary,
    String? keyword,
    LedgerTransactionTypeEnum? selectedType,
    bool clearSelectedType = false,
    int? page,
    int? totalPages,
  }) {
    return LedgerPickerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      items: items ?? this.items,
      summary: summary ?? this.summary,
      keyword: keyword ?? this.keyword,
      selectedType:
          clearSelectedType ? null : (selectedType ?? this.selectedType),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class LedgerPickerNotifier extends Notifier<LedgerPickerState> {
  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  @override
  LedgerPickerState build() {
    Future.microtask(() => loadLedger(showLoading: true));
    return const LedgerPickerState(isLoading: true);
  }

  Future<void> loadLedger({bool showLoading = false, int page = 0}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final result = await _repository.searchLedgerHistory(
        keyword: state.keyword,
        transactionType: state.selectedType,
        page: page,
        size: 20,
      );
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        summary: result.summary,
        page: result.page,
        totalPages: result.totalPages,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: formatLedgerFailure(e),
      );
    }
  }

  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword);
    loadLedger(showLoading: true, page: 0);
  }

  void setTypeFilter(LedgerTransactionTypeEnum? type) {
    state = state.copyWith(
      selectedType: type,
      clearSelectedType: type == null,
    );
    loadLedger(showLoading: true, page: 0);
  }

  /// Cập nhật cục bộ trạng thái khóa dòng vừa lập đề xuất để chặn lập trùng ngay lập tức trên UI.
  void markTransactionPending(String transactionId) {
    final updated = state.items.map((item) {
      if (item.transactionId != transactionId) return item;
      return LedgerHistoryItemModel(
        transactionId: item.transactionId,
        clanId: item.clanId,
        eventId: item.eventId,
        eventName: item.eventName,
        adjustmentRequestId: item.adjustmentRequestId,
        adjustmentReason: item.adjustmentReason,
        evidenceAttachmentUrl: item.evidenceAttachmentUrl,
        disbursementRequestId: item.disbursementRequestId,
        disbursementTitle: item.disbursementTitle,
        originalTransactionId: item.originalTransactionId,
        transactionType: item.transactionType,
        amount: item.amount,
        runningBalance: item.runningBalance,
        description: item.description,
        createdByAccountId: item.createdByAccountId,
        createdByName: item.createdByName,
        approvedByAccountId: item.approvedByAccountId,
        approvedByName: item.approvedByName,
        previousHash: item.previousHash,
        recordHash: item.recordHash,
        createdAt: item.createdAt,
        isAdjustment: item.isAdjustment,
        hasAdjustments: item.hasAdjustments,
        adjustmentCount: item.adjustmentCount,
        netAdjustedAmount: item.netAdjustedAmount,
        pendingAdjustmentRequestCount: item.pendingAdjustmentRequestCount + 1,
        originalTransaction: item.originalTransaction,
        adjustmentTransactions: item.adjustmentTransactions,
      );
    }).toList();
    state = state.copyWith(items: updated);
  }
}

final ledgerPickerProvider =
    NotifierProvider<LedgerPickerNotifier, LedgerPickerState>(
  LedgerPickerNotifier.new,
);

class LedgerAdjustmentHistoryState {
  final bool isLoading;
  final String? errorMessage;
  final List<LedgerAdjustmentRequestModel> items;
  final LedgerAdjustmentStatusEnum? statusFilter;

  const LedgerAdjustmentHistoryState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.statusFilter,
  });

  int get pendingCount => items
      .where((item) => item.approvalStatus == LedgerAdjustmentStatusEnum.pending)
      .length;

  List<LedgerAdjustmentRequestModel> get filteredItems {
    if (statusFilter == null) return items;
    return items.where((item) => item.approvalStatus == statusFilter).toList();
  }

  LedgerAdjustmentHistoryState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<LedgerAdjustmentRequestModel>? items,
    LedgerAdjustmentStatusEnum? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return LedgerAdjustmentHistoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      items: items ?? this.items,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class LedgerAdjustmentHistoryNotifier
    extends Notifier<LedgerAdjustmentHistoryState> {
  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  @override
  LedgerAdjustmentHistoryState build() {
    Future.microtask(() => loadHistory(showLoading: true));
    return const LedgerAdjustmentHistoryState(isLoading: true);
  }

  Future<void> loadHistory({bool showLoading = false}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final list = await _repository.searchAdjustmentRequests();
      state = state.copyWith(
        isLoading: false,
        items: list,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: formatLedgerFailure(e),
      );
    }
  }

  void setStatusFilter(LedgerAdjustmentStatusEnum? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
  }

  void prependRequest(LedgerAdjustmentRequestModel created) {
    state = state.copyWith(items: [created, ...state.items]);
  }
}

final ledgerAdjustmentHistoryProvider = NotifierProvider<
    LedgerAdjustmentHistoryNotifier, LedgerAdjustmentHistoryState>(
  LedgerAdjustmentHistoryNotifier.new,
);
