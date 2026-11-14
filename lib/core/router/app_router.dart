import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/models/auth_models.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/invite_code_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/auth/presentation/screens/register_creator_screen.dart';
import '../../features/auth/presentation/screens/register_member_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/audit/presentation/screens/system_audit_log_screen.dart';
import '../../features/contribution/presentation/screens/clan_asset_inventory_screen.dart';
import '../../features/contribution/presentation/screens/receive_contribution_screen.dart';
import '../../features/event/presentation/screens/event_list_screen.dart';
import '../../features/genealogy/presentation/screens/edit_root_branch_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/invitation/presentation/screens/clan_invites_screen.dart';
import '../../features/role/presentation/screens/role_management_screen.dart';
import '../../features/task/presentation/screens/event_task_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider xác định vị trí khởi đầu của ứng dụng (mặc định là Login Screen '/login').
final initialLocationProvider = Provider<String>((ref) => '/login');

/// Cấu hình điều hướng tập trung với GoRouter hỗ trợ cả Web URL routing và Mobile Deep Linking.
final appRouterProvider = Provider<GoRouter>((ref) {
  final initialLocation = ref.watch(initialLocationProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      // 1. Màn hình Khởi động (Splash)
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 2. Màn hình Mở đầu / Chào mừng (Welcome)
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // 3. Màn hình Đăng Nhập (Login)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 4. Màn hình Đăng Ký Trưởng Tộc (Register Clan Creator)
      GoRoute(
        path: '/register-creator',
        name: 'register-creator',
        builder: (context, state) => const RegisterCreatorScreen(),
      ),

      // 5. Màn hình Nhập / Quét Mã Thư Mời (Invite Code Entry)
      GoRoute(
        path: '/invite-code',
        name: 'invite-code',
        builder: (context, state) => const InviteCodeScreen(),
      ),

      // 6. Màn hình Ghi Tên Vào Gia Phả (Register Member)
      GoRoute(
        path: '/register-member',
        name: 'register-member',
        builder: (context, state) {
          final inviteCode = state.uri.queryParameters['inviteCode'];
          return RegisterMemberScreen(initialInviteCode: inviteCode);
        },
      ),

      // 7. Màn hình Chờ Phê Duyệt (Pending Approval)
      GoRoute(
        path: '/pending-approval',
        name: 'pending-approval',
        builder: (context, state) {
          final request = state.extra is JoinRequestResponseDto
              ? state.extra as JoinRequestResponseDto
              : null;
          return PendingApprovalScreen(joinRequest: request);
        },
      ),

      // 8. Màn hình Quên Mật Khẩu (Forgot Password)
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Màn hình Giả lập & Kiểm tra Phân quyền Dual-RBAC
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),

      // Màn hình Chính sau khi Đăng Nhập Thành Công (Cây Phả Hệ)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // 9. Biểu mẫu chỉnh sửa thông tin Nhánh Gốc (Task #16)
      GoRoute(
        path: '/branches/root/edit',
        name: 'edit-root-branch',
        builder: (context, state) => const EditRootBranchScreen(),
      ),
      GoRoute(
        path: '/genealogy/root/edit',
        name: 'edit-root-branch-alt',
        builder: (context, state) => const EditRootBranchScreen(),
      ),

      // 10. Phân hệ Quản lý & Khởi tạo Sự Kiện Dòng Họ (US-21 & US-22)
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const EventListScreen(),
        routes: [
          // 10.1. Phân hệ Quản lý Công việc & Phân công Chuẩn bị Sự Kiện (US-07)
          GoRoute(
            path: ':eventId/tasks',
            name: 'event-tasks',
            builder: (context, state) {
              final eventId = state.pathParameters['eventId'] ?? '';
              return EventTaskListScreen(eventId: eventId);
            },
          ),
        ],
      ),

      // 11. Phân hệ Quản lý Phân Quyền & Chức Sự Tác Nghiệp (US-03)
      GoRoute(
        path: '/roles',
        name: 'roles',
        builder: (context, state) => const RoleManagementScreen(),
      ),

      // 12. Bàn Tiếp Nhận Đóng Góp & Sổ Cái Thu Chi (Task #71)
      GoRoute(
        path: '/contributions',
        name: 'contributions',
        builder: (context, state) => const ReceiveContributionScreen(),
      ),

      // 13. Kho Hiện Vật & Bảo Vật Từ Đường (Task #74)
      GoRoute(
        path: '/clan-assets',
        name: 'clan-assets',
        builder: (context, state) => const ClanAssetInventoryScreen(),
      ),

      // 14. Phân hệ Cấp Mã Mời & Khởi Tạo Hồ Sơ Gia Phả (US-18)
      GoRoute(
        path: '/clan-invites',
        name: 'clan-invites',
        builder: (context, state) {
          final branchId = state.uri.queryParameters['branchId'];
          return ClanInvitesScreen(initialBranchId: branchId);
        },
      ),

      // 15. Nhật Ký Thao Tác Hệ Thống & So Sánh Diff (Audit Log Viewer)
      GoRoute(
        path: '/audit-logs',
        name: 'audit-logs',
        builder: (context, state) => const SystemAuditLogScreen(),
      ),
    ],
  );
});
