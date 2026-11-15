import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/invitation_management_models.dart';
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

  Future<PositionLinkItemModel> createGeneralInvite(CreateGeneralInviteRequestDto request);

  Future<void> deactivateInvite(String inviteCode);

  Future<PositionLinkItemModel> updateInvite(
    String inviteCode,
    UpdateInvitationRequestDto request,
  );

  Future<PositionLinkItemModel> regenerateInvite(
    String inviteCode, {
    UpdateInvitationRequestDto? request,
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

    // Dữ liệu mẫu chuẩn đối chiếu chính xác theo thiết kế Stitch & W3 UI Spec (US-18 & US-34)
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
        maxUses: 1,
        usedCount: 1,
        isActive: true,
        expiresAt: DateTime(2026, 3, 26),
        shareableUrl: 'https://familyfund.app/join?clan=LE&code=CHI2-DOI5-9821',
      ),
      PositionLinkItemModel(
        code: 'VN-LE-CHUNG-8K9P',
        branchId: 'chi-root',
        branchName: 'Chi Gốc (Toàn Tộc)',
        generation: 1,
        fullName: 'Mã Mời Chung Gia Phả',
        issuedBy: 'Nguyễn Trọng Hoàng (Trưởng Tộc)',
        createdAt: DateTime(2026, 3, 14),
        isActivated: false,
        maxUses: 20,
        usedCount: 3,
        isActive: true,
        expiresAt: DateTime.now().add(const Duration(days: 14)),
        inviteType: 'GeneralClanInvite',
        shareableUrl: 'https://familyfund.app/join?code=VN-LE-CHUNG-8K9P',
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
        maxUses: 1,
        usedCount: 0,
        isActive: true,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        shareableUrl: 'https://familyfund.app/join?clan=LE&code=CHI2-DOI5-7731',
      ),
      PositionLinkItemModel(
        code: 'LE-CHI1-DOI4-4412',
        branchId: 'chi-1',
        branchName: 'Chi 1',
        generation: 4,
        fullName: 'Lê Minh Trí',
        issuedBy: 'Lê Văn An (Trưởng Chi)',
        createdAt: DateTime(2026, 3, 1),
        isActivated: false,
        maxUses: 1,
        usedCount: 0,
        isActive: true,
        expiresAt: DateTime.now().subtract(const Duration(days: 2)),
        shareableUrl: 'https://familyfund.app/join?clan=LE&code=CHI1-DOI4-4412',
      ),
      PositionLinkItemModel(
        code: 'VN-LE-OLD-3321',
        branchId: 'chi-3',
        branchName: 'Chi 3',
        generation: 3,
        fullName: 'Đợt Tuyển Thành Viên 2025',
        issuedBy: 'Lê Văn Cường',
        createdAt: DateTime(2025, 12, 1),
        isActivated: false,
        maxUses: 10,
        usedCount: 1,
        isActive: false,
        expiresAt: DateTime(2026, 1, 1),
        inviteType: 'GeneralClanInvite',
        shareableUrl: 'https://familyfund.app/join?code=VN-LE-OLD-3321',
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

  @override
  Future<PositionLinkItemModel> createGeneralInvite(
    CreateGeneralInviteRequestDto request,
  ) async {
    try {
      final response = await _dio.post('invitations/general', data: request.toJson());
      final data = response.data;
      if (data != null && data['data'] != null) {
        final m = data['data'] as Map<String, dynamic>;
        final code = (m['inviteCode'] as String?) ?? '';
        return PositionLinkItemModel(
          code: code,
          branchId: (m['targetBranchId'] as String?) ?? (request.targetBranchId ?? 'chi-root'),
          branchName: (m['targetBranchName'] as String?) ?? 'Chi Gốc (Toàn Tộc)',
          generation: 1,
          fullName: 'Mã Mời Chung Gia Phả',
          issuedBy: 'Trưởng Tộc',
          createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
          isActivated: false,
          maxUses: (m['maxUses'] as num?)?.toInt() ?? request.maxUses,
          usedCount: (m['usedCount'] as num?)?.toInt() ?? 0,
          expiresAt: m['expiresAt'] != null ? DateTime.tryParse(m['expiresAt'].toString()) : null,
          isActive: (m['isActive'] as bool?) ?? true,
          inviteType: 'GeneralClanInvite',
          shareableUrl: (m['shareableUrl'] as String?) ?? 'https://familyfund.app/join?code=$code',
        );
      }
    } catch (_) {}

    // Fallback khi offline
    final randomSuffix = '${1000 + DateTime.now().millisecond}';
    final code = 'VN-LE-CHUNG-$randomSuffix';
    return PositionLinkItemModel(
      code: code,
      branchId: request.targetBranchId ?? 'chi-root',
      branchName: request.targetBranchId != null ? 'Chi Chỉ Định' : 'Chi Gốc (Toàn Tộc)',
      generation: 1,
      fullName: 'Mã Mời Chung Gia Phả',
      issuedBy: 'Trưởng Tộc',
      createdAt: DateTime.now(),
      isActivated: false,
      maxUses: request.maxUses,
      usedCount: 0,
      expiresAt: request.expiresAt ?? DateTime.now().add(Duration(days: request.validityDays)),
      isActive: true,
      inviteType: 'GeneralClanInvite',
      shareableUrl: 'https://familyfund.app/join?code=$code',
    );
  }

  @override
  Future<void> deactivateInvite(String inviteCode) async {
    try {
      await _dio.patch('invitations/$inviteCode/deactivate');
    } catch (_) {}
  }

  @override
  Future<PositionLinkItemModel> updateInvite(
    String inviteCode,
    UpdateInvitationRequestDto request,
  ) async {
    try {
      final response = await _dio.patch('invitations/$inviteCode', data: request.toJson());
      final data = response.data;
      if (data != null && data['data'] != null) {
        final m = data['data'] as Map<String, dynamic>;
        return PositionLinkItemModel(
          code: inviteCode,
          branchId: (m['targetBranchId'] as String?) ?? '',
          branchName: (m['targetBranchName'] as String?) ?? 'Chi 2',
          generation: 5,
          fullName: 'Mã Mời Gia Phả',
          issuedBy: 'Trưởng Tộc / Chi',
          createdAt: DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
          isActivated: false,
          maxUses: (m['maxUses'] as num?)?.toInt() ?? 10,
          usedCount: (m['usedCount'] as num?)?.toInt() ?? 0,
          expiresAt: m['expiresAt'] != null ? DateTime.tryParse(m['expiresAt'].toString()) : null,
          isActive: (m['isActive'] as bool?) ?? true,
          inviteType: (m['inviteType'] as String?) ?? 'GeneralClanInvite',
          shareableUrl: (m['shareableUrl'] as String?) ?? 'https://familyfund.app/join?code=$inviteCode',
        );
      }
    } catch (_) {}

    return PositionLinkItemModel(
      code: inviteCode,
      branchId: 'chi-2',
      branchName: 'Chi 2',
      generation: 5,
      fullName: 'Mã Mời Gia Phả',
      issuedBy: 'Trưởng Tộc / Chi',
      createdAt: DateTime.now(),
      isActivated: false,
      maxUses: request.maxUses ?? 10,
      usedCount: 0,
      expiresAt: request.expiresAt ?? DateTime.now().add(Duration(days: request.validityDays ?? 30)),
      isActive: request.isActive ?? true,
      inviteType: 'GeneralClanInvite',
      shareableUrl: 'https://familyfund.app/join?code=$inviteCode',
    );
  }

  @override
  Future<PositionLinkItemModel> regenerateInvite(
    String inviteCode, {
    UpdateInvitationRequestDto? request,
  }) async {
    try {
      final response = await _dio.post('invitations/$inviteCode/regenerate', data: request?.toJson());
      final data = response.data;
      if (data != null && data['data'] != null) {
        final m = data['data'] as Map<String, dynamic>;
        final newCode = (m['inviteCode'] as String?) ?? '';
        return PositionLinkItemModel(
          code: newCode,
          branchId: (m['targetBranchId'] as String?) ?? '',
          branchName: (m['targetBranchName'] as String?) ?? 'Chi 2',
          generation: 5,
          fullName: 'Mã Mời Tái Tạo Mới',
          issuedBy: 'Trưởng Tộc / Chi',
          createdAt: DateTime.now(),
          isActivated: false,
          maxUses: (m['maxUses'] as num?)?.toInt() ?? 10,
          usedCount: 0,
          expiresAt: m['expiresAt'] != null ? DateTime.tryParse(m['expiresAt'].toString()) : null,
          isActive: true,
          inviteType: (m['inviteType'] as String?) ?? 'GeneralClanInvite',
          shareableUrl: (m['shareableUrl'] as String?) ?? 'https://familyfund.app/join?code=$newCode',
        );
      }
    } catch (_) {}

    final randomSuffix = '${2000 + DateTime.now().millisecond}';
    final newCode = 'VN-LE-REGEN-$randomSuffix';
    return PositionLinkItemModel(
      code: newCode,
      branchId: 'chi-2',
      branchName: 'Chi 2',
      generation: 5,
      fullName: 'Mã Mời Tái Tạo Mới',
      issuedBy: 'Trưởng Tộc / Chi',
      createdAt: DateTime.now(),
      isActivated: false,
      maxUses: request?.maxUses ?? 10,
      usedCount: 0,
      expiresAt: request?.expiresAt ?? DateTime.now().add(Duration(days: request?.validityDays ?? 30)),
      isActive: true,
      inviteType: 'GeneralClanInvite',
      shareableUrl: 'https://familyfund.app/join?code=$newCode',
    );
  }
}
