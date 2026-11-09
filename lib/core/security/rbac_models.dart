import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 1. Vai trò Tĩnh Toàn cục (Global Static RBAC - lưu tại `SYSTEM_ROLE` & `ACCOUNT_ROLE`).
enum SystemRole {
  roleAdmin('ROLE_ADMIN', 'Quản trị hệ thống'),
  roleClanHead('ROLE_CLAN_HEAD', 'Trưởng tộc'),
  roleBranchHead('ROLE_BRANCH_HEAD', 'Trưởng chi / nhánh'),
  roleMember('ROLE_MEMBER', 'Thành viên / Con cháu');

  final String code;
  final String displayName;
  const SystemRole(this.code, this.displayName);

  static SystemRole fromCode(String code) {
    return SystemRole.values.firstWhere(
      (e) => e.code == code,
      orElse: () => SystemRole.roleMember,
    );
  }
}

/// 2. Vai trò Động Theo Ngữ cảnh Sự kiện (Contextual Event RBAC - lưu tại `EVENT_PERSONNEL`).
enum EventContextualRole {
  headOfOrganizer('HeadOfOrganizer', 'Trưởng Ban Tổ Chức'),
  eventTreasurer('EventTreasurer', 'Thủ Quỹ Sự Kiện'),
  organizerMember('OrganizerMember', 'Thành Viên Ban Tổ Chức');

  final String code;
  final String displayName;
  const EventContextualRole(this.code, this.displayName);

  static EventContextualRole? fromCode(String? code) {
    if (code == null) return null;
    for (final role in EventContextualRole.values) {
      if (role.code == code) return role;
    }
    return null;
  }
}

/// Trạng thái vòng đời của Sự kiện (`EVENT.status`).
enum EventLifecycleStatus {
  draft('Draft', 'Bản nháp'),
  registrationOpen('RegistrationOpen', 'Đang mở đăng ký'),
  registrationClosed('RegistrationClosed', 'Đã chốt danh sách'),
  ongoing('Ongoing', 'Đang diễn ra'),
  ended('Ended', 'Đã bế mạc'),
  closed('Closed', 'Đã khóa sổ (Closed)');

  final String code;
  final String displayName;
  const EventLifecycleStatus(this.code, this.displayName);

  static EventLifecycleStatus fromCode(String? code) {
    if (code == null) return EventLifecycleStatus.draft;
    for (final status in EventLifecycleStatus.values) {
      if (status.code.toLowerCase() == code.toLowerCase()) return status;
    }
    return EventLifecycleStatus.draft;
  }
}

/// Chế độ Không gian làm việc (Portal Workspace) hỗ trợ cả Mobile App lẫn Web App
/// cho phép chuyển đổi linh hoạt giữa 2 phân hệ:
/// - `memberPortal`: Phân hệ Thành viên / Con cháu
/// - `managementPortal`: Phân hệ Quản trị / Trưởng tộc / Ban Tổ Chức
enum PortalWorkspaceMode {
  memberPortal('Thành viên / Con cháu'),
  managementPortal('Quản trị / Trưởng tộc & BTC');

  final String label;
  const PortalWorkspaceMode(this.label);
}

/// Quyền hạn ngữ cảnh của người dùng trong một sự kiện cụ thể.
/// Tuân thủ Quy tắc B (.antigravityrules): Khi `eventStatus == closed`,
/// tự động khóa `effectiveReadOnly = true`.
class EventPermissionContext {
  final String eventId;
  final EventContextualRole role;
  final EventLifecycleStatus eventStatus;
  final bool isReadOnlyFlag;

  const EventPermissionContext({
    required this.eventId,
    required this.role,
    required this.eventStatus,
    this.isReadOnlyFlag = false,
  });

  /// Ràng buộc cứng Quy tắc B: Tự động chuyển sang Chế độ Chỉ đọc khi sự kiện Closed.
  bool get isEffectiveReadOnly =>
      isReadOnlyFlag || eventStatus == EventLifecycleStatus.closed;

  bool get canMutateEventFinance =>
      !isEffectiveReadOnly &&
      (role == EventContextualRole.eventTreasurer ||
          role == EventContextualRole.headOfOrganizer);

  bool get canManageEventTasks =>
      !isEffectiveReadOnly &&
      (role == EventContextualRole.headOfOrganizer ||
          role == EventContextualRole.organizerMember);
}

/// Trạng thái phiên làm việc Dual-RBAC của người dùng hiện tại.
class DualRbacSession {
  final String accountId;
  final String memberId;
  final String fullName;
  final String branchName;
  final String? managedBranchId;
  final Set<SystemRole> globalRoles;
  final Map<String, EventPermissionContext> eventRolesByEventId;
  final PortalWorkspaceMode activePortalMode;

  const DualRbacSession({
    required this.accountId,
    required this.memberId,
    required this.fullName,
    required this.branchName,
    this.managedBranchId,
    required this.globalRoles,
    this.eventRolesByEventId = const {},
    this.activePortalMode = PortalWorkspaceMode.memberPortal,
  });

  bool get isClanHead => globalRoles.contains(SystemRole.roleClanHead);
  bool get isBranchHead => globalRoles.contains(SystemRole.roleBranchHead);
  bool get isAdmin => globalRoles.contains(SystemRole.roleAdmin);

  /// [US-23] Kiểm tra xem người dùng hiện tại có quyền thực hiện các thao tác quản trị
  /// (Thêm thành viên, Sửa chi nhánh, Điều chuyển) trên chi nhánh mục tiêu hay không.
  /// Ràng buộc nghiệp vụ:
  /// - Trưởng tộc (`ROLE_CLAN_HEAD`) & Quản trị hệ thống (`ROLE_ADMIN`): Toàn quyền trên mọi chi nhánh.
  /// - Trưởng chi (`ROLE_BRANCH_HEAD`): Chỉ được phép thao tác trong phạm vi chi mình đại diện / quản lý.
  /// - Thành viên thường (`ROLE_MEMBER`): Không có quyền quản trị chi.
  bool canManageBranch({
    required String branchId,
    String? representativeId,
    String? representativeName,
  }) {
    if (isAdmin || isClanHead) return true;
    if (isBranchHead) {
      // 1. Khớp chính xác representativeId với memberId của Trưởng chi
      if (representativeId != null &&
          representativeId.trim().isNotEmpty &&
          representativeId.trim() == memberId.trim()) {
        return true;
      }
      // 2. Khớp managedBranchId với branchId mục tiêu
      if (managedBranchId != null &&
          managedBranchId!.trim().isNotEmpty &&
          managedBranchId!.trim() == branchId.trim()) {
        return true;
      }
      // 3. Fallback: Khớp họ tên người đại diện với fullName
      if (representativeName != null &&
          representativeName.trim().isNotEmpty &&
          representativeName.trim().toLowerCase() == fullName.trim().toLowerCase()) {
        return true;
      }
      return false;
    }
    return false;
  }

  /// [US-23] Trả về lý do bị từ chối quyền để hiển thị Tooltip hoặc thông báo giải thích cho người dùng
  String? getBranchActionDeniedReason({
    required String branchId,
    String? representativeId,
    String? representativeName,
    String actionName = 'thao tác này',
  }) {
    if (canManageBranch(
      branchId: branchId,
      representativeId: representativeId,
      representativeName: representativeName,
    )) {
      return null;
    }
    if (isBranchHead) {
      return 'Thao tác bị giới hạn: Bạn chỉ có quyền $actionName trong phạm vi chi nhánh bạn đại diện quản lý (ROLE_BRANCH_HEAD).';
    }
    return 'Bạn cần quyền Trưởng tộc hoặc Trưởng chi nhánh để $actionName.';
  }

  /// Kiểm tra người dùng có quyền truy cập Phân hệ Quản trị / Trưởng tộc / BTC hay không.
  bool get canAccessManagementPortal =>
      isAdmin ||
      isClanHead ||
      isBranchHead ||
      eventRolesByEventId.isNotEmpty;

  /// Quy tắc D: Chỉ Trưởng tộc (`ROLE_CLAN_HEAD`) mới có quyền phê duyệt bút toán bù trừ Sổ cái bất biến.
  bool get canApproveLedgerAdjustment => isClanHead;

  /// Quy tắc A & Luồng 1: Trưởng tộc hoặc Trưởng chi duyệt đơn gia nhập & sinh mã mời.
  bool get canReviewBranchJoinRequests => isClanHead || isBranchHead || isAdmin;

  /// Kiểm tra người dùng có quyền quản lý công việc sự kiện (US-07) hay không.
  /// Ràng buộc cứng: Sự kiện chưa Closed VÀ (là Quản trị viên, Trưởng tộc, hoặc giữ vai trò HeadOfOrganizer/OrganizerMember trong ban tổ chức sự kiện).
  bool canManageTasks({
    required bool isClosed,
    List<dynamic>? personnel,
    String? eventId,
  }) {
    if (isClosed) return false;
    if (isAdmin || isClanHead) return true;
    if (eventId != null && eventRolesByEventId.containsKey(eventId)) {
      final ctx = eventRolesByEventId[eventId]!;
      if (ctx.canManageEventTasks) return true;
    }
    if (personnel != null) {
      for (final p in personnel) {
        final pMemberId = p is Map ? p['memberId'] : (p.memberId as String?);
        final pRole = p is Map ? p['eventRole'] : (p.eventRole as String?);
        final pReadOnly = p is Map ? p['isReadOnly'] == true : (p.isReadOnly == true);
        if (pMemberId == memberId && !pReadOnly) {
          if (pRole == 'HeadOfOrganizer' || pRole == 'OrganizerMember') {
            return true;
          }
        }
      }
    }
    return false;
  }

  DualRbacSession copyWith({
    String? accountId,
    String? memberId,
    String? fullName,
    String? branchName,
    String? managedBranchId,
    Set<SystemRole>? globalRoles,
    Map<String, EventPermissionContext>? eventRolesByEventId,
    PortalWorkspaceMode? activePortalMode,
  }) {
    return DualRbacSession(
      accountId: accountId ?? this.accountId,
      memberId: memberId ?? this.memberId,
      fullName: fullName ?? this.fullName,
      branchName: branchName ?? this.branchName,
      managedBranchId: managedBranchId ?? this.managedBranchId,
      globalRoles: globalRoles ?? this.globalRoles,
      eventRolesByEventId: eventRolesByEventId ?? this.eventRolesByEventId,
      activePortalMode: activePortalMode ?? this.activePortalMode,
    );
  }
}

/// Notifier quản lý phiên Dual-RBAC và chuyển đổi giữa 2 phân hệ
/// (Thành viên/Con cháu <-> Quản trị/Trưởng tộc/BTC) trên cả Mobile và Web.
class DualRbacSessionNotifier extends Notifier<DualRbacSession> {
  @override
  DualRbacSession build() {
    // Khởi tạo phiên mẫu phục vụ phát triển giao diện cả 2 phân hệ
    return const DualRbacSession(
      accountId: 'ACC_TRUONG_TOC',
      memberId: 'MEM_TRUONG_TOC',
      fullName: 'Nguyễn Trọng Hoàng',
      branchName: 'Chi Gốc (Đại Tôn)',
      managedBranchId: 'BR_ROOT',
      globalRoles: {
        SystemRole.roleClanHead,
        SystemRole.roleBranchHead,
        SystemRole.roleMember,
      },
      eventRolesByEventId: {
        'EVT_2026_GIOTO': EventPermissionContext(
          eventId: 'EVT_2026_GIOTO',
          role: EventContextualRole.headOfOrganizer,
          eventStatus: EventLifecycleStatus.ongoing,
        ),
      },
      activePortalMode: PortalWorkspaceMode.memberPortal,
    );
  }

  void setManagedBranchId(String? branchId) {
    state = state.copyWith(managedBranchId: branchId);
  }

  /// [US-23] Chuyển đổi nhanh Persona kiểm thử phân quyền:
  /// - 'CLAN_HEAD': Trưởng tộc Nguyễn Trọng Hoàng (Toàn quyền mọi chi nhánh)
  /// - 'BRANCH_HEAD_CHI_2': Trưởng chi 2 Nguyễn Văn An (Chỉ có quyền trên Chi 2, bị khóa trên Chi Gốc)
  /// - 'MEMBER': Con cháu / Thành viên Nguyễn Thị Mai Anh (Chế độ chỉ xem)
  void simulatePersona(String personaType) {
    switch (personaType) {
      case 'CLAN_HEAD':
        state = state.copyWith(
          memberId: 'MEM_TRUONG_TOC',
          fullName: 'Nguyễn Trọng Hoàng',
          branchName: 'Chi Gốc (Đại Tôn)',
          managedBranchId: 'BR_ROOT',
          globalRoles: {
            SystemRole.roleClanHead,
            SystemRole.roleMember,
          },
        );
        break;
      case 'BRANCH_HEAD_CHI_2':
        state = state.copyWith(
          memberId: 'MEM_TRUONG_CHI',
          fullName: 'Nguyễn Văn An',
          branchName: 'Chi 2 - Nhánh Giáp',
          managedBranchId: 'BR_CHI_2',
          globalRoles: {
            SystemRole.roleBranchHead,
            SystemRole.roleMember,
          },
        );
        break;
      case 'MEMBER':
        state = state.copyWith(
          memberId: 'MEM_MAI_ANH',
          fullName: 'Nguyễn Thị Mai Anh',
          branchName: 'Chi 2 - Nhánh Giáp',
          managedBranchId: '',
          globalRoles: {
            SystemRole.roleMember,
          },
        );
        break;
    }
  }

  void switchPortalMode(PortalWorkspaceMode mode) {
    if (mode == PortalWorkspaceMode.managementPortal &&
        !state.canAccessManagementPortal) {
      return;
    }
    state = state.copyWith(activePortalMode: mode);
  }

  void toggleSimulationRole(SystemRole role) {
    final updated = Set<SystemRole>.from(state.globalRoles);
    if (updated.contains(role) && updated.length > 1) {
      updated.remove(role);
    } else {
      updated.add(role);
    }
    state = state.copyWith(globalRoles: updated);
  }
}

final dualRbacSessionProvider =
    NotifierProvider<DualRbacSessionNotifier, DualRbacSession>(
      DualRbacSessionNotifier.new,
    );
