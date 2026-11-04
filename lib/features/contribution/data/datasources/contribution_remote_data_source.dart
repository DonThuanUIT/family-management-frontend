import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/contribution_models.dart';

abstract class ContributionRemoteDataSource {
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
}

final contributionRemoteDataSourceProvider =
    Provider<ContributionRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ContributionRemoteDataSourceImpl(dio);
});
