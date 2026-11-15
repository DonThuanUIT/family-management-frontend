import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../data/models/contribution_models.dart';
import '../../data/repositories/contribution_repository_impl.dart';
import '../providers/contribution_ui_provider.dart';

/// Màn hình 'Đóng góp của tôi' (US-49, Task #175)
/// Hiển thị lịch sử đóng góp cá nhân, tổng đóng góp của nhánh gia đình và nút Xem / In / Tải phiếu thu PDF.
/// Nối trực tiếp 100% Backend REST API (GET /api/v1/contributions/my-history, GET /api/v1/contributions/receipts/{receiptNumber}/pdf).
class MyContributionHistoryScreen extends ConsumerStatefulWidget {
  const MyContributionHistoryScreen({super.key});

  @override
  ConsumerState<MyContributionHistoryScreen> createState() =>
      _MyContributionHistoryScreenState();
}

class _MyContributionHistoryScreenState
    extends ConsumerState<MyContributionHistoryScreen> {
  bool _includeFamily = false;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Trạng thái đang tải file PDF
  String? _downloadingReceiptNumber;

  Future<void> _handleDownloadPdf(String receiptNumber) async {
    setState(() => _downloadingReceiptNumber = receiptNumber);
    try {
      final repo = ref.read(contributionRepositoryProvider);
      final pdfBytes = await repo.downloadReceiptPdf(receiptNumber);

      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'Phieu_Thu_$receiptNumber.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải phiếu thu PDF: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingReceiptNumber = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(myContributionHistoryProvider(_includeFamily));
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    const kPrimaryColor = Color(0xFF8B1E1E);
    const kBgColor = Color(0xFFFAF9F6);

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: const HeritageNavBar(currentRoute: '/contributions/my-history'),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/contributions/my-history'),
      body: historyAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: kPrimaryColor),
                SizedBox(height: 16),
                Text(
                  'Đang tải lịch sử công đức & đóng góp từ hệ thống...',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Color(0xFF54433E)),
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFBA1A1A)),
                const SizedBox(height: 12),
                Text(
                  'Lỗi tải lịch sử đóng góp: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(myContributionHistoryProvider(_includeFamily)),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
        data: (history) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tiêu đề phân hệ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFD4A017)),
                              ),
                              child: const Icon(Icons.history_edu, color: kPrimaryColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đóng Góp Của Tôi & Gia Đình',
                                  style: TextStyle(
                                    fontFamily: 'Merriweather',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                                Text(
                                  'Thành viên: ${history.memberName} • Chi phái: ${history.branchName ?? 'Đại Tôn'}',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12.5,
                                    color: Color(0xFF6B584E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Switch xem cả hộ gia đình / nhánh
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE6DFD8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Bao gồm gia đình/nhánh:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _includeFamily,
                                activeThumbColor: kPrimaryColor,
                                onChanged: (val) {
                                  setState(() => _includeFamily = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Hai thẻ tổng quan đóng góp (US-49)
                    if (isDesktop)
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'TỔNG ĐÓNG GÓP CÁ NHÂN',
                              amount: history.totalPersonalContributed,
                              subtitle: 'Các khoản ghi nhận đứng tên trực tiếp bạn',
                              icon: Icons.person_pin,
                              accentColor: const Color(0xFF2E8B43),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'TỔNG ĐÓNG GÓP CẢ NHÁNH / GIA ĐÌNH',
                              amount: history.totalAllocated,
                              subtitle: 'Bao gồm phần phân bổ công đức cho hộ gia đình',
                              icon: Icons.family_restroom,
                              accentColor: const Color(0xFFD4A017),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildSummaryCard(
                            title: 'TỔNG ĐÓNG GÓP CÁ NHÂN',
                            amount: history.totalPersonalContributed,
                            subtitle: 'Các khoản ghi nhận đứng tên trực tiếp bạn',
                            icon: Icons.person_pin,
                            accentColor: const Color(0xFF2E8B43),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryCard(
                            title: 'TỔNG ĐÓNG GÓP CẢ NHÁNH / GIA ĐÌNH',
                            amount: history.totalAllocated,
                            subtitle: 'Bao gồm phần phân bổ công đức cho hộ gia đình',
                            icon: Icons.family_restroom,
                            accentColor: const Color(0xFFD4A017),
                          ),
                        ],
                      ),

                    // Chi tiết phân rã đệ quy chi nhánh (US-11 & US-49: BranchContributionController)
                    if (history.branchId != null && history.branchId!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ref.watch(branchRecursiveContributionSummaryProvider(history.branchId!)).when(
                        data: (branchSummary) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_tree_outlined, color: Color(0xFF8B1E1E), size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Tổng đóng góp đệ quy toàn chi phái ${branchSummary.branchName}: ',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2B1810), fontSize: 13),
                                      ),
                                      TextSpan(
                                        text: _currencyFormat.format(branchSummary.totalRecursiveAmount),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B1E1E), fontSize: 13.5),
                                      ),
                                      TextSpan(
                                        text: ' (Trực tiếp chi phái: ${_currencyFormat.format(branchSummary.directTotalAmount)} • Các nhánh con: ${_currencyFormat.format(branchSummary.descendantsTotalAmount)})',
                                        style: const TextStyle(color: Color(0xFF6B584E), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Danh sách chi tiết các lần đóng góp
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE6DFD8)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sổ Lịch Sử Đóng Góp (${history.items.length} giao dịch)',
                                  style: const TextStyle(
                                    fontFamily: 'Merriweather',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                                Text(
                                  'Dữ liệu đối soát trực tiếp từ máy chủ',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE6DFD8)),

                          if (history.items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Chưa có lịch sử đóng góp nào được ghi nhận.',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Các khoản công đức trực tiếp hoặc qua VietQR sẽ tự động xuất hiện tại đây.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: history.items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0EDEB)),
                              itemBuilder: (ctx, idx) {
                                final item = history.items[idx];
                                return _buildHistoryItemRow(item, isDesktop);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF6B584E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(amount),
                  style: TextStyle(
                    fontFamily: 'Merriweather',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF78655C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItemRow(MemberContributionHistoryItemDto item, bool isDesktop) {
    const kPrimaryColor = Color(0xFF8B1E1E);
    final isCash = item.contributionType == 'Cash';
    final dateStr = item.contributionDate != null ? _dateFormat.format(item.contributionDate!) : 'Chưa cập nhật';
    final isDownloading = _downloadingReceiptNumber == item.receiptNumber;

    final typeIcon = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCash ? const Color(0xFF2E8B43).withValues(alpha: 0.1) : const Color(0xFFD4A017).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isCash ? Icons.payments : Icons.inventory_2,
        color: isCash ? const Color(0xFF2E8B43) : const Color(0xFFB36E1B),
        size: 20,
      ),
    );

    final infoContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              item.receiptNumber,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDEB),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.paymentMethod.displayName,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          isCash ? 'Đóng góp tiền mặt / chuyển khoản' : 'Hiện vật: ${item.itemName ?? 'Cúng tiến'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF2B1810)),
        ),
        Text(
          'Sự kiện: ${item.eventName ?? item.eventId} • $dateStr',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF78655C)),
        ),
      ],
    );

    final amountContent = Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          _currencyFormat.format(item.totalMonetaryValue),
          style: TextStyle(
            fontFamily: 'Merriweather',
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
            color: isCash ? const Color(0xFF2E8B43) : const Color(0xFFB36E1B),
          ),
        ),
        if (item.myAllocatedAmount > 0 && item.myAllocatedAmount != item.totalMonetaryValue)
          Text(
            'Phân bổ: ${_currencyFormat.format(item.myAllocatedAmount)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF006E2A), fontWeight: FontWeight.w600),
          ),
      ],
    );

    final pdfButton = ElevatedButton.icon(
      onPressed: isDownloading ? null : () => _handleDownloadPdf(item.receiptNumber),
      icon: isDownloading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.picture_as_pdf, size: 16),
      label: Text(isDownloading ? 'Đang tải...' : 'In / Tải PDF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );

    if (!isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                typeIcon,
                const SizedBox(width: 12),
                Expanded(child: infoContent),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                amountContent,
                pdfButton,
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          typeIcon,
          const SizedBox(width: 14),
          Expanded(flex: 4, child: infoContent),
          Expanded(flex: 3, child: amountContent),
          const SizedBox(width: 16),
          pdfButton,
        ],
      ),
    );
  }
}
