import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/audit_repository.dart';
import '../datasources/audit_remote_datasource.dart';
import '../models/audit_log_models.dart';

class AuditRepositoryImpl implements AuditRepository {
  final AuditRemoteDataSource _remoteDataSource;

  AuditRepositoryImpl(this._remoteDataSource);

  @override
  Future<AuditLogPageResponse> getAuditLogs(AuditLogFilter filter) {
    return _remoteDataSource.fetchAuditLogs(filter);
  }

  @override
  Future<AuditLogDetailModel> getAuditLogDetail(String auditId) {
    return _remoteDataSource.fetchAuditLogDetail(auditId);
  }
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final remoteDataSource = ref.watch(auditRemoteDataSourceProvider);
  return AuditRepositoryImpl(remoteDataSource);
});
