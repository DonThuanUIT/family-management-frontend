import '../../data/models/advance_voucher_models.dart';

abstract class AdvanceVoucherRepository {
  Future<AdvanceVoucherModel> createAdvanceVoucher(
      CreateAdvanceVoucherRequestDto request);

  Future<AdvanceVoucherModel> confirmDisbursement(
    String advanceVoucherId,
    ConfirmDisbursementRequestDto request,
  );

  Future<List<AdvanceVoucherModel>> getAdvanceVouchers({
    String? eventId,
    String? taskId,
    String? recipientMemberId,
    AdvanceVoucherStatusEnum? status,
  });

  Future<AdvanceVoucherModel> getAdvanceVoucherDetail(String advanceVoucherId);
}
