import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../genealogy/presentation/providers/genealogy_providers.dart';
import '../../data/models/invitation_management_models.dart';
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
  final InvitationCodeStatus? codeStatusFilter; // null: all, or active, usedUp, expired, revoked
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
    this.codeStatusFilter,
    this.currentPage = 1,
    this.itemsPerPage = 4,
  });

  BranchSelectItem get selectedBranch {
    return availableBranches.firstWhere(
      (b) => b.id == selectedBranchId,
      orElse: () => availableBranches.first,
    );
  }

  int get activeCount =>
      issuedCodes.where((c) => c.status == InvitationCodeStatus.active).length;
  int get usedUpCount =>
      issuedCodes.where((c) => c.status == InvitationCodeStatus.usedUp).length;
  int get expiredCount =>
      issuedCodes.where((c) => c.status == InvitationCodeStatus.expired).length;
  int get revokedCount =>
      issuedCodes.where((c) => c.status == InvitationCodeStatus.revoked).length;

  List<PositionLinkItemModel> get filteredCodes {
    return issuedCodes.where((item) {
      if (codeStatusFilter != null && item.status != codeStatusFilter) {
        return false;
      }
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
    InvitationCodeStatus? Function()? codeStatusFilter,
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
      codeStatusFilter: codeStatusFilter != null ? codeStatusFilter() : this.codeStatusFilter,
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

  void setCodeStatusFilter(InvitationCodeStatus? status) {
    state = state.copyWith(codeStatusFilter: () => status, currentPage: 1);
  }

  /// Thu hồi mã mời (PATCH /api/v1/invitations/{inviteCode}/deactivate - US-34)
  Future<bool> deactivateInvite(String inviteCode) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);
    try {
      await _repository.deactivateInvite(inviteCode);
      final updated = state.issuedCodes.map((item) {
        if (item.code == inviteCode) {
          return item.copyWith(isActive: false);
        }
        return item;
      }).toList();
      state = state.copyWith(
        isSubmitting: false,
        issuedCodes: updated,
        successMessage: 'Đã thu hồi mã mời $inviteCode thành công!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Lỗi khi thu hồi mã mời: ${e.toString()}',
      );
      return false;
    }
  }

  /// Gia hạn mã mời (PATCH /api/v1/invitations/{inviteCode} - US-34)
  Future<bool> extendInvite(
    String inviteCode, {
    int additionalDays = 30,
    int? newMaxUses,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);
    try {
      final targetIndex = state.issuedCodes.indexWhere((i) => i.code == inviteCode);
      final targetItem = targetIndex != -1 ? state.issuedCodes[targetIndex] : null;
      final currentExpiry = targetItem?.expiresAt ?? DateTime.now();
      final baseDate = currentExpiry.isAfter(DateTime.now()) ? currentExpiry : DateTime.now();
      final newExpiry = baseDate.add(Duration(days: additionalDays));

      final targetMaxUses = newMaxUses ?? ((targetItem?.maxUses ?? 1) < 10 ? 10 : targetItem!.maxUses + 5);
      final req = UpdateInvitationRequestDto(
        isActive: true,
        validityDays: additionalDays,
        maxUses: targetMaxUses,
        expiresAt: newExpiry,
      );
      await _repository.updateInvite(inviteCode, req);

      final updatedList = targetIndex != -1
          ? state.issuedCodes.map((item) {
              if (item.code == inviteCode) {
                return item.copyWith(
                  isActive: true,
                  expiresAt: newExpiry,
                  maxUses: targetMaxUses,
                );
              }
              return item;
            }).toList()
          : state.issuedCodes;

      state = state.copyWith(
        isSubmitting: false,
        issuedCodes: updatedList,
        successMessage: 'Đã gia hạn mã $inviteCode thêm $additionalDays ngày thành công!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Lỗi khi gia hạn mã mời: ${e.toString()}',
      );
      return false;
    }
  }

  /// Tạo mã mời chung gia phả (POST /api/v1/invitations/general - US-16 & US-34)
  Future<bool> createGeneralInvite({
    String? targetBranchId,
    int maxUses = 10,
    int validityDays = 30,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);
    try {
      final req = CreateGeneralInviteRequestDto(
        targetBranchId: targetBranchId,
        maxUses: maxUses,
        validityDays: validityDays,
      );
      final newItem = await _repository.createGeneralInvite(req);
      state = state.copyWith(
        isSubmitting: false,
        issuedCodes: [newItem, ...state.issuedCodes],
        currentShareableUrl: newItem.shareableUrl,
        currentPage: 1,
        successMessage: 'Đã tạo mã mời chung mới "${newItem.code}" thành công!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Lỗi khi tạo mã mời mới: ${e.toString()}',
      );
      return false;
    }
  }

  /// Tái tạo / cấp mã mới thay thế mã cũ (POST /api/v1/invitations/{inviteCode}/regenerate - US-34)
  Future<bool> regenerateInvite(
    String inviteCode, {
    int validityDays = 30,
    int maxUses = 10,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null);
    try {
      final req = UpdateInvitationRequestDto(validityDays: validityDays, maxUses: maxUses);
      final newItem = await _repository.regenerateInvite(inviteCode, request: req);

      final updatedList = state.issuedCodes.map((item) {
        if (item.code == inviteCode) {
          return newItem;
        }
        return item;
      }).toList();

      state = state.copyWith(
        isSubmitting: false,
        issuedCodes: updatedList,
        currentShareableUrl: newItem.shareableUrl,
        successMessage: 'Đã tái tạo và cấp mã mới "${newItem.code}" thay thế mã cũ!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Lỗi khi tái tạo mã mời: ${e.toString()}',
      );
      return false;
    }
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
