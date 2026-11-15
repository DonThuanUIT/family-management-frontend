import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/member_media_models.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../providers/member_media_providers.dart';
import '../widgets/attachment_list.dart';
import '../widgets/biography_editor_dialog.dart';
import '../widgets/media_dialog_shell.dart';
import '../widgets/portrait_dialog.dart';
import '../widgets/private_media_image.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memberMediaProvider(memberId));
    final session = ref.watch(mediaSessionProvider);
    final member = state.member;
    return Scaffold(
      appBar: const HeritageNavBar(currentRoute: '/home'),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 768
          ? const HeritageBottomNavBar(currentRoute: '/home')
          : null,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(memberMediaProvider(memberId).notifier).reload(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Về cây phả hệ'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hồ sơ thành viên',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  if (state.loading) const LinearProgressIndicator(),
                  if (state.error != null)
                    MediaError(
                      state.error!,
                      onRefresh: () => ref
                          .read(memberMediaProvider(memberId).notifier)
                          .reload(),
                    ),
                  if (member == null && !state.loading) ...[
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Không thể hiển thị hồ sơ thành viên.'),
                    ),
                    FilledButton(
                      onPressed: state.error?.statusCode == 401
                          ? () => context.go('/login')
                          : () => ref
                                .read(memberMediaProvider(memberId).notifier)
                                .reload(),
                      child: Text(
                        state.error?.statusCode == 401
                            ? 'Đăng nhập'
                            : 'Thử lại',
                      ),
                    ),
                  ],
                  if (member != null)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final profile = _profile(context, ref, member, state);
                        final content = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _card(
                              context,
                              _biography(context, ref, member, state),
                            ),
                            const SizedBox(height: 20),
                            _card(
                              context,
                              AttachmentList(
                                key: ValueKey((session, memberId)),
                                memberId: memberId,
                              ),
                            ),
                          ],
                        );
                        return constraints.maxWidth < 760
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  profile,
                                  const SizedBox(height: 20),
                                  content,
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 248, child: profile),
                                  const SizedBox(width: 24),
                                  Expanded(child: content),
                                ],
                              );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Widget child) => Card(
    color: Theme.of(context).colorScheme.surface,
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
  Widget _profile(
    BuildContext context,
    WidgetRef ref,
    MemberMedia member,
    MemberMediaState state,
  ) => _card(
    context,
    Column(
      children: [
        if (member.avatarUrl != null)
          PrivateMediaImage(
            contentKey: (
              memberId: memberId,
              attachmentId: null,
              version: member.mediaVersion,
            ),
            label: 'Ảnh chân dung ${member.fullName}',
            size: 144,
          )
        else
          CircleAvatar(
            radius: 72,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person_outline,
              size: 72,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        const SizedBox(height: 16),
        Text(
          member.fullName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('Đời thứ ${member.generation}', textAlign: TextAlign.center),
        if (member.branchName != null)
          Text(member.branchName!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        if (member.canEdit) ...[
          OutlinedButton.icon(
            onPressed: state.busy || state.loading
                ? null
                : () => showMediaDialog(
                    context,
                    ref,
                    memberId,
                    PortraitDialog(memberId: memberId),
                  ),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Thay ảnh chân dung'),
          ),
          if (member.avatarUrl != null)
            TextButton(
              onPressed: state.busy || state.loading
                  ? null
                  : () async {
                      final session = ref.read(mediaSessionProvider);
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Gỡ ảnh chân dung?'),
                          content: const Text(
                            'Ảnh đại diện hiện tại sẽ được gỡ khỏi hồ sơ.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Gỡ ảnh'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true ||
                          !context.mounted ||
                          ref.read(mediaSessionProvider) != session) {
                        return;
                      }
                      try {
                        await ref
                            .read(memberMediaProvider(memberId).notifier)
                            .avatar(member.mediaVersion, null);
                      } on Failure catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      }
                    },
              child: const Text('Gỡ ảnh hiện tại'),
            ),
        ] else
          const Text('Bạn đang xem hồ sơ ở chế độ chỉ đọc.'),
      ],
    ),
  );
  Widget _biography(
    BuildContext context,
    WidgetRef ref,
    MemberMedia member,
    MemberMediaState state,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Tiểu sử', style: Theme.of(context).textTheme.titleLarge),
          if (member.canEdit)
            TextButton.icon(
              onPressed: state.busy || state.loading
                  ? null
                  : () => showMediaDialog(
                      context,
                      ref,
                      memberId,
                      BiographyEditorDialog(memberId: memberId),
                    ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Chỉnh sửa'),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (member.biographyRestricted)
        const Row(
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 8),
            Expanded(child: Text('Tiểu sử được giới hạn quyền xem.')),
          ],
        )
      else if (member.biography == null ||
          (member.biography!['ops'] as List).every(
            (e) => (e['insert'] as String).trim().isEmpty,
          ))
        const Text(
          'Chưa có tiểu sử. Hãy lưu lại những câu chuyện để thế hệ sau cùng gìn giữ.',
        )
      else
        BiographyView(
          key: ValueKey((ref.watch(mediaSessionProvider), member.mediaVersion)),
          document: member.biography!,
        ),
      if (!member.biographyRestricted)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('Quyền xem: ${member.visibility.label}'),
        ),
    ],
  );
}
