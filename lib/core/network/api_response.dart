/// Chuẩn hóa cấu trúc phản hồi REST API từ Backend Spring Boot
/// theo quy chuẩn `.antigravityrules`: `code`, `message`, `data`, `timestamp`.
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final DateTime timestamp;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
    required this.timestamp,
  });

  bool get isSuccess => code >= 200 && code < 300;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      code: (json['code'] as num?)?.toInt() ?? 200,
      message: (json['message'] as String?) ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
