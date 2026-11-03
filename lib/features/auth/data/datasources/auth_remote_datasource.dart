import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_models.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource(this._dio);

  Future<AuthTokenResponseDto> login(LoginRequestDto request) async {
    try {
      final response = await _dio.post(
        'auth/login',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AuthTokenResponseDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Đăng nhập không thành công');
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw Exception(message);
    }
  }

  Future<void> registerCreator(RegisterCreatorRequestDto request) async {
    try {
      final response = await _dio.post(
        'auth/register-creator',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (!apiResponse.isSuccess) {
        throw Exception(apiResponse.message);
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<InviteCodePreviewDto> previewInvite(String inviteCode) async {
    try {
      final response = await _dio.get(
        'invitations/${inviteCode.trim()}',
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => InviteCodePreviewDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không tìm thấy thông tin mã mời');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<OnboardingBranchTreeNodeDto> getOnboardingBranchTree(String inviteCode) async {
    try {
      final response = await _dio.get(
        'invitations/${inviteCode.trim()}/tree',
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => OnboardingBranchTreeNodeDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không tìm thấy thông tin cây gia phả thu gọn');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<JoinRequestResponseDto> registerMember(RegisterMemberRequestDto request) async {
    try {
      final response = await _dio.post(
        'invitations/${request.inviteCode.trim()}/join',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => JoinRequestResponseDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Gửi đề xuất gia nhập dòng họ không thành công');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  String _extractErrorMessage(DioException e) {
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
    return e.message ?? 'Đã có lỗi xảy ra trong quá trình kết nối';
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dio);
});
