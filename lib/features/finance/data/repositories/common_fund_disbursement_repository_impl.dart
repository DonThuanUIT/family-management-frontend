import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/common_fund_disbursement_repository.dart';
import '../datasources/common_fund_disbursement_remote_datasource.dart';
import '../models/common_fund_disbursement_models.dart';

class CommonFundDisbursementRepositoryImpl
    implements CommonFundDisbursementRepository {
  final CommonFundDisbursementRemoteDataSource _remoteDataSource;

  CommonFundDisbursementRepositoryImpl(this._remoteDataSource);

  @override
  Future<CommonFundBalanceModel> getFundBalance() {
    return _remoteDataSource.getFundBalance();
  }

  @override
  Future<CommonFundDisbursementModel> proposeDisbursement(
    ProposeCommonFundDisbursementRequestDto request,
  ) {
    return _remoteDataSource.proposeDisbursement(request);
  }

  @override
  Future<List<CommonFundDisbursementModel>> searchDisbursements({
    CommonFundDisbursementStatusEnum? status,
    CommonFundExpenseCategoryEnum? category,
  }) {
    return _remoteDataSource.searchDisbursements(
      status: status,
      category: category,
    );
  }

  @override
  Future<CommonFundDisbursementModel> getDisbursementById(String requestId) {
    return _remoteDataSource.getDisbursementById(requestId);
  }

  @override
  Future<ReviewCommonFundDisbursementResponseModel> reviewDisbursement(
    String requestId,
    ReviewCommonFundDisbursementRequestDto request,
  ) {
    return _remoteDataSource.reviewDisbursement(requestId, request);
  }
}

final commonFundDisbursementRepositoryProvider =
    Provider<CommonFundDisbursementRepository>((ref) {
  final remoteDataSource =
      ref.watch(commonFundDisbursementRemoteDataSourceProvider);
  return CommonFundDisbursementRepositoryImpl(remoteDataSource);
});
