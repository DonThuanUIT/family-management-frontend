import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/audit_log_models.dart';
import '../providers/audit_providers.dart';

/// Phương thức tiện ích mở Diff Viewer thích ứng:
/// - Màn hình rộng (Desktop / Tablet >= 860px): Centered Modal Dialog
/// - Màn hình hẹp (Mobile < 860px): Draggable Bottom Sheet
void showDiffViewer({
  required BuildContext context,
  required String auditId,
}) {
  final isDesktop = MediaQuery.of(context).size.width >= 860;

  if (isDesktop) {
    showDialog(
      context: context,
      barrierColor: const Color(0xFF2A2A2A).withAlpha(115), // rgba(42,42,42,0.45)
      builder: (_) => DiffViewerDialog(auditId: auditId, isDesktop: true),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF2A2A2A).withAlpha(115),
      builder: (_) => DiffViewerDialog(auditId: auditId, isDesktop: false),
    );
  }
}

class DiffViewerDialog extends ConsumerStatefulWidget {
  final String auditId;
  final bool isDesktop;

  const DiffViewerDialog({
    super.key,
    required this.auditId,
    required this.isDesktop,
  });

  @override
  ConsumerState<DiffViewerDialog> createState() => _DiffViewerDialogState();
}

class _DiffViewerDialogState extends ConsumerState<DiffViewerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(auditDetailProvider(widget.auditId));

    final content = detailAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(color: Color(0xFF8B1E1E)),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 40),
              const SizedBox(height: 12),
              Text(
                'Không thể tải chi tiết kiểm toán: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF58413F)),
              ),
            ],
          ),
        ),
      ),
      data: (detail) => _buildDetailContent(context, detail),
    );

    if (widget.isDesktop) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 980,
            maxHeight: 850,
          ),
          child: content,
        ),
      );
    } else {
      return Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Drag handle pill trên mobile
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD4D0CB),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }
  }

  Widget _buildDetailContent(BuildContext context, AuditLogDetailModel detail) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header Hộp thoại
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F3F1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B873F).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF1B873F).withAlpha(60)),
                          ),
                          child: Text(
                            detail.actionType,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            detail.description ?? 'Chi tiết thay đổi dữ liệu kiểm toán',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1C1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mã kiểm toán: ${detail.auditId} • ${dateFormat.format(detail.createdAt)} • IP: ${detail.ipAddress ?? "N/A"}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF58413F),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF58413F), size: 22),
                splashRadius: 20,
              ),
            ],
          ),
        ),

        // 2. Thân Hộp thoại (Scrollable)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thẻ thông tin ngữ cảnh (Metadata Box)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F3F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: widget.isDesktop
                      ? Row(
                          children: [
                            _metaField('NGƯỜI THỰC HIỆN', detail.actorFullName ?? detail.actorAccountId ?? 'Hệ thống', mono: false),
                            _metaField('ĐỐI TƯỢNG TÁC ĐỘNG', '${detail.entityType} • ${detail.entityId ?? "-"}', mono: true),
                            if (detail.targetMemberFullName != null)
                              _metaField('THÀNH VIÊN LIÊN QUAN', detail.targetMemberFullName!, mono: false),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _metaField('NGƯỜI THỰC HIỆN', detail.actorFullName ?? detail.actorAccountId ?? 'Hệ thống', mono: false, isFlex: false),
                            const SizedBox(height: 10),
                            _metaField('ĐỐI TƯỢNG TÁC ĐỘNG', '${detail.entityType} • ${detail.entityId ?? "-"}', mono: true, isFlex: false),
                            if (detail.targetMemberFullName != null) ...[
                              const SizedBox(height: 10),
                              _metaField('THÀNH VIÊN LIÊN QUAN', detail.targetMemberFullName!, mono: false, isFlex: false),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 20),

                // Thanh điều khiển Tab So Sánh
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    Container(
                      height: 42,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F3F1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicator: BoxDecoration(
                          color: const Color(0xFF8B1E1E),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(color: Color(0x338B1E1E), blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF58413F),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: const [
                          Tab(text: 'So Sánh Trực Quan'),
                          Tab(text: '{ } Dữ Liệu Gốc (Raw JSON)'),
                        ],
                      ),
                    ),
                    if (widget.isDesktop)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _legendItem(const Color(0xFFD32F2F), 'Giá trị cũ (Bị thay/Xóa)'),
                          const SizedBox(width: 16),
                          _legendItem(const Color(0xFF1B873F), 'Giá trị mới (Áp dụng)'),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nội dung 2 Tab
                SizedBox(
                  height: 380,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: So sánh trực quan
                      _buildVisualDiffView(detail),
                      // Tab 2: Raw JSON Split
                      _buildRawJsonDiffView(detail),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Footer Bất biến & Nút Đóng
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F3F1),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
          ),
          child: widget.isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(Icons.verified_user, color: Color(0xFF1B873F), size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Bản ghi kiểm toán bất biến (Audit Immutability) • Chống giả mạo',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B873F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B1E1E),
                        side: const BorderSide(color: Color(0xFF8B1E1E), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size(120, 48),
                      ),
                      child: const Text('Đóng cửa sổ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified_user, color: Color(0xFF1B873F), size: 16),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Bản ghi kiểm toán bất biến (Audit Immutability)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B873F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B1E1E),
                          side: const BorderSide(color: Color(0xFF8B1E1E), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Đóng cửa sổ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _metaField(String label, String value, {bool mono = false, bool isFlex = true}) {
    final col = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Color(0xFF58413F),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1C1A),
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );

    if (isFlex) {
      return Expanded(child: col);
    }
    return col;
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withAlpha(50),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF58413F)),
        ),
      ],
    );
  }

  Widget _buildVisualDiffView(AuditLogDetailModel detail) {
    final diffFields = detail.diffFields;

    if (diffFields.isEmpty) {
      return const Center(
        child: Text(
          'Không có trường dữ liệu khác biệt.',
          style: TextStyle(color: Color(0xFF58413F)),
        ),
      );
    }

    if (widget.isDesktop) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5E5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ListView.separated(
            itemCount: diffFields.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE5E5E5)),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Table header
                return Container(
                  color: const Color(0xFFF4F3F1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('TRƯỜNG THÔNG TIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF58413F)))),
                      Expanded(flex: 4, child: Text('GIÁ TRỊ CŨ (TRƯỚC THAO TÁC)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF58413F)))),
                      Expanded(flex: 4, child: Text('GIÁ TRỊ MỚI (SAU THAO TÁC)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF58413F)))),
                    ],
                  ),
                );
              }

              final field = diffFields[index - 1];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.labelDisplayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1A1C1A)),
                          ),
                          Text(
                            field.fieldKey,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF58413F), fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: field.oldValue != null ? const Color(0xFFD32F2F).withAlpha(15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: field.oldValue != null ? const Border(left: BorderSide(color: Color(0xFFD32F2F), width: 3)) : null,
                        ),
                        child: Text(
                          field.oldValue != null ? field.oldValue.toString() : '(Trống / Chưa có)',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: field.oldValue != null ? const Color(0xFF991B1B) : const Color(0xFF58413F),
                            fontStyle: field.oldValue == null ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B873F).withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: const Border(left: BorderSide(color: Color(0xFF1B873F), width: 3)),
                        ),
                        child: Text(
                          field.newValue != null ? field.newValue.toString() : '(Đã xóa)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Mobile Vertical Cards View
      return ListView.separated(
        itemCount: diffFields.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final field = diffFields[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  field.labelDisplayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1A1C1A)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: field.oldValue != null ? const Color(0xFFD32F2F).withAlpha(15) : const Color(0xFFF4F3F1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border(left: BorderSide(color: field.oldValue != null ? const Color(0xFFD32F2F) : const Color(0xFFE5E5E5), width: 3)),
                  ),
                  child: Text(
                    'Cũ: ${field.oldValue != null ? field.oldValue.toString() : "(Trống)"}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                      color: field.oldValue != null ? const Color(0xFF991B1B) : const Color(0xFF58413F),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B873F).withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                    border: const Border(left: BorderSide(color: Color(0xFF1B873F), width: 3)),
                  ),
                  child: Text(
                    'Mới: ${field.newValue != null ? field.newValue.toString() : "(Đã xóa)"}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildRawJsonDiffView(AuditLogDetailModel detail) {
    const encoder = JsonEncoder.withIndent('  ');
    final oldJsonStr = detail.oldValue != null ? encoder.convert(detail.oldValue) : 'null (Không có dữ liệu trước thao tác)';
    final newJsonStr = detail.newValue != null ? encoder.convert(detail.newValue) : 'null (Dữ liệu đã bị xóa)';

    if (widget.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _jsonPanel(context, 'DỮ LIỆU CŨ (old_value JSON)', oldJsonStr, const Color(0xFFD32F2F))),
          const SizedBox(width: 14),
          Expanded(child: _jsonPanel(context, 'DỮ LIỆU MỚI (new_value JSON)', newJsonStr, const Color(0xFF1B873F))),
        ],
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            _jsonPanel(context, 'DỮ LIỆU CŨ (old_value JSON)', oldJsonStr, const Color(0xFFD32F2F)),
            const SizedBox(height: 12),
            _jsonPanel(context, 'DỮ LIỆU MỚI (new_value JSON)', newJsonStr, const Color(0xFF1B873F)),
          ],
        ),
      );
    }
  }

  Widget _jsonPanel(BuildContext context, String title, String jsonContent, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D1C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3D3F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF2B2D2B),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: Color(0xFF3D3F3D))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFF1F1EE), fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép JSON vào clipboard!'), duration: Duration(seconds: 1)),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 14, color: Color(0xFFD4AF37)),
                  label: const Text('Sao chép', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11.5)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(60, 28)),
                ),
              ],
            ),
          ),
          if (widget.isDesktop)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  jsonContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: Color(0xFFEFEEEB),
                    height: 1.5,
                  ),
                ),
              ),
            )
          else
            Container(
              height: 200,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: Color(0xFFEFEEEB),
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
