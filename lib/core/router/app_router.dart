import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/invite_code_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/auth/presentation/screens/register_creator_screen.dart';
import '../../features/auth/presentation/screens/register_member_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/event/presentation/screens/event_list_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider xác định vị trí khởi đầu của ứng dụng (mặc định là Splash Screen '/').
final initialLocationProvider = Provider<String>((ref) => '/');

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
        builder: (context, state) => const PendingApprovalScreen(),
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

      // Màn hình Chính sau khi Đăng Nhập Thành Công (Placeholder để nhóm tự thiết kế các phân hệ)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // 10. Phân hệ Quản lý & Khởi tạo Sự Kiện Dòng Họ (US-21 & US-22)
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const EventListScreen(),
      ),
    ],
  );
});
