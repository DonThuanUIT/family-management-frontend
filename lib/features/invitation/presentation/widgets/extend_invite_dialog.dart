import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/position_link_models.dart';
import '../providers/position_link_providers.dart';

/// Modal gia hạn mã mời: gia hạn số ngày và/hoặc tăng số lượt dùng (US-34 & AC-06)
class ExtendInviteDialog extends ConsumerStatefulWidget {
  final PositionLinkItemModel item;
  final VoidCallback? onExtended;

  const ExtendInviteDialog({
    super.key,
    required this.item,
    this.onExtended,
  });

  static Future<void> show(
    BuildContext context, {
    required PositionLinkItemModel item,
    VoidCallback? onExtended,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExtendInviteDialog(
        item: item,
        onExtended: onExtended,
      ),
    );
  }

  @override
  ConsumerState<ExtendInviteDialog> createState() => _ExtendInviteDialogState();
}

class _ExtendInviteDialogState extends ConsumerState<ExtendInviteDialog> {
  int _selectedAdditionalDays = 30;
  late int _targetMaxUses;
  bool _isLoading = false;

  final List<int> _presetDays = [7, 14, 30, 90];

  @override
  void initState() {
    super.initState();
    // Khởi tạo maxUses mục tiêu
    _targetMaxUses = widget.item.maxUses < 10
        ? 10
        : widget.item.maxUses + 5;
  }

  DateTime get _calculatedNewExpiry {
    final currentExpiry = widget.item.expiresAt ?? DateTime.now();
    final baseDate = currentExpiry.isAfter(DateTime.now())
        ? currentExpiry
        : DateTime.now();
    return baseDate.add(Duration(days: _selectedAdditionalDays));
  }

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    final success = await ref
        .read(clanInvitesProvider.notifier)
        .extendInvite(
          widget.item.code,
          additionalDays: _selectedAdditionalDays,
          newMaxUses: _targetMaxUses,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onExtended?.call();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      backgroundColor: const Color(0xFFFCF9F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.more_time_rounded,
                      color: Color(0xFF006E2A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gia Hạn Mã Mời Gia Phả',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kéo dài thời gian hiệu lực và bổ sung số lượt dùng',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF54433E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    color: const Color(0xFF54433E),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mã mời:',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF54433E)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.item.code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8F482F),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14, color: Color(0xFFF0EDEB)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đối tượng / Nhánh:',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF54433E)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${widget.item.fullName} (${widget.item.branchName})',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1A),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14, color: Color(0xFFF0EDEB)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lượt đã dùng hiện tại:',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF54433E)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${widget.item.usedCount} / ${widget.item.maxUses} lượt',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: widget.item.isUsedUp
                                  ? const Color(0xFFBA1A1A)
                                  : const Color(0xFF006E2A),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14, color: Color(0xFFF0EDEB)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hạn dùng hiện tại:',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF54433E)),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.item.expiresAt != null
                                ? dateFormat.format(widget.item.expiresAt!)
                                : 'Vô thời hạn',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: widget.item.isExpired
                                  ? const Color(0xFFBA1A1A)
                                  : const Color(0xFF1C1C1A),
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Selection: Additional Days
              const Text(
                'Thêm thời gian hiệu lực:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1A),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetDays.map((days) {
                  final isSelected = _selectedAdditionalDays == days;
                  return ChoiceChip(
                    label: Text('+$days ngày'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedAdditionalDays = days);
                      }
                    },
                    selectedColor: const Color(0xFF8F482F),
                    labelStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF54433E),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF8F482F)
                          : const Color(0xFFDAC1BA),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Color(0xFF8F482F)),
                    const SizedBox(width: 8),
                    Text(
                      'Hạn mới sau gia hạn: ${dateFormat.format(_calculatedNewExpiry)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8F482F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Max uses configuration
              const Text(
                'Cập nhật số lượt dùng tối đa (max_uses):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1A),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _targetMaxUses > (widget.item.usedCount > 1 ? widget.item.usedCount : 1)
                        ? () => setState(() => _targetMaxUses--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: const Color(0xFF8F482F),
                  ),
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDAC1BA)),
                    ),
                    child: Text(
                      '$_targetMaxUses',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1A),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _targetMaxUses++),
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF8F482F),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đã dùng ${_widgetItemRemaining(widget.item, _targetMaxUses)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF54433E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDAC1BA)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Hủy Bỏ',
                      style: TextStyle(
                        color: Color(0xFF54433E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleConfirm,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 16),
                    label: Text(
                      _isLoading ? 'Đang gia hạn...' : 'Xác Nhận Gia Hạn',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006E2A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  String _widgetItemRemaining(PositionLinkItemModel item, int newMax) {
    final remaining = newMax - item.usedCount;
    if (remaining > 0) {
      return '(còn lại $remaining lượt sử dụng)';
    }
    return '(đạt giới hạn lượt dùng)';
  }
}
