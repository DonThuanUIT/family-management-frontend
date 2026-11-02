// ignore_for_file: deprecated_member_use
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../data/models/contribution_models.dart';
import '../providers/contribution_ui_provider.dart';
import '../widgets/electronic_receipt_dialog.dart';

/// Task #71: Giao diện Bàn Tiếp Nhận Đóng Góp của Thủ Quỹ (TiepNhanDongGopUI).
/// Chuẩn hóa theo tiêu chuẩn Warm Editorial Heritage & UI/UX Pro Max:
/// - Tone màu di sản: Đỏ son (#8B1E1E), Vàng kim (#D4A017), Xanh ngọc (#2E8B43), Giấy ngà (#FAF9F6).
/// - Bảng Sổ Cái Đối Soát phân cấp thích ứng (Responsive Ledger Table) trên Desktop & Cards trên Mobile.
/// - Trợ lý đọc số tiền bằng chữ thời gian thực chống nhầm lẫn khi nhập liệu.
/// - Bảng chỉ số tài chính 4 thẻ với tỷ lệ tương phản cao đạt chuẩn WCAG AA/AAA.
class ReceiveContributionScreen extends ConsumerStatefulWidget {
  const ReceiveContributionScreen({super.key});

  @override
  ConsumerState<ReceiveContributionScreen> createState() =>
      _ReceiveContributionScreenState();
}

class _ReceiveContributionScreenState
    extends ConsumerState<ReceiveContributionScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _searchController = TextEditingController();
  String _keyword = '';
  String _selectedFilter = 'all'; // 'all', 'cash', 'bank_transfer', 'in_kind', 'pending'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(contributionUiProvider);

    final filteredCash = _getFilteredCash(uiState.cashReceipts);
    final filteredInKind = _getFilteredInKind(uiState.inKindReceipts);
    final totalTransactions = filteredCash.length + filteredInKind.length;
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6), // Warm Canvas
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B1E1E), Color(0xFF6B1414)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD4A017), width: 1.2),
              ),
              child: const Icon(
                Icons.account_balance,
                color: Color(0xFFD4A017),
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bàn Tiếp Nhận Đóng Góp & Sổ Cái',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF2B1810),
                    letterSpacing: -0.2,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E8B43),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'KỲ LỄ 2026 • ĐỐI SOÁT BẤT BIẾN',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                        color: Color(0xFF54433E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.8,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE6DFD8), height: 1),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => context.push('/clan-assets'),
            icon: const Icon(Icons.inventory_2_outlined, size: 17),
            label: const Text('Kho Bảo Vật Từ Đường'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B1E1E),
              side: const BorderSide(color: Color(0xFF8B1E1E), width: 1.2),
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Sự Kiện & Nút Tiếp Nhận Nhanh
                _buildEventBanner(context),
                const SizedBox(height: 20),

                // 4 Thẻ chỉ số tổng kết tài chính sự kiện
                _buildStatCards(uiState, isDesktop),
                const SizedBox(height: 24),

                // Bảng Sổ Cái Giao Dịch kèm Bộ lọc & Tìm kiếm thời gian thực
                _buildTransactionSection(
                  uiState: uiState,
                  filteredCash: filteredCash,
                  filteredInKind: filteredInKind,
                  totalTransactions: totalTransactions,
                  isDesktop: isDesktop,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContributionModal(context),
        backgroundColor: const Color(0xFF8B1E1E),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline, size: 22),
        label: const Text(
          'Lập Phiếu Đóng Góp Mới',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
        ),
      ),
    );
  }

  List<ElectronicReceiptDto> _getFilteredCash(List<ElectronicReceiptDto> list) {
    if (_selectedFilter == 'in_kind' ||
        _selectedFilter == 'pending' ||
        _selectedFilter == 'consumed' ||
        _selectedFilter == 'returned') {
      return [];
    }
    return list.where((r) {
      if (_selectedFilter == 'cash' && r.paymentMethod != PaymentMethod.Cash) {
        return false;
      }
      if (_selectedFilter == 'bank_transfer' &&
          r.paymentMethod != PaymentMethod.BankTransfer) {
        return false;
      }
      if (_keyword.isEmpty) return true;
      final q = _keyword.toLowerCase();
      final payer = (r.payerMemberName ?? r.payerMemberId).toLowerCase();
      return r.receiptNumber.toLowerCase().contains(q) || payer.contains(q);
    }).toList();
  }

  List<InKindElectronicReceiptDto> _getFilteredInKind(
      List<InKindElectronicReceiptDto> list) {
    if (_selectedFilter == 'cash' || _selectedFilter == 'bank_transfer') {
      return [];
    }
    return list.where((r) {
      if (_selectedFilter == 'pending' &&
          r.processingStatus != InKindProcessingStatus.Pending) {
        return false;
      }
      if (_selectedFilter == 'consumed' &&
          r.processingStatus != InKindProcessingStatus.Consumed) {
        return false;
      }
      if (_selectedFilter == 'returned' &&
          r.processingStatus != InKindProcessingStatus.Returned) {
        return false;
      }
      if (_keyword.isEmpty) return true;
      final q = _keyword.toLowerCase();
      final payer = (r.payerMemberName ?? r.payerMemberId).toLowerCase();
      final item = r.itemName.toLowerCase();
      return r.receiptNumber.toLowerCase().contains(q) ||
          payer.contains(q) ||
          item.contains(q);
    }).toList();
  }

  Widget _buildEventBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFDF8), Color(0xFFF7EFE1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C8B1E1E),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final infoColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E1E).withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF8B1E1E), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B1E1E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'KỲ LỄ ĐANG DIỄN RA',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Color(0xFF8B1E1E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Hạch toán tự động qua VietQR & Sổ cái',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF54433E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B1810),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bàn tiếp nhận Thủ quỹ: Đối soát tức thì, tự động xuất biên lai điện tử và niêm phong sổ cái.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF54433E),
                height: 1.4,
              ),
            ),
          ],
        );

        final actionBtn = ElevatedButton.icon(
          onPressed: () => _showAddContributionModal(context),
          icon: const Icon(Icons.post_add, size: 20),
          label: const Text('Tiếp Nhận Đóng Góp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E1E),
            foregroundColor: Colors.white,
            minimumSize: const Size(170, 46),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              infoColumn,
              const SizedBox(height: 16),
              actionBtn,
            ],
          );
        }

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B1E1E), Color(0xFF6B1414)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x208B1E1E),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.celebration,
                  color: Color(0xFFD4A017), size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(child: infoColumn),
            const SizedBox(width: 18),
            actionBtn,
          ],
        );
      }),
    );
  }

  Widget _buildStatCards(ContributionUiState uiState, bool isDesktop) {
    final cards = [
      _statCard(
        title: 'TỔNG THU TIỀN MẶT / CK',
        value: currencyFormatter.format(uiState.totalCashAmount),
        subtitle: '${uiState.cashReceipts.length} lượt đóng góp đã tất toán',
        icon: Icons.payments,
        color: const Color(0xFF2E8B43),
        footerBadge: '+18.4% so với kỳ trước',
        footerIcon: Icons.trending_up,
      ),
      _statCard(
        title: 'ĐỐI SOÁT VIETQR TỰ ĐỘNG',
        value: '100% Khớp Số',
        subtitle: '${uiState.cashReceipts.where((r) => r.paymentMethod == PaymentMethod.BankTransfer).length} giao dịch tự động',
        icon: Icons.qr_code_2,
        color: const Color(0xFF3F51B5),
        footerBadge: 'Đồng bộ sao kê tức thì',
        footerIcon: Icons.verified,
      ),
      _statCard(
        title: 'HIỆN VẬT CÚNG TIẾN (QUY ĐỔI)',
        value: currencyFormatter.format(uiState.totalInKindConvertedAmount),
        subtitle: '${uiState.inKindReceipts.length} hiện vật đã tiếp nhận',
        icon: Icons.inventory_2,
        color: const Color(0xFFB36E1B),
        footerBadge: '${uiState.clanAssets.length} món trong kho từ đường',
        footerIcon: Icons.account_balance,
      ),
      _statCard(
        title: 'HIỆN VẬT CHỜ XỬ LÝ VÒNG ĐỜI',
        value: '${uiState.pendingInKindCount} hiện vật',
        subtitle: 'Cần phân loại: Tiêu hao cỗ / Nhập kho',
        icon: Icons.pending_actions,
        color: const Color(0xFFC64545),
        footerBadge: uiState.pendingInKindCount > 0 ? 'Cần xử lý sau đại lễ' : 'Đã phân loại xong',
        footerIcon: Icons.schedule,
        isAlert: uiState.pendingInKindCount > 0,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      );
    } else {
      return Column(
        children: cards
            .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: c,
                ))
            .toList(),
      );
    }
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String footerBadge,
    required IconData footerIcon,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAlert
              ? const Color(0xFFC64545).withAlpha(120)
              : const Color(0xFFE6DFD8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF54433E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF54433E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(footerIcon, size: 12, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    footerBadge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
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

  Widget _buildTransactionSection({
    required ContributionUiState uiState,
    required List<ElectronicReceiptDto> filteredCash,
    required List<InKindElectronicReceiptDto> filteredInKind,
    required int totalTransactions,
    required bool isDesktop,
  }) {
    final cashCount = uiState.cashReceipts
        .where((r) => r.paymentMethod == PaymentMethod.Cash)
        .length;
    final vietqrCount = uiState.cashReceipts
        .where((r) => r.paymentMethod == PaymentMethod.BankTransfer)
        .length;
    final inKindCount = uiState.inKindReceipts.length;
    final pendingCount = uiState.pendingInKindCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Sổ Cái
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sổ Cái Đối Soát Đóng Góp Sự Kiện',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B1810),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Danh sách ghi nhận các khoản cúng tiến bằng tiền mặt, chuyển khoản và hiện vật.',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF54433E)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang xuất sổ cái đối soát ra file PDF / Excel...'),
                        backgroundColor: Color(0xFF2E8B43),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Xuất Sổ Cái PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E8B43),
                    side: const BorderSide(color: Color(0xFF2E8B43)),
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE6DFD8)),

          // Thanh Tìm Kiếm Thời Gian Thực (UI/UX Pro Max)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _keyword = val.trim()),
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF2B1810)),
              decoration: InputDecoration(
                hintText:
                    'Tìm theo tên con cháu, mã phiếu thu (PT-...) hoặc tên hiện vật...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFF78655C)),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF8B1E1E), size: 20),
                suffixIcon: _keyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Color(0xFF54433E)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _keyword = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFFAF9F6),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE6DFD8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE6DFD8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF8B1E1E), width: 1.5),
                ),
              ),
            ),
          ),

          // Bộ Lọc Phân Đoạn Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all',
                    uiState.cashReceipts.length + uiState.inKindReceipts.length),
                const SizedBox(width: 8),
                _buildFilterChip('Tiền mặt', 'cash', cashCount),
                const SizedBox(width: 8),
                _buildFilterChip('VietQR Auto', 'bank_transfer', vietqrCount),
                const SizedBox(width: 8),
                _buildFilterChip('Hiện vật dâng lễ', 'in_kind', inKindCount),
                const SizedBox(width: 8),
                _buildFilterChip('Chờ xử lý cỗ/kho', 'pending', pendingCount,
                    isWarning: pendingCount > 0),
                const SizedBox(width: 8),
                _buildFilterChip('Đã tiêu hao cỗ', 'consumed', uiState.consumedInKindCount),
                const SizedBox(width: 8),
                _buildFilterChip('Đã hoàn trả', 'returned', uiState.returnedInKindCount),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE6DFD8)),

          // Empty state khi không khớp kết quả tìm kiếm
          if (totalTransactions == 0)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE6DFD8)),
                    ),
                    child: const Icon(Icons.search_off, size: 40, color: Color(0xFF78655C)),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _keyword.isNotEmpty
                        ? 'Không tìm thấy khoản đóng góp nào khớp với "$_keyword"'
                        : 'Không có giao dịch nào trong phân loại này',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B1810),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_keyword.isNotEmpty || _selectedFilter != 'all')
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _keyword = '';
                          _selectedFilter = 'all';
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Xóa bộ lọc để xem tất cả'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B1E1E),
                        side: const BorderSide(color: Color(0xFF8B1E1E)),
                      ),
                    ),
                ],
              ),
            ),

          // Render Desktop Table hoặc Mobile Cards
          if (totalTransactions > 0)
            if (isDesktop)
              _buildDesktopLedgerTable(filteredCash, filteredInKind)
            else
              _buildMobileLedgerCards(filteredCash, filteredInKind),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, int count,
      {bool isWarning = false}) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: isWarning
          ? const Color(0xFFC64545).withAlpha(30)
          : const Color(0xFF8B1E1E),
      backgroundColor: const Color(0xFFFAF9F6),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? (isWarning ? const Color(0xFFC64545) : Colors.white)
            : const Color(0xFF54433E),
      ),
      side: BorderSide(
        color: isSelected
            ? (isWarning ? const Color(0xFFC64545) : const Color(0xFF8B1E1E))
            : const Color(0xFFE6DFD8),
        width: 1.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  // Bảng Sổ Cái Chuẩn Desktop (Warm Editorial Data Table)
  Widget _buildDesktopLedgerTable(
    List<ElectronicReceiptDto> cashList,
    List<InKindElectronicReceiptDto> inKindList,
  ) {
    return Column(
      children: [
        // Table Header
        Container(
          color: const Color(0xFFF0EDEB),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: const [
              SizedBox(
                width: 150,
                child: Text(
                  'MÃ GD / NGÀY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'NGƯỜI NỘP / NỘI DUNG',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'HÌNH THỨC',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: Text(
                  'SỐ TIỀN / QUY ĐỔI',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: Text(
                  'TRẠNG THÁI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  'TÁC VỤ',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Hàng tiền mặt & chuyển khoản
        ...cashList.map((r) => _buildDesktopCashRow(r)),

        // Hàng hiện vật
        ...inKindList.map((r) => _buildDesktopInKindRow(r)),
      ],
    );
  }

  Widget _buildDesktopCashRow(ElectronicReceiptDto r) {
    final isVietQr = r.paymentMethod == PaymentMethod.BankTransfer;
    final initials = _getInitials(r.payerMemberName ?? r.payerMemberId);
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(r.contributionDate ?? DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0EDEB))),
      ),
      child: Row(
        children: [
          // Mã GD & Ngày
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.receiptNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF8B1E1E),
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF78655C),
                  ),
                ),
              ],
            ),
          ),

          // Người nộp & Avatar
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF8B1E1E).withAlpha(20),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B1E1E),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.payerMemberName ?? r.payerMemberId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                      Text(
                        'ID: ${r.payerMemberId}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF54433E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hình thức
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isVietQr
                      ? const Color(0xFFF0F2FE)
                      : const Color(0xFFEDF7EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVietQr
                        ? const Color(0xFF3F51B5).withAlpha(50)
                        : const Color(0xFF2E8B43).withAlpha(50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVietQr ? Icons.qr_code_2 : Icons.payments,
                      size: 13,
                      color: isVietQr
                          ? const Color(0xFF3F51B5)
                          : const Color(0xFF2E8B43),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        r.paymentMethod.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isVietQr
                              ? const Color(0xFF3F51B5)
                              : const Color(0xFF2E8B43),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Số tiền
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B43).withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2E8B43).withAlpha(40),
                  ),
                ),
                child: Text(
                  '+ ${currencyFormatter.format(r.amount)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF2E8B43),
                  ),
                ),
              ),
            ),
          ),

          // Trạng thái
          SizedBox(
            width: 180,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E8B43).withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2E8B43).withAlpha(50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, size: 12, color: Color(0xFF2E8B43)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Đã Tất Toán',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E8B43),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tác vụ
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ElectronicReceiptDialog(cashReceipt: r),
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 15),
                label: const Text('Xem Phiếu'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1E1E),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopInKindRow(InKindElectronicReceiptDto r) {
    final initials = _getInitials(r.payerMemberName ?? r.payerMemberId);
    final isPending = r.processingStatus == InKindProcessingStatus.Pending;
    final dateStr = r.contributionDate != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(r.contributionDate!)
        : '12/03/2026 09:14';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0EDEB))),
      ),
      child: Row(
        children: [
          // Mã GD & Ngày
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.receiptNumber,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF8B1E1E),
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF78655C),
                  ),
                ),
              ],
            ),
          ),

          // Người nộp & Hiện vật
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFB36E1B).withAlpha(20),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB36E1B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.itemName} (${r.quantity} ${r.unit})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                      Text(
                        'Cúng tiến: ${r.payerMemberName ?? r.payerMemberId} • ${r.conversionMethod.displayName}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF54433E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hình thức
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFB36E1B).withAlpha(50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.inventory_2, size: 13, color: Color(0xFFB36E1B)),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Hiện Vật Lễ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB36E1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Số tiền quy đổi
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFB36E1B).withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFB36E1B).withAlpha(40),
                  ),
                ),
                child: Text(
                  '~ ${currencyFormatter.format(r.convertedMonetaryValue)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFB36E1B),
                  ),
                ),
              ),
            ),
          ),

          // Trạng thái
          SizedBox(
            width: 180,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Color(r.processingStatus.bgColorValue),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(r.processingStatus.colorValue).withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPending ? Icons.schedule : Icons.check_circle,
                      size: 12,
                      color: Color(r.processingStatus.colorValue),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        r.processingStatus.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(r.processingStatus.colorValue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tác vụ
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerRight,
              child: isPending
                  ? ElevatedButton(
                      onPressed: () => _showProcessLifecycleDialog(r),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E1E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(80, 32),
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Phân Loại'),
                    )
                  : TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              ElectronicReceiptDialog(inKindReceipt: r),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, size: 15),
                      label: const Text('Xem Phiếu'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8B1E1E),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Danh sách dạng Cards cho thiết bị nhỏ / Mobile
  Widget _buildMobileLedgerCards(
    List<ElectronicReceiptDto> cashList,
    List<InKindElectronicReceiptDto> inKindList,
  ) {
    return Column(
      children: [
        if (cashList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            color: const Color(0xFFFAF9F6),
            child: Row(
              children: [
                const Text(
                  'KHOẢN ĐÓNG GÓP TIỀN MẶT / CHUYỂN KHOẢN',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF8B1E1E),
                  ),
                ),
                const Spacer(),
                Text(
                  '${cashList.length} khoản',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF54433E),
                  ),
                ),
              ],
            ),
          ),
          ...cashList.map((r) => _buildCashReceiptTile(r)),
        ],
        if (inKindList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            color: const Color(0xFFFAF9F6),
            child: Row(
              children: [
                const Text(
                  'HIỆN VẬT CÚNG TIẾN (DÂNG LỄ & TÀI SẢN)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFFB36E1B),
                  ),
                ),
                const Spacer(),
                Text(
                  '${inKindList.length} hiện vật',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF54433E),
                  ),
                ),
              ],
            ),
          ),
          ...inKindList.map((r) => _buildInKindReceiptTile(r)),
        ],
      ],
    );
  }

  Widget _buildCashReceiptTile(ElectronicReceiptDto receipt) {
    final isVietQr = receipt.paymentMethod == PaymentMethod.BankTransfer;
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(receipt.contributionDate ?? DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EDEB))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isVietQr
                  ? const Color(0xFF3F51B5).withAlpha(18)
                  : const Color(0xFF2E8B43).withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isVietQr ? Icons.qr_code_2 : Icons.payments,
              color: isVietQr
                  ? const Color(0xFF3F51B5)
                  : const Color(0xFF2E8B43),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      receipt.receiptNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF8B1E1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isVietQr
                            ? const Color(0xFFF0F2FE)
                            : const Color(0xFFEDF7EE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isVietQr
                              ? const Color(0xFF3F51B5).withAlpha(40)
                              : const Color(0xFF2E8B43).withAlpha(40),
                        ),
                      ),
                      child: Text(
                        receipt.paymentMethod.displayName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isVietQr
                              ? const Color(0xFF3F51B5)
                              : const Color(0xFF2E8B43),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  receipt.payerMemberName ?? receipt.payerMemberId,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1810),
                  ),
                ),
                Text(
                  'ID: ${receipt.payerMemberId} • $dateFormatted',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+ ${currencyFormatter.format(receipt.amount)}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B43),
                ),
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ElectronicReceiptDialog(cashReceipt: receipt),
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 15),
                label: const Text('Xem Phiếu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F0E8),
                  foregroundColor: const Color(0xFF8B1E1E),
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInKindReceiptTile(InKindElectronicReceiptDto receipt) {
    final isPending = receipt.processingStatus == InKindProcessingStatus.Pending;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0EDEB))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFB36E1B).withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2,
                color: Color(0xFFB36E1B), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      receipt.receiptNumber,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF8B1E1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Color(receipt.processingStatus.bgColorValue),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Color(receipt.processingStatus.colorValue)
                                .withAlpha(80)),
                      ),
                      child: Text(
                        receipt.processingStatus.displayName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(receipt.processingStatus.colorValue),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${receipt.itemName} (${receipt.quantity} ${receipt.unit})',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1810),
                  ),
                ),
                Text(
                  'Dâng lễ: ${receipt.payerMemberName ?? receipt.payerMemberId} • ${receipt.conversionMethod.displayName}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '~ ${currencyFormatter.format(receipt.convertedMonetaryValue)}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB36E1B),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            ElectronicReceiptDialog(inKindReceipt: receipt),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B1E1E),
                      side: const BorderSide(color: Color(0xFF8B1E1E)),
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Xem Phiếu'),
                  ),
                  if (isPending) ...[
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () => _showProcessLifecycleDialog(receipt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E1E),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Phân loại'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'FF';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showProcessLifecycleDialog(InKindElectronicReceiptDto item) {
    InKindProcessingStatus selectedStatus =
        InKindProcessingStatus.AddedToCommonAssets;
    final locationController = TextEditingController(
        text: 'Gian thờ chính - Nhà thờ tổ đại gia tộc');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFFDF9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFD4A017), width: 1.5),
            ),
            title: Row(
              children: [
                const Icon(Icons.sync_alt, color: Color(0xFF8B1E1E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phân Loại Vòng Đời: ${item.itemName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B1E1E),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn phương án xử lý hiện vật sau khi kết thúc nghi lễ tế tổ:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF54433E)),
                  ),
                  const SizedBox(height: 14),

                  RadioListTile<InKindProcessingStatus>(
                    title: const Text('Đã tiêu hao cỗ (Consumed)'),
                    subtitle: const Text('Heo quay, xôi hoa quả chia cho mâm cỗ thụ lộc'),
                    value: InKindProcessingStatus.Consumed,
                    groupValue: selectedStatus,
                    activeColor: const Color(0xFF8B1E1E),
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),
                  RadioListTile<InKindProcessingStatus>(
                    title: const Text('Đã hoàn trả gia chủ (Returned)'),
                    subtitle: const Text('Đồ lễ mượn, bàn ghế dâng lễ hoàn trả sau tiệc'),
                    value: InKindProcessingStatus.Returned,
                    groupValue: selectedStatus,
                    activeColor: const Color(0xFF8B1E1E),
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),
                  RadioListTile<InKindProcessingStatus>(
                    title: const Text(
                      'Nhập kho bảo vật Từ Đường (AddedToCommonAssets)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                        'Đồ thờ tự, lư hương, lục bình... lưu vào kho tài sản dòng họ vĩnh viễn'),
                    value: InKindProcessingStatus.AddedToCommonAssets,
                    groupValue: selectedStatus,
                    activeColor: const Color(0xFF8B1E1E),
                    onChanged: (v) => setDialogState(() => selectedStatus = v!),
                  ),

                  if (selectedStatus == InKindProcessingStatus.AddedToCommonAssets) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Vị trí lưu kho / đặt tại Nhà Thờ Tổ *',
                        prefixIcon: Icon(Icons.place, color: Color(0xFF8B1E1E)),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(contributionUiProvider.notifier).processInKindLifecycle(
                        contributionId: item.contributionId,
                        targetStatus: selectedStatus,
                        storageLocation: selectedStatus ==
                                InKindProcessingStatus.AddedToCommonAssets
                            ? locationController.text.trim()
                            : null,
                      );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        selectedStatus == InKindProcessingStatus.AddedToCommonAssets
                            ? 'Đã chuyển thành công "${item.itemName}" vào Sổ kho bảo vật Từ Đường!'
                            : 'Đã cập nhật trạng thái vòng đời thành công!',
                      ),
                      backgroundColor: const Color(0xFF2E8B43),
                    ),
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Lưu Trạng Thái'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E1E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Modal lập phiếu tiếp nhận đóng góp mới
  void _showAddContributionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddContributionSheet(),
    );
  }
}

/// Sheet nhập liệu tiếp nhận Tiền mặt, Chuyển khoản hoặc Hiện vật
/// Trang bị Trợ lý đọc số tiền bằng chữ thời gian thực (Live Preview - UI/UX Pro Max)
class _AddContributionSheet extends ConsumerStatefulWidget {
  const _AddContributionSheet();

  @override
  ConsumerState<_AddContributionSheet> createState() =>
      _AddContributionSheetState();
}

class _AddContributionSheetState extends ConsumerState<_AddContributionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form tiền
  final _cashPayerController =
      TextEditingController(text: 'Lê Văn Cường (Chi 2 - Đời 5)');
  final _cashAmountController = TextEditingController(text: '2000000');
  PaymentMethod _paymentMethod = PaymentMethod.BankTransfer;
  String _liveCashWords = 'Hai triệu đồng chẵn';

  // Form hiện vật
  final _inKindPayerController =
      TextEditingController(text: 'Lê Quang Huy (Chi 3 - Đời 5)');
  final _itemNameController = TextEditingController(text: 'Cặp hoành phi chữ Hán cổ');
  final _quantityController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'cặp');
  final _convertedValueController = TextEditingController(text: '8000000');
  ConversionMethod _conversionMethod = ConversionMethod.BtcBenchmark;
  String _liveInKindWords = 'Tám triệu đồng chẵn';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashPayerController.dispose();
    _cashAmountController.dispose();
    _inKindPayerController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _convertedValueController.dispose();
    super.dispose();
  }

  String _convertToWords(double amount) {
    return VietnameseMoneyConverter.toWords(amount);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh gạt modal
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6DFD8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Header Modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E1E).withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.post_add,
                        color: Color(0xFF8B1E1E), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiếp Nhận Đóng Góp Mới',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        Text(
                          'Cấp phiếu thu điện tử & ghi sổ cái tức thì',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF54433E)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE6DFD8)),

            // Tabs chọn Tiền mặt / Hiện vật
            Container(
              color: const Color(0xFFF5F0E8),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF8B1E1E),
                indicatorColor: const Color(0xFF8B1E1E),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(Icons.payments, size: 18), text: 'Tiền Mặt / VietQR'),
                  Tab(icon: Icon(Icons.inventory_2, size: 18), text: 'Hiện Vật Dâng Lễ'),
                ],
              ),
            ),

            // Nội dung 2 Form
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCashForm(),
                  _buildInKindForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _cashPayerController,
            decoration: const InputDecoration(
              labelText: 'Họ và tên con cháu đóng góp *',
              prefixIcon: Icon(Icons.person, color: Color(0xFF8B1E1E)),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<PaymentMethod>(
            value: _paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Phương thức thanh toán *',
              prefixIcon: Icon(Icons.account_balance_wallet,
                  color: Color(0xFF8B1E1E)),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: PaymentMethod.Cash,
                child: Text('Tiền Mặt Tại Bàn Tiếp Nhận'),
              ),
              DropdownMenuItem(
                value: PaymentMethod.BankTransfer,
                child: Text('Chuyển Khoản Tự Động (VietQR Khớp Số)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _paymentMethod = val);
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _cashAmountController,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0;
              setState(() {
                _liveCashWords = _convertToWords(parsed);
              });
            },
            decoration: const InputDecoration(
              labelText: 'Số tiền đóng góp (VNĐ) *',
              prefixIcon: Icon(Icons.monetization_on, color: Color(0xFF2E8B43)),
              suffixText: 'VNĐ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),

          // Trợ lý đọc số tiền bằng chữ (UI/UX Pro Max)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B43).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2E8B43).withAlpha(40),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over,
                    size: 18, color: Color(0xFF2E8B43)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Số tiền bằng chữ: $_liveCashWords',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E8B43),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () async {
              final amount =
                  double.tryParse(_cashAmountController.text.trim()) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập số tiền hợp lệ lớn hơn 0!'),
                    backgroundColor: Color(0xFFC64545),
                  ),
                );
                return;
              }

              final newReceipt = await
                  ref.read(contributionUiProvider.notifier).recordCashContribution(
                        eventId: 'EVT-GIO-TO-2026',
                        payerMemberId: 'MEM-TEMP-${1000 + Random().nextInt(9000)}',
                        payerMemberName: _cashPayerController.text.trim(),
                        amount: amount,
                        paymentMethod: _paymentMethod,
                      );

              if (!mounted) return;
              Navigator.of(context).pop();

              showDialog(
                context: context,
                builder: (_) => ElectronicReceiptDialog(cashReceipt: newReceipt),
              );
            },
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text(
              'Xác Nhận & Cấp Phiếu Thu Điện Tử',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E1E),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInKindForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _inKindPayerController,
            decoration: const InputDecoration(
              labelText: 'Họ và tên con cháu cúng tiến *',
              prefixIcon: Icon(Icons.person, color: Color(0xFF8B1E1E)),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _itemNameController,
            decoration: const InputDecoration(
              labelText: 'Tên vật phẩm / đồ lễ dâng hương *',
              prefixIcon: Icon(Icons.inventory_2, color: Color(0xFFB36E1B)),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị tính *',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<ConversionMethod>(
            value: _conversionMethod,
            decoration: const InputDecoration(
              labelText: 'Phương thức quy đổi giá trị *',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: ConversionMethod.BtcBenchmark,
                child: Text('Định Mức Ban Tổ Chức'),
              ),
              DropdownMenuItem(
                value: ConversionMethod.Invoice,
                child: Text('Hóa Đơn Mua Hàng Thực Tế'),
              ),
              DropdownMenuItem(
                value: ConversionMethod.Agreement,
                child: Text('Hội Đồng Gia Tộc Thỏa Thuận'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _conversionMethod = val);
            },
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _convertedValueController,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0;
              setState(() {
                _liveInKindWords = _convertToWords(parsed);
              });
            },
            decoration: const InputDecoration(
              labelText: 'Giá trị quy đổi ước tính (VNĐ) *',
              prefixIcon: Icon(Icons.price_check, color: Color(0xFFB36E1B)),
              suffixText: 'VNĐ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFB36E1B).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFB36E1B).withAlpha(40),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.record_voice_over,
                    size: 18, color: Color(0xFFB36E1B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Giá trị bằng chữ: $_liveInKindWords',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB36E1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () async {
              final val =
                  double.tryParse(_convertedValueController.text.trim()) ?? 0;
              final qty = double.tryParse(_quantityController.text.trim()) ?? 1;

              final newReceipt = await ref
                  .read(contributionUiProvider.notifier)
                  .recordInKindContribution(
                    eventId: 'EVT-GIO-TO-2026',
                    payerMemberId: 'MEM-TEMP-${1000 + Random().nextInt(9000)}',
                    payerMemberName: _inKindPayerController.text.trim(),
                    itemName: _itemNameController.text.trim(),
                    quantity: qty,
                    unit: _unitController.text.trim(),
                    conversionMethod: _conversionMethod,
                    convertedMonetaryValue: val,
                  );

              if (!mounted) return;
              Navigator.of(context).pop();

              showDialog(
                context: context,
                builder: (_) =>
                    ElectronicReceiptDialog(inKindReceipt: newReceipt),
              );
            },
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text(
              'Tiếp Nhận Hiện Vật & Xuất Phiếu',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E1E),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
