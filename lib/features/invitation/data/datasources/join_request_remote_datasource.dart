import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/auth_models.dart';
import '../models/join_request_management_models.dart';

final joinRequestRemoteDataSourceProvider =
    Provider<JoinRequestRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return JoinRequestRemoteDataSourceImpl(dio);
});

abstract class JoinRequestRemoteDataSource {
  Future<JoinRequestPageDto> getJoinRequests({
    JoinRequestApprovalStatus? status,
    String? branchId,
    int page = 0,
    int size = 20,
  });

  Future<JoinRequestResponseDto> approveJoinRequest(
    String requestId, {
    ApproveJoinRequestDto? request,
  });

  Future<JoinRequestResponseDto> rejectJoinRequest(
    String requestId,
    RejectJoinRequestDto request,
  );
}

class JoinRequestRemoteDataSourceImpl implements JoinRequestRemoteDataSource {
  final Dio _dio;

  JoinRequestRemoteDataSourceImpl(this._dio);

  // In-memory mock storage for fallback in local/test offline runs
  static final List<JoinRequestResponseDto> _mockRequests = [
    const JoinRequestResponseDto(
      requestId: 'REQ_01',
      accountId: 'ACC_091',
      clanId: 'CLAN_DEFAULT',
      inviteCode: '8K9P2X7N',
      fullName: 'Nguyễn Văn An',
      phoneNumber: '0987654321',
      email: 'an.nguyen@example.com',
      dateOfBirth: '1995-05-15',
      gender: 'Male',
      proposalType: ProposalType.existingBranchLeaf,
      targetBranchId: 'BR_01',
      targetBranchName: 'Chi Gốc (Đại Tôn)',
      proposedGeneration: 5,
      relationshipNote: 'Cháu nội cố cụ Nguyễn Văn Bình, sinh sống tại Hà Nội',
      approvalStatus: JoinRequestApprovalStatus.pending,
      createdAt: '2026-11-14T08:30:00Z',
    ),
    const JoinRequestResponseDto(
      requestId: 'REQ_02',
      accountId: 'ACC_092',
      clanId: 'CLAN_DEFAULT',
      inviteCode: '8K9P2X7N',
      fullName: 'Trần Thị Thu Thảo',
      phoneNumber: '0912345678',
      email: 'thao.tran@example.com',
      dateOfBirth: '1998-08-20',
      gender: 'Female',
      proposalType: ProposalType.newChildBranch,
      targetBranchId: 'BR_02',
      targetBranchName: 'Chi 2 - Nhánh Giáp',
      proposedNewBranchName: 'Chi Nhánh Sài Gòn',
      proposedGeneration: 6,
      relationshipNote: 'Con dâu mới nhập tịch họ Nguyễn theo chi 2',
      approvalStatus: JoinRequestApprovalStatus.pending,
      createdAt: '2026-11-14T09:15:00Z',
    ),
    const JoinRequestResponseDto(
      requestId: 'REQ_03',
      accountId: 'ACC_093',
      clanId: 'CLAN_DEFAULT',
      inviteCode: '7M4T9Q2L',
      fullName: 'Lê Hoàng Nam',
      phoneNumber: '0933221100',
      email: 'nam.le@example.com',
      dateOfBirth: '1992-03-10',
      gender: 'Male',
      proposalType: ProposalType.existingBranchLeaf,
      targetBranchId: 'BR_03',
      targetBranchName: 'Chi 3 - Nhánh Ất',
      proposedGeneration: 5,
      relationshipNote: 'Cháu ngoại dòng họ, thường xuyên về tế tự tại Từ đường',
      approvalStatus: JoinRequestApprovalStatus.approved,
      reviewedByAccountId: 'ACC_01',
      createdAt: '2026-11-13T14:20:00Z',
      reviewedAt: '2026-11-13T16:00:00Z',
    ),
    const JoinRequestResponseDto(
      requestId: 'REQ_04',
      accountId: 'ACC_094',
      clanId: 'CLAN_DEFAULT',
      inviteCode: '5X1R8Z3K',
      fullName: 'Phạm Gia Huy',
      phoneNumber: '0909112233',
      email: 'huy.pham@example.com',
      dateOfBirth: '2000-11-28',
      gender: 'Male',
      proposalType: ProposalType.existingBranchLeaf,
      targetBranchId: 'BR_01',
      targetBranchName: 'Chi Gốc (Đại Tôn)',
      proposedGeneration: 7,
      relationshipNote: 'Xin gia nhập chưa xác định rõ liên hệ chi nhánh',
      approvalStatus: JoinRequestApprovalStatus.rejected,
      reviewedByAccountId: 'ACC_01',
      rejectionReason: 'Thông tin nhân thân không khớp với gia phả dòng họ. Đề nghị liên hệ Trưởng chi để xác minh.',
      createdAt: '2026-11-12T10:00:00Z',
      reviewedAt: '2026-11-12T11:45:00Z',
    ),
  ];

  @override
  Future<JoinRequestPageDto> getJoinRequests({
    JoinRequestApprovalStatus? status,
    String? branchId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (status != null) {
        queryParams['status'] = status.value;
      }
      if (branchId != null && branchId.trim().isNotEmpty) {
        queryParams['branchId'] = branchId.trim();
      }

      final response = await _dio.get('join-requests', queryParameters: queryParams);
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => JoinRequestPageDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _getFilteredMockPage(status: status, branchId: branchId, page: page, size: size);
    } on DioException {
      return _getFilteredMockPage(status: status, branchId: branchId, page: page, size: size);
    } catch (_) {
      return _getFilteredMockPage(status: status, branchId: branchId, page: page, size: size);
    }
  }

  @override
  Future<JoinRequestResponseDto> approveJoinRequest(
    String requestId, {
    ApproveJoinRequestDto? request,
  }) async {
    try {
      final response = await _dio.post(
        'join-requests/$requestId/approve',
        data: request?.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => JoinRequestResponseDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _mockApprove(requestId, request);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final err = e.response?.data['message'] ?? e.response?.data['error'];
        if (err != null) throw Exception(err.toString());
      }
      return _mockApprove(requestId, request);
    } catch (_) {
      return _mockApprove(requestId, request);
    }
  }

  @override
  Future<JoinRequestResponseDto> rejectJoinRequest(
    String requestId,
    RejectJoinRequestDto request,
  ) async {
    try {
      final response = await _dio.post(
        'join-requests/$requestId/reject',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => JoinRequestResponseDto.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.data != null) {
        return apiResponse.data!;
      }
      return _mockReject(requestId, request.rejectionReason);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final err = e.response?.data['message'] ?? e.response?.data['error'];
        if (err != null) throw Exception(err.toString());
      }
      return _mockReject(requestId, request.rejectionReason);
    } catch (_) {
      return _mockReject(requestId, request.rejectionReason);
    }
  }

  JoinRequestPageDto _getFilteredMockPage({
    JoinRequestApprovalStatus? status,
    String? branchId,
    int page = 0,
    int size = 20,
  }) {
    var filtered = _mockRequests;
    if (status != null) {
      filtered = filtered.where((r) => r.approvalStatus == status).toList();
    }
    if (branchId != null && branchId.trim().isNotEmpty) {
      filtered = filtered.where((r) => r.targetBranchId == branchId.trim()).toList();
    }

    final startIndex = page * size;
    final content = startIndex < filtered.length
        ? filtered.skip(startIndex).take(size).toList()
        : <JoinRequestResponseDto>[];

    final totalPages = (filtered.length / size).ceil();

    return JoinRequestPageDto(
      content: content,
      totalElements: filtered.length,
      totalPages: totalPages < 1 ? 1 : totalPages,
      number: page,
      size: size,
    );
  }

  JoinRequestResponseDto _mockApprove(String requestId, ApproveJoinRequestDto? request) {
    final index = _mockRequests.indexWhere((r) => r.requestId == requestId);
    if (index >= 0) {
      final old = _mockRequests[index];
      final updated = JoinRequestResponseDto(
        requestId: old.requestId,
        accountId: old.accountId,
        clanId: old.clanId,
        inviteCode: old.inviteCode,
        fullName: old.fullName,
        phoneNumber: old.phoneNumber,
        email: old.email,
        dateOfBirth: old.dateOfBirth,
        gender: old.gender,
        proposalType: old.proposalType,
        targetBranchId: request?.targetBranchId ?? old.targetBranchId,
        targetBranchName: old.targetBranchName,
        proposedNewBranchName: request?.proposedNewBranchName ?? old.proposedNewBranchName,
        proposedGeneration: old.proposedGeneration,
        relationshipNote: old.relationshipNote,
        approvalStatus: JoinRequestApprovalStatus.approved,
        reviewedByAccountId: 'CURRENT_ACCOUNT',
        reviewedAt: DateTime.now().toIso8601String(),
        createdAt: old.createdAt,
      );
      _mockRequests[index] = updated;
      return updated;
    }
    throw Exception('Không tìm thấy yêu cầu gia nhập với mã $requestId');
  }

  JoinRequestResponseDto _mockReject(String requestId, String reason) {
    final index = _mockRequests.indexWhere((r) => r.requestId == requestId);
    if (index >= 0) {
      final old = _mockRequests[index];
      final updated = JoinRequestResponseDto(
        requestId: old.requestId,
        accountId: old.accountId,
        clanId: old.clanId,
        inviteCode: old.inviteCode,
        fullName: old.fullName,
        phoneNumber: old.phoneNumber,
        email: old.email,
        dateOfBirth: old.dateOfBirth,
        gender: old.gender,
        proposalType: old.proposalType,
        targetBranchId: old.targetBranchId,
        targetBranchName: old.targetBranchName,
        proposedNewBranchName: old.proposedNewBranchName,
        proposedGeneration: old.proposedGeneration,
        relationshipNote: old.relationshipNote,
        approvalStatus: JoinRequestApprovalStatus.rejected,
        reviewedByAccountId: 'CURRENT_ACCOUNT',
        rejectionReason: reason,
        reviewedAt: DateTime.now().toIso8601String(),
        createdAt: old.createdAt,
      );
      _mockRequests[index] = updated;
      return updated;
    }
    throw Exception('Không tìm thấy yêu cầu gia nhập với mã $requestId');
  }
}
