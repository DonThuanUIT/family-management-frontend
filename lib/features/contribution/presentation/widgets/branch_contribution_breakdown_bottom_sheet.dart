import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/adaptive_modal.dart';
import '../../data/models/branch_recursive_contribution_models.dart';
import '../services/contribution_pdf_service.dart';

/// Modal BottomSheet hiển thị phân rã chi tiết cơ cấu cúng tiến đệ quy của một chi nhánh (US-11).
/// Hỗ trợ:
/// - Duyệt đệ quy sâu (Drill-down) trực tiếp trong 1 modal kèm Breadcrumb và nút Quay lại.
/// - Công thức tính tổng đệ quy tự thân + các nhánh con.
/// - Tách bạch tiền mặt và hiện vật quy đổi.
/// - Xuất file PDF Trích Lục Sổ Vàng Nhánh Chi có dấu đỏ dòng họ.
class BranchContributionBreakdownBottomSheet extends ConsumerStatefulWidget {
  final BranchRecursiveContributionDto initialSummary;
  final String? eventId;
  final int? year;

  const BranchContributionBreakdownBottomSheet({
    super.key,
    required this.initialSummary,
    this.eventId,
    this.year,
  });

  static Future<void> show(
    BuildContext context, {
    required BranchRecursiveContributionDto summary,
    String? eventId,
    int? year,
  }) {
    return showAdaptiveSheetOrDialog(
      context: context,
      maxDesktopWidth: 740,
      builder: (context) => BranchContributionBreakdownBottomSheet(
        initialSummary: summary,
        eventId: eventId,
        year: year,
      ),
    );
  }

  @override
  ConsumerState<BranchContributionBreakdownBottomSheet> createState() =>
      _BranchContributionBreakdownBottomSheetState();
}

class _BranchContributionBreakdownBottomSheetState
    extends ConsumerState<BranchContributionBreakdownBottomSheet> {
  static final _currencyFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Lịch sử duyệt đệ quy (Breadcrumb navigation stack)
  late List<BranchRecursiveContributionDto> _navigationStack;

  @override
  void initState() {
    super.initState();
    _navigationStack = [widget.initialSummary];
  }

  BranchRecursiveContributionDto get _currentSummary => _navigationStack.last;
  bool get _canGoBack => _navigationStack.length > 1;

  void _drillDown(BranchRecursiveContributionDto child) {
    setState(() {
      _navigationStack.add(child);
    });
  }

  void _popDrillDown() {
    if (_canGoBack) {
      setState(() {
        _navigationStack.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryMaroon = Color(0xFF8B1E1E); // Đỏ Huyết Dụ chuẩn DESIGN.md
    const kSecondaryGold = Color(0xFFD4AF37); // Vàng Hoàng Kim
    const kBackgroundIvory = Color(0xFFFAF9F6); // Trắng Ngà
    const kBorderColor = Color(0xFFE5E5E5);

    final summary = _currentSummary;
    final eventNameText = summary.eventName != null && summary.eventName!.isNotEmpty
        ? summary.eventName!
        : (summary.year != null ? 'Niên khóa ${summary.year}' : 'Toàn bộ thời gian');

    return Container(
      constraints: BoxConstraints(
        maxWidth: 740,
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: kBorderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPrimaryMaroon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CHI TIẾT PHÂN RÃ',
                          style: TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryMaroon,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cơ Cấu Đệ Quy Cúng Tiến',
                        style: const TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryMaroon,
                        ),
                      ),
                      Text(
                        'Nhánh ${summary.branchName} (Đời ${summary.generationLevel ?? '?'})',
                        style: const TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 12,
                          color: Color(0xFF58413F),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF58413F)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F3F1),
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ),

          // Breadcrumb Bar (hiển thị khi đang drill-down vào nhánh con)
          if (_canGoBack)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kBackgroundIvory,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorderColor),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _popDrillDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_ios, size: 12, color: kPrimaryMaroon),
                        SizedBox(width: 4),
                        Text(
                          'Quay lại',
                          style: TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryMaroon,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: Color(0xFF8B716E))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _navigationStack
                          .map((e) => e.branchName.replaceAll('Nhánh ', '').replaceAll('Chi ', ''))
                          .join(' > '),
                      style: const TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontSize: 11,
                        color: Color(0xFF58413F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: kBorderColor),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Box Công Thức Tính Tổng Đệ Quy
                  _buildFormulaBox(
                    summary: summary,
                    eventName: eventNameText,
                    primaryColor: kPrimaryMaroon,
                    goldColor: kSecondaryGold,
                    bgColor: kBackgroundIvory,
                    borderColor: kBorderColor,
                  ),

                  const SizedBox(height: 20),

                  // 2. Section Tiêu Đề Phân Rã
                  Row(
                    children: [
                      Icon(Icons.pie_chart_outline, size: 18, color: kPrimaryMaroon),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Phân Rã Đóng Góp Thành Phần',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1A),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. Item Đóng Góp Trực Tiếp Tự Thân Nhánh
                  _buildDirectContributionCard(
                    summary: summary,
                    primaryColor: kPrimaryMaroon,
                    borderColor: kBorderColor,
                  ),

                  const SizedBox(height: 10),

                  // 4. Danh Sách Các Nhánh Con Trực Thuộc (hỗ trợ Drill-down)
                  if (summary.hasChildBranches)
                    ...summary.childBranches.map((child) {
                      final percent = summary.totalRecursiveAmount > 0
                          ? (child.totalRecursiveAmount / summary.totalRecursiveAmount) * 100
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildChildBranchCard(
                          child: child,
                          percentage: percent,
                          primaryColor: kPrimaryMaroon,
                          goldColor: kSecondaryGold,
                          borderColor: kBorderColor,
                          onTap: () => _drillDown(child),
                        ),
                      );
                    })
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kBackgroundIvory,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFF8B716E)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nhánh lá hiện tại chưa có nhánh con trực thuộc bên dưới. 100% công đức thuộc tự thân chi nhánh.',
                              style: TextStyle(
                                fontFamily: 'Be Vietnam Pro',
                                fontSize: 11.5,
                                color: Color(0xFF58413F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 5. Nút Xuất PDF Trích Lục Sổ Vàng Dấu Đỏ
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _exportPdf(summary),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                      label: const Text(
                        'Trích Lục Sổ Vàng Nhánh Chi (PDF Dấu Đỏ)',
                        style: TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryMaroon,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hộp hiển thị công thức đệ quy thông minh
  Widget _buildFormulaBox({
    required BranchRecursiveContributionDto summary,
    required String eventName,
    required Color primaryColor,
    required Color goldColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Công thức tính tổng nhánh:',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF58413F),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFED65B).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    eventName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Be Vietnam Pro',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF735C00),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dòng Tự Thân
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Text(
                '∑ Nhánh = ',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Text(
                _currencyFormatter.format(summary.directTotalAmount),
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1A),
                ),
              ),
              const Text(
                '(Tự thân)',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 11.5,
                  color: Color(0xFF58413F),
                ),
              ),
            ],
          ),

          // Các dòng nhánh con
          if (summary.hasChildBranches)
            ...summary.childBranches.map((child) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Text(
                        '+ ',
                        style: TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B716E),
                        ),
                      ),
                      Text(
                        _currencyFormatter.format(child.totalRecursiveAmount),
                        style: const TextStyle(
                          fontFamily: 'JetBrains Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '(${child.branchName})',
                          style: const TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 11.5,
                            color: Color(0xFF58413F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 8),

          // Tổng kết quả
          Row(
            children: [
              Text(
                '= ',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              Text(
                _currencyFormatter.format(summary.totalRecursiveAmount),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          // Tách bạch tiền mặt vs hiện vật
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    '💵 Tiền mặt: ${_currencyFormatter.format(summary.totalRecursiveCashAmount)}',
                    style: const TextStyle(
                      fontFamily: 'Be Vietnam Pro',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                  Text(
                    '🎁 Hiện vật: ${_currencyFormatter.format(summary.totalRecursiveInKindAmount)}',
                    style: const TextStyle(
                      fontFamily: 'Be Vietnam Pro',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ tự thân chi nhánh
  Widget _buildDirectContributionCard({
    required BranchRecursiveContributionDto summary,
    required Color primaryColor,
    required Color borderColor,
  }) {
    final directPercent = summary.directPercentage;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đóng góp trực tiếp (${summary.branchName} - Tự thân)',
                        style: const TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormatter.format(summary.directTotalAmount),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                  Text(
                    '${directPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              '${summary.directContributingMemberCount} thành viên đóng góp • ${summary.directContributionCount} phiếu thu (Đã kiểm ngân)',
              style: const TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontSize: 11,
                color: Color(0xFF58413F),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (directPercent / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFFE5E5E5),
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ chi nhánh con trực thuộc (có nút drill-down)
  Widget _buildChildBranchCard({
    required BranchRecursiveContributionDto child,
    required double percentage,
    required Color primaryColor,
    required Color goldColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
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
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: goldColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          child.branchName,
                          style: const TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8B716E)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormatter.format(child.totalRecursiveAmount),
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF735C00),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                '${child.totalRecursiveMemberCount} nhân khẩu tham gia • ${child.childBranches.length} chi nhánh con',
                style: const TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 11,
                  color: Color(0xFF58413F),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE5E5E5),
                  valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportPdf(BranchRecursiveContributionDto summary) async {
    try {
      await ContributionPdfService.exportBranchGoldBookPdf(summary: summary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất PDF: ${e.toString()}'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }
}
