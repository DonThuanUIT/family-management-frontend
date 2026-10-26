import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4A017),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 46,
                      color: Color(0xFFB8860B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hồ Sơ Đã Ghi Vào Sổ Vàng',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7A1518),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đang chờ Trưởng tộc / Trưởng chi đối soát & phê chuẩn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B584E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8DFD8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Color(0xFF7A1518), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Quy Trình Gia Nhập Phả Hệ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7A1518),
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 20),
                        Text(
                          '1. Thông tin đăng ký của bạn đã được chuyển tới Ban Trị Sự dòng họ.\n'
                          '2. Trưởng tộc hoặc Trưởng chi sẽ đối soát danh tính để gắn đúng thế hệ và chi phái trên cây phả hệ.\n'
                          '3. Khi hồ sơ được phê duyệt, bạn có thể đăng nhập bằng Số điện thoại & Mật khẩu đã tạo.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF3A2B24),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/welcome'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A1518),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Về Màn Hình Chính',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Đến Màn Hình Đăng Nhập',
                      style: TextStyle(
                        color: Color(0xFF7A1518),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
