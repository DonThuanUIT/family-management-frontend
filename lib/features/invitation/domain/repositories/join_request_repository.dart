import '../../../auth/data/models/auth_models.dart';
import '../../../genealogy/data/models/branch_models.dart';
import '../../data/models/join_request_management_models.dart';

abstract class JoinRequestRepository {
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

  Future<BranchTreeNodeDto> getBranchTree();
}
