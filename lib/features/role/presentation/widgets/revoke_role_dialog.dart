import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/role_models.dart';
import '../providers/role_providers.dart';

class RevokeRoleDialog extends ConsumerStatefulWidget {
  final String memberId;
  final String memberName;
  final String roleCode;
  final String roleDisplayName;
  final RoleScopeType scopeType;
  final String scopeId;
  final String scopeName;

  const RevokeRoleDialog({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.roleCode,
    required this.roleDisplayName,
    required this.scopeType,
    required this.scopeId,
    required this.scopeName,
  });

  @override
  ConsumerState<RevokeRoleDialog> createState() => _RevokeRoleDialogState();
}

class _RevokeRoleDialogState extends ConsumerState<RevokeRoleDialog> {
  final _reasons = [
    'Đã hoàn thành kỳ hạn phân công tế lễ',
    'Bàn giao nhiệm vụ cho người kế nhiệm',
    'Thay đổi nhân sự theo quyết định Trưởng Tộc',
    'Thành viên xin thôi nhiệm vụ',
    'Lý do khác',
  ];

  late String _selectedReason;
  final _customReasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first;
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleRevoke() async {
    final finalReason = _selectedReason == 'Lý do khác'
        ? (_customReasonController.text.trim().isNotEmpty
            ? _customReasonController.text.trim()
            : 'Thay đổi nhân sự theo quyết định của Ban Trị Sự')
        : _selectedReason;

    setState(() => _isSubmitting = true);

    final request = RoleRevocationRequestDto(
      memberId: widget.memberId,
      roleCode: widget.roleCode,
      scopeType: widget.scopeType.code,
      scopeId: widget.scopeId,
      reason: finalReason,
    );

    final success =
        await ref.read(roleManagementProvider.notifier).revokeRole(request);

    if (mounted) {
      setState(() => _isSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(success);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã thu hồi thành công vai trò "${widget.roleDisplayName}" của ${widget.memberName}!'
                : ref.read(roleManagementProvider).errorMessage ??
                    'Không thể thu hồi vai trò',
          ),
          backgroundColor:
              success ? const Color(0xFF1B873F) : const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon Gavel Warning
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: Color(0xFFBA1A1A),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Thu Hồi Vai Trò',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1A),
              ),
            ),
            const SizedBox(height: 8),

            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF58413F),
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Xác nhận thu hồi vai trò '),
                  TextSpan(
                    text: widget.roleDisplayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A020A),
                    ),
                  ),
                  const TextSpan(text: ' của '),
                  TextSpan(
                    text: widget.memberName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                  const TextSpan(text: ' tại '),
                  TextSpan(
                    text: widget.scopeName,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF735C00),
                    ),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason selector
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F3F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE9E8E5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lý do thu hồi vào Sổ Bộ (Bắt buộc):',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF58413F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReason,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1C1A),
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFDFBFBC)),
                      ),
                    ),
                    items: _reasons
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedReason = val);
                      }
                    },
                  ),
                  if (_selectedReason == 'Lý do khác') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customReasonController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Nhập chi tiết lý do...',
                        hintStyle: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8B716E),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFDFBFBC)),
                    ),
                    child: const Text(
                      'Hủy Bỏ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF58413F),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleRevoke,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Thu Hồi Ngay',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
