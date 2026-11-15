import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/advance_voucher_models.dart';

abstract class AdvanceVoucherRemoteDataSource {
  Future<AdvanceVoucherModel> createAdvanceVoucher(
      CreateAdvanceVoucherRequestDto request);

  Future<AdvanceVoucherModel> confirmDisbursement(
    String advanceVoucherId,
    ConfirmDisbursementRequestDto request,
  );

  Future<List<AdvanceVoucherModel>> getAdvanceVouchers({
    String? eventId,
    String? taskId,
    String? recipientMemberId,
    AdvanceVoucherStatusEnum? status,
  });

  Future<AdvanceVoucherModel> getAdvanceVoucherDetail(String advanceVoucherId);
}

final advanceVoucherRemoteDataSourceProvider =
    Provider<AdvanceVoucherRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AdvanceVoucherRemoteDataSourceImpl(dio);
});

class AdvanceVoucherRemoteDataSourceImpl
    implements AdvanceVoucherRemoteDataSource {
  final Dio _dio;

  const AdvanceVoucherRemoteDataSourceImpl(this._dio);

  @override
  Future<AdvanceVoucherModel> createAdvanceVoucher(
      CreateAdvanceVoucherRequestDto request) async {
    final response = await _dio.post(
      '/advances',
      data: request.toJson(),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return AdvanceVoucherModel.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return AdvanceVoucherModel.fromJson(data);
    }
    throw Exception('Phản hồi không hợp lệ từ máy chủ khi lập phiếu tạm ứng');
  }

  @override
  Future<AdvanceVoucherModel> confirmDisbursement(
    String advanceVoucherId,
    ConfirmDisbursementRequestDto request,
  ) async {
    final response = await _dio.post(
      '/advances/$advanceVoucherId/disburse',
      data: request.toJson(),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return AdvanceVoucherModel.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return AdvanceVoucherModel.fromJson(data);
    }
    throw Exception('Phản hồi không hợp lệ từ máy chủ khi giải ngân tạm ứng');
  }

  @override
  Future<List<AdvanceVoucherModel>> getAdvanceVouchers({
    String? eventId,
    String? taskId,
    String? recipientMemberId,
    AdvanceVoucherStatusEnum? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (eventId != null && eventId.trim().isNotEmpty) {
      queryParams['eventId'] = eventId.trim();
    }
    if (taskId != null && taskId.trim().isNotEmpty) {
      queryParams['taskId'] = taskId.trim();
    }
    if (recipientMemberId != null && recipientMemberId.trim().isNotEmpty) {
      queryParams['recipientMemberId'] = recipientMemberId.trim();
    }
    if (status != null) {
      queryParams['status'] = status.code;
    }

    final response = await _dio.get(
      '/advances',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data;
    List<dynamic> items = [];
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        items = inner;
      } else if (inner is Map<String, dynamic> && inner['content'] is List) {
        items = inner['content'] as List;
      }
    } else if (data is List) {
      items = data;
    }

    return items
        .map((e) => AdvanceVoucherModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdvanceVoucherModel> getAdvanceVoucherDetail(
      String advanceVoucherId) async {
    final response = await _dio.get('/advances/$advanceVoucherId');

    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return AdvanceVoucherModel.fromJson(
            data['data'] as Map<String, dynamic>);
      }
      return AdvanceVoucherModel.fromJson(data);
    }
    throw Exception(
        'Không tìm thấy thông tin chi tiết phiếu tạm ứng $advanceVoucherId');
  }
}
