import 'dart:typed_data';
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

  @override
  Future<MemberContributionHistoryResponseDto> getMyContributionHistory({bool includeFamily = false}) {
    return _remoteDataSource.getMyContributionHistory(includeFamily: includeFamily);
  }

  @override
  Future<Uint8List> downloadReceiptPdf(String receiptNumber) {
    return _remoteDataSource.downloadReceiptPdf(receiptNumber);
  }

  @override
  Future<List<UnreconciledContributionDto>> getUnreconciledContributions({String? eventId}) {
    return _remoteDataSource.getUnreconciledContributions(eventId: eventId);
  }

  @override
  Future<void> reconcileContribution(String contributionId, ReconcileContributionRequestDto request) {
    return _remoteDataSource.reconcileContribution(contributionId, request);
  }

  @override
  Future<void> auditClanAsset(String assetId, AuditClanAssetRequestDto request) {
    return _remoteDataSource.auditClanAsset(assetId, request);
  }

  @override
  Future<List<ClanAssetAuditResponseDto>> getClanAssetAudits(String assetId) {
    return _remoteDataSource.getClanAssetAudits(assetId);
  }

  @override
  Future<VietQrResponseDto> generateVietQr(GenerateVietQrRequestDto request) {
    return _remoteDataSource.generateVietQr(request);
  }

  @override
  Future<EventPendingInKindCheckResponseDto> checkPendingInKindContributions(String eventId) {
    return _remoteDataSource.checkPendingInKindContributions(eventId);
  }

  @override
  Future<ClanBankingInfoDto> getClanBankingInfo() {
    return _remoteDataSource.getClanBankingInfo();
  }

  @override
  Future<ClanBankingInfoDto> updateClanBankingInfo(UpdateClanBankingRequestDto request) {
    return _remoteDataSource.updateClanBankingInfo(request);
  }

  @override
  Future<List<EventItemBenchmarkDto>> getEventItemBenchmarks(String eventId) {
    return _remoteDataSource.getEventItemBenchmarks(eventId);
  }

  @override
  Future<List<EventItemBenchmarkDto>> getAllClanBenchmarks() {
    return _remoteDataSource.getAllClanBenchmarks();
  }

  @override
  Future<EventItemBenchmarkDto> createEventItemBenchmark({
    required String eventId,
    required CreateEventItemBenchmarkRequestDto request,
  }) {
    return _remoteDataSource.createEventItemBenchmark(
      eventId: eventId,
      request: request,
    );
  }

  @override
  Future<void> deleteEventItemBenchmark({
    required String eventId,
    required String benchmarkId,
  }) {
    return _remoteDataSource.deleteEventItemBenchmark(
      eventId: eventId,
      benchmarkId: benchmarkId,
    );
  }

  @override
  Future<Map<String, dynamic>> simulatePaymentWebhook({
    required double amount,
    required String content,
    String? referenceCode,
    List<MemberAllocationDto> allocations = const [],
  }) {
    return _remoteDataSource.simulatePaymentWebhook(
      amount: amount,
      content: content,
      referenceCode: referenceCode,
      allocations: allocations,
    );
  }

  @override
  Future<BranchRecursiveContributionDto> getBranchRecursiveContributionSummary(
    String branchId, {
    String? eventId,
    int? year,
  }) {
    return _remoteDataSource.getBranchRecursiveContributionSummary(
      branchId,
      eventId: eventId,
      year: year,
    );
  }

  @override
  Future<BranchRecursiveContributionDto> getRecursiveBranchContributionSummary({
    required String branchId,
    String? eventId,
    int? year,
  }) {
    return _remoteDataSource.getRecursiveBranchContributionSummary(
      branchId: branchId,
      eventId: eventId,
      year: year,
    );
  }

  @override
  Future<double> getRecursiveBranchContributionTotal({
    required String branchId,
    String? eventId,
    int? year,
  }) {
    return _remoteDataSource.getRecursiveBranchContributionTotal(
      branchId: branchId,
      eventId: eventId,
      year: year,
    );
  }
}

final contributionRepositoryProvider = Provider<ContributionRepository>((ref) {
  final remote = ref.watch(contributionRemoteDataSourceProvider);
  return ContributionRepositoryImpl(remote);
});
