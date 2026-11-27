import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/common_fund_disbursement_models.dart';

abstract class CommonFundDisbursementRemoteDataSource {
  Future<CommonFundBalanceModel> getFundBalance();

  Future<CommonFundDisbursementModel> proposeDisbursement(
    ProposeCommonFundDisbursementRequestDto request,
  );

  Future<List<CommonFundDisbursementModel>> searchDisbursements({
    CommonFundDisbursementStatusEnum? status,
    CommonFundExpenseCategoryEnum? category,
  });

  Future<CommonFundDisbursementModel> getDisbursementById(String requestId);

  Future<ReviewCommonFundDisbursementResponseModel> reviewDisbursement(
    String requestId,
    ReviewCommonFundDisbursementRequestDto request,
  );
}

class CommonFundDisbursementRemoteDataSourceImpl
    implements CommonFundDisbursementRemoteDataSource {
  final Dio _dio;

  CommonFundDisbursementRemoteDataSourceImpl(this._dio);

  @override
  Future<CommonFundBalanceModel> getFundBalance() async {
    try {
      final response = await _dio.get('ledger/balance');
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Không thể đọc số dư khả dụng Quỹ chung.',
      );
      return CommonFundBalanceModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<CommonFundDisbursementModel> proposeDisbursement(
    ProposeCommonFundDisbursementRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        'ledger/disbursements',
        data: request.toJson(),
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Dữ liệu phản hồi tạo đề xuất chi Quỹ chung không hợp lệ.',
      );
      return CommonFundDisbursementModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<List<CommonFundDisbursementModel>> searchDisbursements({
    CommonFundDisbursementStatusEnum? status,
    CommonFundExpenseCategoryEnum? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status.code;
      }
      if (category != null) {
        queryParams['category'] = category.code;
      }

      final response = await _dio.get(
        'ledger/disbursements',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final body = response.data;
      List<dynamic> items = const [];
      if (body is Map<String, dynamic> && body['data'] is List) {
        items = body['data'] as List<dynamic>;
      } else if (body is List) {
        items = body;
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(CommonFundDisbursementModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<CommonFundDisbursementModel> getDisbursementById(
    String requestId,
  ) async {
    try {
      final response = await _dio.get(
        'ledger/disbursements/${Uri.encodeComponent(requestId.trim())}',
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Không tìm thấy đề xuất chi Quỹ chung $requestId.',
      );
      return CommonFundDisbursementModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<ReviewCommonFundDisbursementResponseModel> reviewDisbursement(
    String requestId,
    ReviewCommonFundDisbursementRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        'ledger/disbursements/${Uri.encodeComponent(requestId.trim())}/review',
        data: request.toJson(),
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Dữ liệu phản hồi ký duyệt chi Quỹ chung không hợp lệ.',
      );
      return ReviewCommonFundDisbursementResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Map<String, dynamic> _unwrapDataMap(
    dynamic body, {
    required String fallbackMessage,
  }) {
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) {
        return body['data'] as Map<String, dynamic>;
      }
      return body;
    }
    throw ServerFailure(message: fallbackMessage);
  }

  Failure _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    String? serverMessage;

    if (body is Map<String, dynamic>) {
      final rawMsg = body['message'];
      if (rawMsg is String && rawMsg.trim().isNotEmpty) {
        serverMessage = rawMsg.trim();
      }
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final details = errors.values.whereType<String>().join('; ');
        if (details.isNotEmpty) {
          serverMessage = details;
        }
      }
    }

    if (statusCode == 401) {
      return UnauthorizedFailure(
        message:
            serverMessage ?? 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ.',
      );
    }
    if (statusCode == 403) {
      return ForbiddenFailure(
        message:
            serverMessage ?? 'Bạn không có quyền thực hiện thao tác chi Quỹ chung này.',
      );
    }
    if (statusCode == 400 || statusCode == 404 || statusCode == 409) {
      return BusinessInvariantFailure(
        message: serverMessage ?? 'Dữ liệu yêu cầu chi Quỹ chung không hợp lệ.',
        statusCode: statusCode ?? 400,
      );
    }
    return ServerFailure(
      message: serverMessage ??
          'Lỗi máy chủ khi xử lý chi Quỹ chung (${statusCode ?? 'N/A'}).',
      statusCode: statusCode,
    );
  }
}

final commonFundDisbursementRemoteDataSourceProvider =
    Provider<CommonFundDisbursementRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CommonFundDisbursementRemoteDataSourceImpl(dio);
});
