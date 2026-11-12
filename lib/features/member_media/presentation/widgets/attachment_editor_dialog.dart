import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/files/member_file_actions.dart';
import '../../data/models/member_media_models.dart';
import '../providers/member_media_providers.dart';
import 'media_dialog_shell.dart';

class _UploadDraft {
  final SelectedMediaFile file;
  String key = newUploadKey();
  final TextEditingController title;
  final TextEditingController description = TextEditingController();
  MediaVisibility visibility = MediaVisibility.restricted;
  Uint8List? bytes;
  bool attempted = false, complete = false;
  _UploadDraft(this.file)
    : title = TextEditingController(
        text: file.name
            .replaceFirst(RegExp(r'\.[^.]+$'), '')
            .characters
            .take(150)
            .toString(),
      );
  void dispose() {
    title.dispose();
    description.dispose();
    bytes = null;
  }
}

class AttachmentEditorDialog extends ConsumerStatefulWidget {
  final String memberId;
  final FamilyAttachment? attachment;
  const AttachmentEditorDialog({
    super.key,
    required this.memberId,
    this.attachment,
  });
  @override
  ConsumerState<AttachmentEditorDialog> createState() =>
      _AttachmentEditorDialogState();
}

class _AttachmentEditorDialogState
    extends ConsumerState<AttachmentEditorDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _drafts = <_UploadDraft>[];
  MediaVisibility _visibility = MediaVisibility.restricted;
  FamilyAttachment? _attachment;
  Failure? _error;
  bool _busy = false;
  double? _progress;
  int _active = 0;
  @override
  void initState() {
    super.initState();
    _attachment = widget.attachment;
    if (_attachment case final attachment?) {
      _title.text = attachment.title;
      _description.text = attachment.description ?? '';
      _visibility = attachment.visibility;
    }
    _title.addListener(_metadataChanged);
    _description.addListener(_metadataChanged);
  }

  void _metadataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final files = await ref.read(memberFileActionsProvider).pick();
      if (!mounted || files.isEmpty) return;
      if (_drafts.length + files.length > 20) {
        throw const MediaFailure(
          code: 'FILE_LIMIT',
          message: 'Chọn tối đa 20 file trong một lượt.',
        );
      }
      for (final file in files) {
        validateMediaFile(file);
      }
      setState(() {
        _drafts.addAll(files.map(_UploadDraft.new));
      });
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = const MediaFailure(
            code: 'PICK_FAILED',
            message: 'Không thể mở file đã chọn.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateTitle(String? value) => value == null || value.trim().isEmpty
      ? 'Vui lòng nhập tên tư liệu.'
      : value.trim().runes.length > 150
      ? 'Tên tối đa 150 ký tự.'
      : null;
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_attachment == null) {
      for (var i = 0; i < _drafts.length; i++) {
        final draft = _drafts[i];
        if (!draft.complete &&
            (_validateTitle(draft.title.text) != null ||
                draft.description.text.runes.length > 1000)) {
          setState(() {
            _active = i;
            _error = const MediaFailure(
              code: 'INVALID_METADATA',
              message: 'Hãy kiểm tra tên và mô tả cho từng file.',
            );
          });
          return;
        }
      }
    }
    setState(() {
      _busy = true;
      _error = null;
      _progress = null;
    });
    try {
      final notifier = ref.read(memberMediaProvider(widget.memberId).notifier);
      if (_attachment case final attachment?) {
        await notifier.edit(
          attachment,
          _title.text,
          _description.text,
          _visibility,
        );
      } else {
        for (var i = 0; i < _drafts.length; i++) {
          final draft = _drafts[i];
          if (draft.complete) continue;
          setState(() {
            _active = i;
            _progress = null;
          });
          draft.bytes ??= await draft.file.read();
          if (!mounted) return;
          validateMediaFile(
            SelectedMediaFile(
              draft.file.name,
              draft.bytes!.length,
              () async => draft.bytes!,
            ),
          );
          draft.attempted = true;
          await notifier.upload(
            draft.bytes!,
            draft.file.name,
            draft.title.text,
            draft.description.text,
            draft.visibility,
            draft.key,
            (sent, total) {
              if (mounted) {
                setState(() => _progress = total > 0 ? sent / total : null);
              }
            },
          );
          if (!mounted) return;
          draft.complete = true;
          draft.bytes = null;
        }
      }
      if (mounted) Navigator.pop(context, true);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = const MediaFailure(
            code: 'FILE_READ_FAILED',
            message: 'Không thể đọc file trên thiết bị. Hãy chọn file khác.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final fresh = await ref
          .read(memberMediaProvider(widget.memberId).notifier)
          .latestAttachment(_attachment!.id);
      if (mounted) {
        setState(() {
          _attachment = fresh;
          _error = null;
        });
      }
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _drafts.isEmpty ? null : _drafts[_active];
    final locked = _busy || (draft?.attempted ?? false);
    return MediaDialogShell(
      dirty: _attachment == null
          ? _drafts.isNotEmpty
          : _title.text != _attachment!.title ||
                _description.text != (_attachment!.description ?? '') ||
                _visibility != _attachment!.visibility,
      title: _attachment == null ? 'Thêm tư liệu gia sử' : 'Chỉnh sửa tư liệu',
      busy: _busy,
      actions: [
        FilledButton(
          onPressed:
              _busy ||
                  (_attachment == null && _drafts.isEmpty) ||
                  (_attachment != null && _error?.statusCode == 409)
              ? null
              : _save,
          child: Text(
            _busy
                ? 'Đang lưu…'
                : _attachment != null
                ? 'Lưu thay đổi'
                : draft?.attempted == true
                ? 'Thử tải lại'
                : 'Tải tư liệu',
          ),
        ),
      ],
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_attachment == null) ...[
              const Text(
                'PDF, JPEG hoặc PNG · Tối đa 10 MiB mỗi file. Tải lần lượt để giảm dung lượng bộ nhớ.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.upload_file),
                label: const Text('Chọn tư liệu từ thiết bị'),
              ),
              if (_drafts.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < _drafts.length; i++)
                      ChoiceChip(
                        label: Text(
                          '${i + 1}. ${_drafts[i].complete ? 'Đã tải' : 'File'}',
                        ),
                        selected: _active == i,
                        onSelected: _busy
                            ? null
                            : (_) => setState(() {
                                _active = i;
                                _error = null;
                              }),
                      ),
                  ],
                ),
              if (draft != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(draft.file.name),
                ),
              if (draft?.attempted == true)
                const Text(
                  'Thông tin đã khóa để thử lại an toàn. Để đổi nội dung, hãy đóng và tạo lượt tải mới.',
                ),
            ],
            if (_attachment != null || draft != null) ...[
              TextFormField(
                key: ValueKey(('title', _active)),
                controller: draft?.title ?? _title,
                enabled: !locked,
                decoration: const InputDecoration(labelText: 'Tên tư liệu *'),
                maxLength: 150,
                validator: _validateTitle,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey(('description', _active)),
                controller: draft?.description ?? _description,
                enabled: !locked,
                decoration: const InputDecoration(
                  labelText: 'Mô tả (không bắt buộc)',
                ),
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                validator: (v) => (v?.runes.length ?? 0) > 1000
                    ? 'Mô tả tối đa 1.000 ký tự.'
                    : null,
              ),
              const SizedBox(height: 12),
              VisibilityField(
                key: ValueKey(('visibility', _active)),
                value: draft?.visibility ?? _visibility,
                onChanged: locked
                    ? null
                    : (v) => setState(() {
                        if (draft != null) {
                          draft.visibility = v;
                        } else {
                          _visibility = v;
                        }
                      }),
              ),
            ],
            if (_busy)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(value: _progress),
              ),
            if (_error is MediaFailure &&
                (_error as MediaFailure).code == 'IDEMPOTENCY_CONFLICT' &&
                draft != null)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        draft.key = newUploadKey();
                        draft.attempted = false;
                        _error = null;
                      }),
                child: const Text('Tạo lượt tải mới (giữ thông tin đã nhập)'),
              ),
            if (_error != null)
              MediaError(
                _error!,
                onRefresh: _attachment == null ? null : _refresh,
              ),
          ],
        ),
      ),
    );
  }
}
