import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/common_fund_disbursement_models.dart';
import '../../data/models/immutable_ledger_integrity_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/models/ledger_annual_audit_models.dart';
import '../../data/repositories/common_fund_disbursement_repository_impl.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../../domain/repositories/ledger_repository.dart';

/// Trạng thái màn hình Biên bản Kiểm kê Quỹ Hằng Năm (`AnnualAuditUI`).
@immutable
class LedgerAnnualAuditState {
  final bool isLoadingInitial;
  final bool isSubmitting;
  final bool isUploadingEvidence;
  final String? errorMessage;
  final String? submitErrorMessage;

  final int selectedYear;
  final double systemBalance;
  final int totalLedgerEntries;
  final LedgerHistoryItemModel? latestTransaction;
  final List<LedgerHistoryItemModel> recentTransactions;
  final LedgerIntegrityReportModel? integrityReport;

  final int pendingAdjustmentCount;
  final int pendingDisbursementCount;

  final List<LedgerAnnualAuditModel> audits;
  final int? historyFilterYear;
  final LedgerAnnualAuditStatusEnum? historyFilterStatus;
  final LedgerAnnualAuditModel? lastSubmittedAudit;

  const LedgerAnnualAuditState({
    this.isLoadingInitial = false,
    this.isSubmitting = false,
    this.isUploadingEvidence = false,
    this.errorMessage,
    this.submitErrorMessage,
    required this.selectedYear,
    this.systemBalance = 0,
    this.totalLedgerEntries = 0,
    this.latestTransaction,
    this.recentTransactions = const [],
    this.integrityReport,
    this.pendingAdjustmentCount = 0,
    this.pendingDisbursementCount = 0,
    this.audits = const [],
    this.historyFilterYear,
    this.historyFilterStatus,
    this.lastSubmittedAudit,
  });

  LedgerAnnualAuditModel? get matchedAuditForSelectedYear {
    for (final item in audits) {
      if (item.auditYear == selectedYear && item.isMatched) {
        return item;
      }
    }
    return null;
  }

  bool get isShaValid => integrityReport == null || integrityReport!.valid;

  int get totalPendingCount =>
      pendingAdjustmentCount + pendingDisbursementCount;

  bool get isPreFlightBlocked => !isShaValid || totalPendingCount > 0;

  List<LedgerAnnualAuditModel> get filteredAudits {
    return audits.where((item) {
      if (historyFilterYear != null && item.auditYear != historyFilterYear) {
        return false;
      }
      if (historyFilterStatus != null &&
          item.auditStatus != historyFilterStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  List<int> get availableYears {
    final currentYear = DateTime.now().year;
    final years = <int>{
      currentYear,
      currentYear - 1,
      selectedYear,
      for (final item in audits) item.auditYear,
    };
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  LedgerAnnualAuditState copyWith({
    bool? isLoadingInitial,
    bool? isSubmitting,
    bool? isUploadingEvidence,
    String? Function()? errorMessage,
    String? Function()? submitErrorMessage,
    int? selectedYear,
    double? systemBalance,
    int? totalLedgerEntries,
    LedgerHistoryItemModel? Function()? latestTransaction,
    List<LedgerHistoryItemModel>? recentTransactions,
    LedgerIntegrityReportModel? Function()? integrityReport,
    int? pendingAdjustmentCount,
    int? pendingDisbursementCount,
    List<LedgerAnnualAuditModel>? audits,
    int? Function()? historyFilterYear,
    LedgerAnnualAuditStatusEnum? Function()? historyFilterStatus,
    LedgerAnnualAuditModel? Function()? lastSubmittedAudit,
  }) {
    return LedgerAnnualAuditState(
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isUploadingEvidence: isUploadingEvidence ?? this.isUploadingEvidence,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      submitErrorMessage: submitErrorMessage != null
          ? submitErrorMessage()
          : this.submitErrorMessage,
      selectedYear: selectedYear ?? this.selectedYear,
      systemBalance: systemBalance ?? this.systemBalance,
      totalLedgerEntries: totalLedgerEntries ?? this.totalLedgerEntries,
      latestTransaction: latestTransaction != null
          ? latestTransaction()
          : this.latestTransaction,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      integrityReport:
          integrityReport != null ? integrityReport() : this.integrityReport,
      pendingAdjustmentCount:
          pendingAdjustmentCount ?? this.pendingAdjustmentCount,
      pendingDisbursementCount:
          pendingDisbursementCount ?? this.pendingDisbursementCount,
      audits: audits ?? this.audits,
      historyFilterYear: historyFilterYear != null
          ? historyFilterYear()
          : this.historyFilterYear,
      historyFilterStatus: historyFilterStatus != null
          ? historyFilterStatus()
          : this.historyFilterStatus,
      lastSubmittedAudit: lastSubmittedAudit != null
          ? lastSubmittedAudit()
          : this.lastSubmittedAudit,
    );
  }
}

class LedgerAnnualAuditNotifier extends Notifier<LedgerAnnualAuditState> {
  LedgerRepository get _ledgerRepository => ref.read(ledgerRepositoryProvider);

  @override
  LedgerAnnualAuditState build() {
    return LedgerAnnualAuditState(selectedYear: DateTime.now().year);
  }

  Future<void> loadInitial({
    int? initialYear,
    bool canPerformAudit = true,
  }) async {
    final targetYear = initialYear ?? state.selectedYear;
    state = state.copyWith(
      selectedYear: targetYear,
      isLoadingInitial: true,
      errorMessage: () => null,
      submitErrorMessage: () => null,
    );

    try {
      final ledgerFuture = _ledgerRepository.searchLedgerHistory(
        page: 0,
        size: 20,
        sortDirection: 'DESC',
      );
      final integrityFuture = _safeVerifyIntegrity();
      final auditsFuture = _ledgerRepository.searchAnnualAudits();
      final pendingAdjFuture = canPerformAudit
          ? _safeCountPendingAdjustments()
          : Future.value(0);
      final pendingDisbFuture = canPerformAudit
          ? _safeCountPendingDisbursements()
          : Future.value(0);

      final pageResult = await ledgerFuture;
      final report = await integrityFuture;
      final audits = await auditsFuture;
      final pendingAdj = await pendingAdjFuture;
      final pendingDisb = await pendingDisbFuture;
      if (!ref.mounted) return;

      final latestTx =
          pageResult.items.isNotEmpty ? pageResult.items.first : null;
      final systemBal =
          latestTx?.runningBalance ?? pageResult.summary.currentFundBalance;

      state = state.copyWith(
        isLoadingInitial: false,
        systemBalance: systemBal,
        totalLedgerEntries: pageResult.totalElements,
        latestTransaction: () => latestTx,
        recentTransactions: pageResult.items,
        integrityReport: () => report,
        audits: audits,
        pendingAdjustmentCount: pendingAdj,
        pendingDisbursementCount: pendingDisb,
      );
    } on Failure catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingInitial: false,
        errorMessage: () => e.message,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingInitial: false,
        errorMessage: () =>
            'Không thể tải dữ liệu kiểm kê Quỹ chung. Vui lòng thử lại.',
      );
    }
  }

  Future<void> refresh({bool canPerformAudit = true}) {
    return loadInitial(
      initialYear: state.selectedYear,
      canPerformAudit: canPerformAudit,
    );
  }

  void setSelectedYear(int year) {
    if (year == state.selectedYear) return;
    state = state.copyWith(
      selectedYear: year,
      lastSubmittedAudit: () => null,
      submitErrorMessage: () => null,
    );
  }

  void setHistoryFilterYear(int? year) {
    state = state.copyWith(historyFilterYear: () => year);
  }

  void setHistoryFilterStatus(LedgerAnnualAuditStatusEnum? status) {
    state = state.copyWith(historyFilterStatus: () => status);
  }

  void clearLastSubmittedAudit() {
    state = state.copyWith(
      lastSubmittedAudit: () => null,
      submitErrorMessage: () => null,
    );
  }

  void clearSubmitError() {
    state = state.copyWith(submitErrorMessage: () => null);
  }

  /// Thực hiện kiểm kê quỹ hằng năm: upload biên bản (nếu có) trước khi gọi `POST /ledger/annual-audit`.
  Future<LedgerAnnualAuditModel?> submitAudit({
    required double actualBalance,
    String? referenceTransactionId,
    String? notes,
    SelectedEvidenceFile? evidenceFile,
    String? evidenceUrl,
    bool canPerformAudit = true,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      isUploadingEvidence: evidenceFile != null,
      submitErrorMessage: () => null,
    );

    try {
      String? resolvedUrl =
          (evidenceUrl != null && evidenceUrl.trim().isNotEmpty)
              ? evidenceUrl.trim()
              : null;

      if (evidenceFile != null) {
        final uploadRes = await _ledgerRepository.uploadEvidence(
          bytes: evidenceFile.bytes,
          filename: evidenceFile.name,
          originalTransactionId: referenceTransactionId,
        );
        if (!ref.mounted) return null;
        resolvedUrl = uploadRes.evidenceUrl;
      }

      state = state.copyWith(isUploadingEvidence: false);

      final created = await _ledgerRepository.performAnnualAudit(
        AnnualLedgerAuditRequestDto(
          actualBalance: actualBalance,
          auditYear: state.selectedYear,
          referenceTransactionId: referenceTransactionId,
          notes: notes,
          evidenceAttachmentUrl: resolvedUrl,
        ),
      );
      if (!ref.mounted) return null;

      final updatedAudits = [
        created,
        ...state.audits.where((a) => a.auditId != created.auditId),
      ];

      state = state.copyWith(
        isSubmitting: false,
        audits: updatedAudits,
        lastSubmittedAudit: () => created,
      );

      // Làm mới snapshot Sổ cái & pending count để đồng bộ ngay sau chốt
      await _refreshSecondarySnapshots(canPerformAudit: canPerformAudit);
      return created;
    } on Failure catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isSubmitting: false,
        isUploadingEvidence: false,
        submitErrorMessage: () => e.message,
      );
      return null;
    } catch (_) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isSubmitting: false,
        isUploadingEvidence: false,
        submitErrorMessage: () =>
            'Có lỗi xảy ra khi xác nhận biên bản kiểm kê. Vui lòng thử lại.',
      );
      return null;
    }
  }

  Future<Uint8List> downloadAuditEvidence(String evidenceUrl) {
    return _ledgerRepository.downloadEvidenceBytes(evidenceUrl);
  }

  Future<void> _refreshSecondarySnapshots({
    required bool canPerformAudit,
  }) async {
    try {
      final pageResult = await _ledgerRepository.searchLedgerHistory(
        page: 0,
        size: 20,
        sortDirection: 'DESC',
      );
      final report = await _safeVerifyIntegrity();
      final pendingAdj = canPerformAudit
          ? await _safeCountPendingAdjustments()
          : state.pendingAdjustmentCount;
      final pendingDisb = canPerformAudit
          ? await _safeCountPendingDisbursements()
          : state.pendingDisbursementCount;
      if (!ref.mounted) return;

      final latestTx =
          pageResult.items.isNotEmpty ? pageResult.items.first : null;
      final systemBal =
          latestTx?.runningBalance ?? pageResult.summary.currentFundBalance;

      state = state.copyWith(
        systemBalance: systemBal,
        totalLedgerEntries: pageResult.totalElements,
        latestTransaction: () => latestTx,
        recentTransactions: pageResult.items,
        integrityReport: () => report,
        pendingAdjustmentCount: pendingAdj,
        pendingDisbursementCount: pendingDisb,
      );
    } catch (_) {
      // Giữ kết quả vừa submit; không ghi đè lỗi phụ sau khi đã 201 Created.
    }
  }

  Future<LedgerIntegrityReportModel?> _safeVerifyIntegrity() async {
    try {
      return await _ledgerRepository.verifyLedgerIntegrity();
    } catch (_) {
      return null;
    }
  }

  Future<int> _safeCountPendingAdjustments() async {
    try {
      final list = await _ledgerRepository.searchAdjustmentRequests(
        status: LedgerAdjustmentStatusEnum.pending,
      );
      return list.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _safeCountPendingDisbursements() async {
    try {
      final repo = ref.read(commonFundDisbursementRepositoryProvider);
      final list = await repo.searchDisbursements(
        status: CommonFundDisbursementStatusEnum.pending,
      );
      return list.length;
    } catch (_) {
      return 0;
    }
  }
}

final ledgerAnnualAuditProvider = NotifierProvider.autoDispose<
    LedgerAnnualAuditNotifier, LedgerAnnualAuditState>(
  LedgerAnnualAuditNotifier.new,
);
