import 'package:flutter/material.dart';

class AuthEditorialPanel extends StatelessWidget {
  const AuthEditorialPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: const BoxDecoration(
        color: Color(0xFFF0EDEB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Brand Wordmark Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B1E1E), Color(0xFF6B1414)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD4A017), width: 1.2),
                    ),
                    child: const Center(
                      child: Icon(Icons.account_balance,
                          color: Color(0xFFD4A017), size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FamilyFund',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'SỔ CÁI & TỘC PHẢ SỐ',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8F482F),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 2. Pill Category
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8F482F).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_tree,
                        size: 15, color: Color(0xFF8F482F)),
                    SizedBox(width: 6),
                    Text(
                      'Di Sản & Cội Nguồn Dòng Họ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8F482F),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Headline & Description
              const Text(
                'Gìn giữ cội nguồn, minh bạch tài chính gia tộc',
                style: TextStyle(
                  fontFamily: 'Merriweather',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hệ thống phả hệ số tự động kết nối con cháu vào đúng nhánh gia đình, sổ cái tài chính phân cấp đối soát 1:1 bảo đảm sự hưng thịnh dài lâu.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF54433E),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // 4. Trust Pillars
              _buildTrustPillar(
                icon: Icons.verified,
                text: 'Tự động khớp vào cây phả hệ qua mã liên kết thế hệ',
              ),
              const SizedBox(height: 10),
              _buildTrustPillar(
                icon: Icons.account_balance,
                text: 'Sổ cái kiểm toán bất biến đối soát 1:1 sao kê ngân hàng',
              ),
              const SizedBox(height: 10),
              _buildTrustPillar(
                icon: Icons.celebration,
                text: 'Điều hành sự kiện giỗ tổ, phân bổ ngân sách minh bạch',
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 5. Patriarch Quote Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A1518),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFD4A017), width: 1.2),
                  ),
                  child: const Center(
                    child: Text(
                      'K',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“Cây có gốc mới nở cành xanh ngọn, nước có nguồn mới biển rộng sông sâu.”',
                        style: TextStyle(
                          fontFamily: 'Merriweather',
                          fontStyle: FontStyle.italic,
                          fontSize: 12.5,
                          color: Color(0xFF1C1C1A),
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Trưởng Tộc Lê Phúc Khang',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8F482F),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '• Đời Thứ 3',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              color: Color(0xFF756864),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustPillar({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF006E2A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C1C1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
