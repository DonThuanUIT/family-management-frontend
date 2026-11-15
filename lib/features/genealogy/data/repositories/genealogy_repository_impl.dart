import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/family_branch.dart';
import '../../domain/repositories/genealogy_repository.dart';
import '../datasources/genealogy_remote_datasource.dart';
import '../models/branch_models.dart';

class GenealogyRepositoryImpl implements GenealogyRepository {
  final GenealogyRemoteDataSource _remoteDataSource;

  GenealogyRepositoryImpl(this._remoteDataSource);

  @override
  Future<FamilyBranchDetail> getRootBranch() async {
    final dto = await _remoteDataSource.getRootBranch();
    return _toEntity(dto);
  }

  @override
  Future<FamilyBranchDetail> updateRootBranch(UpdateRootBranchRequestDto request) async {
    final dto = await _remoteDataSource.updateRootBranch(request);
    return _toEntity(dto);
  }

  @override
  Future<BranchTreeNodeDto> getBranchTree() {
    return _remoteDataSource.getBranchTree();
  }

  @override
  Future<List<BranchMemberItem>> getBranchMembers(String branchId) {
    return _remoteDataSource.getBranchMembers(branchId);
  }

  @override
  Future<List<BranchMemberItem>> getClanMembers() {
    return _remoteDataSource.getClanMembers();
  }

  @override
  Future<BranchDetailDto> updateBranch(String branchId, UpdateBranchRequestDto request) {
    return _remoteDataSource.updateBranch(branchId, request);
  }

  @override
  Future<void> assignMemberToBranch(String memberId, String branchId) {
    return _remoteDataSource.assignMemberToBranch(memberId, branchId);
  }

  @override
  Future<List<MemberSearchDto>> searchMembers({
    String? keyword,
    String? memberId,
    String? fullName,
    int? generation,
    String? branchId,
    String? status,
  }) {
    return _remoteDataSource.searchMembers(
      keyword: keyword,
      memberId: memberId,
      fullName: fullName,
      generation: generation,
      branchId: branchId,
      status: status,
    );
  }

  FamilyBranchDetail _toEntity(BranchDetailDto dto) {
    return FamilyBranchDetail(
      branchId: dto.branchId,
      clanId: dto.clanId,
      clanName: dto.clanName,
      branchName: dto.branchName,
      generationLevel: dto.generationLevel,
      parentBranchId: dto.parentBranchId,
      representativeId: dto.representativeId,
      representativeName: dto.representativeName,
      description: dto.description,
      createdAt: dto.createdAt,
    );
  }
}

final genealogyRepositoryProvider = Provider<GenealogyRepository>((ref) {
  final remoteDataSource = ref.watch(genealogyRemoteDataSourceProvider);
  return GenealogyRepositoryImpl(remoteDataSource);
});
