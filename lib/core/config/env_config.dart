import 'package:flutter/foundation.dart';

/// Cấu hình môi trường chạy cho cả Web App và Mobile App (Android / iOS).
class EnvConfig {
  EnvConfig._();

  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Tự động phân giải Base URL phù hợp với Web (`localhost:8080`)
  /// hoặc Android Emulator (`10.0.2.2:8080`).
  static String get apiBaseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl.endsWith('/') ? _definedBaseUrl : '$_definedBaseUrl/';
    }
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1/';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1/';
    }
    return 'http://localhost:8080/api/v1/';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
