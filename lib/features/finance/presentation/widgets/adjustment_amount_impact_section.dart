import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../data/models/ledger_adjustment_models.dart';

/// Khối Bước 2: Chọn chiều Cộng/Trừ Quỹ chung, nhập số tiền và đọc bằng chữ tiếng Việt.
class AdjustmentAmountInputCard extends StatefulWidget {
  final int direction; // 1 = Cộng vào Quỹ, -1 = Trừ khỏi Quỹ
  final double amount; // Số dương
  final ValueChanged<int> onDirectionChanged;
  final ValueChanged<double> onAmountChanged;

  const AdjustmentAmountInputCard({
    super.key,
    required this.direction,
    required this.amount,
    required this.onDirectionChanged,
    required this.onAmountChanged,
  });

  @override
  State<AdjustmentAmountInputCard> createState() =>
      _AdjustmentAmountInputCardState();
}

class _AdjustmentAmountInputCardState extends State<AdjustmentAmountInputCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.amount > 0 ? _formatRawDigits(widget.amount.round()) : '',
    );
  }

  @override
  void didUpdateWidget(covariant AdjustmentAmountInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final desired =
        widget.amount > 0 ? _formatRawDigits(widget.amount.round()) : '';
    if (oldWidget.amount != widget.amount && _controller.text != desired) {
      _controller.value = TextEditingValue(
        text: desired,
        selection: TextSelection.collapsed(offset: desired.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _formatRawDigits(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _onTextChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _controller.value = const TextEditingValue(text: '');
      widget.onAmountChanged(0);
      return;
    }
    final clampedDigits = digits.length > 15 ? digits.substring(0, 15) : digits;
    final parsed = int.tryParse(clampedDigits) ?? 0;
    final formatted = parsed > 0 ? _formatRawDigits(parsed) : '';
    if (_controller.text != formatted) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    widget.onAmountChanged(parsed.toDouble());
  }

  String _spokenWords(double signedAmount) {
    if (signedAmount == 0) return 'Không đồng chẵn';
    final absWords = VietnameseMoneyConverter.toWords(signedAmount.abs());
    final cleanAbs = absWords.isNotEmpty
        ? '${absWords[0].toLowerCase()}${absWords.substring(1)}'
        : 'không đồng chẵn';
    return signedAmount > 0
        ? 'Cộng (tăng quỹ) $cleanAbs'
        : 'Trừ (giảm quỹ) $cleanAbs';
  }

  @override
  Widget build(BuildContext context) {
    final isPlus = widget.direction >= 0;
    final signedAmount = (isPlus ? 1 : -1) * widget.amount;
    final activeBorderColor =
        isPlus ? AppTheme.immutableLedgerTeal : const Color(0xFFBA1A1A);
    final softBg = isPlus ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final softBorder =
        isPlus ? const Color(0xFF99F6E4) : const Color(0xFFFECACA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _StepCircle(number: 2),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số Tiền Điều Chỉnh (+/-)',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                    Text(
                      'Chọn chiều tác động lên Số dư Quỹ chung',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2-Segment Toggle: Cộng vào Quỹ vs Trừ khỏi Quỹ
          Row(
            children: [
              Expanded(
                child: _DirectionOptionButton(
                  key: const Key('dir_plus_button'),
                  sign: '+',
                  title: 'Cộng vào Quỹ',
                  subtitle: 'Ghi tăng số dư',
                  isSelected: isPlus,
                  activeColor: AppTheme.immutableLedgerTeal,
                  activeBackground: const Color(0xFFECFDF5),
                  onTap: () => widget.onDirectionChanged(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DirectionOptionButton(
                  key: const Key('dir_minus_button'),
                  sign: '−',
                  title: 'Trừ khỏi Quỹ',
                  subtitle: 'Ghi giảm số dư',
                  isSelected: !isPlus,
                  activeColor: const Color(0xFFBA1A1A),
                  activeBackground: const Color(0xFFFEF2F2),
                  onTap: () => widget.onDirectionChanged(-1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'Nhập số tiền điều chỉnh (VNĐ)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF58413F),
            ),
          ),
          const SizedBox(height: 6),

          TextField(
            key: const Key('adjustment_amount_input'),
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: _onTextChanged,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1A),
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 22,
                color: Color(0xFFB5A9A2),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 6),
                child: Text(
                  isPlus ? '+' : '−',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: activeBorderColor,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 32),
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 14, left: 6),
                child: Text(
                  '₫',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF58413F),
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 32),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: softBorder, width: 1.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: activeBorderColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick helper amount chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickAmountChip(
                label: '+500.000',
                onTap: () => widget.onAmountChanged(widget.amount + 500000),
              ),
              _QuickAmountChip(
                label: '+1.000.000',
                onTap: () => widget.onAmountChanged(widget.amount + 1000000),
              ),
              _QuickAmountChip(
                label: '+5.000.000',
                onTap: () => widget.onAmountChanged(widget.amount + 5000000),
              ),
              if (widget.amount > 0)
                _QuickAmountChip(
                  label: 'Xóa số tiền',
                  isDanger: true,
                  onTap: () => widget.onAmountChanged(0),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Vietnamese money words readout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.amount > 0 ? softBg : const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.amount > 0 ? softBorder : const Color(0xFFE6DFD8),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.volume_up_outlined,
                  size: 18,
                  color: widget.amount > 0
                      ? activeBorderColor
                      : const Color(0xFF58413F),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BẰNG CHỮ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.amount > 0
                              ? activeBorderColor
                              : const Color(0xFF58413F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _spokenWords(signedAmount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.amount > 0
                              ? activeBorderColor
                              : const Color(0xFF58413F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (widget.amount <= 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFFBA1A1A)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Số tiền đề xuất bù trừ phải lớn hơn 0 ₫.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Thẻ Mô Phỏng Tác Động Sổ Cái (chính xác từng đồng + cảnh báo âm Quỹ chung US-59).
class LedgerImpactPreviewCard extends StatelessWidget {
  final LedgerHistoryItemModel? selectedTransaction;
  final double currentFundBalance;
  final double signedAdjustmentAmount;

  const LedgerImpactPreviewCard({
    super.key,
    required this.selectedTransaction,
    required this.currentFundBalance,
    required this.signedAdjustmentAmount,
  });

  @override
  Widget build(BuildContext context) {
    final projectedFundBalance = currentFundBalance + signedAdjustmentAmount;
    final isNegativeFund = projectedFundBalance < 0;
    final adjColor = signedAdjustmentAmount > 0
        ? AppTheme.immutableLedgerTeal
        : (signedAdjustmentAmount < 0
            ? const Color(0xFFBA1A1A)
            : const Color(0xFF58413F));
    final projColor =
        isNegativeFund ? const Color(0xFFBA1A1A) : AppTheme.immutableLedgerTeal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNegativeFund ? const Color(0xFFFFF8F8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isNegativeFund ? const Color(0xFFBA1A1A) : const Color(0xFFE6DFD8),
          width: isNegativeFund ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mô Phỏng Tác Động Sổ Cái',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: const Text(
                  'Chính xác từng đồng',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF58413F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _MetricRow(
            label: 'Số dư Quỹ chung hiện tại:',
            value: AppFormatters.formatVnd(currentFundBalance),
            valueColor: const Color(0xFF1A1C1A),
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Khoản bù trừ đề xuất:',
            value: formatSignedLedgerVnd(signedAdjustmentAmount),
            valueColor: adjColor,
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isNegativeFund
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isNegativeFund
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFE6DFD8),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Số dư Quỹ dự kiến sau duyệt:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppFormatters.formatVnd(projectedFundBalance),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: projColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEFECE6)),
          const SizedBox(height: 10),

          if (selectedTransaction != null) ...[
            const Text(
              'HIỆU LỰC TRÊN GIAO DỊCH GỐC',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF58413F),
              ),
            ),
            const SizedBox(height: 6),
            _MetricRow(
              label: 'Giá trị hiện tại:',
              value:
                  formatSignedLedgerVnd(selectedTransaction!.netAdjustedAmount),
              valueColor: const Color(0xFF1A1C1A),
            ),
            const SizedBox(height: 4),
            _MetricRow(
              label: 'Sau bút toán lần này:',
              value: formatSignedLedgerVnd(
                selectedTransaction!.netAdjustedAmount + signedAdjustmentAmount,
              ),
              valueColor: const Color(0xFF1A1C1A),
            ),
          ] else
            const Text(
              'Chọn giao dịch gốc ở Bước 1 để xem hiệu lực ròng trên bút toán.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF58413F),
              ),
            ),

          if (isNegativeFund) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('negative_balance_warning_banner'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBA1A1A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFBA1A1A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cảnh báo: Số dư Quỹ chung bị âm!',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBA1A1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Số dư dự kiến (${AppFormatters.formatVnd(projectedFundBalance)}) nhỏ hơn 0 ₫. Quy định Sổ cái bất biến không cho phép phê duyệt giao dịch làm âm Quỹ chung.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF93000A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DirectionOptionButton extends StatelessWidget {
  final String sign;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color activeColor;
  final Color activeBackground;
  final VoidCallback onTap;

  const _DirectionOptionButton({
    super.key,
    required this.sign,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.activeColor,
    required this.activeBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBackground : const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE6DFD8),
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFE9E8E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  sign,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? Colors.white : const Color(0xFF58413F),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? activeColor
                          : const Color(0xFF58413F),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isSelected
                          ? activeColor.withAlpha(220)
                          : const Color(0xFF58413F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _QuickAmountChip({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: isDanger ? null : 'monospace',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: isDanger ? const Color(0xFFBA1A1A) : const Color(0xFF1A1C1A),
        ),
      ),
      backgroundColor: isDanger ? Colors.white : const Color(0xFFFAF9F6),
      side: BorderSide(
        color: isDanger ? const Color(0xFFFECACA) : const Color(0xFFE6DFD8),
      ),
      onPressed: onTap,
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF58413F)),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  const _StepCircle({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppTheme.primaryCrimson,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
