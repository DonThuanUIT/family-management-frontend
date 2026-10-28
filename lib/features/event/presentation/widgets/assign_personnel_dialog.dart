import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/event_models.dart';
import '../providers/event_providers.dart';

class AssignPersonnelDialog extends ConsumerStatefulWidget {
  final EventModel event;

  const AssignPersonnelDialog({super.key, required this.event});

  @override
  ConsumerState<AssignPersonnelDialog> createState() =>
      _AssignPersonnelDialogState();
}

class _AssignPersonnelDialogState extends ConsumerState<AssignPersonnelDialog> {
  String? _selectedHead;
  String? _selectedTreasurer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedHead = widget.event.headOfOrganizer?.memberId ?? 'MEM_001';
    _selectedTreasurer = widget.event.eventTreasurer?.memberId ?? 'MEM_002';
  }

  Future<void> _submitAssignment() async {
    setState(() => _isSubmitting = true);

    bool ok = true;
    if (_selectedHead != null && _selectedHead!.isNotEmpty) {
      final res = await ref.read(eventListProvider.notifier).assignPersonnel(
            widget.event.eventId,
            AssignPersonnelRequestDto(
              memberId: _selectedHead!,
              eventRole: 'HeadOfOrganizer',
            ),
          );
      if (!res) ok = false;
    }

    if (_selectedTreasurer != null && _selectedTreasurer!.isNotEmpty) {
      final res = await ref.read(eventListProvider.notifier).assignPersonnel(
            widget.event.eventId,
            AssignPersonnelRequestDto(
              memberId: _selectedTreasurer!,
              eventRole: 'EventTreasurer',
            ),
          );
      if (!res) ok = false;
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Đã gọi API chỉ định ban tổ chức và thủ quỹ thành công!'
              : 'Có lỗi xảy ra khi lưu chỉ định nhân sự'),
          backgroundColor: ok ? const Color(0xFF1B5E20) : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.event.isClosed;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Color(0xFF7A1518),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân Định Nhân Sự Tế Sự',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                      Text(
                        'Contextual RBAC: Gắn quyền theo từng sự kiện',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A7A70),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const Divider(height: 20),

            if (isClosed)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Color(0xFFE65100)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sự kiện đã Đóng Sổ (Closed). Quyền hạn đã tự động chuyển sang chế độ Chỉ Đọc (Read-Only).',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFFE65100)),
                      ),
                    ),
                  ],
                ),
              ),

            // Trưởng BTC
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedHead,
              decoration: const InputDecoration(
                labelText: 'Trưởng Ban Tổ Chức (Tối đa 1)',
                prefixIcon: Icon(Icons.person_pin_circle_outlined, size: 20),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'MEM_001',
                  child: Text('Ông Vũ Văn Thịnh (Chi 1)', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'MEM_002',
                  child: Text('Ông Vũ Trọng Nghĩa (Chi 2)', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'MEM_005',
                  child: Text('Ông Vũ Đức Minh (Chi 3)', overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: isClosed || _isSubmitting
                  ? null
                  : (val) => setState(() => _selectedHead = val),
            ),
            const SizedBox(height: 12),

            // Thủ quỹ sự kiện
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedTreasurer,
              decoration: const InputDecoration(
                labelText: 'Thủ Quỹ Sự Kiện (Tối đa 1)',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'MEM_002',
                  child: Text('Bà Vũ Thị Lan (Chi 1)', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'MEM_004',
                  child: Text('Ông Vũ Quốc Huy (Chi 3)', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'MEM_006',
                  child: Text('Bà Vũ Hoàng Yến (Chi 2)', overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: isClosed || _isSubmitting
                  ? null
                  : (val) => setState(() => _selectedTreasurer = val),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ),
                if (!isClosed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A1518),
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Lưu Chỉ Định'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
