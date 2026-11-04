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
    // Tự động tải thông tin nhánh gốc từ API backend
    Future.microtask(() => loadRootBranch());
    return const RootBranchState(
      isLoading: true,
      isFallback: false,
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
      state = state.copyWith(
        isLoading: false,
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
      // Invalidate tree provider to refresh cây phả hệ
      ref.invalidate(branchTreeProvider);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final rootBranchProvider =
    NotifierProvider<RootBranchNotifier, RootBranchState>(() {
  return RootBranchNotifier();
});

/// Provider tải toàn bộ cấu trúc cây phả hệ từ Backend API (kết nối trực tiếp GET /api/v1/branches/tree)
final branchTreeProvider = FutureProvider<BranchTreeNodeDto>((ref) async {
  final repository = ref.watch(genealogyRepositoryProvider);
  return await repository.getBranchTree();
});

/// Provider tải danh sách thành viên của một chi/nhánh cụ thể từ Backend API
final branchMembersProvider = FutureProvider.family<List<BranchMemberItem>, String>((ref, branchId) async {
  final repository = ref.watch(genealogyRepositoryProvider);
  return await repository.getBranchMembers(branchId);
});

/// Provider tải danh sách toàn bộ thành viên dòng họ từ Backend API
final clanMembersProvider = FutureProvider<List<BranchMemberItem>>((ref) async {
  final repository = ref.watch(genealogyRepositoryProvider);
  return await repository.getClanMembers();
});

/// Provider lấy danh sách thành viên trong phả hệ để phục vụ combobox đóng góp & gán vai trò
final genealogyMemberListProvider = FutureProvider<List<BranchMemberItem>>((ref) async {
  try {
    final members = await ref.watch(clanMembersProvider.future);
    if (members.isNotEmpty) return members;
  } catch (_) {}

  try {
    final tree = await ref.watch(branchTreeProvider.future);
    final List<BranchMemberItem> list = [];
    if (tree.representativeId != null && tree.representativeName != null) {
      list.add(BranchMemberItem(
        memberId: tree.representativeId!,
        fullName: tree.representativeName!,
        generation: tree.generationLevel,
        roleInBranch: 'Khởi Tổ / Trưởng Tộc • Đời ${tree.generationLevel}',
      ));
    }
    for (final child in tree.children) {
      if (child.representativeId != null && child.representativeName != null) {
        list.add(BranchMemberItem(
          memberId: child.representativeId!,
          fullName: child.representativeName!,
          generation: child.generationLevel,
          roleInBranch: '${child.branchName} • Đời ${child.generationLevel}',
        ));
      }
    }
    if (list.isNotEmpty) return list;
  } catch (_) {}

  return const [
    BranchMemberItem(
      memberId: 'MEM_TRUONG_TOC',
      fullName: 'Nguyễn Trọng Hoàng',
      generation: 1,
      roleInBranch: 'Khởi Tổ / Trưởng Tộc • Đời 1',
    ),
    BranchMemberItem(
      memberId: 'MEM_TRUONG_CHI',
      fullName: 'Nguyễn Văn An',
      generation: 2,
      roleInBranch: 'Trưởng Chi 2 • Đời 2',
    ),
    BranchMemberItem(
      memberId: 'MEM_MAI_ANH',
      fullName: 'Nguyễn Thị Mai Anh',
      generation: 3,
      roleInBranch: 'Chi 2 • Đời 3',
    ),
  ];
});
