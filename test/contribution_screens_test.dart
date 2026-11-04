import 'package:familyfund_app/core/theme/app_theme.dart';
import 'package:familyfund_app/features/contribution/data/models/contribution_models.dart';
import 'package:familyfund_app/features/contribution/data/repositories/contribution_repository_impl.dart';
import 'package:familyfund_app/features/contribution/domain/repositories/contribution_repository.dart';
import 'package:familyfund_app/features/contribution/presentation/screens/clan_asset_inventory_screen.dart';
import 'package:familyfund_app/features/contribution/presentation/screens/receive_contribution_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeContributionRepository implements ContributionRepository {
  @override
  Future<List<ElectronicReceiptDto>> getCashContributionsByEvent(
      {required String eventId}) async {
    return [
      ElectronicReceiptDto(
        receiptNumber: 'PT-20260328-09482',
        contributionId: 'CTB-CASH-001',
        eventId: eventId,
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM_TRUONG_TOC',
        payerMemberName: 'Nguyễn Trọng Hoàng',
        receiverAccountId: 'ACC_TRUONG_CHI',
        amount: 10000000,
        amountInWords: 'Mười triệu đồng chẵn',
        paymentMethod: PaymentMethod.BankTransfer,
        contributionDate: DateTime(2026, 3, 28, 8, 30),
      ),
    ];
  }

  @override
  Future<List<InKindElectronicReceiptDto>> getInKindContributionsByEvent({
    required String eventId,
    InKindProcessingStatus? status,
  }) async {
    return [
      InKindElectronicReceiptDto(
        receiptNumber: 'PT-20260328-INK02',
        contributionId: 'CTB-INKIND-002',
        eventId: eventId,
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM_MAI_ANH',
        payerMemberName: 'Nguyễn Thị Mai Anh',
        receiverAccountId: 'ACC_TRUONG_CHI',
        itemName: '10 Mâm xôi gấc & gà trống thiến tế tổ',
        quantity: 10,
        unit: 'mâm',
        conversionMethod: ConversionMethod.BtcBenchmark,
        convertedMonetaryValue: 5000000,
        convertedMonetaryValueInWords: 'Năm triệu đồng chẵn',
        processingStatus: InKindProcessingStatus.Consumed,
        contributionDate: DateTime(2026, 3, 28, 7, 30),
      ),
      InKindElectronicReceiptDto(
        receiptNumber: 'PT-20260328-INK03',
        contributionId: 'CTB-INKIND-003',
        eventId: eventId,
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM_TRUONG_TOC',
        payerMemberName: 'Nguyễn Trọng Hoàng',
        receiverAccountId: 'ACC_TRUONG_CHI',
        itemName: 'Dàn âm thanh loa đài phục vụ tế lễ đại triều',
        quantity: 1,
        unit: 'dàn',
        conversionMethod: ConversionMethod.Agreement,
        convertedMonetaryValue: 8000000,
        convertedMonetaryValueInWords: 'Tám triệu đồng chẵn',
        processingStatus: InKindProcessingStatus.Returned,
        contributionDate: DateTime(2026, 3, 28, 7, 0),
      ),
      InKindElectronicReceiptDto(
        receiptNumber: 'PT-20260328-INK01',
        contributionId: 'CTB-INKIND-001',
        eventId: eventId,
        eventName: 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
        payerMemberId: 'MEM_TRUONG_CHI',
        payerMemberName: 'Nguyễn Văn An',
        receiverAccountId: 'ACC_TRUONG_CHI',
        itemName: 'Bộ đỉnh đồng tam sự chạm khắc song long',
        quantity: 1,
        unit: 'bộ',
        conversionMethod: ConversionMethod.Agreement,
        convertedMonetaryValue: 18000000,
        convertedMonetaryValueInWords: 'Mười tám triệu đồng chẵn',
        processingStatus: InKindProcessingStatus.AddedToCommonAssets,
        contributionDate: DateTime(2026, 3, 28, 8, 0),
      ),
    ];
  }

  @override
  Future<List<ClanAssetDto>> getClanAssets(
      {String? keyword, int page = 0, int size = 50}) async {
    return [
      ClanAssetDto(
        assetId: 'AST-2026-001',
        assetName: 'Bộ đỉnh đồng tam sự chạm khắc song long',
        quantity: 1,
        unit: 'bộ',
        assessedValue: 18000000,
        storageLocation: 'Gian thờ chính - Bàn thờ Cụ Khởi Tổ',
        originContributionId: 'CTB-INKIND-001',
        originDonorName: 'Nguyễn Văn An cúng tiến',
        createdAt: DateTime(2026, 3, 28),
      ),
      ClanAssetDto(
        assetId: 'AST-2026-002',
        assetName: 'Hoành phi câu đối sơn son thếp vàng "Đức Lưu Quang"',
        quantity: 1,
        unit: 'bộ',
        assessedValue: 25000000,
        storageLocation: 'Tiền sảnh Từ Đường Dòng Họ Nguyễn',
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
  }

  @override
  Future<ElectronicReceiptDto> recordCashContribution({
    required String eventId,
    required String payerMemberId,
    required double amount,
    required PaymentMethod paymentMethod,
    List<MemberAllocationDto> allocations = const [],
  }) async {
    return ElectronicReceiptDto(
      receiptNumber: 'PT-20260328-09482',
      contributionId: 'CTB-CASH-001',
      eventId: eventId,
      payerMemberId: payerMemberId,
      receiverAccountId: 'ACC_TRUONG_CHI',
      amount: amount,
      paymentMethod: paymentMethod,
    );
  }

  @override
  Future<InKindElectronicReceiptDto> recordInKindContribution({
    required String eventId,
    required String payerMemberId,
    required String itemName,
    required double quantity,
    required String unit,
    required ConversionMethod conversionMethod,
    required double convertedMonetaryValue,
    String? benchmarkId,
    String? invoiceReference,
    List<MemberAllocationDto> allocations = const [],
  }) async {
    return InKindElectronicReceiptDto(
      receiptNumber: 'PT-20260328-INK01',
      contributionId: 'CTB-INKIND-001',
      eventId: eventId,
      payerMemberId: payerMemberId,
      receiverAccountId: 'ACC_TRUONG_CHI',
      itemName: itemName,
      quantity: quantity,
      unit: unit,
      conversionMethod: conversionMethod,
      convertedMonetaryValue: convertedMonetaryValue,
    );
  }

  @override
  Future<InKindElectronicReceiptDto> processInKindLifecycle({
    required String contributionId,
    required InKindProcessingStatus targetStatus,
    String? note,
    String? assetName,
    int? quantity,
    String? unit,
    double? assessedValue,
    String? storageLocation,
  }) async {
    return InKindElectronicReceiptDto(
      receiptNumber: 'PT-20260328-INK01',
      contributionId: contributionId,
      eventId: 'EVT-GIO-TO-2026',
      payerMemberId: 'MEM_TRUONG_CHI',
      receiverAccountId: 'ACC_TRUONG_CHI',
      itemName: assetName ?? 'Vật phẩm',
      quantity: (quantity ?? 1).toDouble(),
      unit: unit ?? 'món',
      conversionMethod: ConversionMethod.Agreement,
      convertedMonetaryValue: assessedValue ?? 0,
      processingStatus: targetStatus,
    );
  }

  @override
  Future<ElectronicReceiptDto> getCashReceiptByNumber(String receiptNumber) async {
    throw UnimplementedError();
  }

  @override
  Future<InKindElectronicReceiptDto> getInKindReceiptByNumber(
      String receiptNumber) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('renders ReceiveContributionScreen with stats and transactions',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contributionRepositoryProvider
              .overrideWithValue(FakeContributionRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReceiveContributionScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Banners
    expect(find.text('Bàn Tiếp Nhận Đóng Góp & Sổ Cái'), findsOneWidget);
    expect(find.text('Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026'), findsOneWidget);
    expect(find.text('Lập Phiếu Đóng Góp Mới'), findsOneWidget);

    // Verify Stat Cards
    expect(find.text('TỔNG THU TIỀN MẶT / CK'), findsOneWidget);
    expect(find.text('HIỆN VẬT CÚNG TIẾN (QUY ĐỔI)'), findsOneWidget);

    // Verify real seeded transactions
    expect(find.text('PT-20260328-09482'), findsOneWidget);
    expect(find.text('Bộ đỉnh đồng tam sự chạm khắc song long (1.0 bộ)'),
        findsOneWidget);
  });

  testWidgets('renders ClanAssetInventoryScreen and displays assets',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contributionRepositoryProvider
              .overrideWithValue(FakeContributionRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ClanAssetInventoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Kho Bảo Vật & Di Sản Dòng Họ'), findsOneWidget);
    expect(find.text('TỔNG SỐ BẢO VẬT'), findsOneWidget);
    expect(find.text('TỔNG GIÁ TRỊ QUY ĐỔI ƯỚC TÍNH'), findsOneWidget);

    // Verify real asset in the list
    expect(find.text('Bộ đỉnh đồng tam sự chạm khắc song long'), findsOneWidget);
  });

  testWidgets(
      'ClanAssetInventoryScreen displays consumed and returned in-kind history',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contributionRepositoryProvider
              .overrideWithValue(FakeContributionRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ClanAssetInventoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 4 overview cards
    expect(find.text('ĐÃ TIÊU HAO & HOÀN TRẢ'), findsOneWidget);

    // Verify Tab 3 exists
    final tab3Finder = find.textContaining('Nhật Ký Đã Tiêu Hao & Hoàn Trả');
    expect(tab3Finder, findsOneWidget);

    // Switch to Tab 3
    await tester.tap(tab3Finder);
    await tester.pumpAndSettle();

    // Verify audit banner text
    expect(find.textContaining('Lưu Trữ Lịch Sử Vĩnh Viễn'), findsOneWidget);

    // Verify real consumed and returned items exist in Tab 3
    expect(find.textContaining('10 Mâm xôi gấc & gà trống thiến tế tổ'),
        findsOneWidget);
    expect(find.text('ĐÃ TIÊU HAO CHO CỖ BÀN'), findsOneWidget);
    
    expect(find.text('ĐÃ HOÀN TRẢ GIA CHỦ'), findsOneWidget);
  });
}
