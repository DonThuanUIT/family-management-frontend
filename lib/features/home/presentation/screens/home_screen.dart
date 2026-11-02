import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:familyfund_app/features/shared/presentation/widgets/heritage_nav_bar.dart';

/// Màn hình Cây Phả Hệ (Chưa triển khai - để trống theo yêu cầu).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: Color(0xFFFAF6F0),
      appBar: HeritageNavBar(currentRoute: '/home'),
      bottomNavigationBar: HeritageBottomNavBar(currentRoute: '/home'),
      body: SizedBox.shrink(),
    );
  }
}
