import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/auth_models.dart';
import '../providers/join_requests_provider.dart';

/// Modal nhập lý do Từ chối đơn xin gia nhập (US-17 & US-33).
/// Tuân thủ quy chuẩn AC-06: Bắt buộc cung cấp lý do từ chối (1-500 ký tự).
class RejectJoinRequestDialog extends ConsumerStatefulWidget {
  final JoinRequestResponseDto request;
  final VoidCallback? onRejected;

  const RejectJoinRequestDialog({
    super.key,
    required this.request,
    this.onRejected,
  });

  static Future<void> show(
    BuildContext context, {
    required JoinRequestResponseDto request,
    VoidCallback? onRejected,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RejectJoinRequestDialog(
        request: request,
        onRejected: onRejected,
      ),
    );
  }

  @override
  ConsumerState<RejectJoinRequestDialog> createState() => _RejectJoinRequestDialogState();
}

class _RejectJoinRequestDialogState extends ConsumerState<RejectJoinRequestDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _quickReasonTemplates = [
    'Thông tin nhân thân không khớp gia phả',
    'Số điện thoại liên lạc không phản hồi',
    'Mã mời đã hết hiệu lực nội bộ',
    'Cần bổ sung minh chứng gia phả trực hệ',
    'Nhánh đề xuất không có mối liên kết xác minh',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _applyTemplate(String text) {
    setState(() {
      _reasonController.text = text;
    });
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(joinRequestsProvider.notifier)
        .rejectRequest(widget.request.requestId, _reasonController.text);

    if (mounted && success) {
      widget.onRejected?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(joinRequestsProvider);
    final isLoading = state.isActionLoading && state.actionRequestId == widget.request.requestId;

    return Dialog(
      backgroundColor: const Color(0xFFFCF9F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.highlight_off_rounded,
                        color: Color(0xFFBA1A1A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Từ Chối Đơn Xin Gia Nhập',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mã đơn: ${widget.request.requestId} • Ứng viên: ${widget.request.fullName}',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12,
                              color: Color(0xFF54433E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      color: const Color(0xFF54433E),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Alert info banner
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
                      Icon(Icons.info_outline, size: 18, color: Color(0xFFBA1A1A)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Theo quy chuẩn AC-06: Khi từ chối, tài khoản tạm của ứng viên sẽ bị vô hiệu hóa an toàn và lý do sẽ được lưu vào biên bản kiểm toán.',
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
                const SizedBox(height: 16),

                // Quick reason template chips
                const Text(
                  'Gợi ý lý do từ chối thường gặp:',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF54433E),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickReasonTemplates.map((template) {
                    final isSelected = _reasonController.text == template;
                    return InkWell(
                      onTap: isLoading ? null : () => _applyTemplate(template),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF8F482F).withAlpha(30) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF8F482F) : const Color(0xFFDAC1BA),
                          ),
                        ),
                        child: Text(
                          template,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? const Color(0xFF8F482F) : const Color(0xFF2B1810),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Multiline reason text field
                const Text(
                  'Lý do từ chối cụ thể (Bắt buộc) *',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1A),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _reasonController,
                  enabled: !isLoading,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Nhập chi tiết lý do từ chối để thông báo cho ứng viên...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF85736E)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFDAC1BA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập lý do từ chối (bắt buộc)';
                    }
                    if (value.trim().length > 500) {
                      return 'Lý do từ chối không được vượt quá 500 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Error feedback if any
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFBA1A1A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: const BorderSide(color: Color(0xFFDAC1BA)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Hủy Bỏ',
                        style: TextStyle(
                          color: Color(0xFF54433E),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _handleConfirm,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.close_rounded, size: 18),
                      label: Text(
                        isLoading ? 'Đang xử lý...' : 'Xác Nhận Từ Chối',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA1A1A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
