import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/advance_voucher_models.dart';
import '../../data/repositories/advance_voucher_repository_impl.dart';
import '../../domain/repositories/advance_voucher_repository.dart';

class TaskAdvanceVouchersState {
  final bool isLoading;
  final String? errorMessage;
  final List<AdvanceVoucherModel> vouchers;

  const TaskAdvanceVouchersState({
    this.isLoading = false,
    this.errorMessage,
    this.vouchers = const [],
  });

  int get totalAmount => vouchers.fold(0, (sum, v) => sum + v.advanceAmount);

  int get totalDisbursedAmount => vouchers
      .where((v) => v.isDisbursed || v.isSettled)
      .fold(0, (sum, v) => sum + v.advanceAmount);

  bool get hasPendingDisbursement =>
      vouchers.any((v) => v.isPendingDisbursement);

  AdvanceVoucherModel? get latestPendingVoucher {
    final list = vouchers.where((v) => v.isPendingDisbursement).toList();
    return list.isNotEmpty ? list.first : null;
  }

  AdvanceVoucherModel? get latestDisbursedVoucher {
    final list = vouchers.where((v) => v.isDisbursed).toList();
    return list.isNotEmpty ? list.first : null;
  }

  TaskAdvanceVouchersState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<AdvanceVoucherModel>? vouchers,
  }) {
    return TaskAdvanceVouchersState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      vouchers: vouchers ?? this.vouchers,
    );
  }
}

class TaskAdvanceVouchersNotifier extends Notifier<TaskAdvanceVouchersState> {
  final String taskId;

  TaskAdvanceVouchersNotifier(this.taskId);

  AdvanceVoucherRepository get _repository =>
      ref.read(advanceVoucherRepositoryProvider);

  @override
  TaskAdvanceVouchersState build() {
    Future.microtask(() => loadVouchers());
    return const TaskAdvanceVouchersState(isLoading: true);
  }

  Future<void> loadVouchers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getAdvanceVouchers(taskId: taskId);
      state = state.copyWith(
        isLoading: false,
        vouchers: list,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<AdvanceVoucherModel> createVoucher(
      CreateAdvanceVoucherRequestDto request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repository.createAdvanceVoucher(request);
      state = state.copyWith(
        isLoading: false,
        vouchers: [created, ...state.vouchers],
        clearError: true,
      );
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<AdvanceVoucherModel> confirmDisbursement(
    String voucherId, {
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.confirmDisbursement(
        voucherId,
        ConfirmDisbursementRequestDto(notes: notes),
      );
      final updatedList = state.vouchers.map((v) {
        return v.advanceVoucherId == voucherId ? updated : v;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        vouchers: updatedList,
        clearError: true,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final taskAdvanceVouchersProvider = NotifierProvider.family<
    TaskAdvanceVouchersNotifier, TaskAdvanceVouchersState, String>(
  (taskId) => TaskAdvanceVouchersNotifier(taskId),
);
