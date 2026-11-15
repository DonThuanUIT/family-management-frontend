import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../error/failures.dart';

class SelectedMediaFile {
  final String name;
  final int size;
  final Future<Uint8List> Function() read;
  const SelectedMediaFile(this.name, this.size, this.read);
}

class MemberFileActions {
  Future<List<SelectedMediaFile>> pick({bool portrait = false}) async {
    final files = portrait
        ? [
            ?await FilePicker.pickFile(
              type: FileType.custom,
              allowedExtensions: ['jpg', 'jpeg', 'png'],
            ),
          ]
        : await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          );
    return Future.wait(
      files.map(
        (file) async => SelectedMediaFile(
          file.name,
          await file.length() ?? 0,
          () => file.readAsBytes(),
        ),
      ),
    );
  }

  Future<bool> save(Uint8List bytes, String filename, String mimeType) async {
    final extension = switch (mimeType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      _ => 'pdf',
    };
    final safeName = filename.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
    final base = safeName.contains('.')
        ? safeName.substring(0, safeName.lastIndexOf('.'))
        : safeName;
    if (!kIsWeb) {
      final result = await FileSaver.instance.saveAs(
        name: base,
        bytes: bytes,
        fileExtension: extension,
        mimeType: MimeType.custom,
        customMimeType: mimeType,
      );
      return result != null && result.isNotEmpty;
    }
    final result = await FileSaver.instance.saveFile(
      name: base,
      bytes: bytes,
      fileExtension: extension,
      mimeType: MimeType.custom,
      customMimeType: mimeType,
    );
    if (result.isEmpty || result.contains('Something went wrong')) {
      throw const MediaFailure(
        code: 'SAVE_FAILED',
        message: 'Không thể lưu file trên thiết bị.',
      );
    }
    return true;
  }
}

final memberFileActionsProvider = Provider((ref) => MemberFileActions());

void validateMediaFile(SelectedMediaFile file, {bool portrait = false}) {
  final extension = file.name.split('.').last.toLowerCase();
  final allowed = portrait
      ? ['jpg', 'jpeg', 'png']
      : ['pdf', 'jpg', 'jpeg', 'png'];
  if (!allowed.contains(extension) || file.size <= 0) {
    throw const MediaFailure(
      code: 'INVALID_MEDIA_FILE',
      message: 'File không hợp lệ hoặc không được hỗ trợ.',
    );
  }
  if (file.size > (portrait ? 5 : 10) * 1024 * 1024) {
    throw MediaFailure(
      code: 'FILE_TOO_LARGE',
      message: 'File tối đa ${portrait ? 5 : 10} MiB.',
    );
  }
}

Future<void> validatePortraitDimensions(Uint8List bytes) async {
  // Encoded ImageDescriptor.width/height throw on Flutter Web. Read headers
  // before decoding on every platform, also rejecting oversized pixel counts.
  final size = portraitDimensions(bytes);
  if (size.width < 128 ||
      size.height < 128 ||
      size.width > 20000000 ~/ size.height) {
    throw const MediaFailure(
      code: 'INVALID_MEDIA_FILE',
      message: 'Ảnh phải từ 128 × 128 pixel và không quá 20 megapixel.',
    );
  }
}

({int width, int height}) portraitDimensions(Uint8List bytes) {
  const invalid = MediaFailure(
    code: 'INVALID_MEDIA_FILE',
    message: 'Ảnh JPEG hoặc PNG không hợp lệ.',
  );
  const png = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length >= 24 &&
      List.generate(8, (i) => bytes[i] == png[i]).every((v) => v)) {
    if (bytes[12] != 73 ||
        bytes[13] != 72 ||
        bytes[14] != 68 ||
        bytes[15] != 82) {
      throw invalid;
    }
    final data = ByteData.sublistView(bytes);
    return (width: data.getUint32(16), height: data.getUint32(20));
  }
  if (bytes.length < 4 || bytes[0] != 255 || bytes[1] != 216) throw invalid;
  var offset = 2;
  const startOfFrame = {
    0xc0,
    0xc1,
    0xc2,
    0xc3,
    0xc5,
    0xc6,
    0xc7,
    0xc9,
    0xca,
    0xcb,
    0xcd,
    0xce,
    0xcf,
  };
  while (offset < bytes.length) {
    if (bytes[offset] != 255) throw invalid;
    while (offset < bytes.length && bytes[offset] == 255) {
      offset++;
    }
    if (offset >= bytes.length) throw invalid;
    final marker = bytes[offset++];
    if (marker == 0xda || marker == 0xd9) throw invalid;
    if (marker == 0x01 || marker == 0xd8 || (marker >= 0xd0 && marker <= 0xd7)) {
      continue;
    }
    if (offset + 2 > bytes.length) throw invalid;
    final length = (bytes[offset] << 8) | bytes[offset + 1];
    if (length < 2 || offset + length > bytes.length) throw invalid;
    if (startOfFrame.contains(marker)) {
      if (length < 8) throw invalid;
      return (
        width: (bytes[offset + 5] << 8) | bytes[offset + 6],
        height: (bytes[offset + 3] << 8) | bytes[offset + 4],
      );
    }
    offset += length;
  }
  throw invalid;
}

Future<Uint8List> resizePortrait(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: 512,
    targetHeight: 512,
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      return (await frame.image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

String newUploadKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
