import 'dart:typed_data';

import '../../data/models/immutable_ledger_integrity_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/models/ledger_annual_audit_models.dart';

abstract class LedgerRepository {
  Future<LedgerHistoryPageModel> searchLedgerHistory({
    String? keyword,
    LedgerTransactionTypeEnum? transactionType,
    bool? onlyWithAdjustments,
    String sortDirection = 'DESC',
    String? from,
    String? to,
    int page = 0,
    int size = 20,
  });

  Future<LedgerIntegrityReportModel> verifyLedgerIntegrity();

  Future<LedgerHistoryItemModel> getTransactionDetail(String transactionId);

  Future<LedgerAdjustmentRequestModel> proposeAdjustment(
    ProposeLedgerAdjustmentRequestDto request,
  );

  Future<List<LedgerAdjustmentRequestModel>> searchAdjustmentRequests({
    String? originalTransactionId,
    LedgerAdjustmentStatusEnum? status,
  });

  Future<LedgerAdjustmentRequestModel> getAdjustmentRequestById(
    String requestId,
  );

  Future<ReviewLedgerAdjustmentResponseModel> reviewAdjustment(
    ReviewLedgerAdjustmentRequestDto request,
  );

  Future<LedgerEvidenceUploadResult> uploadEvidence({
    required Uint8List bytes,
    required String filename,
    String? originalTransactionId,
  });

  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl);

  Future<LedgerAnnualAuditModel> performAnnualAudit(
    AnnualLedgerAuditRequestDto request,
  );

  Future<List<LedgerAnnualAuditModel>> searchAnnualAudits({
    int? auditYear,
    LedgerAnnualAuditStatusEnum? status,
  });

  Future<LedgerAnnualAuditModel> getAnnualAuditById(String auditId);
}
