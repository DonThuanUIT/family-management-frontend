import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: FamilyFundApp(),
    ),
  );
}

/// Ứng dụng Đa nền tảng (Web App & Mobile App) Quản lý Sự kiện và Quỹ Đại Gia Đình.
/// Hỗ trợ đồng thời cả 2 phân hệ:
/// - Phân hệ Thành viên / Con cháu
/// - Phân hệ Quản trị / Trưởng tộc & Ban Tổ Chức (Dual-RBAC)
class FamilyFundApp extends ConsumerWidget {
  const FamilyFundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FamilyFund • Quản Lý Gia Phả & Quỹ Dòng Họ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
