import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/advance_voucher_repository.dart';
import '../datasources/advance_voucher_remote_datasource.dart';
import '../models/advance_voucher_models.dart';

final advanceVoucherRepositoryProvider =
    Provider<AdvanceVoucherRepository>((ref) {
  final remote = ref.watch(advanceVoucherRemoteDataSourceProvider);
  return AdvanceVoucherRepositoryImpl(remote);
});

class AdvanceVoucherRepositoryImpl implements AdvanceVoucherRepository {
  final AdvanceVoucherRemoteDataSource _remoteDataSource;

  const AdvanceVoucherRepositoryImpl(this._remoteDataSource);

  @override
  Future<AdvanceVoucherModel> createAdvanceVoucher(
      CreateAdvanceVoucherRequestDto request) {
    return _remoteDataSource.createAdvanceVoucher(request);
  }

  @override
  Future<AdvanceVoucherModel> confirmDisbursement(
    String advanceVoucherId,
    ConfirmDisbursementRequestDto request,
  ) {
    return _remoteDataSource.confirmDisbursement(advanceVoucherId, request);
  }

  @override
  Future<List<AdvanceVoucherModel>> getAdvanceVouchers({
    String? eventId,
    String? taskId,
    String? recipientMemberId,
    AdvanceVoucherStatusEnum? status,
  }) {
    return _remoteDataSource.getAdvanceVouchers(
      eventId: eventId,
      taskId: taskId,
      recipientMemberId: recipientMemberId,
      status: status,
    );
  }

  @override
  Future<AdvanceVoucherModel> getAdvanceVoucherDetail(String advanceVoucherId) {
    return _remoteDataSource.getAdvanceVoucherDetail(advanceVoucherId);
  }
}
