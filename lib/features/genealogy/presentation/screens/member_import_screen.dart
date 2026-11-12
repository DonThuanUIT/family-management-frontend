import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../providers/member_import_provider.dart';
import '../widgets/member_import_preview_table.dart';

/// Màn hình Nhập hàng loạt thành viên từ file Excel (.xlsx) / CSV (.csv) (US-31).
class MemberImportScreen extends ConsumerWidget {
  const MemberImportScreen({super.key});

  static const Color _primaryColor = Color(0xFF8F482F);
  static const Color _bgColor = Color(0xFFFAF6F0);
  static const Color _borderColor = Color(0xFFDAC1BA);

  Future<void> _handleDownloadTemplate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bytes = await ref.read(memberImportProvider.notifier).downloadTemplateBytes();
    if (bytes == null || !context.mounted) return;

    const mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (!kIsWeb) {
      await FileSaver.instance.saveAs(
        name: 'mau-nhap-thanh-vien',
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.custom,
        customMimeType: mimeType,
      );
    } else {
      await FileSaver.instance.saveFile(
        name: 'mau-nhap-thanh-vien',
        bytes: bytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.custom,
        customMimeType: mimeType,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tải file mẫu Excel (mau-nhap-thanh-vien.xlsx)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handlePickAndPreviewFile(WidgetRef ref) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv'],
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final size = await picked.length() ?? bytes.length;

    await ref.read(memberImportProvider.notifier).uploadAndPreview(
          bytes: bytes,
          fileName: picked.name,
          sizeBytes: size,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memberImportProvider);
    final preview = state.preview;
    final confirmResult = state.confirmResult;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: const HeritageNavBar(currentRoute: '/members/import'),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/members/import'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tiêu đề & nút tải file mẫu
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhập Hàng Loạt Thành Viên (Excel / CSV)',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tải file mẫu, tải lên danh sách thành viên để kiểm tra lỗi từng dòng và xác nhận nhập dữ liệu hợp lệ.',
                          style: TextStyle(color: Color(0xFF54433E), fontSize: 13),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: state.isDownloadingTemplate
                          ? null
                          : () => _handleDownloadTemplate(context, ref),
                      icon: state.isDownloadingTemplate
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      label: const Text('Tải file mẫu Excel (.xlsx)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: const BorderSide(color: _primaryColor),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Khu vực chọn file upload
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5ECE6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.upload_file, color: _primaryColor, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.selectedFileName ?? 'Chưa chọn file (.xlsx hoặc .csv)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Color(0xFF1C1C1A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.selectedFileSizeBytes != null
                                    ? 'Dung lượng: ${(state.selectedFileSizeBytes! / 1024).toStringAsFixed(1)} KB • Tối đa 5 MB / 1.000 dòng'
                                    : 'Hỗ trợ định dạng .xlsx và .csv (UTF-8), tối đa 5 MB / 1.000 dòng',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF54433E)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: state.isUploadingPreview
                            ? null
                            : () => _handlePickAndPreviewFile(ref),
                        icon: state.isUploadingPreview
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.folder_open),
                        label: Text(
                          state.isUploadingPreview ? 'Đang kiểm tra file...' : 'Chọn file Excel / CSV',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                if (state.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (confirmResult != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Đã nhập thành công ${confirmResult.insertedCount} thành viên vào cơ sở dữ liệu'
                            '${confirmResult.skippedCount > 0 ? ' (bỏ qua ${confirmResult.skippedCount} dòng không hợp lệ).' : '.'}',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (preview != null) ...[
                  const SizedBox(height: 20),
                  // Thanh thống kê & bộ lọc
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatChip(
                            label: 'Tổng: ${preview.totalRows}',
                            color: Colors.blueGrey.shade700,
                            bgColor: Colors.blueGrey.shade50,
                          ),
                          _StatChip(
                            label: 'Hợp lệ: ${preview.validCount}',
                            color: Colors.green.shade800,
                            bgColor: Colors.green.shade50,
                          ),
                          _StatChip(
                            label: 'Lỗi: ${preview.errorCount}',
                            color: Colors.red.shade800,
                            bgColor: Colors.red.shade50,
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Tất cả'),
                            selected: state.filterMode == MemberImportFilterMode.all,
                            onSelected: (_) => ref
                                .read(memberImportProvider.notifier)
                                .setFilterMode(MemberImportFilterMode.all),
                          ),
                          ChoiceChip(
                            label: const Text('Hợp lệ'),
                            selected: state.filterMode == MemberImportFilterMode.validOnly,
                            onSelected: (_) => ref
                                .read(memberImportProvider.notifier)
                                .setFilterMode(MemberImportFilterMode.validOnly),
                          ),
                          ChoiceChip(
                            label: const Text('Bị lỗi'),
                            selected: state.filterMode == MemberImportFilterMode.errorOnly,
                            onSelected: (_) => ref
                                .read(memberImportProvider.notifier)
                                .setFilterMode(MemberImportFilterMode.errorOnly),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Preview Table
                  MemberImportPreviewTable(rows: state.filteredRows),
                  const SizedBox(height: 18),

                  // Nút xác nhận nhập các dòng hợp lệ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: (preview.validCount == 0 || state.isConfirming || confirmResult != null)
                            ? null
                            : () => ref.read(memberImportProvider.notifier).confirmValidRows(),
                        icon: state.isConfirming
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.playlist_add_check),
                        label: Text(
                          'Xác nhận nhập các dòng hợp lệ (${preview.validCount})',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
