import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/position_link_models.dart';
import '../providers/position_link_providers.dart';

/// Modal xác nhận thu hồi mã mời (US-34 & AC-06).
class RevokeInviteDialog extends ConsumerStatefulWidget {
  final PositionLinkItemModel item;
  final VoidCallback? onRevoked;

  const RevokeInviteDialog({
    super.key,
    required this.item,
    this.onRevoked,
  });

  static Future<void> show(
    BuildContext context, {
    required PositionLinkItemModel item,
    VoidCallback? onRevoked,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RevokeInviteDialog(
        item: item,
        onRevoked: onRevoked,
      ),
    );
  }

  @override
  ConsumerState<RevokeInviteDialog> createState() => _RevokeInviteDialogState();
}

class _RevokeInviteDialogState extends ConsumerState<RevokeInviteDialog> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    setState(() => _isLoading = true);
    final success = await ref
        .read(clanInvitesProvider.notifier)
        .deactivateInvite(widget.item.code);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.onRevoked?.call();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFCF9F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Color(0xFFBA1A1A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thu Hồi Mã Mời Gia Phả',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Vô hiệu hóa sớm mã truy cập gia nhập',
                          style: TextStyle(fontSize: 12, color: Color(0xFF54433E)),
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
              const SizedBox(height: 16),

              // Code details card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Mã mời: ',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF54433E)),
                        ),
                        Text(
                          widget.item.code,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8F482F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Đối tượng / Tên: ',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF54433E)),
                        ),
                        Expanded(
                          child: Text(
                            widget.item.fullName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Lượt đã dùng: ',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF54433E)),
                        ),
                        Text(
                          '${widget.item.usedCount} / ${widget.item.maxUses} lượt',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Warning alert
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFDAD6)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFBA1A1A)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sau khi thu hồi, mã mời này sẽ chuyển sang trạng thái "Đã Thu Hồi". Con cháu sẽ không thể sử dụng mã này để đăng ký hoặc nhận vị trí.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF93000A),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
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
                      style: TextStyle(color: Color(0xFF54433E), fontWeight: FontWeight.w600),
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
                        : const Icon(Icons.delete_outline, size: 16),
                    label: Text(
                      _isLoading ? 'Đang thu hồi...' : 'Xác Nhận Thu Hồi',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A),
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
