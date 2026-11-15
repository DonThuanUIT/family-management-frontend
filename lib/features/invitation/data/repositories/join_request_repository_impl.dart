import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../../genealogy/data/datasources/genealogy_remote_datasource.dart';
import '../../../genealogy/data/models/branch_models.dart';
import '../../domain/repositories/join_request_repository.dart';
import '../datasources/join_request_remote_datasource.dart';
import '../models/join_request_management_models.dart';

final joinRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  final remoteDataSource = ref.watch(joinRequestRemoteDataSourceProvider);
  final genealogyRemoteDataSource = ref.watch(genealogyRemoteDataSourceProvider);
  return JoinRequestRepositoryImpl(
    remoteDataSource: remoteDataSource,
    genealogyRemoteDataSource: genealogyRemoteDataSource,
  );
});

class JoinRequestRepositoryImpl implements JoinRequestRepository {
  final JoinRequestRemoteDataSource remoteDataSource;
  final GenealogyRemoteDataSource genealogyRemoteDataSource;

  JoinRequestRepositoryImpl({
    required this.remoteDataSource,
    required this.genealogyRemoteDataSource,
  });

  @override
  Future<JoinRequestPageDto> getJoinRequests({
    JoinRequestApprovalStatus? status,
    String? branchId,
    int page = 0,
    int size = 20,
  }) {
    return remoteDataSource.getJoinRequests(
      status: status,
      branchId: branchId,
      page: page,
      size: size,
    );
  }

  @override
  Future<JoinRequestResponseDto> approveJoinRequest(
    String requestId, {
    ApproveJoinRequestDto? request,
  }) {
    return remoteDataSource.approveJoinRequest(requestId, request: request);
  }

  @override
  Future<JoinRequestResponseDto> rejectJoinRequest(
    String requestId,
    RejectJoinRequestDto request,
  ) {
    return remoteDataSource.rejectJoinRequest(requestId, request);
  }

  @override
  Future<BranchTreeNodeDto> getBranchTree() {
    return genealogyRemoteDataSource.getBranchTree();
  }
}
