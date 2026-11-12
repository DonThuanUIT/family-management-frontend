import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/repositories/member_media_repository.dart';

class MemberMediaRemoteDataSource {
  final Dio dio;
  MemberMediaRemoteDataSource(this.dio);

  // Only construct API-relative routes. Never forward credentials to contentUrl.
  String path(String member, [String suffix = '']) =>
      'members/${Uri.encodeComponent(member)}$suffix';

  Future<dynamic> send(
    String member,
    MediaRequest request, {
    String suffix = '',
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? query,
    String? idempotencyKey,
    bool binary = false,
    void Function(int, int)? progress,
  }) async {
    final cancel = CancelToken();
    request.cancelTransport = () => cancel.cancel();
    if (request.cancelled) cancel.cancel();
    final response = await dio.request<dynamic>(
      path(member, suffix),
      data: data,
      queryParameters: query,
      cancelToken: cancel,
      onSendProgress: progress,
      options: Options(
        method: method,
        responseType: binary ? ResponseType.bytes : ResponseType.json,
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        contentType: data is FormData
            ? 'multipart/form-data'
            : 'application/json',
        headers: {
          'Idempotency-Key': ?idempotencyKey,
          if (binary) 'Accept': 'application/octet-stream',
        },
      ),
    );
    if (binary) return Uint8List.fromList((response.data as List).cast<int>());
    if (response.statusCode == 204) return null;
    final body = response.data;
    if (body is! Map || body['success'] != true || body['data'] is! Map) {
      throw const FormatException('Invalid member media response');
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }
}
