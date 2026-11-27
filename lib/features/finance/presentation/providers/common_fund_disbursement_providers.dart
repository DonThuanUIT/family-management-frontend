import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/common_fund_disbursement_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/common_fund_disbursement_repository_impl.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../../domain/repositories/common_fund_disbursement_repository.dart';
import '../../domain/repositories/ledger_repository.dart';
import 'ledger_adjustment_providers.dart';

/// State cho màn hình Lập Đề Xuất Chi Quỹ Chung & Bảng Lịch Sử Phiếu Chi (US-60).
@immutable
class CommonFundOverviewState {
  final bool isLoading;
  final String? errorMessage;
  final CommonFundBalanceModel balance;
  final List<CommonFundDisbursementModel> items;
  final CommonFundDisbursementStatusEnum? statusFilter;

  const CommonFundOverviewState({
    this.isLoading = false,
    this.errorMessage,
    this.balance = const CommonFundBalanceModel(
      clanId: '',
      availableBalance: 0,
      pendingDisbursementAmount: 0,
    ),
    this.items = const [],
    this.statusFilter,
  });

  double get availableBalance => balance.availableBalance;
  double get pendingDisbursementAmount => balance.pendingDisbursementAmount;

  int get pendingCount => items
      .where(
        (e) => e.approvalStatus == CommonFundDisbursementStatusEnum.pending,
      )
      .length;

  List<CommonFundDisbursementModel> get filteredItems {
    if (statusFilter == null) return items;
    return items.where((e) => e.approvalStatus == statusFilter).toList();
  }

  CommonFundOverviewState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    CommonFundBalanceModel? balance,
    List<CommonFundDisbursementModel>? items,
    CommonFundDisbursementStatusEnum? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return CommonFundOverviewState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      balance: balance ?? this.balance,
      items: items ?? this.items,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class CommonFundOverviewNotifier extends Notifier<CommonFundOverviewState> {
  CommonFundDisbursementRepository get _repository =>
      ref.read(commonFundDisbursementRepositoryProvider);

  @override
  CommonFundOverviewState build() {
    Future.microtask(() => loadOverview(showLoading: true));
    return const CommonFundOverviewState(isLoading: true);
  }

  Future<void> loadOverview({bool showLoading = false}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final results = await Future.wait<Object>([
        _repository.getFundBalance(),
        _repository.searchDisbursements(),
      ]);
      state = state.copyWith(
        isLoading: false,
        balance: results[0] as CommonFundBalanceModel,
        items: results[1] as List<CommonFundDisbursementModel>,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: formatLedgerFailure(e),
      );
    }
  }

  void setStatusFilter(CommonFundDisbursementStatusEnum? status) {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
  }

  void prependCreated(CommonFundDisbursementModel created) {
    state = state.copyWith(
      items: [created, ...state.items],
      balance: state.balance.copyWith(
        pendingDisbursementAmount:
            state.balance.pendingDisbursementAmount + created.amount,
      ),
    );
  }
}

final commonFundOverviewProvider =
    NotifierProvider<CommonFundOverviewNotifier, CommonFundOverviewState>(
  CommonFundOverviewNotifier.new,
);

/// Bộ lọc trạng thái hàng chờ ký duyệt chi Quỹ chung (US-60).
enum DisbursementReviewStatusFilter {
  pending('Chờ duyệt'),
  approved('Đã duyệt'),
  rejected('Từ chối'),
  all('Tất cả');

  final String shortLabel;
  const DisbursementReviewStatusFilter(this.shortLabel);

  CommonFundDisbursementStatusEnum? get matchingStatus {
    switch (this) {
      case DisbursementReviewStatusFilter.pending:
        return CommonFundDisbursementStatusEnum.pending;
      case DisbursementReviewStatusFilter.approved:
        return CommonFundDisbursementStatusEnum.approved;
      case DisbursementReviewStatusFilter.rejected:
        return CommonFundDisbursementStatusEnum.rejected;
      case DisbursementReviewStatusFilter.all:
        return null;
    }
  }

  static DisbursementReviewStatusFilter fromStatus(
    CommonFundDisbursementStatusEnum status,
  ) {
    switch (status) {
      case CommonFundDisbursementStatusEnum.pending:
        return DisbursementReviewStatusFilter.pending;
      case CommonFundDisbursementStatusEnum.approved:
        return DisbursementReviewStatusFilter.approved;
      case CommonFundDisbursementStatusEnum.rejected:
        return DisbursementReviewStatusFilter.rejected;
    }
  }
}

@immutable
class DisbursementReviewQueueState {
  final bool isLoading;
  final bool isLoadingLedgerDetail;
  final bool isSubmittingReview;
  final String? errorMessage;
  final CommonFundBalanceModel balance;
  final List<CommonFundDisbursementModel> items;
  final DisbursementReviewStatusFilter statusFilter;
  final CommonFundExpenseCategoryEnum? categoryFilter;
  final String keyword;
  final String? selectedRequestId;
  final Map<String, ImmutableLedgerEntryModel> sealedEntriesByRequestId;

  const DisbursementReviewQueueState({
    this.isLoading = false,
    this.isLoadingLedgerDetail = false,
    this.isSubmittingReview = false,
    this.errorMessage,
    this.balance = const CommonFundBalanceModel(
      clanId: '',
      availableBalance: 0,
      pendingDisbursementAmount: 0,
    ),
    this.items = const [],
    this.statusFilter = DisbursementReviewStatusFilter.pending,
    this.categoryFilter,
    this.keyword = '',
    this.selectedRequestId,
    this.sealedEntriesByRequestId = const {},
  });

  double get availableBalance => balance.availableBalance;
  double get pendingDisbursementAmount => balance.pendingDisbursementAmount;

  int get pendingCount => items
      .where(
        (e) => e.approvalStatus == CommonFundDisbursementStatusEnum.pending,
      )
      .length;

  int get approvedCount => items
      .where(
        (e) => e.approvalStatus == CommonFundDisbursementStatusEnum.approved,
      )
      .length;

  int get rejectedCount => items
      .where(
        (e) => e.approvalStatus == CommonFundDisbursementStatusEnum.rejected,
      )
      .length;

  int get totalCount => items.length;

  int countForFilter(DisbursementReviewStatusFilter filter) {
    switch (filter) {
      case DisbursementReviewStatusFilter.pending:
        return pendingCount;
      case DisbursementReviewStatusFilter.approved:
        return approvedCount;
      case DisbursementReviewStatusFilter.rejected:
        return rejectedCount;
      case DisbursementReviewStatusFilter.all:
        return totalCount;
    }
  }

  List<CommonFundDisbursementModel> get filteredItems {
    final targetStatus = statusFilter.matchingStatus;
    final q = keyword.trim().toLowerCase();
    return items.where((item) {
      if (targetStatus != null && item.approvalStatus != targetStatus) {
        return false;
      }
      if (categoryFilter != null && item.category != categoryFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return item.requestId.toLowerCase().contains(q) ||
          item.title.toLowerCase().contains(q) ||
          (item.beneficiaryName ?? '').toLowerCase().contains(q) ||
          item.purpose.toLowerCase().contains(q) ||
          item.proposedByAccountId.toLowerCase().contains(q);
    }).toList();
  }

  CommonFundDisbursementModel? get selectedRequest {
    final id = selectedRequestId;
    if (id == null) return null;
    for (final item in items) {
      if (item.requestId == id) return item;
    }
    return null;
  }

  ImmutableLedgerEntryModel? get selectedSealedEntry {
    final req = selectedRequest;
    if (req == null) return null;
    return sealedEntriesByRequestId[req.requestId];
  }

  DisbursementReviewQueueState copyWith({
    bool? isLoading,
    bool? isLoadingLedgerDetail,
    bool? isSubmittingReview,
    String? errorMessage,
    bool clearError = false,
    CommonFundBalanceModel? balance,
    List<CommonFundDisbursementModel>? items,
    DisbursementReviewStatusFilter? statusFilter,
    CommonFundExpenseCategoryEnum? categoryFilter,
    bool clearCategoryFilter = false,
    String? keyword,
    String? selectedRequestId,
    bool clearSelectedRequestId = false,
    Map<String, ImmutableLedgerEntryModel>? sealedEntriesByRequestId,
  }) {
    return DisbursementReviewQueueState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingLedgerDetail:
          isLoadingLedgerDetail ?? this.isLoadingLedgerDetail,
      isSubmittingReview: isSubmittingReview ?? this.isSubmittingReview,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      balance: balance ?? this.balance,
      items: items ?? this.items,
      statusFilter: statusFilter ?? this.statusFilter,
      categoryFilter: clearCategoryFilter
          ? null
          : (categoryFilter ?? this.categoryFilter),
      keyword: keyword ?? this.keyword,
      selectedRequestId: clearSelectedRequestId
          ? null
          : (selectedRequestId ?? this.selectedRequestId),
      sealedEntriesByRequestId:
          sealedEntriesByRequestId ?? this.sealedEntriesByRequestId,
    );
  }
}

class DisbursementReviewQueueNotifier
    extends Notifier<DisbursementReviewQueueState> {
  CommonFundDisbursementRepository get _repository =>
      ref.read(commonFundDisbursementRepositoryProvider);
  LedgerRepository get _ledgerRepository => ref.read(ledgerRepositoryProvider);

  @override
  DisbursementReviewQueueState build() {
    return const DisbursementReviewQueueState(isLoading: true);
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
        _repository.getFundBalance(),
        _repository.searchDisbursements(),
      ]);

      final balance = results[0] as CommonFundBalanceModel;
      final fetchedItems = List<CommonFundDisbursementModel>.from(
        results[1] as List<CommonFundDisbursementModel>,
      );

      var nextFilter = state.statusFilter;
      String? nextSelectedId;
      final preferred = preferredRequestId?.trim();

      if (preferred != null && preferred.isNotEmpty) {
        CommonFundDisbursementModel? matched;
        for (final item in fetchedItems) {
          if (item.requestId == preferred) {
            matched = item;
            break;
          }
        }
        if (matched == null) {
          try {
            final fetched = await _repository.getDisbursementById(preferred);
            matched = fetched;
            fetchedItems.insert(0, fetched);
          } catch (_) {
            // Bỏ qua nếu không tìm thấy preferredRequestId cụ thể
          }
        }
        if (matched != null) {
          nextFilter =
              DisbursementReviewStatusFilter.fromStatus(matched.approvalStatus);
          nextSelectedId = matched.requestId;
        }
      }

      if (nextSelectedId == null) {
        final curSelected = state.selectedRequestId;
        if (curSelected != null &&
            fetchedItems.any((e) => e.requestId == curSelected)) {
          nextSelectedId = curSelected;
        } else {
          final targetStatus = nextFilter.matchingStatus;
          final matchingCurrentFilter = fetchedItems.where(
            (e) => targetStatus == null || e.approvalStatus == targetStatus,
          );
          if (matchingCurrentFilter.isNotEmpty) {
            nextSelectedId = matchingCurrentFilter.first.requestId;
          } else if (fetchedItems.isNotEmpty) {
            nextFilter = DisbursementReviewStatusFilter.all;
            nextSelectedId = fetchedItems.first.requestId;
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        balance: balance,
        items: fetchedItems,
        statusFilter: nextFilter,
        selectedRequestId: nextSelectedId,
        clearSelectedRequestId: nextSelectedId == null,
        clearError: true,
      );

      await _loadSealedEntryForSelected();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: formatLedgerFailure(e),
      );
    }
  }

  void selectRequest(String requestId) {
    if (state.selectedRequestId == requestId) return;
    state = state.copyWith(selectedRequestId: requestId);
    Future.microtask(_loadSealedEntryForSelected);
  }

  void setStatusFilter(DisbursementReviewStatusFilter filter) {
    final next = state.copyWith(statusFilter: filter);
    final filtered = next.filteredItems;
    String? nextSelectedId = next.selectedRequestId;
    if (filtered.isNotEmpty &&
        (nextSelectedId == null ||
            !filtered.any((e) => e.requestId == nextSelectedId))) {
      nextSelectedId = filtered.first.requestId;
    }
    state = next.copyWith(
      selectedRequestId: nextSelectedId,
      clearSelectedRequestId: nextSelectedId == null,
    );
    Future.microtask(_loadSealedEntryForSelected);
  }

  void setCategoryFilter(CommonFundExpenseCategoryEnum? category) {
    final next = state.copyWith(
      categoryFilter: category,
      clearCategoryFilter: category == null,
    );
    final filtered = next.filteredItems;
    String? nextSelectedId = next.selectedRequestId;
    if (filtered.isNotEmpty &&
        (nextSelectedId == null ||
            !filtered.any((e) => e.requestId == nextSelectedId))) {
      nextSelectedId = filtered.first.requestId;
    }
    state = next.copyWith(
      selectedRequestId: nextSelectedId,
      clearSelectedRequestId: nextSelectedId == null,
    );
    Future.microtask(_loadSealedEntryForSelected);
  }

  void setKeyword(String keyword) {
    state = state.copyWith(keyword: keyword);
  }

  Future<void> _loadSealedEntryForSelected() async {
    final req = state.selectedRequest;
    if (req == null) return;
    if (req.approvalStatus != CommonFundDisbursementStatusEnum.approved) return;
    final txId = req.ledgerTransactionId?.trim();
    if (txId == null || txId.isEmpty) return;
    if (state.sealedEntriesByRequestId[req.requestId] != null) return;

    state = state.copyWith(isLoadingLedgerDetail: true);
    try {
      final tx = await _ledgerRepository.getTransactionDetail(txId);
      if (state.selectedRequestId != req.requestId) return;
      final sealed = ImmutableLedgerEntryModel.fromHistoryItem(tx);
      final updated = Map<String, ImmutableLedgerEntryModel>.from(
        state.sealedEntriesByRequestId,
      )..[req.requestId] = sealed;
      state = state.copyWith(
        isLoadingLedgerDetail: false,
        sealedEntriesByRequestId: updated,
      );
    } catch (_) {
      if (state.selectedRequestId == req.requestId) {
        state = state.copyWith(isLoadingLedgerDetail: false);
      }
    }
  }

  Future<ReviewCommonFundDisbursementResponseModel> submitReview({
    required String requestId,
    required bool approved,
    String? confirmPassword,
    String? rejectionReason,
    String? description,
  }) async {
    state = state.copyWith(isSubmittingReview: true);
    try {
      final response = await _repository.reviewDisbursement(
        requestId,
        ReviewCommonFundDisbursementRequestDto(
          requestId: requestId,
          approved: approved,
          confirmPassword: confirmPassword,
          rejectionReason: rejectionReason,
          description: description,
        ),
      );

      final updatedReq = response.disbursementRequest;
      final updatedItems = state.items.map((item) {
        if (item.requestId == updatedReq.requestId) {
          return updatedReq;
        }
        return item;
      }).toList();

      final updatedSealed = Map<String, ImmutableLedgerEntryModel>.from(
        state.sealedEntriesByRequestId,
      );
      var nextAvailable = state.balance.availableBalance;
      var nextPendingAmount =
          (state.balance.pendingDisbursementAmount - updatedReq.amount)
              .clamp(0.0, double.infinity);

      if (response.ledgerEntry != null) {
        updatedSealed[requestId] = response.ledgerEntry!;
        nextAvailable = response.ledgerEntry!.runningBalance;
      }

      state = state.copyWith(
        isSubmittingReview: false,
        items: updatedItems,
        sealedEntriesByRequestId: updatedSealed,
        balance: state.balance.copyWith(
          availableBalance: nextAvailable,
          pendingDisbursementAmount: nextPendingAmount,
        ),
        selectedRequestId: requestId,
      );

      return response;
    } catch (e) {
      state = state.copyWith(isSubmittingReview: false);
      rethrow;
    }
  }
}

final disbursementReviewQueueProvider = NotifierProvider<
    DisbursementReviewQueueNotifier, DisbursementReviewQueueState>(
  DisbursementReviewQueueNotifier.new,
);
