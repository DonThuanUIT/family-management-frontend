import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/ledger_repository.dart';
import '../datasources/ledger_remote_datasource.dart';
import '../models/immutable_ledger_integrity_models.dart';
import '../models/ledger_adjustment_models.dart';
import '../models/ledger_annual_audit_models.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final LedgerRemoteDataSource _remoteDataSource;

  LedgerRepositoryImpl(this._remoteDataSource);

  @override
  Future<LedgerHistoryPageModel> searchLedgerHistory({
    String? keyword,
    LedgerTransactionTypeEnum? transactionType,
    bool? onlyWithAdjustments,
    String sortDirection = 'DESC',
    String? from,
    String? to,
    int page = 0,
    int size = 20,
  }) {
    return _remoteDataSource.searchLedgerHistory(
      keyword: keyword,
      transactionType: transactionType,
      onlyWithAdjustments: onlyWithAdjustments,
      sortDirection: sortDirection,
      from: from,
      to: to,
      page: page,
      size: size,
    );
  }

  @override
  Future<LedgerIntegrityReportModel> verifyLedgerIntegrity() {
    return _remoteDataSource.verifyLedgerIntegrity();
  }

  @override
  Future<LedgerHistoryItemModel> getTransactionDetail(String transactionId) {
    return _remoteDataSource.getTransactionDetail(transactionId);
  }

  @override
  Future<LedgerAdjustmentRequestModel> proposeAdjustment(
    ProposeLedgerAdjustmentRequestDto request,
  ) {
    return _remoteDataSource.proposeAdjustment(request);
  }

  @override
  Future<List<LedgerAdjustmentRequestModel>> searchAdjustmentRequests({
    String? originalTransactionId,
    LedgerAdjustmentStatusEnum? status,
  }) {
    return _remoteDataSource.searchAdjustmentRequests(
      originalTransactionId: originalTransactionId,
      status: status,
    );
  }

  @override
  Future<LedgerAdjustmentRequestModel> getAdjustmentRequestById(
    String requestId,
  ) {
    return _remoteDataSource.getAdjustmentRequestById(requestId);
  }

  @override
  Future<ReviewLedgerAdjustmentResponseModel> reviewAdjustment(
    ReviewLedgerAdjustmentRequestDto request,
  ) {
    return _remoteDataSource.reviewAdjustment(request);
  }

  @override
  Future<LedgerEvidenceUploadResult> uploadEvidence({
    required Uint8List bytes,
    required String filename,
    String? originalTransactionId,
  }) {
    return _remoteDataSource.uploadEvidence(
      bytes: bytes,
      filename: filename,
      originalTransactionId: originalTransactionId,
    );
  }

  @override
  Future<Uint8List> downloadEvidenceBytes(String evidenceUrl) {
    return _remoteDataSource.downloadEvidenceBytes(evidenceUrl);
  }

  @override
  Future<LedgerAnnualAuditModel> performAnnualAudit(
    AnnualLedgerAuditRequestDto request,
  ) {
    return _remoteDataSource.performAnnualAudit(request);
  }

  @override
  Future<List<LedgerAnnualAuditModel>> searchAnnualAudits({
    int? auditYear,
    LedgerAnnualAuditStatusEnum? status,
  }) {
    return _remoteDataSource.searchAnnualAudits(
      auditYear: auditYear,
      status: status,
    );
  }

  @override
  Future<LedgerAnnualAuditModel> getAnnualAuditById(String auditId) {
    return _remoteDataSource.getAnnualAuditById(auditId);
  }
}

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  final remoteDataSource = ref.watch(ledgerRemoteDataSourceProvider);
  return LedgerRepositoryImpl(remoteDataSource);
});
