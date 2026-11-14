import 'dart:convert';

import '../../../../core/error/failures.dart';

/// Converts editor deltas to the backend's deliberately limited document format.
Map<String, dynamic> normalizeBiography(List<dynamic> delta) {
  final result = <Map<String, dynamic>>[];
  var characters = 0;
  for (final raw in delta) {
    if (raw is! Map || raw['insert'] is! String) {
      throw const MediaFailure(
        code: 'INVALID_BIOGRAPHY',
        message:
            'Tiểu sử chỉ hỗ trợ văn bản, không hỗ trợ ảnh hoặc nội dung nhúng.',
      );
    }
    final text = raw['insert'] as String;
    if (text.contains('\u0000')) {
      throw const MediaFailure(
        code: 'INVALID_BIOGRAPHY',
        message: 'Tiểu sử chứa ký tự không hợp lệ.',
      );
    }
    characters += text.runes.length;
    final attrs = raw['attributes'] is Map
        ? raw['attributes'] as Map
        : const {};
    final inline = <String, dynamic>{};
    for (final name in ['bold', 'italic', 'underline']) {
      if (attrs[name] == true) inline[name] = true;
    }
    final link = attrs['link'];
    if (link != null) {
      final uri = Uri.tryParse(link.toString());
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw const MediaFailure(
          code: 'INVALID_BIOGRAPHY',
          message: 'Liên kết phải là địa chỉ HTTPS hợp lệ.',
        );
      }
      inline['link'] = uri.toString();
    }
    final block = <String, dynamic>{};
    if ([1, 2, 3].contains(attrs['header'])) {
      block['header'] = attrs['header'];
    } else if (['ordered', 'bullet'].contains(attrs['list'])) {
      block['list'] = attrs['list'];
    } else if (attrs['blockquote'] == true) {
      block['blockquote'] = true;
    }
    // Block formatting must only occur on an isolated newline.
    final pieces = text.split('\n');
    for (var i = 0; i < pieces.length; i++) {
      if (pieces[i].isNotEmpty) {
        result.add({
          'insert': pieces[i],
          if (inline.isNotEmpty) 'attributes': inline,
        });
      }
      if (i < pieces.length - 1) {
        result.add({'insert': '\n', if (block.isNotEmpty) 'attributes': block});
      }
    }
  }
  if (result.isEmpty || result.last['insert'] != '\n') {
    result.add({'insert': '\n'});
    characters++;
  }
  final document = <String, dynamic>{'ops': result};
  if (characters > 20000 ||
      utf8.encode(jsonEncode(document)).length > 100 * 1024) {
    throw const MediaFailure(
      code: 'INVALID_BIOGRAPHY',
      message: 'Tiểu sử tối đa 20.000 ký tự và 100 KiB dữ liệu.',
    );
  }
  return document;
}
