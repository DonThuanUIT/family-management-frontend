import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/contribution_repository.dart';
import '../datasources/contribution_remote_data_source.dart';
import '../models/contribution_models.dart';

class ContributionRepositoryImpl implements ContributionRepository {
  final ContributionRemoteDataSource _remoteDataSource;

  ContributionRepositoryImpl(this._remoteDataSource);

  @override
  Future<ElectronicReceiptDto> recordCashContribution({
    required String eventId,
    required String payerMemberId,
    required double amount,
    required PaymentMethod paymentMethod,
    List<MemberAllocationDto> allocations = const [],
  }) {
    return _remoteDataSource.recordCashContribution(
      eventId: eventId,
      payerMemberId: payerMemberId,
      amount: amount,
      paymentMethod: paymentMethod,
      allocations: allocations,
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
  }) {
    return _remoteDataSource.recordInKindContribution(
      eventId: eventId,
      payerMemberId: payerMemberId,
      itemName: itemName,
      quantity: quantity,
      unit: unit,
      conversionMethod: conversionMethod,
      convertedMonetaryValue: convertedMonetaryValue,
      benchmarkId: benchmarkId,
      invoiceReference: invoiceReference,
      allocations: allocations,
    );
  }

  @override
  Future<List<ElectronicReceiptDto>> getCashContributionsByEvent({
    required String eventId,
  }) {
    return _remoteDataSource.getCashContributionsByEvent(eventId: eventId);
  }

  @override
  Future<List<InKindElectronicReceiptDto>> getInKindContributionsByEvent({
    required String eventId,
    InKindProcessingStatus? status,
  }) {
    return _remoteDataSource.getInKindContributionsByEvent(
      eventId: eventId,
      status: status,
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
  }) {
    return _remoteDataSource.processInKindLifecycle(
      contributionId: contributionId,
      targetStatus: targetStatus,
      note: note,
      assetName: assetName,
      quantity: quantity,
      unit: unit,
      assessedValue: assessedValue,
      storageLocation: storageLocation,
    );
  }

  @override
  Future<List<ClanAssetDto>> getClanAssets({
    String? keyword,
    int page = 0,
    int size = 50,
  }) {
    return _remoteDataSource.getClanAssets(
      keyword: keyword,
      page: page,
      size: size,
    );
  }

  @override
  Future<ElectronicReceiptDto> getCashReceiptByNumber(String receiptNumber) {
    return _remoteDataSource.getCashReceiptByNumber(receiptNumber);
  }

  @override
  Future<InKindElectronicReceiptDto> getInKindReceiptByNumber(
      String receiptNumber) {
    return _remoteDataSource.getInKindReceiptByNumber(receiptNumber);
  }
}

final contributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  final remote = ref.watch(contributionRemoteDataSourceProvider);
  return ContributionRepositoryImpl(remote);
});
