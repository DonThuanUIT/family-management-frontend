import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/contribution_models.dart';

/// Dịch vụ xuất file PDF Sổ Cái và Biên Lai Điện Tử chuẩn Di Sản & In Ấn.
class ContributionPdfService {
  static final currencyFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  /// Xuất file PDF Sổ Cái Đối Soát Đóng Góp Sự Kiện
  static Future<void> exportLedgerPdf({
    required String eventName,
    required List<ElectronicReceiptDto> cashReceipts,
    required List<InKindElectronicReceiptDto> inKindReceipts,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    final totalCash =
        cashReceipts.fold<double>(0.0, (sum, item) => sum + item.amount);
    final totalInKind = inKindReceipts.fold<double>(
        0.0, (sum, item) => sum + item.convertedMonetaryValue);
    final totalCount = cashReceipts.length + inKindReceipts.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
          italic: italicFont,
        ),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DÒNG HỌ NGUYỄN TỘC (ĐẠI TÔN) • TỪ ĐƯỜNG DÒNG HỌ',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 10,
                        color: PdfColors.brown900,
                      ),
                    ),
                    pw.Text(
                      'BAN QUẢN LÝ TÀI CHÍNH & TỪ ĐƯỜNG TỔ',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Niên khóa 2026 - Kỷ Lễ Xuân Bính Ngọ',
                  style: pw.TextStyle(
                    font: italicFont,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1, color: PdfColors.brown),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) => [
          // Tiêu đề chính
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'SỔ CÁI ĐỐI SOÁT CÔNG ĐỨC & ĐÓNG GÓP',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 16,
                    color: PdfColors.brown900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  eventName,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    color: PdfColors.brown700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Ngày in sổ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(font: italicFont, fontSize: 9.5),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Khối tóm tắt KPI
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text('TỔNG GIAO DỊCH',
                        style: pw.TextStyle(font: boldFont, fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.Text('$totalCount khoản',
                        style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: PdfColors.brown900)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('TIỀN MẶT / CHUYỂN KHOẢN',
                        style: pw.TextStyle(font: boldFont, fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.Text(currencyFormatter.format(totalCash),
                        style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: PdfColors.green800)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('HIỆN VẬT QUY ĐỔI',
                        style: pw.TextStyle(font: boldFont, fontSize: 9)),
                    pw.SizedBox(height: 2),
                    pw.Text(currencyFormatter.format(totalInKind),
                        style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: PdfColors.amber800)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Bảng kê chi tiết
          pw.Text('CHI TIẾT CÁC KHOẢN CÚNG TIẾN',
              style: pw.TextStyle(font: boldFont, fontSize: 11)),
          pw.SizedBox(height: 8),

          pw.TableHelper.fromTextArray(
            headers: [
              'Mã GD',
              'Thời gian',
              'Người cúng tiến / Nội dung',
              'Hình thức',
              'Số tiền / Giá trị',
              'Trạng thái'
            ],
            headerStyle: pw.TextStyle(font: boldFont, fontSize: 8.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.center,
            },
            data: [
              ...cashReceipts.map((r) => [
                    r.receiptNumber,
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(r.contributionDate ?? DateTime.now()),
                    '${r.payerMemberName ?? r.payerMemberId}\n(ID: ${r.payerMemberId})',
                    r.paymentMethod.displayName,
                    currencyFormatter.format(r.amount),
                    'Đã tất toán',
                  ]),
              ...inKindReceipts.map((r) => [
                    r.receiptNumber,
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(r.contributionDate ?? DateTime.now()),
                    '${r.itemName} (${r.quantity} ${r.unit})\nCúng tiến: ${r.payerMemberName ?? r.payerMemberId}',
                    'Hiện vật lễ',
                    '~ ${currencyFormatter.format(r.convertedMonetaryValue)}',
                    r.processingStatus.displayName,
                  ]),
            ],
          ),
          pw.SizedBox(height: 28),

          // Khối chứng thực trích xuất tự động (không qua phê duyệt giấy tờ trung gian)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BÁO CÁO TRÍCH XUẤT TỰ ĐỘNG TỪ SỔ CÁI BẤT BIẾN FAMILYFUND',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 8.5,
                        color: PdfColors.brown900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Dữ liệu đối soát thời gian thực 1:1 • Hệ thống quản trị tài chính Dòng họ Nguyễn Tộc (Đại Tôn)',
                      style: pw.TextStyle(
                        font: italicFont,
                        fontSize: 7.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Niêm phong: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Chứng từ điện tử được niêm phong từ Sổ Cái Bất Biến FamilyFund',
              style: pw.TextStyle(
                  font: italicFont, fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'So_Cai_Doi_Soat_Dong_Gop_2026.pdf',
    );
  }

  /// Xuất file PDF Phiếu Thu & Chứng Nhận Công Đức Điện Tử
  static Future<void> exportReceiptPdf({
    ElectronicReceiptDto? cashReceipt,
    InKindElectronicReceiptDto? inKindReceipt,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    final isCash = cashReceipt != null;
    final receiptNumber =
        isCash ? cashReceipt.receiptNumber : inKindReceipt!.receiptNumber;
    final eventName =
        isCash ? cashReceipt.eventName : inKindReceipt!.eventName;
    final payerName = isCash
        ? (cashReceipt.payerMemberName ?? cashReceipt.payerMemberId)
        : (inKindReceipt!.payerMemberName ?? inKindReceipt.payerMemberId);
    final date = isCash
        ? (cashReceipt.contributionDate ?? DateTime.now())
        : (inKindReceipt!.contributionDate ?? DateTime.now());
    final amountText = isCash
        ? currencyFormatter.format(cashReceipt.amount)
        : currencyFormatter.format(inKindReceipt!.convertedMonetaryValue);
    final inWords = isCash
        ? cashReceipt.amountInWords
        : inKindReceipt!.convertedMonetaryValueInWords;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.brown800, width: 2),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ĐẠI GIA TỘC VIỆT NAM',
                          style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 11,
                              color: PdfColors.brown900)),
                      pw.Text('BAN QUẢN LÝ TÀI CHÍNH DÒNG HỌ',
                          style: pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.BarcodeWidget(
                    data: receiptNumber,
                    barcode: pw.Barcode.qrCode(),
                    width: 44,
                    height: 44,
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.brown),
              pw.SizedBox(height: 10),

              // Tiêu đề
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      isCash
                          ? 'BIÊN LAI ĐÓNG GÓP TÀI CHÍNH'
                          : 'BIÊN LAI TIẾP NHẬN HIỆN VẬT CÚNG TIẾN',
                      style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 13,
                          color: PdfColors.brown900),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text('Mã số: $receiptNumber',
                        style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 9,
                            color: PdfColors.brown700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Thông tin chi tiết
              pw.Text('Sự kiện / Lễ giỗ: $eventName',
                  style: const pw.TextStyle(fontSize: 9.5)),
              pw.SizedBox(height: 4),
              pw.Text(
                  'Thời gian ghi nhận: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                  style: const pw.TextStyle(fontSize: 9.5)),
              pw.SizedBox(height: 4),
              pw.Text('Người cúng tiến: $payerName',
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 10, color: PdfColors.brown900)),
              pw.SizedBox(height: 4),
              if (!isCash && inKindReceipt != null) ...[
                pw.Text(
                    'Hiện vật dâng lễ: ${inKindReceipt.itemName} (${inKindReceipt.quantity} ${inKindReceipt.unit})',
                    style: const pw.TextStyle(fontSize: 9.5)),
                pw.SizedBox(height: 4),
                pw.Text(
                    'Phương thức định giá: ${inKindReceipt.conversionMethod.displayName}',
                    style: const pw.TextStyle(fontSize: 9.5)),
                pw.SizedBox(height: 4),
              ],
              pw.Text('Số tiền / Giá trị quy đổi: $amountText',
                  style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 11,
                      color: PdfColors.green900)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: PdfColors.grey100,
                child: pw.Text('Bằng chữ: $inWords',
                    style: pw.TextStyle(font: italicFont, fontSize: 8.5)),
              ),
              pw.SizedBox(height: 16),

              // Chữ ký 2 bên thực tế (Người dâng lễ - Người thu tiền / Thủ quỹ)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('NGƯỜI DÂNG LỄ',
                          style: pw.TextStyle(font: boldFont, fontSize: 9)),
                      pw.Text('(Ký & ghi rõ họ tên)',
                          style: pw.TextStyle(font: italicFont, fontSize: 7.5)),
                      pw.SizedBox(height: 28),
                      pw.Text(payerName,
                          style: pw.TextStyle(font: boldFont, fontSize: 8.5)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('NGƯỜI THU TIỀN / THỦ QUỸ',
                          style: pw.TextStyle(font: boldFont, fontSize: 9)),
                      pw.Text('(Ký nhận & đóng mộc chứng thực)',
                          style: pw.TextStyle(font: italicFont, fontSize: 7.5)),
                      pw.SizedBox(height: 28),
                      pw.Text('Ban Tiếp Nhận & Thủ Quỹ Dòng Họ',
                          style: pw.TextStyle(font: boldFont, fontSize: 8.5)),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  'Chứng từ điện tử hợp lệ đã ghi nhận vào Sổ cái gia tộc & đối soát 1:1',
                  style: pw.TextStyle(
                      font: italicFont, fontSize: 7.5, color: PdfColors.grey600),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Phieu_Thu_$receiptNumber.pdf',
    );
  }
}
