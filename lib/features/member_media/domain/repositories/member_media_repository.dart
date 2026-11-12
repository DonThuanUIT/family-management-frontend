import 'dart:typed_data';

import '../../data/models/member_media_models.dart';

/// Cancellation boundary keeps transport details out of presentation.
class MediaRequest {
  bool cancelled = false;
  void Function()? cancelTransport;
  void cancel() {
    cancelled = true;
    cancelTransport?.call();
  }
}

abstract interface class MemberMediaRepository {
  Future<MemberMedia> detail(String memberId, MediaRequest request);
  Future<AttachmentPage> attachments(
    String memberId,
    int page,
    MediaRequest request,
  );
  Future<FamilyAttachment> attachment(
    String memberId,
    String id,
    MediaRequest request,
  );
  Future<Uint8List> content(
    String memberId,
    String? attachmentId,
    MediaRequest request,
  );
  Future<void> avatar(
    String memberId,
    int version,
    Uint8List? bytes,
    MediaRequest request,
  );
  Future<void> biography(
    String memberId,
    int version,
    Map<String, dynamic> document,
    MediaVisibility visibility,
    MediaRequest request,
  );
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
  );
  Future<void> edit(
    String memberId,
    FamilyAttachment attachment,
    String title,
    String description,
    MediaVisibility visibility,
    MediaRequest request,
  );
  Future<void> delete(
    String memberId,
    FamilyAttachment attachment,
    MediaRequest request,
  );
}
