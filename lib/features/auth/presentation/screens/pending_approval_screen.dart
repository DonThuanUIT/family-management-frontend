import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/auth_models.dart';

class PendingApprovalScreen extends StatelessWidget {
  final JoinRequestResponseDto? joinRequest;

  const PendingApprovalScreen({super.key, this.joinRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
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
                  const SizedBox(height: 24),

                  if (joinRequest != null) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_outlined,
                                  color: Color(0xFF7A1518), size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Thông Tin Hồ Sơ Đăng Ký',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7A1518),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3CD),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFFFEEBA)),
                                ),
                                child: const Text(
                                  'Chờ Duyệt',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF856404),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            context,
                            'Mã hồ sơ:',
                            joinRequest!.requestId,
                            isCopyable: true,
                          ),
                          _buildDetailRow(
                            context,
                            'Họ và tên:',
                            joinRequest!.fullName,
                          ),
                          if (joinRequest!.phoneNumber != null)
                            _buildDetailRow(
                              context,
                              'Số điện thoại:',
                              joinRequest!.phoneNumber!,
                            ),
                          _buildDetailRow(
                            context,
                            'Chi nhánh đề xuất:',
                            joinRequest!.targetBranchName ??
                                joinRequest!.targetBranchId,
                          ),
                          if (joinRequest!.proposalType ==
                                  ProposalType.newChildBranch &&
                              joinRequest!.proposedNewBranchName != null)
                            _buildDetailRow(
                              context,
                              'Nhánh mới đề xuất:',
                              joinRequest!.proposedNewBranchName!,
                            ),
                          _buildDetailRow(
                            context,
                            'Đời thứ đề xuất:',
                            'Đời thứ ${joinRequest!.proposedGeneration}',
                          ),
                          if (joinRequest!.createdAt != null)
                            _buildDetailRow(
                              context,
                              'Thời gian gửi:',
                              joinRequest!.createdAt!.replaceFirst('T', ' ').substring(0, 16),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

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
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A1518),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Đến Màn Hình Đăng Nhập',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/welcome'),
                    child: const Text(
                      'Về Màn Hình Chính',
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

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B584E),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B1810),
                    ),
                  ),
                ),
                if (isCopyable)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã sao chép mã: $value'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Color(0xFF7A1518),
                      ),
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
