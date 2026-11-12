import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/member_media_models.dart';
import '../providers/member_media_providers.dart';

Future<T?> showMediaDialog<T>(
  BuildContext context,
  WidgetRef ref,
  String memberId,
  Widget child,
) {
  final session = ref.read(mediaSessionProvider);
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SessionBoundary(
      memberId: memberId,
      initialSession: session,
      child: child,
    ),
  );
}

class _SessionBoundary extends ConsumerWidget {
  final String memberId;
  final Object initialSession;
  final Widget child;
  const _SessionBoundary({
    required this.memberId,
    required this.initialSession,
    required this.child,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memberMediaProvider(memberId));
    if (ref.watch(mediaSessionProvider) != initialSession ||
        [401, 403, 404].contains(state.error?.statusCode)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final navigator = Navigator.of(context);
          final ownRoute = ModalRoute.of(context);
          navigator.popUntil((route) => route == ownRoute);
          navigator.pop();
        }
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}

class MediaDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool busy;
  final bool dirty;
  const MediaDialogShell({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.busy = false,
    this.dirty = true,
  });

  Future<void> _close(BuildContext context) async {
    if (busy) return;
    final discard =
        !dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Bỏ các thay đổi?'),
                content: const Text('Nội dung chưa lưu sẽ bị xóa.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Tiếp tục sửa'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Bỏ thay đổi'),
                  ),
                ],
              ),
            ) ==
            true;
    if (discard && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy && !dirty,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !busy) _close(context);
    },
    child: AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          Expanded(child: Text(title)),
          IconButton(
            tooltip: 'Đóng',
            onPressed: busy ? null : () => _close(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(width: 640, child: SingleChildScrollView(child: child)),
      actions: [
        TextButton(
          onPressed: busy ? null : () => _close(context),
          child: const Text('Hủy'),
        ),
        ...actions,
      ],
    ),
  );
}

class MediaError extends StatelessWidget {
  final Failure error;
  final VoidCallback? onRefresh;
  const MediaError(this.error, {super.key, this.onRefresh});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          error.message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        if (error.statusCode == 409 && onRefresh != null)
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Tải phiên bản mới (giữ bản nháp)'),
          ),
      ],
    ),
  );
}

class VisibilityField extends StatelessWidget {
  final MediaVisibility value;
  final ValueChanged<MediaVisibility>? onChanged;
  const VisibilityField({super.key, required this.value, this.onChanged});
  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<MediaVisibility>(
        initialValue: value,
        decoration: const InputDecoration(labelText: 'Ai được xem nội dung?'),
        items: MediaVisibility.values
            .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
            .toList(),
        onChanged: onChanged == null
            ? null
            : (v) {
                if (v != null) onChanged!(v);
              },
      );
}
