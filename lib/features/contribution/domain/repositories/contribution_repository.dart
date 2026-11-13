import '../../data/models/branch_recursive_contribution_models.dart';
import '../../data/models/contribution_models.dart';

abstract class ContributionRepository {
  Future<BranchRecursiveContributionDto> getRecursiveBranchContributionSummary({
    required String branchId,
    String? eventId,
    int? year,
  });

  Future<double> getRecursiveBranchContributionTotal({
    required String branchId,
    String? eventId,
    int? year,
  });
  Future<ElectronicReceiptDto> recordCashContribution({
    required String eventId,
    required String payerMemberId,
    required double amount,
    required PaymentMethod paymentMethod,
    List<MemberAllocationDto> allocations = const [],
  });

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
  });

  Future<List<ElectronicReceiptDto>> getCashContributionsByEvent({
    required String eventId,
  });

  Future<List<InKindElectronicReceiptDto>> getInKindContributionsByEvent({
    required String eventId,
    InKindProcessingStatus? status,
  });

  Future<InKindElectronicReceiptDto> processInKindLifecycle({
    required String contributionId,
    required InKindProcessingStatus targetStatus,
    String? note,
    String? assetName,
    int? quantity,
    String? unit,
    double? assessedValue,
    String? storageLocation,
  });

  Future<List<ClanAssetDto>> getClanAssets({
    String? keyword,
    int page = 0,
    int size = 50,
  });

  Future<ElectronicReceiptDto> getCashReceiptByNumber(String receiptNumber);

  Future<InKindElectronicReceiptDto> getInKindReceiptByNumber(String receiptNumber);
}
