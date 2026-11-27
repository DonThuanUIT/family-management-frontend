import '../../data/models/common_fund_disbursement_models.dart';

abstract class CommonFundDisbursementRepository {
  Future<CommonFundBalanceModel> getFundBalance();

  Future<CommonFundDisbursementModel> proposeDisbursement(
    ProposeCommonFundDisbursementRequestDto request,
  );

  Future<List<CommonFundDisbursementModel>> searchDisbursements({
    CommonFundDisbursementStatusEnum? status,
    CommonFundExpenseCategoryEnum? category,
  });

  Future<CommonFundDisbursementModel> getDisbursementById(String requestId);

  Future<ReviewCommonFundDisbursementResponseModel> reviewDisbursement(
    String requestId,
    ReviewCommonFundDisbursementRequestDto request,
  );
}
