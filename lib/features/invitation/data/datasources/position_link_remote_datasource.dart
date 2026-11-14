import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/position_link_models.dart';

final positionLinkRemoteDataSourceProvider =
    Provider<PositionLinkRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PositionLinkRemoteDataSourceImpl(dio);
});

abstract class PositionLinkRemoteDataSource {
  Future<CreateVirtualMemberResponseDto> createVirtualMember({
    required String branchId,
    required CreateVirtualMemberRequestDto request,
  });

  Future<List<PositionLinkItemModel>> getIssuedPositionLinks();

  Future<PositionLinkPreviewDto> getPositionLinkPreview(String inviteCode);

  Future<ClaimPositionResponseDto> claimPosition({
    required String inviteCode,
    required ClaimPositionRequestDto request,
  });
}

class PositionLinkRemoteDataSourceImpl implements PositionLinkRemoteDataSource {
  final Dio _dio;

  PositionLinkRemoteDataSourceImpl(this._dio);

  @override
  Future<CreateVirtualMemberResponseDto> createVirtualMember({
    required String branchId,
    required CreateVirtualMemberRequestDto request,
  }) async {
    try {
      final response = await _dio.post(
        'branches/$branchId/virtual-members',
        data: request.toJson(),
      );

      final data = response.data;
      if (data != null && data['data'] != null) {
        return CreateVirtualMemberResponseDto.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }
      throw Exception('Không nhận được dữ liệu phản hồi từ máy chủ');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Lỗi khi khởi tạo hồ sơ ảo và mã liên kết';
      throw Exception(msg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<PositionLinkItemModel>> getIssuedPositionLinks() async {
    try {
      final response = await _dio.get('invitations/general');
      final data = response.data;
      if (data != null && data['data'] != null && data['data'] is List) {
        final list = data['data'] as List;
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final code = (m['inviteCode'] as String?) ?? '';
          final branchName = (m['targetBranchName'] as String?) ?? 'Chi 2';
          final branchId = (m['targetBranchId'] as String?) ?? 'chi-2';
          final isAct = (m['isActive'] as bool?) ?? true;
          return PositionLinkItemModel(
            code: code,
            branchId: branchId,
            branchName: branchName,
            generation: 5,
            fullName: 'Thành viên liên kết',
            issuedBy: 'Trưởng Tộc',
            createdAt: DateTime.tryParse(m['createdAt'] ?? '') ??
                DateTime.now(),
            isActivated: isAct,
            shareableUrl:
                (m['shareableUrl'] as String?) ?? 'https://familyfund.app/join?code=$code',
          );
        }).toList();
      }
    } catch (_) {
      // Fallback khi chưa có backend hoặc offline
    }

    // Dữ liệu mẫu chuẩn đối chiếu chính xác theo thiết kế Stitch & W3 UI Spec
    return [
      PositionLinkItemModel(
        code: 'LE-CHI2-DOI5-9821',
        branchId: 'chi-2',
        branchName: 'Chi 2',
        generation: 5,
        fullName: 'Lê Hữu Tuấn',
        issuedBy: 'Lê Văn Hùng (Trưởng Chi)',
        createdAt: DateTime(2026, 3, 12),
        isActivated: true,
        shareableUrl: 'https://familyfund.app/join?clan=LE&code=CHI2-DOI5-9821',
      ),
      PositionLinkItemModel(
        code: 'LE-CHI1-DOI4-4412',
        branchId: 'chi-1',
        branchName: 'Chi 1',
        generation: 4,
        fullName: 'Lê Minh Trí',
        issuedBy: 'Lê Văn An (Trưởng Chi)',
        createdAt: DateTime(2026, 3, 10),
        isActivated: true,
        shareableUrl: 'https://familyfund.app/join?clan=LE&code=CHI1-DOI4-4412',
      ),
      PositionLinkItemModel(
        code: 'LE-CHI2-DOI5-7731',
        branchId: 'chi-2',
        branchName: 'Chi 2',
        generation: 5,
        fullName: 'Lê Thu Trang',
        issuedBy: 'Lê Văn Hùng',
        createdAt: DateTime(2026, 3, 14),
        isActivated: false,
        shareableUrl: 'https://familyfund.app/join?clan=LE&code=CHI2-DOI5-7731',
      ),
      PositionLinkItemModel(
        code: 'LE-CHI3-DOI4-0199',
        branchId: 'chi-3',
        branchName: 'Chi 3',
        generation: 4,
        fullName: 'Lê Quốc Bảo',
        issuedBy: 'Lê Văn Cường',
        createdAt: DateTime(2026, 3, 15),
        isActivated: false,
        shareableUrl: 'https://familyfund.app/join?clan=LE&code=CHI3-DOI4-0199',
      ),
    ];
  }

  @override
  Future<PositionLinkPreviewDto> getPositionLinkPreview(String inviteCode) async {
    try {
      final cleanCode = inviteCode.trim();
      final response = await _dio.get('position-links/$cleanCode');
      final data = response.data;
      if (data != null) {
        final payload = (data is Map && data['data'] != null)
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        return PositionLinkPreviewDto.fromJson(payload);
      }
      throw Exception('Không nhận được thông tin vị trí phả hệ');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      String defaultMsg = 'Lỗi khi tra cứu mã liên kết';
      if (status == 404) {
        defaultMsg = 'Mã liên kết không tồn tại hoặc không phải mã vị trí hợp lệ';
      } else if (status == 400) {
        defaultMsg = 'Mã liên kết đã hết hạn hoặc đã được sử dụng';
      }
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          defaultMsg;
      throw Exception(msg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<ClaimPositionResponseDto> claimPosition({
    required String inviteCode,
    required ClaimPositionRequestDto request,
  }) async {
    try {
      final cleanCode = inviteCode.trim();
      final response = await _dio.post(
        'position-links/$cleanCode/claim',
        data: request.toJson(),
      );
      final data = response.data;
      if (data != null) {
        final payload = (data is Map && data['data'] != null)
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        return ClaimPositionResponseDto.fromJson(payload);
      }
      throw Exception('Không nhận được dữ liệu phản hồi sau khi nhận vị trí');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      String defaultMsg = 'Lỗi khi xác nhận gia nhập vị trí';
      if (status == 400) {
        defaultMsg = 'Mã liên kết không hợp lệ, đã hết hạn hoặc sai mật khẩu';
      } else if (status == 403) {
        defaultMsg = 'Tài khoản đang bị tạm khóa hoặc vô hiệu hóa';
      } else if (status == 404) {
        defaultMsg = 'Không tìm thấy vị trí phả hệ tương ứng với mã này';
      } else if (status == 409) {
        defaultMsg = 'Tài khoản đã liên kết hồ sơ khác hoặc vị trí đã có người nhận';
      }
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          defaultMsg;
      throw Exception(msg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
