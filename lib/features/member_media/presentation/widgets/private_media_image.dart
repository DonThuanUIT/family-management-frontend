import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../providers/member_media_providers.dart';

/// Uses a disposable decoder instead of Flutter's global ImageCache for private bytes.
class PrivateMediaImage extends ConsumerWidget {
  final MediaContentKey contentKey;
  final double? size;
  final String label;
  final bool preview;
  const PrivateMediaImage({
    super.key,
    required this.contentKey,
    required this.label,
    this.size,
    this.preview = false,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(mediaContentProvider(contentKey));
    return SizedBox(
      width: size,
      height: size,
      child: content.when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => size != null && size! < 80
            ? IconButton(
                tooltip: 'Không thể tải ảnh. Thử lại',
                onPressed: () =>
                    ref.invalidate(mediaContentProvider(contentKey)),
                icon: const Icon(Icons.person_outline),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_outlined),
                    if (preview)
                      Text(
                        error is Failure ? error.message : 'Không thể đọc ảnh.',
                      ),
                    IconButton(
                      tooltip: 'Tải lại ảnh',
                      onPressed: () =>
                          ref.invalidate(mediaContentProvider(contentKey)),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
        data: (bytes) => _DecodedImage(
          key: ValueKey((ref.watch(mediaSessionProvider), contentKey, bytes)),
          bytes: bytes,
          label: label,
          preview: preview,
        ),
      ),
    );
  }
}

class _DecodedImage extends StatefulWidget {
  final Uint8List bytes;
  final String label;
  final bool preview;
  const _DecodedImage({
    super.key,
    required this.bytes,
    required this.label,
    required this.preview,
  });
  @override
  State<_DecodedImage> createState() => _DecodedImageState();
}

class _DecodedImageState extends State<_DecodedImage> {
  ui.Image? _image;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(
        widget.bytes,
        targetWidth: widget.preview ? 1600 : 512,
      );
      try {
        final frame = await codec.getNextFrame();
        if (!mounted) {
          frame.image.dispose();
          return;
        }
        setState(() => _image = frame.image);
      } finally {
        codec.dispose();
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const Center(child: Text('Không thể giải mã ảnh.'));
    if (_image == null) return const Center(child: CircularProgressIndicator());
    final image = Semantics(
      label: widget.label,
      image: true,
      child: RawImage(
        image: _image,
        fit: widget.preview ? BoxFit.contain : BoxFit.cover,
      ),
    );
    return widget.preview
        ? InteractiveViewer(child: image)
        : ClipOval(child: image);
  }
}
