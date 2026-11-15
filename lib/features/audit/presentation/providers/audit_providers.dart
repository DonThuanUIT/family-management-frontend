import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/audit_log_models.dart';
import '../../data/repositories/audit_repository_impl.dart';
import '../../domain/repositories/audit_repository.dart';

/// Notifier quản lý bộ lọc tìm kiếm hiện tại của màn hình Nhật Ký
class AuditFilterNotifier extends Notifier<AuditLogFilter> {
  @override
  AuditLogFilter build() {
    return const AuditLogFilter();
  }

  void setFilter(AuditLogFilter filter) {
    state = filter;
  }

  void reset() {
    state = const AuditLogFilter();
  }
}

final auditFilterProvider =
    NotifierProvider<AuditFilterNotifier, AuditLogFilter>(AuditFilterNotifier.new);

/// AsyncNotifier nạp danh sách nhật ký tự động phản ứng theo bộ lọc
class AuditLogsNotifier extends AsyncNotifier<AuditLogPageResponse> {
  AuditRepository get _repository => ref.read(auditRepositoryProvider);

  @override
  Future<AuditLogPageResponse> build() async {
    final filter = ref.watch(auditFilterProvider);
    return _repository.getAuditLogs(filter);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final auditLogsProvider =
    AsyncNotifierProvider<AuditLogsNotifier, AuditLogPageResponse>(AuditLogsNotifier.new);

/// Provider nạp chi tiết bản ghi kiểm toán kèm Diff theo auditId
final auditDetailProvider =
    FutureProvider.family<AuditLogDetailModel, String>((ref, auditId) async {
  final repository = ref.watch(auditRepositoryProvider);
  return repository.getAuditLogDetail(auditId);
});

/// Thống kê nhanh số lượng 4 nhóm hành động chính
class AuditStatsSummary {
  final int totalCount;
  final int assignCount;
  final int joinCount;
  final int genealogyCount;

  const AuditStatsSummary({
    required this.totalCount,
    required this.assignCount,
    required this.joinCount,
    required this.genealogyCount,
  });
}

final auditStatsProvider = Provider<AuditStatsSummary>((ref) {
  return const AuditStatsSummary(
    totalCount: 128,
    assignCount: 24,
    joinCount: 38,
    genealogyCount: 42,
  );
});
