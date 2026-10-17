import 'package:flutter/material.dart';

import '../../../../core/widgets/module_overview_card.dart';

/// Phân hệ 5: Tạm ứng, Quyết toán & Sổ cái Bất biến (`features/finance`).
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePortalScaffold(
      moduleCode: 'MODULE 05 • FINANCE, VOUCHERS & IMMUTABLE LEDGER',
      title: 'Tạm Ứng, Quyết Toán & Sổ Cái Quỹ Chung Bất Biến',
      subtitle:
          'Minh bạch hóa thu chi sự kiện, kiểm soát hóa đơn quyết toán và bảo toàn lịch sử tài chính bằng chuỗi băm SHA-256 (Audit Trail NFR-01).',
      databaseTables: [
        'advance_vouchers',
        'expense_settlement_vouchers',
        'ledger_adjustment_requests',
        'immutable_ledgers',
      ],
      memberFeatures: [
        'Tra cứu công khai toàn bộ Sổ cái Quỹ chung bất biến (IMMUTABLE_LEDGER) kèm mã băm SHA-256 xác thực.',
        'Người phụ trách công việc gửi ảnh hóa đơn/chứng từ để làm thủ tục quyết toán hoàn ứng (US-12).',
        'Theo dõi trạng thái giải trình khi hóa đơn bị đánh dấu Cần giải trình (NeedsExplanation).',
      ],
      managementFeatures: [
        'Thủ quỹ lập phiếu tạm ứng (ADVANCE_VOUCHER) gắn với hạng mục công việc (event_tasks).',
        'Đối soát phiếu quyết toán (EXPENSE_SETTLEMENT_VOUCHER): Duyệt hợp lệ (Valid) hoặc yêu cầu giải trình (NeedsExplanation).',
        'Đề xuất điều chỉnh sai sót sổ cái (LEDGER_ADJUSTMENT_REQUEST) và Trưởng tộc (ROLE_CLAN_HEAD) phê duyệt tạo bút toán bù trừ (AdjustmentTransaction - US-15).',
      ],
      businessRuleNote:
          'Quy tắc C & D: Chặn tuyệt đối thao tác khóa sổ sự kiện nếu còn khoản quyết toán ở trạng thái '
          'NeedsExplanation. Bảng IMMUTABLE_LEDGER chỉ cho phép INSERT (Append-Only), cấm UPDATE/DELETE.',
    );
  }
}
