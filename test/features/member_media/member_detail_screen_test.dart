import 'dart:async';
import 'dart:typed_data';

import 'package:familyfund_app/core/error/failures.dart';
import 'package:familyfund_app/core/files/member_file_actions.dart';
import 'package:familyfund_app/core/storage/secure_token_storage.dart';
import 'package:familyfund_app/core/theme/app_theme.dart';
import 'package:familyfund_app/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:familyfund_app/features/member_media/data/models/member_media_models.dart';
import 'package:familyfund_app/features/member_media/presentation/providers/member_media_providers.dart';
import 'package:familyfund_app/features/member_media/presentation/screens/member_detail_screen.dart';
import 'package:familyfund_app/features/member_media/presentation/widgets/biography_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'member_media_test.dart'
    show TestMediaRepository, TestStorage, memberJson;

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _Files extends MemberFileActions {
  int reads = 0;
  @override
  Future<List<SelectedMediaFile>> pick({bool portrait = false}) async => [
    SelectedMediaFile('Ky-niem.pdf', 8, () async {
      reads++;
      return Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55]);
    }),
  ];
}

Future<void> openScreen(
  WidgetTester tester,
  TestMediaRepository repository, {
  double width = 1280,
  double scale = 1,
  MemberFileActions? files,
}) async {
  tester.view.physicalSize = Size(width, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memberMediaRepositoryProvider.overrideWithValue(repository),
        secureTokenStorageProvider.overrideWithValue(TestStorage()),
        authStateProvider.overrideWith(_Auth.new),
        if (files != null) memberFileActionsProvider.overrideWithValue(files),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [FlutterQuillLocalizations.delegate],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const MemberDetailScreen(memberId: 'member-test'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  for (final width in [390.0, 840.0, 1280.0]) {
    testWidgets('member profile fits $width px and larger text', (
      tester,
    ) async {
      final repository = TestMediaRepository();
      repository.member = MemberMedia.fromJson({
        ...memberJson(),
        'biography': {
          'ops': [
            {
              'insert': 'Ký ức gia đình\n',
              'attributes': {'bold': true},
            },
            {'insert': 'Những câu chuyện để con cháu cùng gìn giữ.\n'},
          ],
        },
      });
      await openScreen(tester, repository, width: width, scale: 1.25);
      await tester.pumpAndSettle();
      expect(find.text('Thành viên kiểm thử'), findsOneWidget);
      expect(find.text('Thêm tư liệu'), findsOneWidget);
      expect(find.text('Thay ảnh chân dung'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'loading state and read-only restricted biography do not expose editor',
    (tester) async {
      final repository = TestMediaRepository()
        ..pending = Completer<MemberMedia>();
      await openScreen(tester, repository, width: 390);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final json = memberJson(edit: false)..['biographyAccess'] = 'RESTRICTED';
      repository.pending!.complete(MemberMedia.fromJson(json));
      await tester.pumpAndSettle();
      expect(find.text('Tiểu sử được giới hạn quyền xem.'), findsOneWidget);
      expect(find.text('Thêm tư liệu'), findsNothing);
      expect(find.text('Chỉnh sửa'), findsNothing);
      expect(find.text('Bạn đang xem hồ sơ ở chế độ chỉ đọc.'), findsOneWidget);
    },
  );
  for (final failure in [const NetworkFailure(), const ForbiddenFailure()]) {
    testWidgets(
      'error state ${failure.runtimeType} can retry without rendering private content',
      (tester) async {
        final repository = TestMediaRepository()..failure = failure;
        await openScreen(tester, repository);
        await tester.pumpAndSettle();
        expect(find.text(failure.message), findsOneWidget);
        expect(find.text('Thành viên kiểm thử'), findsNothing);
        expect(find.text('Thêm tư liệu'), findsNothing);
        expect(find.text('Thử lại'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'biography conflict retains draft and requires explicit refresh',
    (tester) async {
      final repository = TestMediaRepository();
      await openScreen(tester, repository);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      expect(find.byType(BiographyEditorDialog), findsOneWidget);
      final controller = tester
          .widget<QuillEditor>(find.byType(QuillEditor))
          .controller;
      controller.document.insert(0, 'Bản nháp tiếng Việt');
      repository.failure = const MediaFailure(
        message: 'Dữ liệu đã thay đổi.',
        code: 'MEDIA_VERSION_CONFLICT',
        statusCode: 409,
      );
      await tester.tap(find.text('Lưu tiểu sử'));
      await tester.pumpAndSettle();
      expect(
        controller.document.toPlainText(),
        contains('Bản nháp tiếng Việt'),
      );
      expect(
        find.descendant(
          of: find.byType(BiographyEditorDialog),
          matching: find.text('Tải phiên bản mới (giữ bản nháp)'),
        ),
        findsOneWidget,
      );
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Lưu tiểu sử'),
      );
      expect(save.onPressed, isNull);
      repository.failure = null;
      await tester.tap(
        find.descendant(
          of: find.byType(BiographyEditorDialog),
          matching: find.text('Tải phiên bản mới (giữ bản nháp)'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        controller.document.toPlainText(),
        contains('Bản nháp tiếng Việt'),
      );
      await tester.tap(find.text('Lưu tiểu sử'));
      await tester.pumpAndSettle();
      expect(find.byType(BiographyEditorDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('session change closes editor and clears the draft', (
    tester,
  ) async {
    await openScreen(tester, TestMediaRepository());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MemberDetailScreen)),
    );
    container.read(privateSessionRevisionProvider.notifier).advance();
    await tester.pumpAndSettle();
    expect(find.byType(BiographyEditorDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('session change also closes nested link dialog', (tester) async {
    await openScreen(tester, TestMediaRepository());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chèn liên kết HTTPS'));
    await tester.pumpAndSettle();
    expect(find.text('Địa chỉ liên kết'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MemberDetailScreen)),
    );
    container.read(privateSessionRevisionProvider.notifier).advance();
    await tester.pumpAndSettle();
    expect(find.byType(BiographyEditorDialog), findsNothing);
    expect(find.text('Địa chỉ liên kết'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'upload retry keeps selected bytes and idempotency key with locked metadata',
    (tester) async {
      final repository = TestMediaRepository();
      final files = _Files();
      await openScreen(tester, repository, files: files);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm tư liệu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn tư liệu từ thiết bị'));
      await tester.pumpAndSettle();
      expect(find.text('Ky-niem.pdf'), findsOneWidget);
      await tester.tap(find.text('Tải tư liệu'));
      await tester.pumpAndSettle();
      expect(find.text(const NetworkFailure().message), findsWidgets);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
        false,
      );
      await tester.tap(find.text('Thử tải lại'));
      await tester.pumpAndSettle();
      expect(repository.keys.length, 2);
      expect(repository.keys.first, repository.keys.last);
      expect(files.reads, 1);
      expect(find.text('Chọn tư liệu từ thiết bị'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
