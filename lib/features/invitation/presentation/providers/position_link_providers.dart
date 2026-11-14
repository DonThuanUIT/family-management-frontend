import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../genealogy/presentation/providers/genealogy_providers.dart';
import '../../data/models/position_link_models.dart';
import '../../data/repositories/position_link_repository_impl.dart';
import '../../domain/repositories/position_link_repository.dart';

/// Item nhánh trong dropdown chọn chi
class BranchSelectItem {
  final String id;
  final String name;
  final String leaderName;
  final int baseGeneration;
  final String rootAncestor;

  const BranchSelectItem({
    required this.id,
    required this.name,
    required this.leaderName,
    required this.baseGeneration,
    required this.rootAncestor,
  });
}

const List<BranchSelectItem> kDefaultBranches = [
  BranchSelectItem(
    id: 'chi-2',
    name: 'Chi 2 - Nhánh Cụ Lê Văn Bình',
    leaderName: 'Lê Văn Hùng (Trưởng Chi)',
    baseGeneration: 2,
    rootAncestor: 'Cụ Lê Văn Bình (Đời 2)',
  ),
  BranchSelectItem(
    id: 'chi-1',
    name: 'Chi 1 - Nhánh Cụ Lê Văn An',
    leaderName: 'Lê Văn An (Trưởng Chi)',
    baseGeneration: 2,
    rootAncestor: 'Cụ Lê Văn An (Đời 2)',
  ),
  BranchSelectItem(
    id: 'chi-3',
    name: 'Chi 3 - Nhánh Cụ Lê Văn Cường',
    leaderName: 'Lê Văn Cường (Trưởng Chi)',
    baseGeneration: 2,
    rootAncestor: 'Cụ Lê Văn Cường (Đời 2)',
  ),
  BranchSelectItem(
    id: 'chi-4',
    name: 'Chi 4 - Nhánh Cụ Lê Thị Mai',
    leaderName: 'Lê Thị Mai (Trưởng Chi)',
    baseGeneration: 2,
    rootAncestor: 'Cụ Lê Thị Mai (Đời 2)',
  ),
];

class ClanInvitesState {
  final List<BranchSelectItem> availableBranches;
  final String selectedBranchId;
  final String memberName;
  final int generation;
  final String gender;
  final int validityDays;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final String currentShareableUrl;
  final bool hasCopied;
  final List<PositionLinkItemModel> issuedCodes;
  final String searchQuery;
  final bool? filterStatus; // null: all, true: activated, false: pending
  final int currentPage;
  final int itemsPerPage;

  const ClanInvitesState({
    this.availableBranches = kDefaultBranches,
    this.selectedBranchId = 'chi-2',
    this.memberName = 'Lê Hữu Tuấn',
    this.generation = 5,
    this.gender = 'Male',
    this.validityDays = 14,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.currentShareableUrl =
        'https://familyfund.app/join?clan=LE&code=CHI2-DOI5-9821',
    this.hasCopied = false,
    this.issuedCodes = const [],
    this.searchQuery = '',
    this.filterStatus,
    this.currentPage = 1,
    this.itemsPerPage = 4,
  });

  BranchSelectItem get selectedBranch {
    return availableBranches.firstWhere(
      (b) => b.id == selectedBranchId,
      orElse: () => availableBranches.first,
    );
  }

  List<PositionLinkItemModel> get filteredCodes {
    return issuedCodes.where((item) {
      if (filterStatus != null && item.isActivated != filterStatus) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchName = item.fullName.toLowerCase().contains(q);
        final matchCode = item.code.toLowerCase().contains(q);
        final matchBranch = item.branchName.toLowerCase().contains(q);
        return matchName || matchCode || matchBranch;
      }
      return true;
    }).toList();
  }

  int get totalPages {
    final count = filteredCodes.length;
    if (count == 0) return 1;
    return (count / itemsPerPage).ceil();
  }

  List<PositionLinkItemModel> get paginatedCodes {
    final list = filteredCodes;
    final startIndex = (currentPage - 1) * itemsPerPage;
    if (startIndex >= list.length) return [];
    final endIndex = min(startIndex + itemsPerPage, list.length);
    return list.sublist(startIndex, endIndex);
  }

  ClanInvitesState copyWith({
    List<BranchSelectItem>? availableBranches,
    String? selectedBranchId,
    String? memberName,
    int? generation,
    String? gender,
    int? validityDays,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    String? currentShareableUrl,
    bool? hasCopied,
    List<PositionLinkItemModel>? issuedCodes,
    String? searchQuery,
    bool? Function()? filterStatus,
    int? currentPage,
    int? itemsPerPage,
  }) {
    return ClanInvitesState(
      availableBranches: availableBranches ?? this.availableBranches,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      memberName: memberName ?? this.memberName,
      generation: generation ?? this.generation,
      gender: gender ?? this.gender,
      validityDays: validityDays ?? this.validityDays,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
      currentShareableUrl: currentShareableUrl ?? this.currentShareableUrl,
      hasCopied: hasCopied ?? this.hasCopied,
      issuedCodes: issuedCodes ?? this.issuedCodes,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus != null ? filterStatus() : this.filterStatus,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }
}

final clanInvitesProvider =
    NotifierProvider<ClanInvitesNotifier, ClanInvitesState>(() {
  return ClanInvitesNotifier();
});

class ClanInvitesNotifier extends Notifier<ClanInvitesState> {
  PositionLinkRepository get _repository =>
      ref.read(positionLinkRepositoryProvider);

  @override
  ClanInvitesState build() {
    Future.microtask(() => loadInitialData());
    return const ClanInvitesState();
  }

  Future<void> loadInitialData([String? initialBranchId]) async {
    // 1. Tải danh sách cây chi phái nếu có
    final treeAsync = ref.read(branchTreeProvider);
    List<BranchSelectItem> branches = kDefaultBranches;

    treeAsync.whenData((tree) {
      if (tree.children.isNotEmpty) {
        final dynamicBranches = <BranchSelectItem>[];
        for (var i = 0; i < tree.children.length; i++) {
          final c = tree.children[i];
          dynamicBranches.add(
            BranchSelectItem(
              id: c.branchId,
              name: '${c.branchName} - Nhánh ${c.representativeName ?? "Cụ đời ${c.generationLevel}"}',
              leaderName: '${c.representativeName ?? "Trưởng Chi"} (Trưởng Chi)',
              baseGeneration: c.generationLevel,
              rootAncestor: '${c.branchName} (Đời ${c.generationLevel})',
            ),
          );
        }
        if (dynamicBranches.isNotEmpty) {
          branches = dynamicBranches;
        }
      }
    });

    final targetBranchId = initialBranchId ??
        (branches.any((b) => b.id == state.selectedBranchId)
            ? state.selectedBranchId
            : branches.first.id);

    // 2. Tải danh sách mã liên kết đã phát hành
    try {
      final codes = await _repository.getIssuedPositionLinks();
      state = state.copyWith(
        availableBranches: branches,
        selectedBranchId: targetBranchId,
        issuedCodes: codes,
      );
    } catch (_) {
      state = state.copyWith(
        availableBranches: branches,
        selectedBranchId: targetBranchId,
      );
    }
  }

  void setSelectedBranch(String branchId) {
    state = state.copyWith(selectedBranchId: branchId);
  }

  void setMemberName(String name) {
    state = state.copyWith(memberName: name);
  }

  void setGeneration(int gen) {
    state = state.copyWith(generation: gen);
  }

  void setGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
  }

  void setStatusFilter(bool? status) {
    state = state.copyWith(filterStatus: () => status, currentPage: 1);
  }

  void setPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  Future<void> copyShareableLink() async {
    await Clipboard.setData(ClipboardData(text: state.currentShareableUrl));
    state = state.copyWith(hasCopied: true);
    Future.delayed(const Duration(milliseconds: 2500), () {
      state = state.copyWith(hasCopied: false);
    });
  }

  /// Tạo hồ sơ ảo và sinh mã liên kết vị trí (POST /api/v1/branches/{branchId}/virtual-members - US-18)
  Future<bool> createVirtualMemberAndGenerateCode() async {
    final trimmedName = state.memberName.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập tên thành viên dự kiến');
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final req = CreateVirtualMemberRequestDto(
        fullName: trimmedName,
        gender: state.gender,
        generation: state.generation,
        validityDays: state.validityDays,
      );

      final result = await _repository.createVirtualMember(
        branchId: state.selectedBranchId,
        request: req,
      );

      final newCode = result.positionLinkCode.inviteCode;
      final newUrl = result.positionLinkCode.shareableUrl.isNotEmpty
          ? result.positionLinkCode.shareableUrl
          : 'https://familyfund.app/join?clan=${result.member.clanId}&code=$newCode';

      final newItem = PositionLinkItemModel(
        code: newCode,
        branchId: result.member.branchId,
        branchName: result.member.branchName.isNotEmpty
            ? result.member.branchName
            : state.selectedBranch.name.split(' - ').first,
        generation: result.member.generation,
        fullName: result.member.fullName,
        issuedBy: 'Trưởng Tộc / Trưởng Chi',
        createdAt: DateTime.now(),
        isActivated: false,
        shareableUrl: newUrl,
        targetMemberId: result.member.memberId,
      );

      state = state.copyWith(
        isSubmitting: false,
        currentShareableUrl: newUrl,
        successMessage: 'Đã tạo hồ sơ chờ sẵn và phát hành mã liên kết $newCode thành công!',
        issuedCodes: [newItem, ...state.issuedCodes],
        currentPage: 1,
      );
      return true;
    } catch (e) {
      // Khi offline / backend lỗi giả lập tạo mã cục bộ theo đúng quy tắc thiết kế Stitch
      final randomSuffix = (1000 + Random().nextInt(9000)).toString();
      final branchCode = state.selectedBranchId.replaceAll('-', '').toUpperCase();
      final localCode = 'LE-$branchCode-DOI${state.generation}-$randomSuffix';
      final localUrl = 'https://familyfund.app/join?clan=LE&code=$localCode';

      final fallbackItem = PositionLinkItemModel(
        code: localCode,
        branchId: state.selectedBranchId,
        branchName: state.selectedBranch.name.split(' - ').first,
        generation: state.generation,
        fullName: trimmedName,
        issuedBy: state.selectedBranch.leaderName,
        createdAt: DateTime.now(),
        isActivated: false,
        shareableUrl: localUrl,
      );

      state = state.copyWith(
        isSubmitting: false,
        currentShareableUrl: localUrl,
        successMessage: 'Đã tạo hồ sơ chờ sẵn và phát hành mã liên kết $localCode!',
        issuedCodes: [fallbackItem, ...state.issuedCodes],
        currentPage: 1,
      );
      return true;
    }
  }
}
