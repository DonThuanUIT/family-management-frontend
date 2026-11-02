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
    try {
      final results = await Future.wait([
        _repository.getInKindContributionsByEvent(eventId: eventId),
        _repository.getClanAssets(),
      ]);

      final inKindList = results[0] as List<InKindElectronicReceiptDto>;
      final assetList = results[1] as List<ClanAssetDto>;

      state = state.copyWith(
        inKindReceipts: inKindList.isNotEmpty ? inKindList : state.inKindReceipts,
        clanAssets: assetList.isNotEmpty ? assetList : state.clanAssets,
        isLiveConnected: inKindList.isNotEmpty || assetList.isNotEmpty,
      );
    } catch (e) {
      debugPrint('Backend sync offline/fallback mode: $e');
    }
  }

  ContributionUiState _createInitialData() {
    final now = DateTime.now();

    final initialCash = [
      ElectronicReceiptDto(
        receiptNumber: 'PT-20261102-09482',
        contributionId: 'CTB-CASH-089',
        eventId: 'EVT-GIO-TO-2026',
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM-005',
        payerMemberName: 'Lê Hữu Tuấn (Chi 2 - Đời 5)',
        receiverAccountId: 'ACC-TREASURER-01',
        amount: 1000000,
        amountInWords: 'Một triệu đồng chẵn',
        paymentMethod: PaymentMethod.BankTransfer,
        contributionDate: now.subtract(const Duration(hours: 2)),
        allocations: const [
          MemberAllocationDto(
            memberId: 'MEM-005',
            memberName: 'Lê Hữu Tuấn',
            generation: 'Đời 5',
            amount: 1000000,
            percentage: 100.0,
          ),
        ],
      ),
      ElectronicReceiptDto(
        receiptNumber: 'PT-20261102-08114',
        contributionId: 'CTB-CASH-065',
        eventId: 'EVT-GIO-TO-2026',
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM-002',
        payerMemberName: 'Lê Văn An (Trưởng Chi 1)',
        receiverAccountId: 'ACC-TREASURER-01',
        amount: 5000000,
        amountInWords: 'Năm triệu đồng chẵn',
        paymentMethod: PaymentMethod.Cash,
        contributionDate: now.subtract(const Duration(hours: 4)),
        allocations: const [
          MemberAllocationDto(
            memberId: 'MEM-002',
            memberName: 'Lê Văn An',
            generation: 'Đời 4',
            amount: 3000000,
            percentage: 60.0,
          ),
          MemberAllocationDto(
            memberId: 'MEM-022',
            memberName: 'Lê Văn Bình',
            generation: 'Đời 5',
            amount: 2000000,
            percentage: 40.0,
          ),
        ],
      ),
    ];

    final initialInKind = [
      InKindElectronicReceiptDto(
        receiptNumber: 'PT-20261102-07721',
        contributionId: 'CTB-INKIND-077',
        eventId: 'EVT-GIO-TO-2026',
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM-018',
        payerMemberName: 'Lê Thị Mai (Chi 1 - Đời 4)',
        receiverAccountId: 'ACC-TREASURER-01',
        itemName: 'Đôi lục bình gốm Bát Tràng men lam cổ',
        quantity: 1,
        unit: 'đôi',
        conversionMethod: ConversionMethod.Agreement,
        convertedMonetaryValue: 3500000,
        convertedMonetaryValueInWords: 'Ba triệu năm trăm nghìn đồng chẵn',
        processingStatus: InKindProcessingStatus.Pending,
        contributionDate: now.subtract(const Duration(hours: 3)),
        allocations: const [
          MemberAllocationDto(
            memberId: 'MEM-018',
            memberName: 'Lê Thị Mai',
            generation: 'Đời 4',
            amount: 3500000,
            percentage: 100.0,
          ),
        ],
      ),
      InKindElectronicReceiptDto(
        receiptNumber: 'PT-20261102-06512',
        contributionId: 'CTB-INKIND-052',
        eventId: 'EVT-GIO-TO-2026',
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM-009',
        payerMemberName: 'Lê Quang Huy (Chi 3 - Đời 5)',
        receiverAccountId: 'ACC-TREASURER-01',
        itemName: 'Heo quay nguyên con dâng lễ tế tổ',
        quantity: 1,
        unit: 'con',
        conversionMethod: ConversionMethod.BtcBenchmark,
        convertedMonetaryValue: 4000000,
        convertedMonetaryValueInWords: 'Bốn triệu đồng chẵn',
        processingStatus: InKindProcessingStatus.Pending,
        contributionDate: now.subtract(const Duration(hours: 5)),
        allocations: const [
          MemberAllocationDto(
            memberId: 'MEM-009',
            memberName: 'Lê Quang Huy',
            generation: 'Đời 5',
            amount: 4000000,
            percentage: 100.0,
          ),
        ],
      ),
      InKindElectronicReceiptDto(
        receiptNumber: 'PT-20261102-05189',
        contributionId: 'CTB-INKIND-041',
        eventId: 'EVT-GIO-TO-2026',
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM-014',
        payerMemberName: 'Lê Văn Tuấn (Chi 2 - Đời 4)',
        receiverAccountId: 'ACC-TREASURER-01',
        itemName: '10 Mâm xôi gấc & gà trống thiến tế tổ',
        quantity: 10,
        unit: 'mâm',
        conversionMethod: ConversionMethod.BtcBenchmark,
        convertedMonetaryValue: 5000000,
        convertedMonetaryValueInWords: 'Năm triệu đồng chẵn',
        processingStatus: InKindProcessingStatus.Consumed,
        contributionDate: now.subtract(const Duration(hours: 6)),
        allocations: const [
          MemberAllocationDto(
            memberId: 'MEM-014',
            memberName: 'Lê Văn Tuấn',
            generation: 'Đời 4',
            amount: 5000000,
            percentage: 100.0,
          ),
        ],
      ),
      InKindElectronicReceiptDto(
        receiptNumber: 'PT-20261102-04332',
        contributionId: 'CTB-INKIND-038',
        eventId: 'EVT-GIO-TO-2026',
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM-031',
        payerMemberName: 'Lê Minh Tâm (Trưởng Chi 4)',
        receiverAccountId: 'ACC-TREASURER-01',
        itemName: 'Dàn âm thanh loa đài phục vụ tế lễ đại triều',
        quantity: 1,
        unit: 'dàn',
        conversionMethod: ConversionMethod.Agreement,
        convertedMonetaryValue: 8000000,
        convertedMonetaryValueInWords:
            'Tám triệu đồng chẵn (Quy đổi công đức mượn tế lễ)',
        processingStatus: InKindProcessingStatus.Returned,
        contributionDate: now.subtract(const Duration(hours: 8)),
        allocations: const [
          MemberAllocationDto(
            memberId: 'MEM-031',
            memberName: 'Lê Minh Tâm',
            generation: 'Đời 4',
            amount: 8000000,
            percentage: 100.0,
          ),
        ],
      ),
    ];

    final initialAssets = [
      ClanAssetDto(
        assetId: 'AST-2026-001',
        assetName: 'Bộ đỉnh đồng tam sự chạm khắc song long',
        quantity: 1,
        unit: 'bộ',
        assessedValue: 18000000,
        storageLocation: 'Gian thờ chính - Bàn thờ Thủy Tổ',
        originContributionId: 'CTB-LEGACY-01',
        originDonorName: 'Cụ Lê Văn Chính (Trưởng Tộc Đời 3)',
        createdAt: DateTime(2025, 3, 10),
      ),
      ClanAssetDto(
        assetId: 'AST-2026-002',
        assetName: 'Hoành phi câu đối sơn son thếp vàng "Đức Lưu Quang"',
        quantity: 1,
        unit: 'bộ',
        assessedValue: 25000000,
        storageLocation: 'Tiền sảnh Từ Đường Đại Gia Tộc',
        originContributionId: 'CTB-LEGACY-02',
        originDonorName: 'Hội đồng Tộc Biểu Chi 1 & Chi 2',
        createdAt: DateTime(2025, 8, 15),
      ),
      ClanAssetDto(
        assetId: 'AST-2026-003',
        assetName: 'Bát hương đồng ngũ sắc thời Nguyễn',
        quantity: 3,
        unit: 'chiếc',
        assessedValue: 12000000,
        storageLocation: 'Hương án Từ Đường',
        originContributionId: 'CTB-LEGACY-03',
        originDonorName: 'Chi 3 Miền Nam cúng tiến',
        createdAt: DateTime(2025, 11, 20),
      ),
    ];

    return ContributionUiState(
      cashReceipts: initialCash,
      inKindReceipts: initialInKind,
      clanAssets: initialAssets,
    );
  }

  // Ghi nhận tiền mặt / chuyển khoản
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

    try {
      final remoteReceipt = await _repository.recordCashContribution(
        eventId: eventId,
        payerMemberId: payerMemberId,
        amount: amount,
        paymentMethod: paymentMethod,
        allocations: effectiveAllocations,
      );
      state = state.copyWith(
        cashReceipts: [remoteReceipt, ...state.cashReceipts],
        isLiveConnected: true,
      );
      return remoteReceipt;
    } catch (e) {
      debugPrint('API call error, using local fallback receipt: $e');

      final randId = 10000 + Random().nextInt(90000);
      final receiptNumber = 'PT-${_formatDate(DateTime.now())}-$randId';
      final contributionId = 'CTB-CASH-$randId';

      final receipt = ElectronicReceiptDto(
        receiptNumber: receiptNumber,
        contributionId: contributionId,
        eventId: eventId,
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: payerMemberId,
        payerMemberName: payerMemberName,
        receiverAccountId: 'ACC-TREASURER-01',
        amount: amount,
        amountInWords: _numberToVietnameseWords(amount),
        paymentMethod: paymentMethod,
        contributionDate: DateTime.now(),
        allocations: effectiveAllocations,
      );

      state = state.copyWith(
        cashReceipts: [receipt, ...state.cashReceipts],
      );

      return receipt;
    }
  }

  // Ghi nhận hiện vật cúng tiến
  Future<InKindElectronicReceiptDto> recordInKindContribution({
    required String eventId,
    required String payerMemberId,
    required String payerMemberName,
    required String itemName,
    required double quantity,
    required String unit,
    required ConversionMethod conversionMethod,
    required double convertedMonetaryValue,
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

    try {
      final remoteReceipt = await _repository.recordInKindContribution(
        eventId: eventId,
        payerMemberId: payerMemberId,
        itemName: itemName,
        quantity: quantity,
        unit: unit,
        conversionMethod: conversionMethod,
        convertedMonetaryValue: convertedMonetaryValue,
        allocations: effectiveAllocations,
      );
      state = state.copyWith(
        inKindReceipts: [remoteReceipt, ...state.inKindReceipts],
        isLiveConnected: true,
      );
      return remoteReceipt;
    } catch (e) {
      debugPrint('API call error, using local fallback in-kind receipt: $e');

      final randId = 10000 + Random().nextInt(90000);
      final receiptNumber = 'PT-${_formatDate(DateTime.now())}-$randId';
      final contributionId = 'CTB-INKIND-$randId';

      final receipt = InKindElectronicReceiptDto(
        receiptNumber: receiptNumber,
        contributionId: contributionId,
        eventId: eventId,
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: payerMemberId,
        payerMemberName: payerMemberName,
        receiverAccountId: 'ACC-TREASURER-01',
        itemName: itemName,
        quantity: quantity,
        unit: unit,
        conversionMethod: conversionMethod,
        convertedMonetaryValue: convertedMonetaryValue,
        convertedMonetaryValueInWords:
            _numberToVietnameseWords(convertedMonetaryValue),
        processingStatus: InKindProcessingStatus.Pending,
        contributionDate: DateTime.now(),
        allocations: effectiveAllocations,
      );

      state = state.copyWith(
        inKindReceipts: [receipt, ...state.inKindReceipts],
      );

      return receipt;
    }
  }

  // Phân loại vòng đời hiện vật sau sự kiện (Task #73 / #74)
  Future<void> processInKindLifecycle({
    required String contributionId,
    required InKindProcessingStatus targetStatus,
    String? storageLocation,
  }) async {
    try {
      await _repository.processInKindLifecycle(
        contributionId: contributionId,
        targetStatus: targetStatus,
        storageLocation: storageLocation,
      );
      if (targetStatus == InKindProcessingStatus.AddedToCommonAssets) {
        final assets = await _repository.getClanAssets();
        if (assets.isNotEmpty) {
          state = state.copyWith(clanAssets: assets);
        }
      }
    } catch (e) {
      debugPrint('API lifecycle update error: $e');
    }

    final updatedList = <InKindElectronicReceiptDto>[];
    InKindElectronicReceiptDto? updatedItem;

    for (final item in state.inKindReceipts) {
      if (item.contributionId == contributionId) {
        final updated = item.copyWith(
          processingStatus: targetStatus,
          storageLocation: storageLocation,
        );
        updatedList.add(updated);
        updatedItem = updated;
      } else {
        updatedList.add(item);
      }
    }

    // Nếu chọn Nhập kho tài sản dòng họ -> Tự động thêm vào danh mục Clan Assets
    var newAssets = List<ClanAssetDto>.from(state.clanAssets);
    if (targetStatus == InKindProcessingStatus.AddedToCommonAssets &&
        updatedItem != null) {
      final randAssetId = 100 + Random().nextInt(900);
      final asset = ClanAssetDto(
        assetId: 'AST-2026-$randAssetId',
        assetName: updatedItem.itemName,
        quantity: updatedItem.quantity.toInt(),
        unit: updatedItem.unit,
        assessedValue: updatedItem.convertedMonetaryValue,
        storageLocation: storageLocation ?? 'Nhà thờ từ đường đại gia tộc',
        originContributionId: updatedItem.contributionId,
        originDonorName: updatedItem.payerMemberName,
        createdAt: DateTime.now(),
      );
      newAssets.insert(0, asset);
    }

    state = state.copyWith(
      inKindReceipts: updatedList,
      clanAssets: newAssets,
    );
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
    final randAssetId = 100 + Random().nextInt(900);
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
