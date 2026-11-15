import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/advance_voucher_models.dart';
import '../../data/repositories/advance_voucher_repository_impl.dart';
import '../../domain/repositories/advance_voucher_repository.dart';

enum OverdueDaysFilter {
  all('Tất cả'),
  days1to3('Trễ 1-3 ngày'),
  days4to7('Trễ 4-7 ngày'),
  over7Days('Trễ > 7 ngày');

  final String label;
  const OverdueDaysFilter(this.label);
}

class OverdueAdvanceListState {
  final bool isLoading;
  final String? errorMessage;
  final List<AdvanceVoucherModel> vouchers;
  final String searchQuery;
  final OverdueDaysFilter daysFilter;
  final bool isScanning;
  final OverdueScanSummaryModel? lastScanSummary;

  const OverdueAdvanceListState({
    this.isLoading = false,
    this.errorMessage,
    this.vouchers = const [],
    this.searchQuery = '',
    this.daysFilter = OverdueDaysFilter.all,
    this.isScanning = false,
    this.lastScanSummary,
  });

  /// Danh sách phiếu sau khi lọc theo từ khóa tìm kiếm và khoảng thời gian trễ hạn.
  List<AdvanceVoucherModel> get filteredVouchers {
    return vouchers.where((voucher) {
      // 1. Lọc theo từ khóa tìm kiếm
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchRecipient = (voucher.recipientMemberName ?? '')
            .toLowerCase()
            .contains(query);
        final matchTask =
            (voucher.taskName ?? '').toLowerCase().contains(query);
        final matchId = voucher.advanceVoucherId.toLowerCase().contains(query);
        final matchTaskId = voucher.taskId.toLowerCase().contains(query);
        if (!matchRecipient && !matchTask && !matchId && !matchTaskId) {
          return false;
        }
      }

      // 2. Lọc theo số ngày trễ hạn
      final days = voucher.overdueDays;
      switch (daysFilter) {
        case OverdueDaysFilter.all:
          return true;
        case OverdueDaysFilter.days1to3:
          return days >= 1 && days <= 3;
        case OverdueDaysFilter.days4to7:
          return days >= 4 && days <= 7;
        case OverdueDaysFilter.over7Days:
          return days > 7;
      }
    }).toList();
  }

  /// Tổng số tiền nợ tạm ứng quá hạn (VNĐ) của các phiếu đang hiển thị.
  int get totalOverdueAmount =>
      filteredVouchers.fold(0, (sum, v) => sum + v.advanceAmount);

  /// Tổng số lượng phiếu quá hạn.
  int get totalOverdueCount => filteredVouchers.length;

  /// Số ngày trễ hạn dài nhất trong danh sách.
  int get maxOverdueDays {
    if (filteredVouchers.isEmpty) return 0;
    return filteredVouchers
        .map((v) => v.overdueDays)
        .reduce((max, d) => d > max ? d : max);
  }

  /// Số lượng thành viên duy nhất đang giữ tiền tạm ứng quá hạn.
  int get debtorCount {
    final set = filteredVouchers.map((v) => v.recipientMemberId).toSet();
    return set.length;
  }

  OverdueAdvanceListState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<AdvanceVoucherModel>? vouchers,
    String? searchQuery,
    OverdueDaysFilter? daysFilter,
    bool? isScanning,
    OverdueScanSummaryModel? lastScanSummary,
  }) {
    return OverdueAdvanceListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      vouchers: vouchers ?? this.vouchers,
      searchQuery: searchQuery ?? this.searchQuery,
      daysFilter: daysFilter ?? this.daysFilter,
      isScanning: isScanning ?? this.isScanning,
      lastScanSummary: lastScanSummary ?? this.lastScanSummary,
    );
  }
}

class OverdueAdvanceListNotifier extends Notifier<OverdueAdvanceListState> {
  final String? eventId;

  OverdueAdvanceListNotifier(this.eventId);

  AdvanceVoucherRepository get _repository =>
      ref.read(advanceVoucherRepositoryProvider);

  @override
  OverdueAdvanceListState build() {
    Future.microtask(() => loadOverdueVouchers(showLoading: true));
    return const OverdueAdvanceListState(isLoading: true);
  }

  Future<void> loadOverdueVouchers({bool showLoading = false}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      // Tải cả phiếu trạng thái QuaHan và ChuaTatToan để phát hiện các phiếu đã quá hạn
      final list = await _repository.getAdvanceVouchers(
        eventId: eventId,
      );

      final overdueList = list.where((v) => v.isOverdue).toList()
        ..sort((a, b) => b.overdueDays.compareTo(a.overdueDays));

      state = state.copyWith(
        isLoading: false,
        vouchers: overdueList,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDaysFilter(OverdueDaysFilter filter) {
    state = state.copyWith(daysFilter: filter);
  }

  /// Kích hoạt quét quá hạn thủ công từ server (`POST /api/v1/advances/scan-overdue`).
  Future<OverdueScanSummaryModel> scanOverdue() async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final summary = await _repository.scanOverdueVouchers();
      state = state.copyWith(
        isScanning: false,
        lastScanSummary: summary,
      );
      // Tải lại danh sách sau khi quét
      await loadOverdueVouchers(showLoading: false);
      return summary;
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Gửi thông điệp đôn đốc thu hồi tạm ứng tới người nhận.
  Future<void> sendReminder(
    String voucherId, {
    String? customMessage,
  }) async {
    await _repository.sendSettlementReminder(
      SendSettlementReminderRequestDto(
        voucherId: voucherId,
        customMessage: customMessage,
      ),
    );
  }
}

/// Provider quản lý danh sách phiếu tạm ứng quá hạn theo từng sự kiện (`eventId`) hoặc toàn cục (`null` / rỗng).
final overdueAdvanceListProvider = NotifierProvider.family<
    OverdueAdvanceListNotifier, OverdueAdvanceListState, String?>(
  (eventId) => OverdueAdvanceListNotifier(eventId),
);
