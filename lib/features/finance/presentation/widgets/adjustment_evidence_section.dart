import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/files/member_file_actions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/ledger_adjustment_models.dart';

enum EvidenceInputMode { file, url }

/// Vùng đính kèm 01 biên bản/chứng từ duy nhất (Dropzone toàn hàng, không cắt chữ).
/// Giữ file tạm trên bộ nhớ và chỉ upload lên server tại thời điểm xác nhận gửi (Deferred Upload).
class AdjustmentEvidenceSection extends ConsumerStatefulWidget {
  final EvidenceInputMode mode;
  final SelectedEvidenceFile? selectedFile;
  final String evidenceUrl;
  final ValueChanged<EvidenceInputMode> onModeChanged;
  final ValueChanged<SelectedEvidenceFile?> onFileChanged;
  final ValueChanged<String> onUrlChanged;

  const AdjustmentEvidenceSection({
    super.key,
    required this.mode,
    required this.selectedFile,
    required this.evidenceUrl,
    required this.onModeChanged,
    required this.onFileChanged,
    required this.onUrlChanged,
  });

  static bool isValidExternalUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed.length > 500) return false;
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  @override
  ConsumerState<AdjustmentEvidenceSection> createState() =>
      _AdjustmentEvidenceSectionState();
}

class _AdjustmentEvidenceSectionState
    extends ConsumerState<AdjustmentEvidenceSection> {
  late final TextEditingController _urlController;
  String? _fileError;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.evidenceUrl);
  }

  @override
  void didUpdateWidget(covariant AdjustmentEvidenceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.evidenceUrl != widget.evidenceUrl &&
        _urlController.text != widget.evidenceUrl) {
      _urlController.text = widget.evidenceUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _fileError = null;
    });
    try {
      final files = await ref.read(memberFileActionsProvider).pick();
      if (!mounted || files.isEmpty) return;
      final picked = files.first;
      validateMediaFile(picked, portrait: false);
      final bytes = await picked.read();
      if (!mounted) return;
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw const MediaFailure(
          code: 'FILE_TOO_LARGE',
          message: 'Tệp biên bản phải có dữ liệu và không vượt quá 10 MB.',
        );
      }
      widget.onFileChanged(
        SelectedEvidenceFile(
          name: picked.name,
          sizeBytes: bytes.length,
          bytes: bytes,
        ),
      );
    } on Failure catch (e) {
      if (mounted) setState(() => _fileError = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _fileError = 'Không thể đọc tệp đã chọn. Vui lòng thử tệp khác.',
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urlInvalid = !AdjustmentEvidenceSection.isValidExternalUrl(
      widget.evidenceUrl,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24, color: Color(0xFFEFECE6)),
        const Text(
          'Biên bản đính kèm (Tùy chọn — 01 tài liệu chính)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1C1A),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Hỗ trợ PDF, JPG, PNG tối đa 10 MB hoặc dán đường dẫn lưu trữ',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
        ),
        const SizedBox(height: 10),

        // Mode switcher: File vs URL
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F3F1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModeTab(
                  key: const Key('evidence_tab_file'),
                  label: 'Tải file từ máy',
                  selected: widget.mode == EvidenceInputMode.file,
                  onTap: () => widget.onModeChanged(EvidenceInputMode.file),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _ModeTab(
                  key: const Key('evidence_tab_url'),
                  label: 'Dán đường dẫn (URL)',
                  selected: widget.mode == EvidenceInputMode.url,
                  onTap: () => widget.onModeChanged(EvidenceInputMode.url),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (widget.mode == EvidenceInputMode.file) ...[
          if (widget.selectedFile == null)
            _buildDropzone()
          else
            _buildSelectedFileCard(widget.selectedFile!),
          if (_fileError != null) ...[
            const SizedBox(height: 8),
            Text(
              _fileError!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBA1A1A),
              ),
            ),
          ],
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('evidence_url_input'),
                  controller: _urlController,
                  maxLength: 500,
                  onChanged: widget.onUrlChanged,
                  decoration: InputDecoration(
                    hintText:
                        'https://storage.familyfund.vn/evidence/bien-ban-2026.pdf',
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF8B716E),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Xóa đường dẫn',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFAF9F6),
                  side: const BorderSide(color: Color(0xFFE6DFD8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _urlController.clear();
                  widget.onUrlChanged('');
                },
                icon: const Icon(Icons.close, color: Color(0xFF58413F)),
              ),
            ],
          ),
          if (urlInvalid) ...[
            const SizedBox(height: 6),
            const Text(
              'Đường dẫn phải bắt đầu bằng http:// hoặc https:// và không quá 500 ký tự.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBA1A1A),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDropzone() {
    return InkWell(
      key: const Key('evidence_dropzone_button'),
      onTap: _isPicking ? null : _pickFile,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 108),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFDFD8D0),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE6DFD8)),
              ),
              child: _isPicking
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryCrimson,
                      ),
                    )
                  : const Icon(
                      Icons.upload_file_outlined,
                      color: AppTheme.primaryCrimson,
                      size: 22,
                    ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn biên bản PDF hoặc ảnh chụp chứng từ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1A),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Nhấn để chọn file từ thiết bị • Tối đa 10 MB (.pdf, .jpg, .png)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileCard(SelectedEvidenceFile file) {
    return Container(
      key: const Key('selected_evidence_file_card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: file.isPdf
                      ? const Color(0xFFFDF2F2)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: file.isPdf
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Icon(
                  file.isPdf
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  color: file.isPdf
                      ? AppTheme.primaryCrimson
                      : AppTheme.secondaryGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          file.formattedSize,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF58413F),
                          ),
                        ),
                        const Text('•', style: TextStyle(color: Color(0xFF58413F))),
                        const Text(
                          'Sẵn sàng tải lên khi gửi',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.immutableLedgerTeal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                key: const Key('evidence_change_file_button'),
                onPressed: _isPicking ? null : _pickFile,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  foregroundColor: const Color(0xFF1A1C1A),
                  side: const BorderSide(color: Color(0xFFDFD8D0)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Đổi file',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('evidence_remove_file_button'),
                onPressed: () {
                  setState(() => _fileError = null);
                  widget.onFileChanged(null);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  foregroundColor: const Color(0xFFBA1A1A),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text(
                  'Xóa',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.primaryCrimson : const Color(0xFF58413F),
            ),
          ),
        ),
      ),
    );
  }
}
