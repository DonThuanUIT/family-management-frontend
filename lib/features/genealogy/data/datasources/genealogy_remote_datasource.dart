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
}

final genealogyRemoteDataSourceProvider = Provider<GenealogyRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider);
  return GenealogyRemoteDataSourceImpl(dio);
});
