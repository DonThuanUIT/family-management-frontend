import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/contribution_models.dart';

abstract class ContributionRemoteDataSource {
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

  Future<MemberContributionHistoryResponseDto> getMyContributionHistory({bool includeFamily = false});

  Future<Uint8List> downloadReceiptPdf(String receiptNumber);

  Future<List<UnreconciledContributionDto>> getUnreconciledContributions({String? eventId});

  Future<void> reconcileContribution(String contributionId, ReconcileContributionRequestDto request);

  Future<void> auditClanAsset(String assetId, AuditClanAssetRequestDto request);

  Future<List<ClanAssetAuditResponseDto>> getClanAssetAudits(String assetId);

  Future<VietQrResponseDto> generateVietQr(GenerateVietQrRequestDto request);

  Future<EventPendingInKindCheckResponseDto> checkPendingInKindContributions(String eventId);

  Future<ClanBankingInfoDto> getClanBankingInfo();
  Future<ClanBankingInfoDto> updateClanBankingInfo(UpdateClanBankingRequestDto request);

  Future<List<EventItemBenchmarkDto>> getEventItemBenchmarks(String eventId);
  Future<List<EventItemBenchmarkDto>> getAllClanBenchmarks();
  Future<EventItemBenchmarkDto> createEventItemBenchmark({
    required String eventId,
    required CreateEventItemBenchmarkRequestDto request,
  });
  Future<void> deleteEventItemBenchmark({
    required String eventId,
    required String benchmarkId,
  });

  Future<Map<String, dynamic>> simulatePaymentWebhook({
    required double amount,
    required String content,
    String? referenceCode,
    List<MemberAllocationDto> allocations = const [],
  });

  Future<BranchRecursiveContributionDto> getBranchRecursiveContributionSummary(
    String branchId, {
    String? eventId,
    int? year,
  });
}

class ContributionRemoteDataSourceImpl implements ContributionRemoteDataSource {
  final Dio _dio;

  ContributionRemoteDataSourceImpl(this._dio);

  @override
  Future<ElectronicReceiptDto> recordCashContribution({
    required String eventId,
    required String payerMemberId,
    required double amount,
    required PaymentMethod paymentMethod,
    List<MemberAllocationDto> allocations = const [],
  }) async {
    final payload = {
      'eventId': eventId,
      'payerMemberId': payerMemberId,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'allocations': allocations.map((e) => e.toJson()).toList(),
    };

    final response = await _dio.post(
      'contributions/cash',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return ElectronicReceiptDto.fromJson(data);
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
    final payload = {
      'eventId': eventId,
      'payerMemberId': payerMemberId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'conversionMethod': conversionMethod.name,
      'convertedMonetaryValue': convertedMonetaryValue,
      'benchmarkId': benchmarkId,
      'invoiceReference': invoiceReference,
      'allocations': allocations.map((e) => e.toJson()).toList(),
    };

    final response = await _dio.post(
      'contributions/in-kind',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return InKindElectronicReceiptDto.fromJson(data);
  }

  @override
  Future<List<ElectronicReceiptDto>> getCashContributionsByEvent({
    required String eventId,
  }) async {
    final response = await _dio.get('contributions/cash/events/$eventId');
    final rawList = response.data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => ElectronicReceiptDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<InKindElectronicReceiptDto>> getInKindContributionsByEvent({
    required String eventId,
    InKindProcessingStatus? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) {
      queryParams['status'] = status.name;
    }

    final response = await _dio.get(
      'contributions/in-kind/events/$eventId',
      queryParameters: queryParams,
    );

    final rawList = response.data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => InKindElectronicReceiptDto.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final payload = {
      'targetStatus': targetStatus.name,
      'note': note,
      'assetName': assetName,
      'quantity': quantity,
      'unit': unit,
      'assessedValue': assessedValue,
      'storageLocation': storageLocation,
    };

    final response = await _dio.put(
      'contributions/in-kind/$contributionId/lifecycle',
      data: payload,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    // Trả về DTO đã cập nhật
    return InKindElectronicReceiptDto.fromJson(data);
  }

  @override
  Future<List<ClanAssetDto>> getClanAssets({
    String? keyword,
    int page = 0,
    int size = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    final response = await _dio.get(
      'clan-assets',
      queryParameters: queryParams,
    );

    final data = response.data['data'] as Map<String, dynamic>?;
    final content = data?['content'] as List<dynamic>? ?? [];
    return content
        .map((e) => ClanAssetDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ElectronicReceiptDto> getCashReceiptByNumber(String receiptNumber) async {
    final response = await _dio.get('contributions/cash/receipts/$receiptNumber');
    final data = response.data['data'] as Map<String, dynamic>;
    return ElectronicReceiptDto.fromJson(data);
  }

  @override
  Future<InKindElectronicReceiptDto> getInKindReceiptByNumber(
      String receiptNumber) async {
    final response =
        await _dio.get('contributions/in-kind/receipts/$receiptNumber');
    final data = response.data['data'] as Map<String, dynamic>;
    return InKindElectronicReceiptDto.fromJson(data);
  }

  @override
  Future<MemberContributionHistoryResponseDto> getMyContributionHistory({bool includeFamily = false}) async {
    final response = await _dio.get(
      'contributions/my-history',
      queryParameters: {'includeFamily': includeFamily},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return MemberContributionHistoryResponseDto.fromJson(data);
  }

  @override
  Future<Uint8List> downloadReceiptPdf(String receiptNumber) async {
    final response = await _dio.get<List<int>>(
      'contributions/receipts/$receiptNumber/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  @override
  Future<List<UnreconciledContributionDto>> getUnreconciledContributions({String? eventId}) async {
    final queryParams = <String, dynamic>{};
    if (eventId != null && eventId.isNotEmpty) {
      queryParams['eventId'] = eventId;
    }
    final response = await _dio.get(
      'contributions/cash/unreconciled',
      queryParameters: queryParams,
    );
    final rawList = response.data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => UnreconciledContributionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> reconcileContribution(String contributionId, ReconcileContributionRequestDto request) async {
    await _dio.put(
      'contributions/cash/$contributionId/reconcile',
      data: request.toJson(),
    );
  }

  @override
  Future<void> auditClanAsset(String assetId, AuditClanAssetRequestDto request) async {
    await _dio.put(
      'clan-assets/$assetId/audit',
      data: request.toJson(),
    );
  }

  @override
  Future<List<ClanAssetAuditResponseDto>> getClanAssetAudits(String assetId) async {
    final response = await _dio.get('clan-assets/$assetId/audits');
    final rawList = response.data['data'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => ClanAssetAuditResponseDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<VietQrResponseDto> generateVietQr(GenerateVietQrRequestDto request) async {
    final response = await _dio.post(
      'contributions/vietqr/generate',
      data: request.toJson(),
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return VietQrResponseDto.fromJson(data);
  }

  @override
  Future<EventPendingInKindCheckResponseDto> checkPendingInKindContributions(String eventId) async {
    final response = await _dio.get('contributions/in-kind/events/$eventId/pending-check');
    final data = response.data['data'] as Map<String, dynamic>;
    return EventPendingInKindCheckResponseDto.fromJson(data);
  }

  @override
  Future<ClanBankingInfoDto> getClanBankingInfo() async {
    final response = await _dio.get('clans/banking-info');
    final data = response.data['data'] as Map<String, dynamic>;
    return ClanBankingInfoDto.fromJson(data);
  }

  @override
  Future<ClanBankingInfoDto> updateClanBankingInfo(UpdateClanBankingRequestDto request) async {
    final response = await _dio.put('clans/banking-info', data: request.toJson());
    final data = response.data['data'] as Map<String, dynamic>;
    return ClanBankingInfoDto.fromJson(data);
  }

  @override
  Future<List<EventItemBenchmarkDto>> getEventItemBenchmarks(String eventId) async {
    final response = await _dio.get('events/$eventId/benchmarks');
    final list = (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => EventItemBenchmarkDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<List<EventItemBenchmarkDto>> getAllClanBenchmarks() async {
    final response = await _dio.get('benchmarks');
    final list = (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => EventItemBenchmarkDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  @override
  Future<EventItemBenchmarkDto> createEventItemBenchmark({
    required String eventId,
    required CreateEventItemBenchmarkRequestDto request,
  }) async {
    final response = await _dio.post('events/$eventId/benchmarks', data: request.toJson());
    final data = response.data['data'] as Map<String, dynamic>;
    return EventItemBenchmarkDto.fromJson(data);
  }

  @override
  Future<void> deleteEventItemBenchmark({
    required String eventId,
    required String benchmarkId,
  }) async {
    await _dio.delete('events/$eventId/benchmarks/$benchmarkId');
  }

  @override
  Future<Map<String, dynamic>> simulatePaymentWebhook({
    required double amount,
    required String content,
    String? referenceCode,
    List<MemberAllocationDto> allocations = const [],
  }) async {
    final payload = {
      'transferAmount': amount,
      'content': content,
      'referenceCode': referenceCode ?? 'DEV_SIM_${DateTime.now().millisecondsSinceEpoch}',
      if (allocations.isNotEmpty)
        'allocations': allocations.map((e) => e.toJson()).toList(),
    };
    final response = await _dio.post('contributions/vietqr/webhook', data: payload);
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<BranchRecursiveContributionDto> getBranchRecursiveContributionSummary(
    String branchId, {
    String? eventId,
    int? year,
  }) {
    return getRecursiveBranchContributionSummary(
      branchId: branchId,
      eventId: eventId,
      year: year,
    );
  }

  @override
  Future<BranchRecursiveContributionDto> getRecursiveBranchContributionSummary({
    required String branchId,
    String? eventId,
    int? year,
  }) async {
    final queryParams = <String, dynamic>{};
    if (eventId != null && eventId.trim().isNotEmpty) {
      queryParams['eventId'] = eventId.trim();
    }
    if (year != null && year > 0) {
      queryParams['year'] = year;
    }

    final response = await _dio.get(
      'contributions/branches/$branchId/recursive-summary',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return BranchRecursiveContributionDto.fromJson(data);
  }

  @override
  Future<double> getRecursiveBranchContributionTotal({
    required String branchId,
    String? eventId,
    int? year,
  }) async {
    final queryParams = <String, dynamic>{};
    if (eventId != null && eventId.trim().isNotEmpty) {
      queryParams['eventId'] = eventId.trim();
    }
    if (year != null && year > 0) {
      queryParams['year'] = year;
    }

    final response = await _dio.get(
      'contributions/branches/$branchId/recursive-total',
      queryParameters: queryParams,
    );
    final numVal = response.data['data'];
    return ((numVal ?? 0) as num).toDouble();
  }
}

final contributionRemoteDataSourceProvider =
    Provider<ContributionRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ContributionRemoteDataSourceImpl(dio);
});
