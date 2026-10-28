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
  final Set<SystemRole> globalRoles;
  final Map<String, EventPermissionContext> eventRolesByEventId;
  final PortalWorkspaceMode activePortalMode;

  const DualRbacSession({
    required this.accountId,
    required this.memberId,
    required this.fullName,
    required this.branchName,
    required this.globalRoles,
    this.eventRolesByEventId = const {},
    this.activePortalMode = PortalWorkspaceMode.memberPortal,
  });

  bool get isClanHead => globalRoles.contains(SystemRole.roleClanHead);
  bool get isBranchHead => globalRoles.contains(SystemRole.roleBranchHead);
  bool get isAdmin => globalRoles.contains(SystemRole.roleAdmin);

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

  DualRbacSession copyWith({
    Set<SystemRole>? globalRoles,
    Map<String, EventPermissionContext>? eventRolesByEventId,
    PortalWorkspaceMode? activePortalMode,
  }) {
    return DualRbacSession(
      accountId: accountId,
      memberId: memberId,
      fullName: fullName,
      branchName: branchName,
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
      accountId: 'ACC_HOANG_01',
      memberId: 'MEM_001',
      fullName: 'Nguyễn Trọng Hoàng',
      branchName: 'Chi 1 - Nhánh Trưởng',
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
