import '../../data/models/audit_log_models.dart';

abstract class AuditRepository {
  Future<AuditLogPageResponse> getAuditLogs(AuditLogFilter filter);
  Future<AuditLogDetailModel> getAuditLogDetail(String auditId);
}
