import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../data/models/contribution_models.dart';
import '../../data/repositories/contribution_repository_impl.dart';
import '../../domain/repositories/contribution_repository.dart';

/// Trạng thái dữ liệu giao diện Tiếp nhận đóng góp và Quản lý tài sản.
class ContributionUiState {
  final List<ElectronicReceiptDto> cashReceipts;
  final List<InKindElectronicReceiptDto> inKindReceipts;
  final List<ClanAssetDto> clanAssets;
  final String searchQuery;
  final bool isLoading;
  final bool isLiveConnected;
  final String? errorMessage;

  const ContributionUiState({
    this.cashReceipts = const [],
    this.inKindReceipts = const [],
    this.clanAssets = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.isLiveConnected = false,
    this.errorMessage,
  });

  ContributionUiState copyWith({
    List<ElectronicReceiptDto>? cashReceipts,
    List<InKindElectronicReceiptDto>? inKindReceipts,
    List<ClanAssetDto>? clanAssets,
    String? searchQuery,
    bool? isLoading,
    bool? isLiveConnected,
    String? errorMessage,
  }) {
    return ContributionUiState(
      cashReceipts: cashReceipts ?? this.cashReceipts,
      inKindReceipts: inKindReceipts ?? this.inKindReceipts,
      clanAssets: clanAssets ?? this.clanAssets,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isLiveConnected: isLiveConnected ?? this.isLiveConnected,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Thống kê nhanh
  double get totalCashAmount =>
      cashReceipts.fold(0.0, (sum, item) => sum + item.amount);

  double get totalInKindConvertedAmount => inKindReceipts.fold(
      0.0, (sum, item) => sum + item.convertedMonetaryValue);

  int get pendingInKindCount => inKindReceipts
      .where((item) => item.processingStatus == InKindProcessingStatus.Pending)
      .length;

  int get consumedInKindCount => inKindReceipts
      .where((item) => item.processingStatus == InKindProcessingStatus.Consumed)
      .length;

  int get returnedInKindCount => inKindReceipts
      .where((item) => item.processingStatus == InKindProcessingStatus.Returned)
      .length;

  int get processedInKindCount => inKindReceipts
      .where((item) => item.processingStatus != InKindProcessingStatus.Pending)
      .length;

  double get totalAssetValue =>
      clanAssets.fold(0.0, (sum, item) => sum + item.assessedValue);

  int get totalAssetItemCount =>
      clanAssets.fold(0, (sum, item) => sum + item.quantity);
}

class ContributionUiNotifier extends Notifier<ContributionUiState> {
  ContributionRepository get _repository =>
      ref.read(contributionRepositoryProvider);

  @override
  ContributionUiState build() {
    final initial = _createInitialData();
    // Tự động gọi API backend ở nền (nếu backend đang chạy và có mạng)
    Future.microtask(() => fetchFromBackend());
    return initial;
  }

  /// Tải dữ liệu thật từ Backend qua REST API
  Future<void> fetchFromBackend({String eventId = 'EVT-GIO-TO-2026'}) async {
    List<ElectronicReceiptDto> cashList = state.cashReceipts;
    List<InKindElectronicReceiptDto> inKindList = state.inKindReceipts;
    List<ClanAssetDto> assetList = state.clanAssets;
    bool connected = false;

    try {
      cashList = await _repository.getCashContributionsByEvent(eventId: eventId);
      connected = true;
    } catch (e) {
      debugPrint('Backend sync error (cash): $e');
    }

    try {
      inKindList = await _repository.getInKindContributionsByEvent(eventId: eventId);
      connected = true;
    } catch (e) {
      debugPrint('Backend sync error (in-kind): $e');
    }

    try {
      assetList = await _repository.getClanAssets();
      connected = true;
    } catch (e) {
      debugPrint('Backend sync error (assets): $e');
    }

    state = state.copyWith(
      cashReceipts: cashList,
      inKindReceipts: inKindList,
      clanAssets: assetList,
      isLiveConnected: connected,
    );
  }

  ContributionUiState _createInitialData() {
    return const ContributionUiState(
      cashReceipts: [],
      inKindReceipts: [],
      clanAssets: [],
    );
  }

  // Ghi nhận tiền mặt / chuyển khoản trực tiếp qua Backend API
  Future<ElectronicReceiptDto> recordCashContribution({
    required String eventId,
    required String payerMemberId,
    required String payerMemberName,
    required double amount,
    required PaymentMethod paymentMethod,
    List<MemberAllocationDto> allocations = const [],
  }) async {
    final effectiveAllocations = allocations.isNotEmpty
        ? allocations
        : [
            MemberAllocationDto(
              memberId: payerMemberId,
              memberName: payerMemberName,
              generation: 'Thành viên',
              amount: amount,
              percentage: 100.0,
            ),
          ];

    final remoteReceipt = await _repository.recordCashContribution(
      eventId: eventId,
      payerMemberId: payerMemberId,
      amount: amount,
      paymentMethod: paymentMethod,
      allocations: effectiveAllocations,
    );
    await fetchFromBackend(eventId: eventId);
    return remoteReceipt;
  }

  // Ghi nhận hiện vật cúng tiến trực tiếp qua Backend API
  Future<InKindElectronicReceiptDto> recordInKindContribution({
    required String eventId,
    required String payerMemberId,
    required String payerMemberName,
    required String itemName,
    required double quantity,
    required String unit,
    required ConversionMethod conversionMethod,
    required double convertedMonetaryValue,
    String? benchmarkId,
    String? invoiceReference,
    List<MemberAllocationDto> allocations = const [],
  }) async {
    final effectiveAllocations = allocations.isNotEmpty
        ? allocations
        : [
            MemberAllocationDto(
              memberId: payerMemberId,
              memberName: payerMemberName,
              generation: 'Thành viên',
              amount: convertedMonetaryValue,
              percentage: 100.0,
            ),
          ];

    final remoteReceipt = await _repository.recordInKindContribution(
      eventId: eventId,
      payerMemberId: payerMemberId,
      itemName: itemName,
      quantity: quantity,
      unit: unit,
      conversionMethod: conversionMethod,
      convertedMonetaryValue: convertedMonetaryValue,
      benchmarkId: benchmarkId,
      invoiceReference: invoiceReference,
      allocations: effectiveAllocations,
    );
    await fetchFromBackend(eventId: eventId);
    return remoteReceipt;
  }

  // Phân loại vòng đời hiện vật sau sự kiện trực tiếp qua Backend API
  Future<void> processInKindLifecycle({
    required String contributionId,
    required InKindProcessingStatus targetStatus,
    String? storageLocation,
  }) async {
    await _repository.processInKindLifecycle(
      contributionId: contributionId,
      targetStatus: targetStatus,
      storageLocation: storageLocation,
    );
    await fetchFromBackend();
  }

  /// Trực tiếp đăng ký bảo vật, đồ thờ gia truyền vào kho dòng họ (Task #74)
  void addDirectClanAsset({
    required String assetName,
    required int quantity,
    required String unit,
    required double assessedValue,
    required String storageLocation,
    String? originDonorName,
  }) {
    final randAssetId = 100 + (assetName.hashCode.abs() % 900);
    final asset = ClanAssetDto(
      assetId: 'AST-2026-$randAssetId',
      assetName: assetName,
      quantity: quantity,
      unit: unit,
      assessedValue: assessedValue,
      storageLocation: storageLocation,
      originDonorName: originDonorName,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      clanAssets: [asset, ...state.clanAssets],
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
  }

  String _numberToVietnameseWords(double amount) {
    return VietnameseMoneyConverter.toWords(amount);
  }
}

final contributionUiProvider =
    NotifierProvider<ContributionUiNotifier, ContributionUiState>(
  ContributionUiNotifier.new,
);
