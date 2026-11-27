import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../../domain/repositories/ledger_repository.dart';
import 'ledger_adjustment_providers.dart';

/// Bộ lọc trạng thái hàng chờ thẩm định đề xuất bù trừ Sổ cái (US-59).
enum LedgerReviewStatusFilter {
  pending('Chờ duyệt'),
  approved('Đã duyệt'),
  rejected('Từ chối'),
  all('Tất cả');

  final String shortLabel;
  const LedgerReviewStatusFilter(this.shortLabel);

  LedgerAdjustmentStatusEnum? get matchingStatus {
    switch (this) {
      case LedgerReviewStatusFilter.pending:
        return LedgerAdjustmentStatusEnum.pending;
      case LedgerReviewStatusFilter.approved:
        return LedgerAdjustmentStatusEnum.approved;
      case LedgerReviewStatusFilter.rejected:
        return LedgerAdjustmentStatusEnum.rejected;
      case LedgerReviewStatusFilter.all:
        return null;
    }
  }

  static LedgerReviewStatusFilter fromStatus(
    LedgerAdjustmentStatusEnum status,
  ) {
    switch (status) {
      case LedgerAdjustmentStatusEnum.pending:
        return LedgerReviewStatusFilter.pending;
      case LedgerAdjustmentStatusEnum.approved:
        return LedgerReviewStatusFilter.approved;
      case LedgerAdjustmentStatusEnum.rejected:
        return LedgerReviewStatusFilter.rejected;
    }
  }
}

@immutable
class LedgerReviewQueueState {
  final bool isLoading;
  final bool isLoadingDetail;
  final bool isSubmittingReview;
  final String? errorMessage;
  final String? detailErrorMessage;
  final double currentFundBalance;
  final List<LedgerAdjustmentRequestModel> items;
  final LedgerReviewStatusFilter statusFilter;
  final String keyword;
  final String? selectedRequestId;
  final Map<String, LedgerHistoryItemModel> originalTransactionsById;
  final Map<String, ImmutableLedgerEntryModel> sealedEntriesByRequestId;

  const LedgerReviewQueueState({
    this.isLoading = false,
    this.isLoadingDetail = false,
    this.isSubmittingReview = false,
    this.errorMessage,
    this.detailErrorMessage,
    this.currentFundBalance = 0,
    this.items = const [],
    this.statusFilter = LedgerReviewStatusFilter.pending,
    this.keyword = '',
    this.selectedRequestId,
    this.originalTransactionsById = const {},
    this.sealedEntriesByRequestId = const {},
  });

  int get pendingCount => items
      .where((e) => e.approvalStatus == LedgerAdjustmentStatusEnum.pending)
      .length;

  int get approvedCount => items
      .where((e) => e.approvalStatus == LedgerAdjustmentStatusEnum.approved)
      .length;

  int get rejectedCount => items
      .where((e) => e.approvalStatus == LedgerAdjustmentStatusEnum.rejected)
      .length;

  int get totalCount => items.length;

  int countForFilter(LedgerReviewStatusFilter filter) {
    switch (filter) {
      case LedgerReviewStatusFilter.pending:
        return pendingCount;
      case LedgerReviewStatusFilter.approved:
        return approvedCount;
      case LedgerReviewStatusFilter.rejected:
        return rejectedCount;
      case LedgerReviewStatusFilter.all:
        return totalCount;
    }
  }

  List<LedgerAdjustmentRequestModel> get filteredItems {
    final targetStatus = statusFilter.matchingStatus;
    final q = keyword.trim().toLowerCase();
    return items.where((item) {
      if (targetStatus != null && item.approvalStatus != targetStatus) {
        return false;
      }
      if (q.isEmpty) return true;
      return item.requestId.toLowerCase().contains(q) ||
          item.originalTransactionId.toLowerCase().contains(q) ||
          item.adjustmentReason.toLowerCase().contains(q) ||
          item.proposedByAccountId.toLowerCase().contains(q);
    }).toList();
  }

  /// Tra cứu trong toàn bộ `items` thay vì `filteredItems` để ngay sau khi
  /// Trưởng tộc Phê duyệt / Từ chối ở tab "Chờ duyệt", màn hình vẫn hiển thị
  /// thẻ kết quả SHA-256 hoặc thẻ Lý do từ chối vừa xử lý.
  LedgerAdjustmentRequestModel? get selectedRequest {
    final id = selectedRequestId;
    if (id == null) return null;
    for (final item in items) {
      if (item.requestId == id) return item;
    }
    return null;
  }

  LedgerHistoryItemModel? get selectedOriginalTransaction {
    final req = selectedRequest;
    if (req == null) return null;
    return originalTransactionsById[req.originalTransactionId];
  }

  ImmutableLedgerEntryModel? get selectedSealedEntry {
    final req = selectedRequest;
    if (req == null) return null;
    return sealedEntriesByRequestId[req.requestId];
  }

  LedgerReviewQueueState copyWith({
    bool? isLoading,
    bool? isLoadingDetail,
    bool? isSubmittingReview,
    String? errorMessage,
    bool clearError = false,
    String? detailErrorMessage,
    bool clearDetailError = false,
    double? currentFundBalance,
    List<LedgerAdjustmentRequestModel>? items,
    LedgerReviewStatusFilter? statusFilter,
    String? keyword,
    String? selectedRequestId,
    bool clearSelectedRequestId = false,
    Map<String, LedgerHistoryItemModel>? originalTransactionsById,
    Map<String, ImmutableLedgerEntryModel>? sealedEntriesByRequestId,
  }) {
    return LedgerReviewQueueState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isSubmittingReview: isSubmittingReview ?? this.isSubmittingReview,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      detailErrorMessage: clearDetailError
          ? null
          : (detailErrorMessage ?? this.detailErrorMessage),
      currentFundBalance: currentFundBalance ?? this.currentFundBalance,
      items: items ?? this.items,
      statusFilter: statusFilter ?? this.statusFilter,
      keyword: keyword ?? this.keyword,
      selectedRequestId: clearSelectedRequestId
          ? null
          : (selectedRequestId ?? this.selectedRequestId),
      originalTransactionsById:
          originalTransactionsById ?? this.originalTransactionsById,
      sealedEntriesByRequestId:
          sealedEntriesByRequestId ?? this.sealedEntriesByRequestId,
    );
  }
}

class LedgerReviewQueueNotifier extends Notifier<LedgerReviewQueueState> {
  LedgerRepository get _repository => ref.read(ledgerRepositoryProvider);

  @override
  LedgerReviewQueueState build() {
    return const LedgerReviewQueueState(isLoading: true);
  }

  Future<void> loadQueue({
    bool showLoading = true,
    String? preferredRequestId,
  }) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final results = await Future.wait<Object>([
        _repository.searchAdjustmentRequests(),
        _repository.searchLedgerHistory(page: 0, size: 1),
      ]);

      final fetchedItems = List<LedgerAdjustmentRequestModel>.from(
        results[0] as List<LedgerAdjustmentRequestModel>,
      );
      final ledgerPage = results[1] as LedgerHistoryPageModel;

      var nextFilter = state.statusFilter;
      String? nextSelectedId;
      final preferred = preferredRequestId?.trim();

      if (preferred != null && preferred.isNotEmpty) {
        LedgerAdjustmentRequestModel? matched;
        for (final item in fetchedItems) {
          if (item.requestId == preferred) {
            matched = item;
            break;
          }
        }
        if (matched == null) {
          try {
            matched = await _repository.getAdjustmentRequestById(preferred);
            fetchedItems.insert(0, matched);
          } catch (_) {
            // Bỏ qua nếu không tìm thấy preferredRequestId cụ thể
          }
        }
        if (matched != null) {
          nextFilter =
              LedgerReviewStatusFilter.fromStatus(matched.approvalStatus);
          nextSelectedId = matched.requestId;
        }
      }

      if (nextSelectedId == null) {
        final currentSelected = state.selectedRequestId;
        if (currentSelected != null &&
            fetchedItems.any((e) => e.requestId == currentSelected)) {
          nextSelectedId = currentSelected;
        } else {
          final targetStatus = nextFilter.matchingStatus;
          final matchingCurrentFilter = fetchedItems.where(
            (e) => targetStatus == null || e.approvalStatus == targetStatus,
          );
          if (matchingCurrentFilter.isNotEmpty) {
            nextSelectedId = matchingCurrentFilter.first.requestId;
          } else if (fetchedItems.isNotEmpty) {
            nextFilter = LedgerReviewStatusFilter.all;
            nextSelectedId = fetchedItems.first.requestId;
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        items: fetchedItems,
        currentFundBalance: ledgerPage.summary.currentFundBalance,
        statusFilter: nextFilter,
        selectedRequestId: nextSelectedId,
        clearSelectedRequestId: nextSelectedId == null,
        clearError: true,
      );

      await _loadContextForSelected();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: formatLedgerFailure(e),
      );
    }
  }

  void selectRequest(String requestId) {
    if (state.selectedRequestId == requestId) return;
    state = state.copyWith(
      selectedRequestId: requestId,
      clearDetailError: true,
    );
    Future.microtask(_loadContextForSelected);
  }

  void setStatusFilter(LedgerReviewStatusFilter filter) {
    final nextState = state.copyWith(statusFilter: filter);
    final filtered = nextState.filteredItems;
    String? nextSelectedId = nextState.selectedRequestId;
    if (filtered.isNotEmpty &&
        (nextSelectedId == null ||
            !filtered.any((e) => e.requestId == nextSelectedId))) {
      nextSelectedId = filtered.first.requestId;
    }
    state = nextState.copyWith(
      selectedRequestId: nextSelectedId,
      clearSelectedRequestId: nextSelectedId == null,
      clearDetailError: true,
    );
    Future.microtask(_loadContextForSelected);
  }

  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword);
  }

  Future<void> _loadContextForSelected() async {
    final req = state.selectedRequest;
    if (req == null) return;

    final requestId = req.requestId;
    final origTxId = req.originalTransactionId;
    LedgerHistoryItemModel? origTx = state.originalTransactionsById[origTxId];

    if (origTx == null) {
      state = state.copyWith(isLoadingDetail: true, clearDetailError: true);
      try {
        origTx = await _repository.getTransactionDetail(origTxId);
        if (state.selectedRequestId != requestId) return;
        final updatedOrigMap = Map<String, LedgerHistoryItemModel>.from(
          state.originalTransactionsById,
        )..[origTxId] = origTx;
        state = state.copyWith(
          isLoadingDetail: false,
          originalTransactionsById: updatedOrigMap,
          clearDetailError: true,
        );
      } catch (e) {
        if (state.selectedRequestId != requestId) return;
        state = state.copyWith(
          isLoadingDetail: false,
          detailErrorMessage: formatLedgerFailure(e),
        );
      }
    }

    if (origTx != null &&
        req.approvalStatus == LedgerAdjustmentStatusEnum.approved &&
        state.sealedEntriesByRequestId[requestId] == null) {
      LinkedLedgerTransactionModel? matchedLinked;
      for (final linked in origTx.adjustmentTransactions) {
        if (linked.adjustmentRequestId == requestId) {
          matchedLinked = linked;
          break;
        }
      }
      if (matchedLinked != null) {
        try {
          final fullAdjTx =
              await _repository.getTransactionDetail(matchedLinked.transactionId);
          final sealed = ImmutableLedgerEntryModel.fromHistoryItem(fullAdjTx);
          final updatedSealed = Map<String, ImmutableLedgerEntryModel>.from(
            state.sealedEntriesByRequestId,
          )..[requestId] = sealed;
          state = state.copyWith(sealedEntriesByRequestId: updatedSealed);
        } catch (_) {
          final fallbackSealed = ImmutableLedgerEntryModel(
            transactionId: matchedLinked.transactionId,
            clanId: req.clanId,
            eventId: req.eventId,
            adjustmentRequestId: requestId,
            originalTransactionId: req.originalTransactionId,
            transactionType: matchedLinked.transactionType,
            amount: matchedLinked.amount,
            runningBalance: matchedLinked.runningBalance,
            description: matchedLinked.description,
            createdByAccountId: req.proposedByAccountId,
            approvedByAccountId: req.reviewedByAccountId ?? '',
            previousHash: '',
            recordHash: '',
            createdAt: matchedLinked.createdAt,
          );
          final updatedSealed = Map<String, ImmutableLedgerEntryModel>.from(
            state.sealedEntriesByRequestId,
          )..[requestId] = fallbackSealed;
          state = state.copyWith(sealedEntriesByRequestId: updatedSealed);
        }
      }
    }
  }

  Future<ReviewLedgerAdjustmentResponseModel> submitReview({
    required String requestId,
    required bool approved,
    String? rejectionReason,
    String? description,
  }) async {
    state = state.copyWith(isSubmittingReview: true);
    try {
      final response = await _repository.reviewAdjustment(
        ReviewLedgerAdjustmentRequestDto(
          requestId: requestId,
          approved: approved,
          rejectionReason: rejectionReason,
          description: description,
        ),
      );

      final updatedItems = state.items.map((item) {
        if (item.requestId == response.adjustmentRequest.requestId) {
          return response.adjustmentRequest;
        }
        return item;
      }).toList();

      final updatedSealed = Map<String, ImmutableLedgerEntryModel>.from(
        state.sealedEntriesByRequestId,
      );
      var nextFundBalance = state.currentFundBalance;
      if (response.ledgerEntry != null) {
        updatedSealed[requestId] = response.ledgerEntry!;
        nextFundBalance = response.ledgerEntry!.runningBalance;
      }

      // Làm mới giao dịch gốc nếu đang được cache để cập nhật netAdjustedAmount
      final updatedOrig = Map<String, LedgerHistoryItemModel>.from(
        state.originalTransactionsById,
      );
      updatedOrig.remove(response.adjustmentRequest.originalTransactionId);

      state = state.copyWith(
        isSubmittingReview: false,
        items: updatedItems,
        sealedEntriesByRequestId: updatedSealed,
        originalTransactionsById: updatedOrig,
        currentFundBalance: nextFundBalance,
        selectedRequestId: requestId,
      );

      Future.microtask(_loadContextForSelected);
      return response;
    } catch (e) {
      state = state.copyWith(isSubmittingReview: false);
      rethrow;
    }
  }
}

final ledgerReviewQueueProvider =
    NotifierProvider<LedgerReviewQueueNotifier, LedgerReviewQueueState>(
  LedgerReviewQueueNotifier.new,
);
