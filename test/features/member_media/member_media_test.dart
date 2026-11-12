import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:familyfund_app/core/error/failures.dart';
import 'package:familyfund_app/core/files/member_file_actions.dart';
import 'package:familyfund_app/core/storage/secure_token_storage.dart';
import 'package:familyfund_app/features/member_media/data/datasources/member_media_remote_data_source.dart';
import 'package:familyfund_app/features/member_media/data/models/member_media_models.dart';
import 'package:familyfund_app/features/member_media/data/repositories/member_media_repository_impl.dart';
import 'package:familyfund_app/features/member_media/domain/repositories/member_media_repository.dart';
import 'package:familyfund_app/features/member_media/domain/usecases/biography_document.dart';
import 'package:familyfund_app/features/member_media/presentation/providers/member_media_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> memberJson({bool edit = true}) => {
  'memberId': 'member-test',
  'fullName': 'Thành viên kiểm thử',
  'generation': 3,
  'mediaVersion': 2,
  'biographyAccess': 'VISIBLE',
  'capabilities': {'canEditMedia': edit, 'canUploadAttachment': edit},
};
AttachmentPage emptyPage() => AttachmentPage.fromJson({
  'items': [],
  'page': 0,
  'totalPages': 0,
  'totalElements': 0,
});

class TestStorage extends SecureTokenStorage {
  bool loggedIn = true;
  TestStorage() : super(const FlutterSecureStorage());
  @override
  Future<String?> getAccessToken() async => loggedIn ? 'test-token' : null;
}

class TestMediaRepository implements MemberMediaRepository {
  MemberMedia member = MemberMedia.fromJson(memberJson());
  Failure? failure;
  Completer<MemberMedia>? pending;
  final requests = <MediaRequest>[];
  final keys = <String>[];
  Failure? contentFailure;
  @override
  Future<Uint8List> content(
    String memberId,
    String? attachmentId,
    MediaRequest request,
  ) async {
    if (contentFailure != null) throw contentFailure!;
    return Uint8List.fromList([1]);
  }

  @override
  Future<MemberMedia> detail(String memberId, MediaRequest request) async {
    requests.add(request);
    if (failure != null) throw failure!;
    return pending?.future ?? member;
  }

  @override
  Future<AttachmentPage> attachments(
    String memberId,
    int page,
    MediaRequest request,
  ) async => emptyPage();
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
  ) async {
    keys.add(key);
    if (keys.length == 1) throw const NetworkFailure();
  }

  @override
  Future<void> biography(
    String memberId,
    int version,
    Map<String, dynamic> document,
    MediaVisibility visibility,
    MediaRequest request,
  ) async {
    if (failure != null) throw failure!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _Adapter implements HttpClientAdapter {
  int status = 200;
  Object body = {'success': true, 'data': memberJson()};
  RequestOptions? last;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'portrait dimensions work without unsupported Web ImageDescriptor getters',
    () async {
      final png = Uint8List(24)
        ..setRange(0, 8, [137, 80, 78, 71, 13, 10, 26, 10])
        ..setRange(12, 16, [73, 72, 68, 82]);
      final data = ByteData.sublistView(png)
        ..setUint32(16, 320)
        ..setUint32(20, 240);
      expect(portraitDimensions(png), (width: 320, height: 240));
      await validatePortraitDimensions(png);
      data.setUint32(16, 10000);
      data.setUint32(20, 10000);
      await expectLater(
        validatePortraitDimensions(png),
        throwsA(isA<MediaFailure>()),
      );
      final jpeg = Uint8List.fromList([
        255,
        216,
        255,
        225,
        0,
        4,
        0,
        0,
        255,
        192,
        0,
        8,
        8,
        1,
        0,
        2,
        0,
        0,
      ]);
      expect(portraitDimensions(jpeg), (width: 512, height: 256));
      await validatePortraitDimensions(jpeg);
      for (final invalid in [
        jpeg.sublist(0, 14),
        Uint8List.fromList([71, 73, 70, 56]),
        Uint8List(0),
      ]) {
        expect(() => portraitDimensions(invalid), throwsA(isA<MediaFailure>()));
      }
    },
  );
  group('Biography contract', () {
    test('preserves Vietnamese and splits line formatting, strips unsupported attributes', () {
      final doc = normalizeBiography([
        {
          'insert': 'Kỷ niệm\nGia đình\n',
          'attributes': {
            'bold': true,
            'header': 2,
            'color': '#ffffff',
            'align': 'center',
          },
        },
      ]);
      final ops = doc['ops'] as List;
      expect(ops.first, {
        'insert': 'Kỷ niệm',
        'attributes': {'bold': true},
      });
      expect(ops[1], {
        'insert': '\n',
        'attributes': {'header': 2},
      });
      expect(jsonEncode(doc), isNot(contains('color')));
      expect(jsonEncode(doc), isNot(contains('align')));
    });
    test('rejects embeds and unsafe URLs', () {
      for (final delta in [
        [
          {
            'insert': {'image': 'https://example.com/a.png'},
          },
        ],
        [
          {
            'insert': 'x',
            'attributes': {'link': 'javascript:alert(1)'},
          },
        ],
        [
          {
            'insert': 'x',
            'attributes': {'link': 'http://example.com'},
          },
        ],
        [
          {
            'insert': 'x',
            'attributes': {'link': 'https://user:pass@example.com'},
          },
        ],
      ]) {
        expect(() => normalizeBiography(delta), throwsA(isA<MediaFailure>()));
      }
    });
    test(
      'counts Unicode scalars and enforces serialized byte limit independently',
      () {
        expect(
          () => normalizeBiography([
            {'insert': '${'😀' * 19999}\n'},
          ]),
          returnsNormally,
        );
        expect(
          () => normalizeBiography([
            {'insert': '${'a' * 20000}\n'},
          ]),
          throwsA(isA<MediaFailure>()),
        );
        expect(
          () => normalizeBiography(
            List.generate(
              1000,
              (_) => {
                'insert': 'a',
                'attributes': {'link': 'https://example.com/${'b' * 120}'},
              },
            ),
          ),
          throwsA(isA<MediaFailure>()),
        );
      },
    );
  });
  test(
    'missing capabilities fail closed and hidden biography is discarded',
    () {
      final json = memberJson()..remove('capabilities');
      json['biographyAccess'] = 'RESTRICTED';
      json['biography'] = {
        'ops': [
          {'insert': 'hidden'},
        ],
      };
      final member = MemberMedia.fromJson(json);
      expect(member.canEdit, false);
      expect(member.canUpload, false);
      expect(member.biography, null);
      expect(MediaVisibility.parse('PUBLIC'), MediaVisibility.restricted);
    },
  );
  test('file limits checked before reading and UUIDs are distinct v4 keys', () {
    Future<Uint8List> read() async => throw StateError('must not read');
    expect(
      () => validateMediaFile(
        SelectedMediaFile('a.pdf', 10 * 1024 * 1024 + 1, read),
      ),
      throwsA(isA<MediaFailure>()),
    );
    expect(
      () => validateMediaFile(
        SelectedMediaFile('a.pdf', 100, read),
        portrait: true,
      ),
      throwsA(isA<MediaFailure>()),
    );
    final keys = List.generate(50, (_) => newUploadKey());
    expect(keys.toSet().length, 50);
    for (final key in keys) {
      expect(
        key,
        matches(
          RegExp(
            r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
          ),
        ),
      );
    }
  });
  group('Repository transport', () {
    late _Adapter adapter;
    late MemberMediaRepository repository;
    setUp(() {
      adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/v1/'))
        ..httpClientAdapter = adapter;
      repository = MemberMediaRepositoryImpl(MemberMediaRemoteDataSource(dio));
    });
    test(
      'uses trusted API route, never contentUrl and never duplicates /api/v1',
      () async {
        await repository.content('a/b', 'id', MediaRequest());
        expect(
          adapter.last!.uri.toString(),
          'https://api.example.com/api/v1/members/a%2Fb/attachments/id/content',
        );
      },
    );
    test(
      'rejects success=false and maps version/quota/auth failures',
      () async {
        adapter.body = {'success': false, 'data': memberJson()};
        await expectLater(
          repository.detail('id', MediaRequest()),
          throwsA(
            isA<MediaFailure>().having(
              (e) => e.code,
              'code',
              'INVALID_RESPONSE',
            ),
          ),
        );
        for (final entry in [
          (409, 'MEDIA_VERSION_CONFLICT'),
          (503, 'STORAGE_QUOTA_EXCEEDED'),
          (403, 'MEMBER_MEDIA_FORBIDDEN'),
        ]) {
          adapter.status = entry.$1;
          adapter.body = {'success': false, 'code': entry.$2};
          await expectLater(
            repository.detail('id', MediaRequest()),
            throwsA(
              isA<MediaFailure>()
                  .having((e) => e.code, 'code', entry.$2)
                  .having((e) => e.statusCode, 'status', entry.$1),
            ),
          );
        }
      },
    );
  });
  group('Session and mutations', () {
    late ProviderContainer container;
    late TestStorage storage;
    late TestMediaRepository repository;
    setUp(() {
      storage = TestStorage();
      repository = TestMediaRepository();
      container = ProviderContainer(
        overrides: [
          secureTokenStorageProvider.overrideWithValue(storage),
          memberMediaRepositoryProvider.overrideWithValue(repository),
        ],
      );
      container.listen(memberMediaProvider('member-test'), (_, _) {});
    });
    tearDown(() => container.dispose());
    Future<void> settle() async {
      for (var i = 0; i < 12; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('clears member immediately on session change and rejects late old response', () async {
      repository.pending = Completer<MemberMedia>();
      await settle();
      storage.loggedIn = false;
      container.read(privateSessionRevisionProvider.notifier).advance();
      expect(container.read(memberMediaProvider('member-test')).member, null);
      await settle();
      expect(repository.requests.first.cancelled, true);
      repository.pending!.complete(repository.member);
      await settle();
      final state = container.read(memberMediaProvider('member-test'));
      expect(state.member, null);
      expect(state.error, isA<UnauthorizedFailure>());
    });
    test(
      'retains loaded member on conflict and clears protected state on 403',
      () async {
        await settle();
        final notifier = container.read(
          memberMediaProvider('member-test').notifier,
        );
        repository.failure = const MediaFailure(
          message: 'conflict',
          code: 'MEDIA_VERSION_CONFLICT',
          statusCode: 409,
        );
        await expectLater(
          notifier.biography(2, {'ops': []}, MediaVisibility.clan),
          throwsA(isA<Failure>()),
        );
        expect(
          container.read(memberMediaProvider('member-test')).member,
          isNotNull,
        );
        repository.failure = const ForbiddenFailure();
        await expectLater(
          notifier.biography(2, {'ops': []}, MediaVisibility.clan),
          throwsA(isA<Failure>()),
        );
        expect(container.read(memberMediaProvider('member-test')).member, null);
        expect(
          container.read(memberMediaProvider('member-test')).attachments,
          null,
        );
      },
    );
    test('retry passes same idempotency key after uncertain failure', () async {
      await settle();
      final notifier = container.read(
        memberMediaProvider('member-test').notifier,
      );
      final key = newUploadKey();
      Future<void> upload() => notifier.upload(
        Uint8List.fromList([1]),
        'a.pdf',
        'Tư liệu',
        '',
        MediaVisibility.restricted,
        key,
        (_, _) {},
      );
      await expectLater(upload(), throwsA(isA<NetworkFailure>()));
      await upload();
      expect(repository.keys, [key, key]);
    });
    test(
      'private content denial purges the loaded profile without retry loop',
      () async {
        await settle();
        repository.contentFailure = const ForbiddenFailure();
        const key = (
          memberId: 'member-test',
          attachmentId: 'attachment-test',
          version: 1,
        );
        final subscription = container.listen(
          mediaContentProvider(key),
          (_, _) {},
        );
        await expectLater(
          container.read(mediaContentProvider(key).future),
          throwsA(isA<ForbiddenFailure>()),
        );
        await settle();
        expect(container.read(memberMediaProvider('member-test')).member, null);
        expect(
          container.read(memberMediaProvider('member-test')).attachments,
          null,
        );
        subscription.close();
      },
    );
  });
}
