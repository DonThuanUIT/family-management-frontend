import 'package:flutter/material.dart';

import '../../../../core/widgets/module_overview_card.dart';

/// Phân hệ 1: Cây Gia phả, Định danh Thành viên & Lời mời (`features/genealogy`).
class GenealogyScreen extends StatelessWidget {
  const GenealogyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePortalScaffold(
      moduleCode: 'MODULE 01 • GENEALOGY & CLAN',
      title: 'Cây Gia Phả Đa Cấp, Hồ Sơ Thành Viên & Lời Mời',
      subtitle:
          'Quản lý cấu trúc cây dòng họ (Composite Pattern), tách biệt hồ sơ sinh học (MEMBER) và tài khoản đăng nhập (USER_ACCOUNT).',
      databaseTables: [
        'family_branches',
        'members',
        'user_accounts',
        'system_roles',
        'account_roles',
        'invitation_codes',
        'branch_join_requests',
      ],
      memberFeatures: [
        'Tra cứu sơ đồ cây gia phả đa thế hệ trực quan trên cả Web & Mobile.',
        'Xem thông tin chi tiết tổ tiên, ngày giỗ âm lịch và nhánh phả hệ.',
        'Gửi đơn xin gia nhập dòng họ (GeneralClanInvite) hoặc kích hoạt trực tiếp qua Mã liên kết vị trí (PositionLinkCode - US-18, US-19).',
        'Cập nhật thông tin liên lạc cá nhân gắn với hồ sơ thành viên.',
      ],
      managementFeatures: [
        'Quản trị nhánh phả hệ (Thêm/Sửa FAMILY_BRANCH) tích hợp thuật toán kiemTraChuTrinh() chống vòng lặp cha-con.',
        'Tạo trước hồ sơ ảo (MEMBER.is_placeholder = true) và phát hành mã mời PositionLinkCode cho con cháu.',
        'Phê duyệt hoặc từ chối đơn xin gia nhập dòng họ (BRANCH_JOIN_REQUEST - US-17).',
        'Bổ nhiệm Trưởng chi (representative_id) và phân quyền ROLE_BRANCH_HEAD.',
      ],
      businessRuleNote:
          'Quy tắc A: FAMILY_BRANCH là nút nhánh (parent_branch_id IS NULL là Nhánh Thủy tổ), '
          'MEMBER là nút lá. Bắt buộc kiểm tra chống chu trình khi thay đổi nhánh cấp trên.',
    );
  }
}
