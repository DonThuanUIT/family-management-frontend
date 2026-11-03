import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/family_branch.dart';
import '../../domain/repositories/genealogy_repository.dart';
import '../../data/models/branch_models.dart';
import '../../data/repositories/genealogy_repository_impl.dart';

class RootBranchState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final FamilyBranchDetail? branch;
  final bool isFallback;

  const RootBranchState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.branch,
    this.isFallback = false,
  });

  RootBranchState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    FamilyBranchDetail? branch,
    bool? isFallback,
  }) {
    return RootBranchState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      branch: branch ?? this.branch,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}

class RootBranchNotifier extends Notifier<RootBranchState> {
  GenealogyRepository get _repository => ref.read(genealogyRepositoryProvider);

  @override
  RootBranchState build() {
    // Tự động gọi API backend ở nền
    Future.microtask(() => loadRootBranch());
    return _createInitialData();
  }

  RootBranchState _createInitialData() {
    return RootBranchState(
      isLoading: false,
      branch: FamilyBranchDetail(
        branchId: 'BR_ROOT_TB',
        clanId: 'CLAN_DEFAULT',
        clanName: 'DÒNG HỌ LÊ VIỆT NAM • Nam Trung, Thái Bình',
        branchName: 'Chi Gốc Nam Trung, Thái Bình',
        generationLevel: 1,
        representativeId: 'MEM-001',
        representativeName: 'Cụ Lê Phúc Khang (1890 – 1968)',
        description:
            'Nhánh Thủy tổ khởi lập từ cụ Lê Phúc Khang năm 1890 tại làng Nam Trung. Cội nguồn phát tích toàn bộ con cháu các chi phái hiện nay.',
        createdAt: DateTime(1890, 1, 1),
      ),
      isFallback: true,
    );
  }

  /// Tải thông tin nhánh gốc từ Backend
  Future<void> loadRootBranch({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final branch = await _repository.getRootBranch();
      state = state.copyWith(
        isLoading: false,
        branch: branch,
        isFallback: false,
        errorMessage: null,
      );
    } catch (e) {
      // Khi backend chưa sẵn sàng, giữ nguyên fallback data
      state = state.copyWith(
        isLoading: false,
        isFallback: true,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Cập nhật thông tin nhánh gốc (PUT /api/v1/branches/root)
  Future<bool> updateRootBranch(UpdateRootBranchRequestDto request) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final updated = await _repository.updateRootBranch(request);
      state = state.copyWith(
        isSaving: false,
        branch: updated,
        isFallback: false,
        successMessage: 'Cập nhật nhánh gốc thành công!',
      );
      return true;
    } catch (e) {
      // Nếu offline, tạm thời cập nhật giao diện để phục vụ thử nghiệm
      if (state.branch != null) {
        final localUpdated = FamilyBranchDetail(
          branchId: state.branch!.branchId,
          clanId: state.branch!.clanId,
          clanName: state.branch!.clanName,
          branchName: request.branchName,
          generationLevel: 1,
          parentBranchId: null,
          representativeId: request.representativeId,
          representativeName: state.branch!.representativeName,
          description: request.description,
          createdAt: state.branch!.createdAt,
        );
        state = state.copyWith(
          isSaving: false,
          branch: localUpdated,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      } else {
        state = state.copyWith(
          isSaving: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      }
      return false;
    }
  }
}

final rootBranchProvider =
    NotifierProvider<RootBranchNotifier, RootBranchState>(() {
  return RootBranchNotifier();
});
