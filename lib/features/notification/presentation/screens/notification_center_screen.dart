import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../widgets/notification_center_dialog.dart';

/// Màn hình Trung Tâm Thông Báo Độc Lập cho route `/notifications` (US-08 & US-39)
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 860;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      appBar: const HeritageNavBar(currentRoute: '/notifications'),
      bottomNavigationBar:
          const HeritageBottomNavBar(currentRoute: '/notifications'),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const NotificationCenterDialog(),
          ),
        ),
      ),
    );
  }
}
