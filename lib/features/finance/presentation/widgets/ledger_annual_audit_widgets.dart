import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/models/immutable_ledger_integrity_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/models/ledger_annual_audit_models.dart';

/// Định dạng chuỗi chữ số nguyên sang dạng ngăn cách dấu chấm kiểu Việt Nam (`99800000` -> `99.800.000`).
String formatVndDigitsWithDots(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buf.write('.');
    }
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Formatter nhập số tiền nguyên VNĐ tự động chèn dấu chấm nghìn và chặn ký tự âm/chữ.
class VietnameseThousandDotFormatter extends TextInputFormatter {
  final int maxDigits;

  const VietnameseThousandDotFormatter({this.maxDigits = 14});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final clamped =
        digits.length > maxDigits ? digits.substring(0, maxDigits) : digits;
    final parsed = int.tryParse(clamped);
    if (parsed == null) {
      return oldValue;
    }
    final formatted = formatVndDigitsWithDots(parsed);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Hiển thị số tiền 1 dòng duy nhất (`nowrap`) với `FittedBox` chống rớt ký hiệu `₫`.
class AnnualAuditMoneyText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Alignment alignment;

  const AnnualAuditMoneyText(
    this.text, {
    super.key,
    required this.style,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: style.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Dải kiểm tra điều kiện tiên quyết ngay dưới header (SHA-256 • Pending • Trạng thái năm).
class AnnualAuditPreFlightStrip extends StatelessWidget {
  final bool isShaValid;
  final int verifiedEntries;
  final int totalEntries;
  final int brokenLinksCount;
  final int pendingAdjustmentCount;
  final int pendingDisbursementCount;
  final int selectedYear;
  final LedgerAnnualAuditModel? matchedForYear;

  const AnnualAuditPreFlightStrip({
    super.key,
    required this.isShaValid,
    required this.verifiedEntries,
    required this.totalEntries,
    required this.brokenLinksCount,
    required this.pendingAdjustmentCount,
    required this.pendingDisbursementCount,
    required this.selectedYear,
    required this.matchedForYear,
  });

  @override
  Widget build(BuildContext context) {
    final pendingTotal = pendingAdjustmentCount + pendingDisbursementCount;

    final shaPill = _StatusPill(
      icon: isShaValid
          ? Icons.verified_user_outlined
          : Icons.warning_amber_rounded,
      label: isShaValid
          ? 'SHA-256: Toàn vẹn $verifiedEntries/$totalEntries khối'
          : 'SHA-256: $brokenLinksCount điểm gãy',
      bg: isShaValid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
      fg: isShaValid ? const Color(0xFF0F766E) : const Color(0xFFBA1A1A),
      border: isShaValid ? const Color(0xFF99F6E4) : const Color(0xFFFECACA),
    );

    final pendingPill = _StatusPill(
      icon: pendingTotal == 0
          ? Icons.check_circle_outline
          : Icons.hourglass_top_rounded,
      label: pendingTotal == 0
          ? 'Đề xuất chờ duyệt: 0 Pending'
          : 'Đang vướng $pendingAdjustmentCount Bù trừ + $pendingDisbursementCount Chi quỹ Pending',
      bg: pendingTotal == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
      fg: pendingTotal == 0 ? const Color(0xFF0F766E) : const Color(0xFFB45309),
      border:
          pendingTotal == 0 ? const Color(0xFF99F6E4) : const Color(0xFFFDE68A),
    );

    final yearPill = _StatusPill(
      icon: matchedForYear != null
          ? Icons.lock_outline_rounded
          : Icons.radio_button_checked,
      label: matchedForYear != null
          ? 'Kỳ $selectedYear: Đã chốt (${matchedForYear!.auditId})'
          : 'Kỳ $selectedYear: Chưa chốt đầu kỳ ${selectedYear + 1}',
      bg: matchedForYear != null
          ? const Color(0xFFECFDF5)
          : const Color(0xFFF5EBE6),
      fg: matchedForYear != null
          ? const Color(0xFF0F766E)
          : const Color(0xFF8B1E1E),
      border: matchedForYear != null
          ? const Color(0xFF99F6E4)
          : const Color(0xFFEBD5CC),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [shaPill, pendingPill, yearPill],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final Color border;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner cảnh báo sớm khi hệ thống chưa đủ điều kiện kiểm kê (gãy SHA-256 hoặc còn đề xuất Pending).
class AnnualAuditPreFlightBlockerBanner extends StatelessWidget {
  final bool isShaValid;
  final int brokenLinksCount;
  final int pendingAdjustmentCount;
  final int pendingDisbursementCount;
  final VoidCallback onOpenLedger;
  final VoidCallback onOpenReviewAdjustments;
  final VoidCallback onOpenReviewDisbursements;

  const AnnualAuditPreFlightBlockerBanner({
    super.key,
    required this.isShaValid,
    required this.brokenLinksCount,
    required this.pendingAdjustmentCount,
    required this.pendingDisbursementCount,
    required this.onOpenLedger,
    required this.onOpenReviewAdjustments,
    required this.onOpenReviewDisbursements,
  });

  @override
  Widget build(BuildContext context) {
    if (!isShaValid) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vi phạm toàn vẹn Sổ cái SHA-256 (NFR-01)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFBA1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Hệ thống phát hiện $brokenLinksCount điểm gãy chuỗi mã băm. Không thể thực hiện kiểm kê năm cho tới khi điều tra toàn vẹn dữ liệu.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF7F1D1D),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onOpenLedger,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.shield_outlined, size: 16),
              label: const Text('Kiểm toán chuỗi SHA-256'),
            ),
          ],
        ),
      );
    }

    if (pendingAdjustmentCount == 0 && pendingDisbursementCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Không thể chốt kiểm kê do còn đề xuất đang chờ duyệt (Pending)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Hiện còn $pendingAdjustmentCount đề xuất bù trừ (US-15) và $pendingDisbursementCount đề xuất chi Quỹ chung (US-60) ở trạng thái Pending. Vui lòng xử lý dứt điểm trước khi chốt sổ.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (pendingAdjustmentCount > 0)
                ElevatedButton(
                  onPressed: onOpenReviewAdjustments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Duyệt Bù trừ (US-59)'),
                ),
              if (pendingDisbursementCount > 0)
                ElevatedButton(
                  onPressed: onOpenReviewDisbursements,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E1E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Duyệt Chi Quỹ (US-60)'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bảng tính nhanh thu gọn mặc định: đếm tiền mặt theo 9 mệnh giá + nhập số dư sao kê ngân hàng.
class AnnualAuditQuickCalculatorAccordion extends StatefulWidget {
  final ValueChanged<double> onApplyTotal;

  const AnnualAuditQuickCalculatorAccordion({
    super.key,
    required this.onApplyTotal,
  });

  @override
  State<AnnualAuditQuickCalculatorAccordion> createState() =>
      _AnnualAuditQuickCalculatorAccordionState();
}

class _AnnualAuditQuickCalculatorAccordionState
    extends State<AnnualAuditQuickCalculatorAccordion> {
  static const List<int> _denominations = [
    500000,
    200000,
    100000,
    50000,
    20000,
    10000,
    5000,
    2000,
    1000,
  ];

  bool _expanded = false;
  late final TextEditingController _bankController;
  final Map<int, TextEditingController> _denomControllers = {};
  final Map<int, int> _counts = {
    for (final d in _denominations) d: 0,
  };
  int _bankBalance = 0;

  @override
  void initState() {
    super.initState();
    _bankController = TextEditingController();
    for (final d in _denominations) {
      _denomControllers[d] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _bankController.dispose();
    for (final c in _denomControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _cashTotal {
    var total = 0;
    for (final d in _denominations) {
      total += d * (_counts[d] ?? 0);
    }
    return total;
  }

  int get _grandTotal => _cashTotal + _bankBalance;

  void _updateDenomCount(int denom, int nextCount) {
    final safe = nextCount < 0 ? 0 : nextCount;
    setState(() {
      _counts[denom] = safe;
    });
    final ctrl = _denomControllers[denom]!;
    final text = safe.toString();
    if (ctrl.text != text) {
      ctrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _onBankChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      _bankBalance = digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            key: const Key('annual_audit_calculator_toggle'),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              color: const Color(0xFFFAF9F6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  const Icon(
                    Icons.calculate_outlined,
                    size: 19,
                    color: Color(0xFF8B1E1E),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Bảng tính nhanh (Tiền mặt + Ngân hàng)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2B1810),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: const Color(0xFFE6DFD8)),
                              ),
                              child: const Text(
                                'Tùy chọn',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF78655C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Tổng tạm tính:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF78655C),
                              ),
                            ),
                            AnnualAuditMoneyText(
                              AppFormatters.formatVnd(_grandTotal),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF8B1E1E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF8B1E1E),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Số dư tài khoản ngân hàng quỹ họ (theo sao kê thực tế)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF54433E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const Key('annual_audit_calc_bank_input'),
                    controller: _bankController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [VietnameseThousandDotFormatter()],
                    onChanged: _onBankChanged,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B1810),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập số dư tài khoản ngân hàng...',
                      suffixText: '₫',
                      suffixStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1E1E),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Đếm tiền mặt trong két theo mệnh giá',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF54433E),
                        ),
                      ),
                      Text(
                        'Gõ số tờ hoặc bấm ±',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF78655C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6DFD8)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: _denominations.map((denom) {
                        final count = _counts[denom] ?? 0;
                        final subtotal = denom * count;
                        final isLast = denom == _denominations.last;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: isLast
                              ? null
                              : const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF0EDEB),
                                    ),
                                  ),
                                ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 88,
                                child: AnnualAuditMoneyText(
                                  '${formatVndDigitsWithDots(denom)}\u00A0₫',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _StepperMiniBtn(
                                    key: Key('annual_audit_denom_minus_$denom'),
                                    label: '−',
                                    onTap: () =>
                                        _updateDenomCount(denom, count - 1),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 54,
                                    height: 30,
                                    child: TextField(
                                      key: Key(
                                          'annual_audit_denom_input_$denom'),
                                      controller: _denomControllers[denom],
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(6),
                                      ],
                                      onChanged: (raw) {
                                        final val = raw.trim().isEmpty
                                            ? 0
                                            : (int.tryParse(raw.trim()) ?? 0);
                                        setState(() => _counts[denom] = val);
                                      },
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2B1810),
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 4,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFDFD8D0),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFDFD8D0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _StepperMiniBtn(
                                    key: Key('annual_audit_denom_plus_$denom'),
                                    label: '+',
                                    onTap: () =>
                                        _updateDenomCount(denom, count + 1),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AnnualAuditMoneyText(
                                  AppFormatters.formatVnd(subtotal),
                                  alignment: Alignment.centerRight,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBE6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEBD5CC)),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tiền mặt: ${AppFormatters.formatVnd(_cashTotal)} • Ngân hàng: ${AppFormatters.formatVnd(_bankBalance)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF54433E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Tổng cộng: ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                                AnnualAuditMoneyText(
                                  AppFormatters.formatVnd(_grandTotal),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF8B1E1E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          key: const Key('annual_audit_apply_calc_btn'),
                          onPressed: () =>
                              widget.onApplyTotal(_grandTotal.toDouble()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1E1E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_upward, size: 15),
                          label: const Text('Áp dụng vào Số thực đếm'),
                        ),
                      ],
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

class _StepperMiniBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepperMiniBtn({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDFD8D0)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF54433E),
          ),
        ),
      ),
    );
  }
}

/// Bảng đối chiếu trực tiếp `running_balance` vs `actualBalance` & Nút Trưởng tộc xác nhận.
class AnnualAuditReconcilePanel extends StatelessWidget {
  final int selectedYear;
  final double systemBalance;
  final double? actualBalance;
  final int totalEntries;
  final LedgerHistoryItemModel? latestTransaction;
  final bool isPreFlightBlocked;
  final bool isSubmitting;
  final bool isUploadingEvidence;
  final String? submitErrorMessage;
  final VoidCallback onConfirmPressed;

  const AnnualAuditReconcilePanel({
    super.key,
    required this.selectedYear,
    required this.systemBalance,
    required this.actualBalance,
    required this.totalEntries,
    required this.latestTransaction,
    required this.isPreFlightBlocked,
    required this.isSubmitting,
    required this.isUploadingEvidence,
    this.submitErrorMessage,
    required this.onConfirmPressed,
  });

  @override
  Widget build(BuildContext context) {
    final diff = actualBalance == null ? null : actualBalance! - systemBalance;
    final isMatched = diff != null && diff.abs() < 0.005;
    final isSurplus = diff != null && diff >= 0.005;
    final isShortage = diff != null && diff <= -0.005;

    final String ctaLabel;
    final Color ctaColor;
    final IconData ctaIcon;
    final String outcomeHint;

    if (isSurplus || isShortage) {
      ctaLabel = 'Ghi nhận lệch & Tạo Đề xuất bù trừ (US-15)';
      ctaColor =
          isSurplus ? const Color(0xFFB45309) : const Color(0xFFBA1A1A);
      ctaIcon = Icons.balance_outlined;
      outcomeHint =
          'Hệ quả: Sổ năm $selectedYear chưa khóa; tự động sinh đề xuất bù trừ ${formatSignedLedgerVnd(diff)} chờ Trưởng tộc phê duyệt (US-59).';
    } else {
      ctaLabel = 'Trưởng tộc xác nhận chốt sổ năm $selectedYear';
      ctaColor = const Color(0xFF8B1E1E);
      ctaIcon = Icons.lock_outline_rounded;
      outcomeHint =
          'Hệ quả: Ghi nối bút toán OpeningBalanceCarryForward (${AppFormatters.formatVnd(systemBalance)}) làm số dư đầu kỳ năm ${selectedYear + 1}.';
    }

    final canSubmit = !isPreFlightBlocked &&
        actualBalance != null &&
        !isSubmitting &&
        !isUploadingEvidence;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2B1810),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đối Chiếu & Xác Nhận Chốt',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'So sánh trực tiếp với running_balance mới nhất',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF78655C)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Text(
                  '#$totalEntries',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: Color(0xFFF0EDEB)),

          // Line 1: running_balance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số dư Sổ cái (running_balance)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF78655C),
                      ),
                    ),
                    if (latestTransaction != null)
                      Text(
                        '${latestTransaction!.transactionId} • ${latestTransaction!.formattedSolarDate} (${latestTransaction!.formattedLunarDate})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF78655C),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnnualAuditMoneyText(
                AppFormatters.formatVnd(systemBalance),
                alignment: Alignment.centerRight,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B1810),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Line 2: actualBalance
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0EDEB))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Số tiền thực tế đếm được',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF78655C),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnnualAuditMoneyText(
                  actualBalance == null
                      ? '—'
                      : AppFormatters.formatVnd(actualBalance!),
                  alignment: Alignment.centerRight,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B1E1E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Line 3: Live 4-state Discrepancy Card
          _buildDiscrepancyCard(diff, isMatched, isSurplus),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFE6DFD8)),
            ),
            child: Text(
              outcomeHint,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF54433E),
                height: 1.4,
              ),
            ),
          ),

          if (submitErrorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                submitErrorMessage!,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBA1A1A),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          ElevatedButton.icon(
            key: const Key('annual_audit_submit_btn'),
            onPressed: canSubmit ? onConfirmPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ctaColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE6DFD8),
              disabledForegroundColor: const Color(0xFF78655C),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: (isSubmitting || isUploadingEvidence)
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(ctaIcon, size: 18),
            label: Text(
              isUploadingEvidence
                  ? 'Đang tải biên bản chứng từ...'
                  : (isSubmitting ? 'Đang gửi xác nhận...' : ctaLabel),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          const Divider(height: 1, color: Color(0xFFF0EDEB)),
          const SizedBox(height: 10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 15,
                color: Color(0xFF0F766E),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Khi khớp số dư, hệ thống niêm phong bút toán kết chuyển vào chuỗi mã băm SHA-256 (previous_hash → record_hash), đảm bảo bất biến NFR-01.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF78655C),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscrepancyCard(double? diff, bool isMatched, bool isSurplus) {
    if (diff == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6DFD8)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Độ lệch đối chiếu',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF78655C),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Nhập số tiền thực tế đếm được ở bên trái để hệ thống đối soát tự động.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF54433E)),
            ),
          ],
        ),
      );
    }

    if (isMatched) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF99F6E4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Khớp số dư tuyệt đối',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F766E),
                  ),
                ),
                _MiniOutcomeBadge(
                  label: 'Matched',
                  color: const Color(0xFF0F766E),
                  border: const Color(0xFF99F6E4),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AnnualAuditMoneyText(
              AppFormatters.formatVnd(0),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sẵn sàng chốt số dư đầu kỳ năm ${selectedYear + 1}.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E)),
            ),
          ],
        ),
      );
    }

    final fg = isSurplus ? const Color(0xFFB45309) : const Color(0xFFBA1A1A);
    final bg = isSurplus ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2);
    final border =
        isSurplus ? const Color(0xFFFDE68A) : const Color(0xFFFECACA);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                isSurplus ? 'Phát hiện thừa quỹ' : 'Phát hiện thiếu quỹ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              _MiniOutcomeBadge(
                label: 'DiscrepancyDetected',
                color: fg,
                border: border,
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnnualAuditMoneyText(
            formatSignedLedgerVnd(diff),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSurplus
                ? 'Thực tế nhiều hơn Sổ cái. Hệ thống sẽ giữ sổ mở và tự sinh Đề xuất bù trừ (US-15).'
                : 'Thực tế ít hơn Sổ cái. Hệ thống sẽ giữ sổ mở và tự sinh Đề xuất bù trừ (US-15).',
            style: TextStyle(fontSize: 12, color: fg),
          ),
        ],
      ),
    );
  }
}

class _MiniOutcomeBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color border;

  const _MiniOutcomeBadge({
    required this.label,
    required this.color,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Hộp thoại xác nhận trước khi gọi POST /api/v1/ledger/annual-audit.
class AnnualAuditConfirmDialog extends StatelessWidget {
  final int auditYear;
  final double systemBalance;
  final double actualBalance;
  final String referenceTransactionId;

  const AnnualAuditConfirmDialog({
    super.key,
    required this.auditYear,
    required this.systemBalance,
    required this.actualBalance,
    required this.referenceTransactionId,
  });

  @override
  Widget build(BuildContext context) {
    final diff = actualBalance - systemBalance;
    final isMatched = diff.abs() < 0.005;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        isMatched
            ? 'Xác nhận chốt Sổ quỹ năm $auditYear'
            : 'Xác nhận ghi nhận lệch & Tạo Đề xuất bù trừ',
        style: const TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2B1810),
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6DFD8)),
              ),
              child: Column(
                children: [
                  _ConfirmRow(
                    label: 'Số dư Sổ cái (running_balance):',
                    value: AppFormatters.formatVnd(systemBalance),
                  ),
                  const SizedBox(height: 8),
                  _ConfirmRow(
                    label: 'Số tiền thực tế đếm được:',
                    value: AppFormatters.formatVnd(actualBalance),
                  ),
                  const Divider(height: 16, color: Color(0xFFE6DFD8)),
                  _ConfirmRow(
                    label: 'Độ lệch đối soát:',
                    value: isMatched
                        ? '${AppFormatters.formatVnd(0)} (Khớp 100%)'
                        : formatSignedLedgerVnd(diff),
                    valueColor: isMatched
                        ? const Color(0xFF0F766E)
                        : const Color(0xFFBA1A1A),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMatched
                    ? const Color(0xFFF7FEFC)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMatched
                      ? const Color(0xFF99F6E4)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                isMatched
                    ? 'Sau khi xác nhận, hệ thống ghi bút toán OpeningBalanceCarryForward (${AppFormatters.formatVnd(actualBalance)}) nối chuỗi SHA-256 và khóa chốt năm $auditYear. Thao tác này không thể sửa hoặc xóa.'
                    : 'Hệ thống sẽ tạo Đề xuất bù trừ (US-15) trị giá ${formatSignedLedgerVnd(diff)} gắn vào bút toán $referenceTransactionId ở trạng thái Pending. Sổ năm $auditYear chỉ chốt sau khi bù trừ được phê duyệt.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isMatched
                      ? const Color(0xFF0F766E)
                      : const Color(0xFF92400E),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF54433E),
            side: const BorderSide(color: Color(0xFFDFD8D0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Hủy kiểm tra lại'),
        ),
        ElevatedButton(
          key: const Key('annual_audit_confirm_submit_btn'),
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isMatched
                ? const Color(0xFF8B1E1E)
                : const Color(0xFFB45309),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            isMatched
                ? 'Xác nhận chốt & Niêm phong SHA-256'
                : 'Xác nhận tạo Đề xuất bù trừ',
          ),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _ConfirmRow({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF2B1810),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF78655C)),
          ),
        ),
        const SizedBox(width: 8),
        AnnualAuditMoneyText(
          value,
          alignment: Alignment.centerRight,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Thẻ biên bản đã chốt sổ thành công (Matched) cho kỳ đang chọn.
class AnnualAuditSealedReceiptCard extends StatelessWidget {
  final LedgerAnnualAuditModel record;
  final VoidCallback onViewHistory;
  final VoidCallback onOpenOnLedger;
  final ValueChanged<String>? onDownloadEvidence;

  const AnnualAuditSealedReceiptCard({
    super.key,
    required this.record,
    required this.onViewHistory,
    required this.onOpenOnLedger,
    this.onDownloadEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final closing = record.closingLedgerEntry;
    final opening = record.openingBalanceNextPeriod ?? record.actualBalance;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF99F6E4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F766E),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFFECFDF5),
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFF99F6E4)),
                          ),
                          child: Text(
                            'ĐÃ CHỐT SỔ ĐẦU KỲ MỚI • NĂM ${record.nextPeriodYear}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Biên Bản Kiểm Kê Năm ${record.auditYear} Đã Niêm Phong',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Mã biên bản: ${record.auditId} • ${record.formattedAuditDate} (${record.formattedLunarDate})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SỐ DƯ ĐẦU KỲ NĂM ${record.nextPeriodYear}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnnualAuditMoneyText(
                          AppFormatters.formatVnd(opening),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 600;
                        final cards = [
                          _MetricTile(
                            label: 'Số dư Sổ cái',
                            value: AppFormatters.formatVnd(record.systemBalance),
                          ),
                          _MetricTile(
                            label: 'Số tiền thực đếm',
                            value: AppFormatters.formatVnd(record.actualBalance),
                          ),
                          const _MetricTile(
                            label: 'Độ lệch đối soát',
                            value: '0\u00A0₫ (Khớp 100%)',
                            bg: Color(0xFFECFDF5),
                            border: Color(0xFF99F6E4),
                            valueColor: Color(0xFF0F766E),
                          ),
                        ];
                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                cards[i],
                                if (i < cards.length - 1)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 10),
                            Expanded(child: cards[1]),
                            const SizedBox(width: 10),
                            Expanded(child: cards[2]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FEFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Niêm phong Sổ cái Bất biến (OpeningBalanceCarryForward)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              if (record.closingTransactionId != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE6DFD8),
                                    ),
                                  ),
                                  child: Text(
                                    record.closingTransactionId!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2B1810),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (closing != null &&
                              closing.recordHash.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'previousHash: ${shortLedgerHash(closing.previousHash)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                color: Color(0xFF54433E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'recordHash: ${shortLedgerHash(closing.recordHash)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Trưởng tộc xác nhận: ${record.effectiveAuditorName}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    if (record.notes != null &&
                        record.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9F6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE6DFD8)),
                        ),
                        child: Text(
                          'Ghi chú: ${record.notes!}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ),
                    ],
                    if (record.evidenceAttachmentUrl != null &&
                        record.evidenceAttachmentUrl!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onDownloadEvidence != null
                              ? () => onDownloadEvidence!(
                                    record.evidenceAttachmentUrl!,
                                  )
                              : null,
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: Text(
                            'Biên bản đính kèm (${record.evidenceAttachmentUrl!})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    const Divider(height: 24, color: Color(0xFFF0EDEB)),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: onViewHistory,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF54433E),
                            side: const BorderSide(color: Color(0xFFDFD8D0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Xem lịch sử biên bản'),
                        ),
                        ElevatedButton.icon(
                          onPressed: onOpenOnLedger,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1E1E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Xem trên Sổ cái'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ kết quả sau khi phát hiện lệch và tự động sinh Đề xuất bù trừ (US-15).
class AnnualAuditDiscrepancyResultCard extends StatelessWidget {
  final LedgerAnnualAuditModel record;
  final VoidCallback onAuditAgain;
  final VoidCallback onViewHistory;
  final VoidCallback onOpenReviewAdjustment;

  const AnnualAuditDiscrepancyResultCard({
    super.key,
    required this.record,
    required this.onAuditAgain,
    required this.onViewHistory,
    required this.onOpenReviewAdjustment,
  });

  @override
  Widget build(BuildContext context) {
    final isSurplus = record.isSurplus;
    final fg = isSurplus ? const Color(0xFFB45309) : const Color(0xFFBA1A1A);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0CB45309),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFFFFFBEB),
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Text(
                            'PHÁT HIỆN LỆCH SỐ DƯ • ĐÃ TẠO ĐỀ XUẤT BÙ TRỪ (US-15)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Biên Bản ${record.auditId} — Sổ Năm ${record.auditYear} Chưa Khóa',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Hệ thống giữ nguyên sổ cái hiện tại và tự động sinh đề xuất bù trừ chờ phê duyệt.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSurplus
                              ? 'CHÊNH LỆCH THỪA QUỸ'
                              : 'CHÊNH LỆCH THIẾU QUỸ',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnnualAuditMoneyText(
                          formatSignedLedgerVnd(record.discrepancyAmount),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 600;
                        final cards = [
                          _MetricTile(
                            label: 'Số dư Sổ cái',
                            value: AppFormatters.formatVnd(record.systemBalance),
                          ),
                          _MetricTile(
                            label: 'Số tiền thực đếm',
                            value: AppFormatters.formatVnd(record.actualBalance),
                          ),
                          _MetricTile(
                            label: 'Mã đề xuất bù trừ (Pending)',
                            value: record.adjustmentRequestId ?? '—',
                            bg: const Color(0xFFFFFBEB),
                            border: const Color(0xFFFDE68A),
                            valueColor: const Color(0xFF8B1E1E),
                          ),
                        ];
                        if (narrow) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                cards[i],
                                if (i < cards.length - 1)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 10),
                            Expanded(child: cards[1]),
                            const SizedBox(width: 10),
                            Expanded(child: cards[2]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F6),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0xFFE6DFD8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bút toán gốc đối chiếu: ${record.referenceTransactionId ?? '—'}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                          if (record.autoGeneratedAdjustmentRequest != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Lý do tự động: ${record.autoGeneratedAdjustmentRequest!.adjustmentReason}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF54433E),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 24, color: Color(0xFFF0EDEB)),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: onAuditAgain,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF54433E),
                            side: const BorderSide(color: Color(0xFFDFD8D0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('+ Kiểm kê lại sau khi xử lý'),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: onViewHistory,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF54433E),
                                side:
                                    const BorderSide(color: Color(0xFFDFD8D0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Lịch sử biên bản'),
                            ),
                            ElevatedButton.icon(
                              onPressed: onOpenReviewAdjustment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B1E1E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.fact_check_outlined,
                                  size: 16),
                              label: const Text(
                                'Mở màn Phê duyệt Bù trừ (US-59)',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;
  final Color border;
  final Color valueColor;

  const _MetricTile({
    required this.label,
    required this.value,
    this.bg = const Color(0xFFFAF9F6),
    this.border = const Color(0xFFE6DFD8),
    this.valueColor = const Color(0xFF2B1810),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF78655C),
            ),
          ),
          const SizedBox(height: 4),
          AnnualAuditMoneyText(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Giao diện Chỉ đọc cho Thành viên / Trưởng chi (`MEMBER` / `BRANCH_HEAD`).
class AnnualAuditMemberReadOnlyCard extends StatelessWidget {
  final double systemBalance;
  final LedgerHistoryItemModel? latestTransaction;
  final int totalAuditsCount;
  final VoidCallback onViewHistory;

  const AnnualAuditMemberReadOnlyCard({
    super.key,
    required this.systemBalance,
    required this.latestTransaction,
    required this.totalAuditsCount,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDEB),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDFD8D0)),
                ),
                child: const Text(
                  'Chế độ Thành viên — Chỉ đọc (RBAC)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF54433E),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Quyền Thực Hiện Kiểm Kê & Chốt Sổ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B1810),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chỉ Trưởng tộc (CLAN_HEAD) hoặc Quản trị viên (ADMIN) mới có quyền nhập số kiểm đếm và xác nhận chốt biên bản kiểm kê hằng năm. Bạn có thể theo dõi số dư Sổ cái và tra cứu minh bạch toàn bộ Lịch sử biên bản.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF54433E),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 560;
                  final balTile = Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6DFD8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số dư Sổ cái hiện tại (running_balance)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF78655C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnnualAuditMoneyText(
                          AppFormatters.formatVnd(systemBalance),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B1E1E),
                          ),
                        ),
                        if (latestTransaction != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Bút toán mới nhất: ${latestTransaction!.transactionId}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF78655C),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );

                  final historyTile = Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6DFD8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lịch sử kiểm kê đã công khai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF78655C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalAuditsCount biên bản',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: onViewHistory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1E1E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Xem Lịch sử biên bản →'),
                        ),
                      ],
                    ),
                  );

                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        balTile,
                        const SizedBox(height: 12),
                        historyTile,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: balTile),
                      const SizedBox(width: 12),
                      Expanded(child: historyTile),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Danh sách lịch sử biên bản kiểm kê + bộ lọc năm/trạng thái.
class AnnualAuditHistoryList extends StatelessWidget {
  final List<LedgerAnnualAuditModel> audits;
  final int totalCount;
  final List<int> availableYears;
  final int? filterYear;
  final LedgerAnnualAuditStatusEnum? filterStatus;
  final ValueChanged<int?> onFilterYearChanged;
  final ValueChanged<LedgerAnnualAuditStatusEnum?> onFilterStatusChanged;
  final ValueChanged<LedgerAnnualAuditModel> onSelectAudit;

  const AnnualAuditHistoryList({
    super.key,
    required this.audits,
    required this.totalCount,
    required this.availableYears,
    required this.filterYear,
    required this.filterStatus,
    required this.onFilterYearChanged,
    required this.onFilterStatusChanged,
    required this.onSelectAudit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DropdownFilterBox<int?>(
                    value: filterYear,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tất cả năm'),
                      ),
                      for (final y in availableYears)
                        DropdownMenuItem<int?>(
                          value: y,
                          child: Text('Năm $y'),
                        ),
                    ],
                    onChanged: onFilterYearChanged,
                  ),
                  _DropdownFilterBox<LedgerAnnualAuditStatusEnum?>(
                    value: filterStatus,
                    items: [
                      const DropdownMenuItem<LedgerAnnualAuditStatusEnum?>(
                        value: null,
                        child: Text('Mọi trạng thái'),
                      ),
                      for (final st in LedgerAnnualAuditStatusEnum.values)
                        DropdownMenuItem<LedgerAnnualAuditStatusEnum?>(
                          value: st,
                          child: Text(st.displayName),
                        ),
                    ],
                    onChanged: onFilterStatusChanged,
                  ),
                ],
              ),
              Text(
                'Hiển thị ${audits.length}/$totalCount biên bản',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF78655C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (audits.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE6DFD8)),
            ),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 32, color: Color(0xFF78655C)),
                SizedBox(height: 8),
                Text(
                  'Chưa có biên bản kiểm kê nào khớp bộ lọc',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B1810),
                  ),
                ),
              ],
            ),
          )
        else
          for (final item in audits) ...[
            _HistoryAuditCard(
              item: item,
              onTap: () => onSelectAudit(item),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _DropdownFilterBox<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownFilterBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDFD8D0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B1810),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _HistoryAuditCard extends StatelessWidget {
  final LedgerAnnualAuditModel item;
  final VoidCallback onTap;

  const _HistoryAuditCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMatched = item.isMatched;
    final status = item.auditStatus;
    final diffText = isMatched
        ? AppFormatters.formatVnd(0)
        : formatSignedLedgerVnd(item.discrepancyAmount);
    final diffColor = isMatched
        ? const Color(0xFF0F766E)
        : (item.isSurplus
            ? const Color(0xFFB45309)
            : const Color(0xFFBA1A1A));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Kiểm kê năm ${item.auditYear}',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: status.badgeBackgroundColor,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: status.badgeBorderColor),
                            ),
                            child: Text(
                              status.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: status.badgeTextColor,
                              ),
                            ),
                          ),
                          Text(
                            item.auditId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              color: Color(0xFF78655C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.formattedAuditDate} (${item.formattedLunarDate}) • ${item.effectiveAuditorName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78655C),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Độ lệch',
                        style: TextStyle(fontSize: 11, color: Color(0xFF78655C)),
                      ),
                      AnnualAuditMoneyText(
                        diffText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: diffColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFF0EDEB)),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Sổ cái: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78655C),
                            ),
                          ),
                          AnnualAuditMoneyText(
                            AppFormatters.formatVnd(item.systemBalance),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Thực đếm: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78655C),
                            ),
                          ),
                          AnnualAuditMoneyText(
                            AppFormatters.formatVnd(item.actualBalance),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    isMatched
                        ? 'Bút toán chốt: ${item.closingTransactionId ?? '—'} →'
                        : 'Đề xuất US-15: ${item.adjustmentRequestId ?? '—'} →',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B1E1E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hộp thoại xem chi tiết một biên bản trong lịch sử kiểm kê.
class AnnualAuditDetailDialog extends StatelessWidget {
  final LedgerAnnualAuditModel record;
  final ValueChanged<String>? onOpenLedgerTransaction;
  final ValueChanged<String>? onOpenAdjustmentReview;
  final ValueChanged<String>? onDownloadEvidence;

  const AnnualAuditDetailDialog({
    super.key,
    required this.record,
    this.onOpenLedgerTransaction,
    this.onOpenAdjustmentReview,
    this.onDownloadEvidence,
  });

  @override
  Widget build(BuildContext context) {
    final isMatched = record.isMatched;
    final closing = record.closingLedgerEntry;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${record.auditId} • Năm ${record.auditYear}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF78655C),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isMatched
                ? 'Biên Bản Khớp Số Dư (Matched)'
                : 'Biên Bản Phát Hiện Độ Lệch (US-15)',
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2B1810),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Builder(
                builder: (context) {
                  final tiles = [
                    _MetricTile(
                      label: 'Số dư Sổ cái',
                      value: AppFormatters.formatVnd(record.systemBalance),
                    ),
                    _MetricTile(
                      label: 'Thực đếm',
                      value: AppFormatters.formatVnd(record.actualBalance),
                    ),
                    _MetricTile(
                      label: 'Độ lệch',
                      value: isMatched
                          ? AppFormatters.formatVnd(0)
                          : formatSignedLedgerVnd(record.discrepancyAmount),
                      bg: isMatched
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      border: isMatched
                          ? const Color(0xFF99F6E4)
                          : const Color(0xFFFECACA),
                      valueColor: isMatched
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFBA1A1A),
                    ),
                  ];
                  if (MediaQuery.sizeOf(context).width < 480) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[
                          tiles[i],
                          if (i < tiles.length - 1) const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 8),
                      Expanded(child: tiles[1]),
                      const SizedBox(width: 8),
                      Expanded(child: tiles[2]),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời gian: ${record.formattedAuditDate} (${record.formattedLunarDate})',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Người thực hiện: ${record.effectiveAuditorName} (${record.auditorAccountId})',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bút toán đối chiếu: ${record.referenceTransactionId ?? '—'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isMatched)
                      Text(
                        'Bút toán chốt đầu kỳ ${record.nextPeriodYear}: ${record.closingTransactionId ?? '—'}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                        ),
                      )
                    else
                      Text(
                        'Đề xuất bù trừ US-15: ${record.adjustmentRequestId ?? '—'}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                  ],
                ),
              ),
              if (closing != null && closing.recordHash.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6DFD8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chuỗi niêm phong SHA-256',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'previousHash: ${closing.previousHash}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF54433E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'recordHash: ${closing.recordHash}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ghi chú kiểm kê',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (record.notes != null && record.notes!.trim().isNotEmpty)
                          ? record.notes!
                          : 'Không có ghi chú',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF54433E),
                      ),
                    ),
                  ],
                ),
              ),
              if (record.evidenceAttachmentUrl != null &&
                  record.evidenceAttachmentUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onDownloadEvidence != null
                        ? () =>
                            onDownloadEvidence!(record.evidenceAttachmentUrl!)
                        : null,
                    icon: const Icon(Icons.attach_file, size: 16),
                    label: Text(
                      'Xem tệp chứng từ (${record.evidenceAttachmentUrl!})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (isMatched &&
            record.closingTransactionId != null &&
            onOpenLedgerTransaction != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOpenLedgerTransaction!(record.closingTransactionId!);
            },
            child: const Text('Xem bút toán trên Sổ cái'),
          ),
        if (!isMatched &&
            record.adjustmentRequestId != null &&
            onOpenAdjustmentReview != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOpenAdjustmentReview!(record.adjustmentRequestId!);
            },
            child: const Text('Mở Phê duyệt US-59'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2B1810),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
