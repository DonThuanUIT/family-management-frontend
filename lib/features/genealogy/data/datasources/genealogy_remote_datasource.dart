import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/branch_models.dart';

abstract class GenealogyRemoteDataSource {
  Future<BranchDetailDto> getRootBranch();
  Future<BranchDetailDto> updateRootBranch(UpdateRootBranchRequestDto request);
  Future<BranchTreeNodeDto> getBranchTree();
  Future<List<BranchMemberItem>> getBranchMembers(String branchId);
  Future<List<BranchMemberItem>> getClanMembers();
  Future<BranchDetailDto> updateBranch(String branchId, UpdateBranchRequestDto request);
  Future<void> assignMemberToBranch(String memberId, String branchId);
  Future<List<MemberSearchDto>> searchMembers({
    String? keyword,
    String? memberId,
    String? fullName,
    int? generation,
    String? branchId,
    String? status,
  });
}

class GenealogyRemoteDataSourceImpl implements GenealogyRemoteDataSource {
  final Dio _dio;

  GenealogyRemoteDataSourceImpl(this._dio);

  @override
  Future<BranchDetailDto> getRootBranch() async {
    try {
      final response = await _dio.get('branches/root');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return BranchDetailDto.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Không nhận được dữ liệu nhánh gốc từ máy chủ');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Lỗi khi tải thông tin nhánh gốc';
      throw Exception(msg);
    }
  }

  @override
  Future<BranchDetailDto> updateRootBranch(UpdateRootBranchRequestDto request) async {
    try {
      final response = await _dio.put(
        'branches/root',
        data: request.toJson(),
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        return BranchDetailDto.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Không nhận được phản hồi sau khi cập nhật nhánh gốc');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Lỗi khi cập nhật nhánh gốc';
      throw Exception(msg);
    }
  }

  @override
  Future<BranchTreeNodeDto> getBranchTree() async {
    try {
      final response = await _dio.get('branches/tree');
      final data = response.data;
      if (data != null && data['data'] != null) {
        return BranchTreeNodeDto.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Không nhận được dữ liệu cây phả hệ');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Lỗi khi tải cây phả hệ';
      throw Exception(msg);
    }
  }

  @override
  Future<List<BranchMemberItem>> getBranchMembers(String branchId) async {
    try {
      final response = await _dio.get('branches/$branchId/members');
      final data = response.data;
      if (data != null && data['data'] != null && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => BranchMemberItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Lỗi khi tải thành viên chi nhánh';
      throw Exception(msg);
    }
  }

  @override
  Future<List<BranchMemberItem>> getClanMembers() async {
    try {
      final response = await _dio.get('members');
      final data = response.data;
      if (data != null && data['data'] != null && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => BranchMemberItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Lỗi khi tải danh sách thành viên';
      throw Exception(msg);
    }
  }

  @override
  Future<BranchDetailDto> updateBranch(String branchId, UpdateBranchRequestDto request) async {
    try {
      final response = await _dio.put(
        'branches/$branchId',
        data: request.toJson(),
      );
      final data = response.data;
      if (data != null && data['data'] != null) {
        return BranchDetailDto.fromJson(data['data'] as Map<String, dynamic>);
      }
      throw Exception('Không nhận được phản hồi sau khi cập nhật chi nhánh');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Lỗi khi điều chuyển chi nhánh';
      throw Exception(msg);
    }
  }

  @override
  Future<void> assignMemberToBranch(String memberId, String branchId) async {
    try {
      await _dio.put(
        'members/$memberId/assign-branch',
        data: AssignMemberRequestDto(branchId: branchId).toJson(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Lỗi khi điều chuyển thành viên';
      throw Exception(msg);
    }
  }

  @override
  Future<List<MemberSearchDto>> searchMembers({
    String? keyword,
    String? memberId,
    String? fullName,
    int? generation,
    String? branchId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (keyword != null && keyword.trim().isNotEmpty) {
        queryParams['keyword'] = keyword.trim();
      }
      if (memberId != null && memberId.trim().isNotEmpty) {
        queryParams['memberId'] = memberId.trim();
      }
      if (fullName != null && fullName.trim().isNotEmpty) {
        queryParams['fullName'] = fullName.trim();
      }
      if (generation != null) {
        queryParams['generation'] = generation;
      }
      if (branchId != null && branchId.trim().isNotEmpty) {
        queryParams['branchId'] = branchId.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        queryParams['status'] = status.trim();
      }

      final response = await _dio.get(
        'members/search',
        queryParameters: queryParams,
      );
      final data = response.data;
      if (data != null && data['data'] != null && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => MemberSearchDto.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Lỗi khi tìm kiếm thành viên';
      throw Exception(msg);
    }
  }
}

final genealogyRemoteDataSourceProvider = Provider<GenealogyRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return GenealogyRemoteDataSourceImpl(dio);
});
