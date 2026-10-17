import 'package:flutter/material.dart';

import '../../../../core/widgets/module_overview_card.dart';

/// Phân hệ 4: Đóng góp Đa hình & Tài sản Dòng họ (`features/contribution`).
class ContributionScreen extends StatelessWidget {
  const ContributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePortalScaffold(
      moduleCode: 'MODULE 04 • CONTRIBUTIONS & CLAN ASSETS',
      title: 'Đóng Góp Đa Hình (Tiền Mặt / Hiện Vật) & Tài Sản Dòng Họ',
      subtitle:
          'Ghi nhận công đức tiền mặt hoặc hiện vật quy đổi, phân bổ chi tiết tới từng thành viên trong hộ gia đình.',
      databaseTables: [
        'contributions',
        'contribution_member_details',
        'cash_contributions',
        'in_kind_contributions',
        'clan_assets',
      ],
      memberFeatures: [
        'Tra cứu lịch sử đóng góp / công đức của bản thân và hộ gia đình qua các kỳ sự kiện.',
        'Xem biên lai điện tử tự sinh (receipt_number) cho các khoản đóng góp tiền mặt / chuyển khoản (US-09).',
        'Xem bảng vàng ghi nhận công đức hiện vật cúng tiến và danh mục tài sản từ đường.',
      ],
      managementFeatures: [
        'Tiếp nhận đóng góp đa hình: Tiền mặt/Chuyển khoản (CASH_CONTRIBUTION) & Hiện vật (IN_KIND_CONTRIBUTION - US-10).',
        'Chia nhỏ và phân bổ số tiền công đức cho từng thành viên trong hộ qua CONTRIBUTION_MEMBER_DETAIL.',
        'Định giá quy đổi hiện vật và chuyển giao hiện vật dư sau sự kiện vào Danh mục Tài sản chung (CLAN_ASSET).',
      ],
      businessRuleNote:
          'Quy tắc F: CONTRIBUTION_MEMBER_DETAIL lưu phân bổ công đức cá nhân, làm cơ sở cho thuật toán '
          'TinhTongDongGopDeQuy() cộng dồn tiền mặt và giá trị quy đổi hiện vật theo từng nhánh phả hệ.',
    );
  }
}
