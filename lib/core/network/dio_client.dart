import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env_config.dart';
import '../storage/secure_token_storage.dart';

/// Interceptor tự động đính kèm JWT Token vào Header `Authorization`
/// và xử lý thống nhất cấu trúc `ApiResponse<T>` từ Spring Boot Backend.
class AuthInterceptor extends Interceptor {
  final SecureTokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final clanId = await _tokenStorage.getActiveClanId();
    if (clanId != null && clanId.isNotEmpty) {
      options.headers['X-Clan-Id'] = clanId;
    }
    handler.next(options);
  }
}

final dioClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(secureTokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: EnvConfig.connectTimeout,
      receiveTimeout: EnvConfig.receiveTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(AuthInterceptor(tokenStorage));
  return dio;
});
