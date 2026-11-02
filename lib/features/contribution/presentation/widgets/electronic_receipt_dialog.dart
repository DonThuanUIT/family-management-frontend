import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../data/models/contribution_models.dart';
import '../services/contribution_pdf_service.dart';

/// Task #74: Hộp thoại In / Xuất Phiếu Thu Điện Tử & Chứng Nhận Công Đức Dòng Họ.
/// Chuẩn hóa theo tiêu chuẩn UI/UX Pro Max:
/// - Vùng chạm >= 44x44pt, độ tương phản >= 4.5:1.
/// - Sao chép mã biên lai 1-chạm (Clipboard).
/// - Con dấu mộc đỏ nghiêng tự nhiên tạo cảm giác chân thực giấy dó truyền thống.
class ElectronicReceiptDialog extends StatelessWidget {
  final ElectronicReceiptDto? cashReceipt;
  final InKindElectronicReceiptDto? inKindReceipt;

  const ElectronicReceiptDialog({
    super.key,
    this.cashReceipt,
    this.inKindReceipt,
  }) : assert(cashReceipt != null || inKindReceipt != null,
            'Phải truyền cashReceipt hoặc inKindReceipt');

  bool get isInKind => inKindReceipt != null;

  String get receiptNumber =>
      isInKind ? inKindReceipt!.receiptNumber : cashReceipt!.receiptNumber;

  String get payerName => isInKind
      ? (inKindReceipt!.payerMemberName ?? inKindReceipt!.payerMemberId)
      : (cashReceipt!.payerMemberName ?? cashReceipt!.payerMemberId);

  String get eventName => isInKind
      ? (inKindReceipt!.eventName ?? 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026')
      : (cashReceipt!.eventName ?? 'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026');

  DateTime get date => isInKind
      ? (inKindReceipt!.contributionDate ?? DateTime.now())
      : (cashReceipt!.contributionDate ?? DateTime.now());

  List<MemberAllocationDto> get allocations =>
      isInKind ? inKindReceipt!.allocations : cashReceipt!.allocations;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

    final amountValue =
        isInKind ? inKindReceipt!.convertedMonetaryValue : cashReceipt!.amount;
    final rawAmountWords = isInKind
        ? (inKindReceipt!.convertedMonetaryValueInWords ?? '')
        : (cashReceipt!.amountInWords ?? '');
    final amountWords = (rawAmountWords.isNotEmpty && !rawAmountWords.contains(RegExp(r'\d')))
        ? rawAmountWords
        : VietnameseMoneyConverter.toWords(amountValue);
    final isAddedToClanAssets = isInKind &&
        inKindReceipt!.processingStatus ==
            InKindProcessingStatus.AddedToCommonAssets;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 660,
        constraints: const BoxConstraints(maxHeight: 880),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF9), // Giấy ngà cổ kính
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4A017), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF8B1E1E), // Đỏ son
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFFD4A017), size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'PHIẾU THU & CHỨNG NHẬN CÔNG ĐỨC ĐIỆN TỬ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
            ),

            // Scrollable Receipt Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tiêu đề & Dòng tộc
                    const Text(
                      'HỘI ĐỒNG GIA TỘC ĐẠI TỘC VIỆT NAM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Color(0xFF8B1E1E),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'BAN QUẢN LÝ TÀI CHÍNH & TỪ ĐƯỜNG TỔ',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '✦ ✦ ✦',
                      style: TextStyle(color: Color(0xFFD4A017), fontSize: 11),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      isInKind
                          ? 'BIÊN LAI TIẾP NHẬN HIỆN VẬT CÚNG TIẾN'
                          : 'PHIẾU THU CÔNG ĐỨC DÒNG HỌ',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1E1E),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Mã số biên lai kèm nút sao chép 1-chạm
                    Tooltip(
                      message: 'Bấm để sao chép mã biên lai',
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: receiptNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Đã sao chép mã biên lai "$receiptNumber" vào bộ nhớ tạm!'),
                              backgroundColor: const Color(0xFF2E8B43),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F0E8),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFD4A017).withAlpha(100)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Mã số biên lai: $receiptNumber',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF54433E),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy_rounded,
                                  size: 14, color: Color(0xFF8B1E1E)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 28, color: Color(0xFFE8DFD8)),

                    // Thông tin cơ bản
                    _buildRow('Sự kiện / Lễ giỗ:', eventName, isBold: true),
                    const SizedBox(height: 8),
                    _buildRow('Thời gian ghi nhận:', formattedDate),
                    const SizedBox(height: 8),
                    _buildRow('Người cúng tiến:', payerName,
                        isBold: true, highlightColor: const Color(0xFF8B1E1E)),
                    const SizedBox(height: 8),

                    if (isInKind) ...[
                      _buildRow('Hiện vật dâng lễ:', inKindReceipt!.itemName,
                          isBold: true),
                      const SizedBox(height: 8),
                      _buildRow('Số lượng / Đơn vị:',
                          '${inKindReceipt!.quantity} ${inKindReceipt!.unit}'),
                      const SizedBox(height: 8),
                      _buildRow('Cách thức định giá:',
                          inKindReceipt!.conversionMethod.displayName),
                      const SizedBox(height: 8),
                      _buildRow('Giá trị quy đổi:',
                          currencyFormatter.format(amountValue),
                          isBold: true, highlightColor: const Color(0xFF2E8B43)),
                      const SizedBox(height: 8),
                      _buildRow('Trạng thái vòng đời:',
                          inKindReceipt!.processingStatus.displayName,
                          highlightColor: Color(inKindReceipt!.processingStatus.colorValue)),
                      if (inKindReceipt!.storageLocation != null) ...[
                        const SizedBox(height: 8),
                        _buildRow('Vị trí lưu kho:',
                            inKindReceipt!.storageLocation!,
                            isBold: true),
                      ],
                    ] else ...[
                      _buildRow('Hình thức đóng góp:',
                          cashReceipt!.paymentMethod.displayName),
                      const SizedBox(height: 8),
                      _buildRow('Số tiền cúng đức:',
                          currencyFormatter.format(amountValue),
                          isBold: true, highlightColor: const Color(0xFF2E8B43)),
                    ],

                    if (amountWords.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F6F0),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8DFD8)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bằng chữ: ',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF54433E)),
                            ),
                            Expanded(
                              child: Text(
                                amountWords,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B1E1E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Danh sách phân bổ cho nhiều con cháu
                    if (allocations.length > 1) ...[
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Danh sách con cháu đồng ghi nhận công đức (${allocations.length} người):',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE8DFD8)),
                        ),
                        child: Column(
                          children: allocations.map((alloc) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '• ${alloc.memberName} (${alloc.generation})',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2B1810)),
                                    ),
                                  ),
                                  Text(
                                    currencyFormatter.format(alloc.amount),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8B1E1E),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${alloc.percentage.toStringAsFixed(0)}%)',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF6B584E)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    if (isAddedToClanAssets) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF4EB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD4A017)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.account_balance,
                                size: 16, color: Color(0xFF8B1E1E)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hiện vật đã được Hội đồng gia tộc thẩm định & nhập Kho Bảo Vật Từ Đường (Đã ghi danh Sổ Vàng Gia Tộc).',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8B1E1E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Con dấu & Chữ ký 3 bên
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSigner('NGƯỜI DÂNG LỄ', '(Ký & ghi rõ họ tên)',
                            payerName),
                        _buildReceiverSigner('NGƯỜI TIẾP NHẬN', '(Ký & xác nhận)',
                            'Bàn Tiếp Nhận Sự Kiện'),
                        Transform.rotate(
                          angle: -0.06,
                          child: _buildTreasurerStamp(
                            'THỦ QUỸ SỰ KIỆN',
                            '(Chứng thực & Đóng dấu)',
                            'Ban Tài Chính Dòng Họ',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0E8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE6DFD8)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 18, color: Color(0xFF2E8B43)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Chứng từ điện tử hợp lệ được cấp bởi Ban Tài Chính Sự Kiện 2026. Đã ghi nhận vào Sổ cái gia tộc & đối soát 1:1',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E8B43),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons (Touch target >= 44dp)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F6F0),
                border: Border(top: BorderSide(color: Color(0xFFE8DFD8))),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(13),
                  bottomRight: Radius.circular(13),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Quay lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF54433E),
                      side: const BorderSide(color: Color(0xFFD4A017)),
                      minimumSize: const Size(88, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  Wrap(
                    spacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await ContributionPdfService.exportReceiptPdf(
                              cashReceipt: cashReceipt,
                              inKindReceipt: inKindReceipt,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi tải tệp PDF: $e'),
                                  backgroundColor: const Color(0xFFBA1A1A),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Tải PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E8B43),
                          side: const BorderSide(color: Color(0xFF2E8B43)),
                          minimumSize: const Size(100, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await ContributionPdfService.exportReceiptPdf(
                              cashReceipt: cashReceipt,
                              inKindReceipt: inKindReceipt,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Lỗi in phiếu thu: $e'),
                                  backgroundColor: const Color(0xFFBA1A1A),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('In Phiếu Thu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1E1E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(120, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
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
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? highlightColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 170,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF54433E), // Tương phản cao >= 4.5:1
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: highlightColor ?? const Color(0xFF2B1810),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSigner(String title, String subtitle, String name) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B1810),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10.5,
            fontStyle: FontStyle.italic,
            color: Color(0xFF54433E),
          ),
        ),
        const SizedBox(height: 38),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B1810),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiverSigner(String title, String subtitle, String name) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B1810),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10.5,
            fontStyle: FontStyle.italic,
            color: Color(0xFF54433E),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF2E8B43).withAlpha(20),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2E8B43).withAlpha(70)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 11, color: Color(0xFF2E8B43)),
              SizedBox(width: 4),
              Text(
                'ĐÃ TIẾP NHẬN',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E8B43),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B1810),
          ),
        ),
      ],
    );
  }

  Widget _buildTreasurerStamp(String title, String subtitle, String name) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B1810),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFF54433E),
              ),
            ),
            const SizedBox(height: 38),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B1810),
              ),
            ),
          ],
        ),
        Positioned(
          top: 14,
          child: Opacity(
            opacity: 0.90,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC64545), width: 2.2),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BAN TÀI CHÍNH',
                      style: TextStyle(
                        color: Color(0xFFC64545),
                        fontWeight: FontWeight.bold,
                        fontSize: 7.2,
                      ),
                    ),
                    Text(
                      '★ CHỨNG THỰC ★',
                      style: TextStyle(
                        color: Color(0xFFC64545),
                        fontWeight: FontWeight.w900,
                        fontSize: 6.2,
                      ),
                    ),
                    Text(
                      'CÔNG ĐỨC',
                      style: TextStyle(
                        color: Color(0xFFC64545),
                        fontWeight: FontWeight.bold,
                        fontSize: 7.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
