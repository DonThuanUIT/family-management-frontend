import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../../../core/security/rbac_models.dart';
import '../../../genealogy/presentation/providers/genealogy_providers.dart';
import '../../data/datasources/member_media_remote_data_source.dart';
import '../../data/repositories/member_media_repository_impl.dart';
import '../../data/models/member_media_models.dart';
import '../../domain/repositories/member_media_repository.dart';

final mediaSessionProvider = Provider(
  (ref) => (
    ref.watch(privateSessionRevisionProvider),
    ref.watch(dualRbacSessionProvider.select((s) => (s.accountId, s.memberId))),
  ),
);
final memberMediaRepositoryProvider = Provider<MemberMediaRepository>(
  (ref) => MemberMediaRepositoryImpl(
    MemberMediaRemoteDataSource(ref.watch(dioClientProvider)),
  ),
);

class MemberMediaState {
  final MemberMedia? member;
  final AttachmentPage? attachments;
  final bool loading, busy;
  final Failure? error;
  const MemberMediaState({
    this.member,
    this.attachments,
    this.loading = true,
    this.busy = false,
    this.error,
  });
}

final memberMediaProvider = NotifierProvider.autoDispose
    .family<MemberMediaNotifier, MemberMediaState, String>(
      MemberMediaNotifier.new,
    );

class MemberMediaNotifier extends Notifier<MemberMediaState> {
  final String memberId;
  MemberMediaNotifier(this.memberId);
  final _requests = <MediaRequest>[];
  Object? _scope;
  int _loadSequence = 0;
  MemberMediaRepository get _repository =>
      ref.read(memberMediaRepositoryProvider);

  @override
  MemberMediaState build() {
    _scope = Object();
    ref.watch(mediaSessionProvider);
    final scope = _scope;
    ref.onDispose(() {
      for (final request in _requests) {
        request.cancel();
      }
      _requests.clear();
    });
    Future.microtask(() {
      if (ref.mounted && _scope == scope) reload();
    });
    return const MemberMediaState();
  }

  MediaRequest _request() {
    final request = MediaRequest();
    _requests.add(request);
    return request;
  }

  bool _current(Object? scope) => ref.mounted && _scope == scope;

  Future<void> reload({int page = 0, bool mutationRefresh = false}) async {
    if (state.busy && !mutationRefresh) return;
    final sequence = ++_loadSequence;
    final scope = _scope;
    final request = _request();
    MediaRequest? pageRequest;
    state = MemberMediaState(
      member: state.member,
      attachments: state.attachments,
      busy: state.busy,
      loading: true,
    );
    try {
      final storage = ref.read(secureTokenStorageProvider);
      if ((await storage.getAccessToken())?.isNotEmpty != true) {
        throw const UnauthorizedFailure();
      }
      if (!_current(scope)) return;
      final member = await _repository.detail(memberId, request);
      if (!_current(scope) || sequence != _loadSequence) return;
      pageRequest = _request();
      final attachments = await _repository.attachments(
        memberId,
        page,
        pageRequest,
      );
      if (_current(scope) && sequence == _loadSequence) {
        state = MemberMediaState(
          member: member,
          attachments: attachments,
          loading: false,
          busy: state.busy,
        );
      }
    } on Failure catch (e) {
      if (_current(scope) && sequence == _loadSequence) _fail(e);
    } finally {
      _requests.remove(request);
      _requests.remove(pageRequest);
    }
  }

  void _fail(Failure error, {bool invalidateContent = true}) {
    final revoked = [401, 403, 404].contains(error.statusCode);
    if (revoked) {
      for (final request in _requests) {
        request.cancel();
      }
      if (invalidateContent) ref.invalidate(mediaContentProvider);
    }
    state = MemberMediaState(
      member: revoked ? null : state.member,
      attachments: revoked ? null : state.attachments,
      loading: false,
      error: error,
    );
  }

  void revokePrivateContent(Failure error) =>
      _fail(error, invalidateContent: false);

  Future<void> _mutate(Future<void> Function(MediaRequest) action) async {
    if (state.busy || state.loading || state.member == null) {
      throw const MediaFailure(
        code: 'BUSY',
        message: 'Vui lòng chờ tải hồ sơ xong.',
      );
    }
    final scope = _scope;
    final request = _request();
    state = MemberMediaState(
      member: state.member,
      attachments: state.attachments,
      loading: false,
      busy: true,
    );
    try {
      await action(request);
      if (!_current(scope)) throw const UnauthorizedFailure();
      ref.invalidate(mediaContentProvider);
      ref.invalidate(branchMembersProvider);
      ref.invalidate(clanMembersProvider);
      ref.invalidate(genealogyMemberListProvider);
      await reload(page: state.attachments?.page ?? 0, mutationRefresh: true);
    } on Failure catch (e) {
      if (_current(scope)) _fail(e);
      rethrow;
    } finally {
      _requests.remove(request);
      if (_current(scope) && state.busy) {
        state = MemberMediaState(
          member: state.member,
          attachments: state.attachments,
          loading: false,
          error: state.error,
        );
      }
    }
  }

  Future<void> avatar(int version, Uint8List? bytes) =>
      _mutate((r) => _repository.avatar(memberId, version, bytes, r));
  Future<void> biography(
    int version,
    Map<String, dynamic> document,
    MediaVisibility visibility,
  ) => _mutate(
    (r) => _repository.biography(memberId, version, document, visibility, r),
  );
  Future<void> upload(
    Uint8List bytes,
    String filename,
    String title,
    String description,
    MediaVisibility visibility,
    String key,
    void Function(int, int) progress,
  ) => _mutate(
    (r) => _repository.upload(
      memberId,
      bytes,
      filename,
      title,
      description,
      visibility,
      key,
      r,
      progress,
    ),
  );
  Future<void> edit(
    FamilyAttachment attachment,
    String title,
    String description,
    MediaVisibility visibility,
  ) => _mutate(
    (r) => _repository.edit(
      memberId,
      attachment,
      title,
      description,
      visibility,
      r,
    ),
  );
  Future<void> delete(FamilyAttachment attachment) =>
      _mutate((r) => _repository.delete(memberId, attachment, r));
  Future<FamilyAttachment> latestAttachment(String id) async {
    final scope = _scope;
    final request = _request();
    try {
      final attachment = await _repository.attachment(memberId, id, request);
      if (!_current(scope)) throw const UnauthorizedFailure();
      return attachment;
    } on Failure catch (e) {
      if (_current(scope)) _fail(e);
      rethrow;
    } finally {
      _requests.remove(request);
    }
  }

  Future<Uint8List> download(String id) async {
    final scope = _scope;
    final request = _request();
    try {
      final bytes = await _repository.content(memberId, id, request);
      if (!_current(scope)) throw const UnauthorizedFailure();
      return bytes;
    } on Failure catch (e) {
      if (_current(scope)) _fail(e);
      rethrow;
    } finally {
      _requests.remove(request);
    }
  }
}

typedef MediaContentKey = ({
  String memberId,
  String? attachmentId,
  int version,
});
final mediaContentProvider = FutureProvider.autoDispose
    .family<Uint8List, MediaContentKey>((ref, key) async {
      ref.watch(mediaSessionProvider);
      final request = MediaRequest();
      ref.onDispose(request.cancel);
      try {
        return await ref
            .watch(memberMediaRepositoryProvider)
            .content(key.memberId, key.attachmentId, request);
      } on Failure catch (error) {
        if (ref.mounted && [401, 403, 404].contains(error.statusCode)) {
          ref
              .read(memberMediaProvider(key.memberId).notifier)
              .revokePrivateContent(error);
        }
        rethrow;
      }
    }, retry: (retryCount, error) => null);
