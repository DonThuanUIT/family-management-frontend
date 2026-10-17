import 'package:flutter/material.dart';

import '../../../../core/widgets/module_overview_card.dart';

/// Phân hệ 6: Báo cáo Thống kê & Cộng dồn Đóng góp Đệ quy (`features/report`).
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePortalScaffold(
      moduleCode: 'MODULE 06 • REPORTS & RECURSIVE ANALYTICS',
      title: 'Báo Cáo Thu Chi & Thống Kê Công Đức Đệ Quy Theo Nhánh',
      subtitle:
          'Tổng hợp bức tranh tài chính dòng họ, thống kê công đức đệ quy theo từng Chi/Nhánh và báo cáo quyết toán sau sự kiện.',
      databaseTables: [
        'family_branches',
        'contributions',
        'contribution_member_details',
        'immutable_ledgers',
      ],
      memberFeatures: [
        'Xem báo cáo tổng kết thu - chi minh bạch sau mỗi kỳ lễ giỗ, sự kiện họ tộc.',
        'Xem bảng xếp hạng / thống kê đóng góp của các Chi, Nhánh trong toàn dòng họ.',
        'Tra cứu lịch sử biến động số dư Quỹ chung qua các năm.',
      ],
      managementFeatures: [
        'Chạy báo cáo cộng dồn đóng góp đệ quy TinhTongDongGopDeQuy() (CTE WITH RECURSIVE) cho bất kỳ nhánh phả hệ nào (US-11).',
        'Báo cáo đối chiếu Dự toán sự kiện vs Chi thực tế vs Tạm ứng chưa tất toán.',
        'Xuất báo cáo kiểm toán chuỗi băm Sổ cái bất biến và lịch sử các bút toán bù trừ.',
      ],
      businessRuleNote:
          'Quy tắc F: Thuật toán TinhTongDongGopDeQuy() duyệt đệ quy toàn bộ cây nhánh con '
          'và cộng dồn cả tiền mặt lẫn giá trị quy đổi hiện vật của mọi thành viên trực thuộc.',
    );
  }
}
