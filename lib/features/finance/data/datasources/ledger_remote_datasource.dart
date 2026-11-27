import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../models/immutable_ledger_integrity_models.dart';
import '../models/ledger_adjustment_models.dart';
import '../models/ledger_annual_audit_models.dart';

abstract class LedgerRemoteDataSource {
  Future<LedgerHistoryPageModel> searchLedgerHistory({
    String? keyword,
    LedgerTransactionTypeEnum? transactionType,
    bool? onlyWithAdjustments,
    String sortDirection = 'DESC',
    String? from,
    String? to,
    int page = 0,
    int size = 20,
  });

  Future<LedgerIntegrityReportModel> verifyLedgerIntegrity();

  Future<LedgerHistoryItemModel> getTransactionDetail(String transactionId);

  Future<LedgerAdjustmentRequestModel> proposeAdjustment(
    ProposeLedgerAdjustmentRequestDto request,
  );

  Future<List<LedgerAdjustmentRequestModel>> searchAdjustmentRequests({
    String? originalTransactionId,
    LedgerAdjustmentStatusEnum? status,
  });

  Future<LedgerAdjustmentRequestModel> getAdjustmentRequestById(
    String requestId,
  );

  Future<ReviewLedgerAdjustmentResponseModel> reviewAdjustment(
    ReviewLedgerAdjustmentRequestDto request,
  );

  Future<LedgerEvidenceUploadResult> uploadEvidence({
    required Uint8List bytes,
    required String filename,
    String? originalTransactionId,
  });

  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl);

  Future<LedgerAnnualAuditModel> performAnnualAudit(
    AnnualLedgerAuditRequestDto request,
  );

  Future<List<LedgerAnnualAuditModel>> searchAnnualAudits({
    int? auditYear,
    LedgerAnnualAuditStatusEnum? status,
  });

  Future<LedgerAnnualAuditModel> getAnnualAuditById(String auditId);
}

class LedgerRemoteDataSourceImpl implements LedgerRemoteDataSource {
  static final RegExp _proxyPathPattern = RegExp(
    r'^(?:https?://[^/]+)?(?:/api(?:/v1)?)?/ledger/evidence/([a-fA-F0-9-]{36}\.(?:jpg|png|pdf))$',
  );

  final Dio _dio;

  LedgerRemoteDataSourceImpl(this._dio);

  @override
  Future<LedgerHistoryPageModel> searchLedgerHistory({
    String? keyword,
    LedgerTransactionTypeEnum? transactionType,
    bool? onlyWithAdjustments,
    String sortDirection = 'DESC',
    String? from,
    String? to,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final normalizedSort =
          sortDirection.trim().toUpperCase() == 'ASC' ? 'ASC' : 'DESC';
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
        'sortDirection': normalizedSort,
      };
      if (keyword != null && keyword.trim().isNotEmpty) {
        queryParams['keyword'] = keyword.trim();
      }
      if (transactionType != null) {
        queryParams['transactionType'] = transactionType.code;
      }
      if (onlyWithAdjustments != null) {
        queryParams['onlyWithAdjustments'] = onlyWithAdjustments;
      }
      if (from != null && from.trim().isNotEmpty) {
        queryParams['from'] = from.trim();
      }
      if (to != null && to.trim().isNotEmpty) {
        queryParams['to'] = to.trim();
      }

      final response = await _dio.get('ledger', queryParameters: queryParams);
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Dữ liệu tra cứu Sổ cái không hợp lệ',
      );
      return LedgerHistoryPageModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<LedgerIntegrityReportModel> verifyLedgerIntegrity() async {
    try {
      final response = await _dio.get('ledger/verify-integrity');
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Dữ liệu kiểm toán chuỗi SHA-256 Sổ cái không hợp lệ',
      );
      return LedgerIntegrityReportModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<LedgerHistoryItemModel> getTransactionDetail(
    String transactionId,
  ) async {
    try {
      final response = await _dio.get(
        'ledger/transactions/${Uri.encodeComponent(transactionId.trim())}',
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Không tìm thấy chi tiết giao dịch $transactionId',
      );
      return LedgerHistoryItemModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<LedgerAdjustmentRequestModel> proposeAdjustment(
    ProposeLedgerAdjustmentRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        'ledger/propose-adjustment',
        data: request.toJson(),
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Dữ liệu phản hồi tạo đề xuất bù trừ không hợp lệ',
      );
      return LedgerAdjustmentRequestModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<List<LedgerAdjustmentRequestModel>> searchAdjustmentRequests({
    String? originalTransactionId,
    LedgerAdjustmentStatusEnum? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (originalTransactionId != null &&
          originalTransactionId.trim().isNotEmpty) {
        queryParams['originalTransactionId'] = originalTransactionId.trim();
      }
      if (status != null) {
        queryParams['status'] = status.code;
      }

      final response = await _dio.get(
        'ledger/adjustments',
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
          .map(LedgerAdjustmentRequestModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<LedgerAdjustmentRequestModel> getAdjustmentRequestById(
    String requestId,
  ) async {
    try {
      final response = await _dio.get(
        'ledger/adjustments/${Uri.encodeComponent(requestId.trim())}',
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Không tìm thấy đề xuất điều chỉnh $requestId',
      );
      return LedgerAdjustmentRequestModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<ReviewLedgerAdjustmentResponseModel> reviewAdjustment(
    ReviewLedgerAdjustmentRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        'ledger/review-adjustment',
        data: request.toJson(),
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Dữ liệu phản hồi thẩm định đề xuất không hợp lệ',
      );
      return ReviewLedgerAdjustmentResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<LedgerEvidenceUploadResult> uploadEvidence({
    required Uint8List bytes,
    required String filename,
    String? originalTransactionId,
  }) async {
    try {
      final mimeType = _resolveMimeType(filename);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final queryParams = <String, dynamic>{};
      if (originalTransactionId != null &&
          originalTransactionId.trim().isNotEmpty) {
        queryParams['originalTransactionId'] = originalTransactionId.trim();
      }

      final response = await _dio.post(
        'ledger/evidence-upload',
        data: formData,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Dữ liệu phản hồi tải lên biên bản không hợp lệ',
      );
      return LedgerEvidenceUploadResult.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl) async {
    final fileName = extractInternalEvidenceFilename(evidenceUrl);
    if (fileName == null) {
      throw const MediaFailure(
        code: 'INVALID_EVIDENCE_URL',
        message: 'Đường dẫn biên bản không thuộc kho lưu trữ nội bộ.',
      );
    }
    try {
      final response = await _dio.get<List<int>>(
        'ledger/evidence/$fileName',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
          headers: const {'Accept': 'application/octet-stream'},
        ),
      );
      final raw = response.data;
      if (raw == null || raw.isEmpty) {
        throw const MediaFailure(
          code: 'EMPTY_EVIDENCE_FILE',
          message: 'Không nhận được dữ liệu tệp biên bản.',
        );
      }
      return Uint8List.fromList(raw);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<LedgerAnnualAuditModel> performAnnualAudit(
    AnnualLedgerAuditRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        'ledger/annual-audit',
        data: request.toJson(),
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Dữ liệu phản hồi kiểm kê quỹ hằng năm không hợp lệ',
      );
      return LedgerAnnualAuditModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<List<LedgerAnnualAuditModel>> searchAnnualAudits({
    int? auditYear,
    LedgerAnnualAuditStatusEnum? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (auditYear != null) {
        queryParams['auditYear'] = auditYear;
      }
      if (status != null) {
        queryParams['status'] = status.code;
      }

      final response = await _dio.get(
        'ledger/annual-audits',
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
          .map(LedgerAnnualAuditModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<LedgerAnnualAuditModel> getAnnualAuditById(String auditId) async {
    try {
      final response = await _dio.get(
        'ledger/annual-audits/${Uri.encodeComponent(auditId.trim())}',
      );
      final data = _unwrapDataMap(
        response.data,
        fallbackMessage: 'Không tìm thấy biên bản kiểm kê $auditId',
      );
      return LedgerAnnualAuditModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Trích xuất tên file an toàn nếu [evidenceUrl] là đường dẫn proxy nội bộ của hệ thống.
  static String? extractInternalEvidenceFilename(String? evidenceUrl) {
    if (evidenceUrl == null || evidenceUrl.trim().isEmpty) return null;
    final match = _proxyPathPattern.firstMatch(evidenceUrl.trim());
    return match?.group(1);
  }

  static String _resolveMimeType(String filename) {
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
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
    String? errorCode;

    if (body is Map<String, dynamic>) {
      final rawMsg = body['message'];
      if (rawMsg is String && rawMsg.trim().isNotEmpty) {
        serverMessage = rawMsg.trim();
      }
      final rawCode = body['errorCode'] ?? body['code'];
      if (rawCode is String && rawCode.trim().isNotEmpty) {
        errorCode = rawCode.trim();
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
        message: serverMessage ?? 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ.',
      );
    }
    if (statusCode == 403) {
      return ForbiddenFailure(
        message:
            serverMessage ?? 'Bạn không có quyền thực hiện thao tác Sổ cái này.',
      );
    }
    if (statusCode == 400 || statusCode == 404 || statusCode == 409) {
      return BusinessInvariantFailure(
        message: serverMessage ?? 'Dữ liệu yêu cầu không hợp lệ.',
        statusCode: statusCode ?? 400,
      );
    }
    if (statusCode == 413 || statusCode == 415 || errorCode != null) {
      return MediaFailure(
        code: errorCode ?? 'MEDIA_ERROR',
        message: serverMessage ?? 'Tệp biên bản không hợp lệ hoặc vượt dung lượng cho phép.',
        statusCode: statusCode,
      );
    }
    return ServerFailure(
      message: serverMessage ?? 'Lỗi máy chủ khi xử lý Sổ cái (${statusCode ?? 'N/A'}).',
      statusCode: statusCode,
    );
  }
}

final ledgerRemoteDataSourceProvider = Provider<LedgerRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return LedgerRemoteDataSourceImpl(dio);
});
