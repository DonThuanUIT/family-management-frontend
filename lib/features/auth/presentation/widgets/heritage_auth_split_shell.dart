import 'package:flutter/material.dart';

/// Khung giao diện Auth thích ứng đa nền tảng theo chuẩn Stitch W1 & DESIGN.md:
/// - Điện thoại / Màn hình hẹp (`< 960px`): Hiển thị 1 cột căn giữa (`maxMobileWidth`).
/// - Máy tính / Web (`>= 960px`): Hiển thị Card Split-Screen 2 cột
///   (Trái: Bảng triết lý gia tộc nền Đỏ Huyết Dụ; Phải: Form thao tác).
class HeritageAuthSplitShell extends StatelessWidget {
  final Widget child;
  final double maxMobileWidth;
  final String badgeLabel;

  const HeritageAuthSplitShell({
    super.key,
    required this.child,
    this.maxMobileWidth = 440,
    this.badgeLabel = 'DI SẢN & GIA TỘC',
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

    if (!isDesktop) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxMobileWidth),
            child: child,
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1020),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5DDD5)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x142A2A2A),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _HeritageShowcasePanel(badgeLabel: badgeLabel),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 32,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeritageShowcasePanel extends StatelessWidget {
  final String badgeLabel;

  const _HeritageShowcasePanel({required this.badgeLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A020A),
            Color(0xFF8B1E1E),
          ],
        ),
      ),
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withAlpha(140),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 14,
                      color: Color(0xFFFFE088),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      badgeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Color(0xFFFFE088),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '“Cây có cội mới nở cành xanh ngọn,\nNước có nguồn mới bể rộng sông sâu.”',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Không gian lưu giữ gia phả truyền đời, minh bạch công đức tài chính và điều phối nghi lễ tông môn dành cho mọi thế hệ con cháu.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFFF5E6E4),
                  height: 1.55,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Column(
            children: const [
              _PillarItem(
                icon: Icons.account_tree_outlined,
                title: 'Phả Hệ Đa Chi Trực Quan',
                subtitle: 'Định vị thế hệ, chi phái và kết nối nguồn cội rõ ràng.',
              ),
              SizedBox(height: 14),
              _PillarItem(
                icon: Icons.verified_user_outlined,
                title: 'Sổ Cái Bất Biến Minh Bạch',
                subtitle: 'Đối soát thu chi công khai và lưu vết kiểm toán toàn vẹn.',
              ),
              SizedBox(height: 14),
              _PillarItem(
                icon: Icons.celebration_outlined,
                title: 'Tế Lễ & Chấp Sự Chu Toàn',
                subtitle: 'Lịch âm dương nhắc giỗ tổ, phân việc BTC và dự toán ngân sách.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PillarItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFFFE088)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFEAD4D0),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
