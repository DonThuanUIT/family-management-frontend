import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/member_media_models.dart';
import '../../domain/usecases/biography_document.dart';
import '../providers/member_media_providers.dart';
import 'media_dialog_shell.dart';

class BiographyEditorDialog extends ConsumerStatefulWidget {
  final String memberId;
  const BiographyEditorDialog({super.key, required this.memberId});
  @override
  ConsumerState<BiographyEditorDialog> createState() =>
      _BiographyEditorDialogState();
}

class _BiographyEditorDialogState extends ConsumerState<BiographyEditorDialog> {
  late final quill.QuillController _controller;
  late MediaVisibility _visibility;
  late int _version;
  late String _initialDocument;
  late MediaVisibility _initialVisibility;
  Failure? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final member = ref.read(memberMediaProvider(widget.memberId)).member!;
    _visibility = member.visibility;
    _version = member.mediaVersion;
    _controller = quill.QuillController(
      document: member.biography == null
          ? quill.Document()
          : quill.Document.fromJson(member.biography!['ops'] as List),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _controller.addListener(_changed);
    _initialDocument = jsonEncode(_controller.document.toDelta().toJson());
    _initialVisibility = _visibility;
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
      _controller.readOnly = true;
    });
    try {
      final document = normalizeBiography(
        _controller.document.toDelta().toJson(),
      );
      await ref
          .read(memberMediaProvider(widget.memberId).notifier)
          .biography(_version, document, _visibility);
      if (mounted) Navigator.pop(context, true);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _controller.readOnly = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    await ref.read(memberMediaProvider(widget.memberId).notifier).reload();
    if (!mounted) return;
    final state = ref.read(memberMediaProvider(widget.memberId));
    setState(() {
      _busy = false;
      _error = state.error;
      if (state.error == null) _version = state.member!.mediaVersion;
    });
  }

  void _format(quill.Attribute attribute) {
    final active =
        _controller.getSelectionStyle().attributes[attribute.key]?.value ==
        attribute.value;
    _controller.formatSelection(
      active ? quill.Attribute.clone(attribute, null) : attribute,
    );
  }

  Future<void> _link() async {
    final text = TextEditingController(text: 'https://');
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chèn liên kết HTTPS'),
        content: TextField(
          controller: text,
          decoration: const InputDecoration(labelText: 'Địa chỉ liên kết'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text.trim()),
            child: const Text('Chèn'),
          ),
        ],
      ),
    );
    // Dispose after the closing route's animation has released the TextField.
    Future.delayed(const Duration(milliseconds: 300), text.dispose);
    if (!mounted || url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      setState(
        () => _error = const MediaFailure(
          code: 'INVALID_LINK',
          message: 'Hãy nhập liên kết HTTPS hợp lệ.',
        ),
      );
      return;
    }
    _controller.formatSelection(quill.LinkAttribute(url));
  }

  @override
  Widget build(BuildContext context) => MediaDialogShell(
    dirty:
        jsonEncode(_controller.document.toDelta().toJson()) !=
            _initialDocument ||
        _visibility != _initialVisibility,
    title: 'Chỉnh sửa tiểu sử',
    busy: _busy,
    actions: [
      FilledButton(
        onPressed: _busy || _error?.statusCode == 409 ? null : _save,
        child: Text(_busy ? 'Đang lưu…' : 'Lưu tiểu sử'),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ghi lại cuộc đời, đóng góp và những câu chuyện đáng nhớ của thành viên.',
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: _busy,
          child: Wrap(
            children: [
              for (final item in [
                (Icons.format_bold, 'In đậm', quill.Attribute.bold),
                (Icons.format_italic, 'In nghiêng', quill.Attribute.italic),
                (
                  Icons.format_underlined,
                  'Gạch chân',
                  quill.Attribute.underline,
                ),
                (Icons.looks_one_outlined, 'Tiêu đề 1', quill.Attribute.h1),
                (Icons.looks_two_outlined, 'Tiêu đề 2', quill.Attribute.h2),
                (Icons.looks_3_outlined, 'Tiêu đề 3', quill.Attribute.h3),
                (Icons.format_list_bulleted, 'Danh sách', quill.Attribute.ul),
                (
                  Icons.format_list_numbered,
                  'Danh sách đánh số',
                  quill.Attribute.ol,
                ),
                (Icons.format_quote, 'Trích dẫn', quill.Attribute.blockQuote),
              ])
                IconButton(
                  tooltip: item.$2,
                  icon: Icon(item.$1),
                  onPressed: () => _format(item.$3),
                ),
              IconButton(
                tooltip: 'Chèn liên kết HTTPS',
                onPressed: _link,
                icon: const Icon(Icons.link),
              ),
              IconButton(
                tooltip: 'Bỏ liên kết',
                onPressed: () => _controller.formatSelection(
                  const quill.LinkAttribute(null),
                ),
                icon: const Icon(Icons.link_off),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 280,
            child: quill.QuillEditor.basic(
              controller: _controller,
              config: QuillEditorConfigForMedia.editable,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_controller.document.toPlainText().runes.length} / 20.000 ký tự',
        ),
        const SizedBox(height: 16),
        VisibilityField(
          value: _visibility,
          onChanged: _busy ? null : (v) => setState(() => _visibility = v),
        ),
        if (_error != null) MediaError(_error!, onRefresh: _refresh),
      ],
    ),
  );
}

abstract final class QuillEditorConfigForMedia {
  static final editable = quill.QuillEditorConfig(
    padding: const EdgeInsets.all(16),
    placeholder: 'Viết tiểu sử tại đây…',
    onLaunchUrl: copyLink,
  );
  static void copyLink(String url) {
    if (Uri.tryParse(url)?.scheme == 'https') {
      Clipboard.setData(ClipboardData(text: url));
    }
  }
}

class BiographyView extends StatefulWidget {
  final Map<String, dynamic> document;
  const BiographyView({super.key, required this.document});
  @override
  State<BiographyView> createState() => _BiographyViewState();
}

class _BiographyViewState extends State<BiographyView> {
  late final quill.QuillController _controller = quill.QuillController(
    document: quill.Document.fromJson(widget.document['ops'] as List),
    selection: const TextSelection.collapsed(offset: 0),
    readOnly: true,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => quill.QuillEditor.basic(
    controller: _controller,
    config: quill.QuillEditorConfig(
      scrollable: false,
      showCursor: false,
      onLaunchUrl: (url) {
        QuillEditorConfigForMedia.copyLink(url);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã sao chép liên kết.')));
      },
    ),
  );
}
