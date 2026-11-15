import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/member_media_repository.dart';
import '../datasources/member_media_remote_data_source.dart';
import '../models/member_media_models.dart';

class MemberMediaRepositoryImpl implements MemberMediaRepository {
  final MemberMediaRemoteDataSource source;
  MemberMediaRepositoryImpl(this.source);

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final body = e.response?.data;
      final code = body is Map
          ? (body['code'] ?? body['errorCode'])?.toString()
          : null;
      final status = e.response?.statusCode;
      final message = switch (code) {
        'MEDIA_VERSION_CONFLICT' =>
          'Hồ sơ đã được thay đổi. Tải bản mới trước khi lưu lại bản nháp.',
        'ATTACHMENT_LIMIT_REACHED' => 'Hồ sơ đã đạt giới hạn 20 tư liệu.',
        'UPLOAD_IN_PROGRESS' =>
          'Tư liệu đang được xử lý. Vui lòng thử lại sau.',
        'IDEMPOTENCY_CONFLICT' =>
          'Nội dung lần thử lại không khớp. Hãy tạo lượt tải mới.',
        'STORAGE_QUOTA_EXCEEDED' =>
          'Kho lưu trữ đã hết dung lượng. Vui lòng liên hệ quản trị viên.',
        _ => switch (status) {
          401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          403 => 'Bạn không có quyền xem hoặc thay đổi nội dung này.',
          404 => 'Nội dung không còn tồn tại hoặc không được phép xem.',
          409 => 'Dữ liệu đã thay đổi. Tải bản mới trước khi thử lại.',
          413 => 'File vượt quá dung lượng cho phép.',
          415 => 'Chỉ hỗ trợ PDF, JPEG và PNG.',
          429 => 'Bạn thao tác quá nhanh. Vui lòng thử lại sau.',
          503 => 'Kho lưu trữ tạm thời không khả dụng. Vui lòng thử lại sau.',
          400 =>
            'Nội dung không hợp lệ. Hãy kiểm tra file và thông tin đã nhập.',
          _ => 'Không thể kết nối máy chủ. Vui lòng thử lại.',
        },
      };
      throw MediaFailure(
        code:
            code ?? (CancelToken.isCancel(e) ? 'CANCELLED' : 'REQUEST_FAILED'),
        message: message,
        statusCode: status,
      );
    } on FormatException {
      throw const MediaFailure(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ trả về dữ liệu không hợp lệ.',
      );
    } on TypeError {
      throw const MediaFailure(
        code: 'INVALID_RESPONSE',
        message: 'Máy chủ trả về dữ liệu không hợp lệ.',
      );
    }
  }

  @override
  Future<MemberMedia> detail(String memberId, MediaRequest request) => _run(
    () async => MemberMedia.fromJson(await source.send(memberId, request)),
  );
  @override
  Future<AttachmentPage> attachments(
    String memberId,
    int page,
    MediaRequest request,
  ) => _run(
    () async => AttachmentPage.fromJson(
      await source.send(
        memberId,
        request,
        suffix: '/attachments',
        query: {'page': page, 'size': 10},
      ),
    ),
  );
  @override
  Future<FamilyAttachment> attachment(
    String memberId,
    String id,
    MediaRequest request,
  ) => _run(
    () async => FamilyAttachment.fromJson(
      await source.send(
        memberId,
        request,
        suffix: '/attachments/${Uri.encodeComponent(id)}',
      ),
    ),
  );
  @override
  Future<Uint8List> content(
    String memberId,
    String? attachmentId,
    MediaRequest request,
  ) => _run(
    () async => await source.send(
      memberId,
      request,
      suffix: attachmentId == null
          ? '/avatar/content'
          : '/attachments/${Uri.encodeComponent(attachmentId)}/content',
      binary: true,
    ) as Uint8List,
  );
  @override
  Future<void> avatar(
    String memberId,
    int version,
    Uint8List? bytes,
    MediaRequest request,
  ) => _run(() async {
    await source.send(
      memberId,
      request,
      suffix: '/avatar',
      method: bytes == null ? 'DELETE' : 'PUT',
      query: bytes == null ? {'expectedMediaVersion': version} : null,
      data: bytes == null
          ? null
          : FormData.fromMap({
              'file': MultipartFile.fromBytes(
                bytes,
                filename: 'portrait.png',
                contentType: DioMediaType('image', 'png'),
              ),
              'expectedMediaVersion': version,
            }),
    );
  });
  @override
  Future<void> biography(
    String memberId,
    int version,
    Map<String, dynamic> document,
    MediaVisibility visibility,
    MediaRequest request,
  ) => _run(() async {
    await source.send(
      memberId,
      request,
      suffix: '/biography',
      method: 'PUT',
      data: {
        'expectedMediaVersion': version,
        'biography': document,
        'visibility': visibility.value,
      },
    );
  });
  @override
  Future<void> upload(
    String memberId,
    Uint8List bytes,
    String filename,
    String title,
    String description,
    MediaVisibility visibility,
    String key,
    MediaRequest request,
    void Function(int, int) progress,
  ) => _run(() async {
    await source.send(
      memberId,
      request,
      suffix: '/attachments',
      method: 'POST',
      idempotencyKey: key,
      progress: progress,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(switch (filename
              .split('.')
              .last
              .toLowerCase()) {
            'png' => 'image/png',
            'jpg' || 'jpeg' => 'image/jpeg',
            _ => 'application/pdf',
          }),
        ),
        'title': title.trim(),
        'description': description.trim(),
        'visibility': visibility.value,
      }),
    );
  });
  @override
  Future<void> edit(
    String memberId,
    FamilyAttachment attachment,
    String title,
    String description,
    MediaVisibility visibility,
    MediaRequest request,
  ) => _run(() async {
    await source.send(
      memberId,
      request,
      suffix: '/attachments/${Uri.encodeComponent(attachment.id)}',
      method: 'PATCH',
      data: {
        'expectedVersion': attachment.version,
        'title': title.trim(),
        'description': description.trim().isEmpty ? null : description.trim(),
        'visibility': visibility.value,
      },
    );
  });
  @override
  Future<void> delete(
    String memberId,
    FamilyAttachment attachment,
    MediaRequest request,
  ) => _run(() async {
    await source.send(
      memberId,
      request,
      suffix: '/attachments/${Uri.encodeComponent(attachment.id)}',
      method: 'DELETE',
      query: {'expectedVersion': attachment.version},
    );
  });
}
