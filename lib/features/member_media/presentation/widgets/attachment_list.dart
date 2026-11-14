import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/files/member_file_actions.dart';
import '../../data/models/member_media_models.dart';
import '../providers/member_media_providers.dart';
import 'attachment_editor_dialog.dart';
import 'media_dialog_shell.dart';
import 'private_media_image.dart';

class AttachmentList extends ConsumerStatefulWidget {
  final String memberId;
  const AttachmentList({super.key, required this.memberId});
  @override
  ConsumerState<AttachmentList> createState() => _AttachmentListState();
}

class _AttachmentListState extends ConsumerState<AttachmentList> {
  String? _downloading;
  Failure? _error;
  Future<void> _download(FamilyAttachment item) async {
    final scope = ref.read(mediaSessionProvider);
    setState(() {
      _downloading = item.id;
      _error = null;
    });
    try {
      final bytes = await ref
          .read(memberMediaProvider(widget.memberId).notifier)
          .download(item.id);
      if (!mounted || ref.read(mediaSessionProvider) != scope) return;
      final saved = await ref
          .read(memberFileActionsProvider)
          .save(bytes, item.originalFilename, item.mimeType);
      if (saved && mounted && ref.read(mediaSessionProvider) == scope) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi tư liệu tới trình lưu file của thiết bị.'),
          ),
        );
      }
    } on Failure catch (e) {
      if (mounted && ref.read(mediaSessionProvider) == scope) {
        setState(() => _error = e);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = const MediaFailure(
            code: 'SAVE_FAILED',
            message: 'Không thể lưu file trên thiết bị.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  Future<void> _delete(FamilyAttachment item) async {
    final scope = ref.read(mediaSessionProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tư liệu?'),
        content: const Text(
          'Tư liệu sẽ bị xóa khỏi hồ sơ. Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa tư liệu'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        ref.read(mediaSessionProvider) != scope) {
      return;
    }
    try {
      await ref
          .read(memberMediaProvider(widget.memberId).notifier)
          .delete(item);
    } on Failure catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _preview(FamilyAttachment item) => showMediaDialog<void>(
    context,
    ref,
    widget.memberId,
    MediaDialogShell(
      title: item.title,
      dirty: false,
      actions: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.visibility.label} · ${(item.sizeBytes / 1024).ceil()} KiB',
          ),
          if (item.description?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(item.description!),
            ),
          if (item.isImage)
            SizedBox(
              height: 400,
              child: PrivateMediaImage(
                contentKey: (
                  memberId: widget.memberId,
                  attachmentId: item.id,
                  version: item.version,
                ),
                label: item.title,
                preview: true,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Tư liệu PDF: dùng nút tải xuống để mở bằng ứng dụng đọc PDF trên thiết bị.',
              ),
            ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberMediaProvider(widget.memberId));
    final page = state.attachments;
    final busy = state.busy || state.loading || _downloading != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Tư liệu gia sử',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (state.member?.canUpload == true)
              FilledButton.icon(
                onPressed: busy
                    ? null
                    : () => showMediaDialog(
                        context,
                        ref,
                        widget.memberId,
                        AttachmentEditorDialog(memberId: widget.memberId),
                      ),
                icon: const Icon(Icons.add),
                label: const Text('Thêm tư liệu'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Chỉ hiển thị những tư liệu bạn được phép xem.'),
        if (_error != null)
          MediaError(
            _error!,
            onRefresh: () async {
              await ref
                  .read(memberMediaProvider(widget.memberId).notifier)
                  .reload(page: page?.page ?? 0);
              if (mounted) setState(() => _error = null);
            },
          ),
        const SizedBox(height: 12),
        if (page == null || page.items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Chưa có tư liệu được phép hiển thị.'),
          )
        else ...[
          for (final item in page.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.isImage
                              ? Icons.image_outlined
                              : Icons.picture_as_pdf_outlined,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.mimeType.split('/').last.toUpperCase()} · ${(item.sizeBytes / 1024).ceil()} KiB · ${item.visibility.label}',
                    ),
                    if (item.description?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(item.description!),
                      ),
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: busy ? null : () => _preview(item),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Xem'),
                        ),
                        TextButton.icon(
                          onPressed: busy ? null : () => _download(item),
                          icon: _downloading == item.id
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_outlined),
                          label: const Text('Tải xuống'),
                        ),
                        if (item.canEdit)
                          IconButton(
                            tooltip: 'Chỉnh sửa tư liệu',
                            onPressed: busy
                                ? null
                                : () => showMediaDialog(
                                    context,
                                    ref,
                                    widget.memberId,
                                    AttachmentEditorDialog(
                                      memberId: widget.memberId,
                                      attachment: item,
                                    ),
                                  ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        if (item.canDelete)
                          IconButton(
                            tooltip: 'Xóa tư liệu',
                            onPressed: busy ? null : () => _delete(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (page.totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Trang trước',
                  onPressed: busy || page.page <= 0
                      ? null
                      : () => ref
                            .read(memberMediaProvider(widget.memberId).notifier)
                            .reload(page: page.page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Trang ${page.page + 1} / ${page.totalPages}'),
                IconButton(
                  tooltip: 'Trang sau',
                  onPressed: busy || page.page + 1 >= page.totalPages
                      ? null
                      : () => ref
                            .read(memberMediaProvider(widget.memberId).notifier)
                            .reload(page: page.page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ],
    );
  }
}
