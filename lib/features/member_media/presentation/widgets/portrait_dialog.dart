import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/files/member_file_actions.dart';
import '../providers/member_media_providers.dart';
import 'media_dialog_shell.dart';

class PortraitDialog extends ConsumerStatefulWidget {
  final String memberId;
  const PortraitDialog({super.key, required this.memberId});
  @override
  ConsumerState<PortraitDialog> createState() => _PortraitDialogState();
}

class _PortraitDialogState extends ConsumerState<PortraitDialog> {
  final _crop = CropController();
  Uint8List? _source;
  Uint8List? _prepared;
  Failure? _error;
  bool _busy = false;
  bool _ready = false;
  late int _version;
  @override
  void initState() {
    super.initState();
    _version = ref
        .read(memberMediaProvider(widget.memberId))
        .member!
        .mediaVersion;
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final files = await ref
          .read(memberFileActionsProvider)
          .pick(portrait: true);
      if (!mounted || files.isEmpty) return;
      validateMediaFile(files.single, portrait: true);
      final bytes = await files.single.read();
      validateMediaFile(
        SelectedMediaFile(files.single.name, bytes.length, () async => bytes),
        portrait: true,
      );
      await validatePortraitDimensions(bytes);
      if (mounted) {
        setState(() {
          _source = bytes;
          _prepared = null;
          _ready = false;
        });
      }
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = const MediaFailure(
            code: 'INVALID_MEDIA_FILE',
            message: 'Không thể đọc ảnh đã chọn.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(Uint8List bytes) async {
    try {
      final prepared = _prepared ?? await resizePortrait(bytes);
      _prepared = prepared;
      if (!mounted) return;
      await ref
          .read(memberMediaProvider(widget.memberId).notifier)
          .avatar(_version, prepared);
      if (mounted) Navigator.pop(context, true);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = const MediaFailure(
            code: 'INVALID_MEDIA_FILE',
            message: 'Không thể xử lý ảnh. Hãy chọn ảnh khác.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    await ref.read(memberMediaProvider(widget.memberId).notifier).reload();
    if (!mounted) return;
    final state = ref.read(memberMediaProvider(widget.memberId));
    if (state.error != null) {
      setState(() => _error = state.error);
      return;
    }
    setState(() {
      _version = state.member!.mediaVersion;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => MediaDialogShell(
    title: 'Thay ảnh chân dung',
    busy: _busy,
    dirty: _source != null,
    actions: [
      FilledButton(
        onPressed: _busy || !_ready || _error?.statusCode == 409
            ? null
            : () {
                setState(() {
                  _busy = true;
                  _error = null;
                });
                if (_prepared != null) {
                  _save(_prepared!);
                } else {
                  _crop.crop();
                }
              },
        child: Text(_busy ? 'Đang xử lý…' : 'Lưu ảnh'),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JPEG hoặc PNG · Tối đa 5 MiB. Chọn khung vuông để làm ảnh đại diện.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pick,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Chọn ảnh'),
        ),
        if (_source != null)
          SizedBox(
            height: 320,
            child: Crop(
              key: ObjectKey(_source),
              image: _source!,
              controller: _crop,
              aspectRatio: 1,
              onStatusChanged: (status) {
                if (mounted) {
                  setState(() => _ready = status == CropStatus.ready);
                }
              },
              onCropped: (result) {
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    _save(croppedImage);
                  case CropFailure():
                    setState(() {
                      _busy = false;
                      _error = const MediaFailure(
                        code: 'CROP_FAILED',
                        message: 'Không thể cắt ảnh. Hãy thử ảnh khác.',
                      );
                    });
                }
              },
            ),
          ),
        if (_error != null) MediaError(_error!, onRefresh: _refresh),
      ],
    ),
  );
}
