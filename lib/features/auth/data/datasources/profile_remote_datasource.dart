import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/profile_models.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileDto> getMyProfile();
  Future<UserProfileDto> updateContactProfile(UpdateContactProfileRequestDto request);
  Future<void> changePassword(ChangePasswordRequestDto request);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSourceImpl(this._dio);

  @override
  Future<UserProfileDto> getMyProfile() async {
    try {
      final response = await _dio.get('profile/me');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserProfileDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải thông tin hồ sơ cá nhân');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Lỗi khi tải thông tin hồ sơ cá nhân'));
    }
  }

  @override
  Future<UserProfileDto> updateContactProfile(
      UpdateContactProfileRequestDto request) async {
    try {
      final response = await _dio.put(
        'profile/me',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserProfileDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không nhận được phản hồi sau khi cập nhật hồ sơ');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Lỗi khi cập nhật thông tin liên lạc'));
    }
  }

  @override
  Future<void> changePassword(ChangePasswordRequestDto request) async {
    try {
      final response = await _dio.post(
        'profile/change-password',
        data: request.toJson(),
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message.isNotEmpty
            ? apiResponse.message
            : 'Đổi mật khẩu không thành công');
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Lỗi khi thực hiện đổi mật khẩu'));
    }
  }

  String _extractErrorMessage(DioException e, String fallback) {
    if (e.response?.data != null && e.response?.data is Map) {
      final map = e.response!.data as Map;
      if (map['errors'] != null && map['errors'] is Map) {
        final errors = map['errors'] as Map;
        if (errors.isNotEmpty) {
          return errors.values.first.toString();
        }
      }
      if (map['message'] != null && map['message'].toString().isNotEmpty) {
        return map['message'].toString();
      }
      if (map['error'] != null) {
        return map['error'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.response == null) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.';
    }
    return e.message ?? fallback;
  }
}

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ProfileRemoteDataSourceImpl(dio);
});
