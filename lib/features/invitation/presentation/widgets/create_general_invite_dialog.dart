import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/position_link_providers.dart';

/// Modal tạo mã mời chung dòng họ hoặc phân nhánh (US-34 & US-16)
class CreateGeneralInviteDialog extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;

  const CreateGeneralInviteDialog({
    super.key,
    this.onCreated,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onCreated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateGeneralInviteDialog(onCreated: onCreated),
    );
  }

  @override
  ConsumerState<CreateGeneralInviteDialog> createState() =>
      _CreateGeneralInviteDialogState();
}

class _CreateGeneralInviteDialogState
    extends ConsumerState<CreateGeneralInviteDialog> {
  String? _selectedBranchId; // null = Toàn Tộc (Chi Gốc)
  int _selectedMaxUses = 20;
  int _selectedValidityDays = 30;
  bool _isLoading = false;

  final List<int> _maxUsesOptions = [5, 10, 20, 50, 100];
  final List<int> _validityDaysOptions = [7, 14, 30, 90];

  Future<void> _handleCreate() async {
    setState(() => _isLoading = true);
    final success = await ref
        .read(clanInvitesProvider.notifier)
        .createGeneralInvite(
          targetBranchId: _selectedBranchId,
          maxUses: _selectedMaxUses,
          validityDays: _selectedValidityDays,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onCreated?.call();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clanInvitesProvider);

    return Dialog(
      backgroundColor: const Color(0xFFFCF9F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                      color: const Color(0xFFF0EDEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_link_rounded,
                      color: Color(0xFF8F482F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo Mã Mời Gia Phả Mới',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Phát hành mã mời tham gia gia phả hoặc phân nhánh',
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

              // 2. Select Target Branch
              const Text(
                'Phân nhánh áp dụng:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDAC1BA)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedBranchId,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8F482F)),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          '🏛️ Toàn Tộc (Chi Gốc / Tất cả các nhánh)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...state.availableBranches.map((b) {
                        return DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(
                            '🌿 ${b.name}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedBranchId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Max Uses selection
              const Text(
                'Số lượt sử dụng tối đa (max_uses):',
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
                children: _maxUsesOptions.map((uses) {
                  final isSelected = _selectedMaxUses == uses;
                  return ChoiceChip(
                    label: Text('$uses lượt'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMaxUses = uses);
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
              const SizedBox(height: 18),

              // 4. Validity Days selection
              const Text(
                'Thời hạn hiệu lực:',
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
                children: _validityDaysOptions.map((days) {
                  final isSelected = _selectedValidityDays == days;
                  return ChoiceChip(
                    label: Text('$days ngày'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedValidityDays = days);
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
              const SizedBox(height: 20),

              // 5. Explanatory Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF8F482F)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mã mời chung cho phép nhiều con cháu cùng sử dụng link hoặc mã để đăng ký gia nhập dòng họ. Sau khi đạt đủ số lượt hoặc hết hạn, mã sẽ tự động khóa.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF54433E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Actions
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
                    onPressed: _isLoading ? null : _handleCreate,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add, size: 16),
                    label: Text(
                      _isLoading ? 'Đang tạo...' : 'Tạo Mã Mời Ngay',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F482F),
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
}
