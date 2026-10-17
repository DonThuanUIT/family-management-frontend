import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/contribution/presentation/screens/contribution_screen.dart';
import '../../features/event/presentation/screens/event_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/genealogy/presentation/screens/genealogy_screen.dart';
import '../../features/report/presentation/screens/report_screen.dart';
import '../../features/task/presentation/screens/task_screen.dart';
import '../widgets/adaptive_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Cấu hình điều hướng tập trung với GoRouter hỗ trợ cả Web URL routing và Mobile Deep Linking.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/genealogy',
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdaptiveWorkspaceShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/genealogy',
                name: 'genealogy',
                builder: (context, state) => const GenealogyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                name: 'events',
                builder: (context, state) => const EventScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                name: 'tasks',
                builder: (context, state) => const TaskScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/contributions',
                name: 'contributions',
                builder: (context, state) => const ContributionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finance',
                name: 'finance',
                builder: (context, state) => const FinanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                name: 'reports',
                builder: (context, state) => const ReportScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
