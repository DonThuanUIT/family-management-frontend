// ignore_for_file: constant_identifier_names

enum PaymentMethod {
  Cash('Tiền mặt'),
  BankTransfer('Chuyển khoản VietQR');

  final String displayName;
  const PaymentMethod(this.displayName);
}

enum ConversionMethod {
  BtcBenchmark('Định mức BTC'),
  Invoice('Theo hóa đơn thực tế'),
  Agreement('Thỏa thuận gia tộc');

  final String displayName;
  const ConversionMethod(this.displayName);
}

enum InKindProcessingStatus {
  Pending('Chờ phân loại', 0xFFE65100, 0xFFFFF3E0),
  Consumed('Đã tiêu hao cỗ', 0xFF455A64, 0xFFECEFF1),
  Returned('Đã hoàn trả', 0xFF0277BD, 0xFFE1F5FE),
  AddedToCommonAssets('Đã nhập kho từ đường', 0xFF2E7D32, 0xFFE8F5E9);

  final String displayName;
  final int colorValue;
  final int bgColorValue;
  const InKindProcessingStatus(this.displayName, this.colorValue, this.bgColorValue);
}

class MemberAllocationDto {
  final String memberId;
  final String memberName;
  final String generation;
  final double amount;
  final double percentage;

  const MemberAllocationDto({
    required this.memberId,
    required this.memberName,
    required this.generation,
    required this.amount,
    required this.percentage,
  });
}

class ElectronicReceiptDto {
  final String receiptNumber;
  final String contributionId;
  final String eventId;
  final String? eventName;
  final String payerMemberId;
  final String? payerMemberName;
  final String receiverAccountId;
  final double amount;
  final String? amountInWords;
  final PaymentMethod paymentMethod;
  final DateTime? contributionDate;
  final List<MemberAllocationDto> allocations;

  const ElectronicReceiptDto({
    required this.receiptNumber,
    required this.contributionId,
    required this.eventId,
    this.eventName,
    required this.payerMemberId,
    this.payerMemberName,
    required this.receiverAccountId,
    required this.amount,
    this.amountInWords,
    required this.paymentMethod,
    this.contributionDate,
    this.allocations = const [],
  });
}

class InKindElectronicReceiptDto {
  final String receiptNumber;
  final String contributionId;
  final String eventId;
  final String? eventName;
  final String payerMemberId;
  final String? payerMemberName;
  final String receiverAccountId;
  final String itemName;
  final double quantity;
  final String unit;
  final ConversionMethod conversionMethod;
  final double convertedMonetaryValue;
  final String? convertedMonetaryValueInWords;
  final InKindProcessingStatus processingStatus;
  final String? storageLocation;
  final DateTime? contributionDate;
  final List<MemberAllocationDto> allocations;

  const InKindElectronicReceiptDto({
    required this.receiptNumber,
    required this.contributionId,
    required this.eventId,
    this.eventName,
    required this.payerMemberId,
    this.payerMemberName,
    required this.receiverAccountId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.conversionMethod,
    required this.convertedMonetaryValue,
    this.convertedMonetaryValueInWords,
    this.processingStatus = InKindProcessingStatus.Pending,
    this.storageLocation,
    this.contributionDate,
    this.allocations = const [],
  });

  InKindElectronicReceiptDto copyWith({
    InKindProcessingStatus? processingStatus,
    String? storageLocation,
  }) {
    return InKindElectronicReceiptDto(
      receiptNumber: receiptNumber,
      contributionId: contributionId,
      eventId: eventId,
      eventName: eventName,
      payerMemberId: payerMemberId,
      payerMemberName: payerMemberName,
      receiverAccountId: receiverAccountId,
      itemName: itemName,
      quantity: quantity,
      unit: unit,
      conversionMethod: conversionMethod,
      convertedMonetaryValue: convertedMonetaryValue,
      convertedMonetaryValueInWords: convertedMonetaryValueInWords,
      processingStatus: processingStatus ?? this.processingStatus,
      storageLocation: storageLocation ?? this.storageLocation,
      contributionDate: contributionDate,
      allocations: allocations,
    );
  }
}

class ClanAssetDto {
  final String assetId;
  final String assetName;
  final int quantity;
  final String unit;
  final double assessedValue;
  final String storageLocation;
  final String? originContributionId;
  final String? originDonorName;
  final DateTime createdAt;

  const ClanAssetDto({
    required this.assetId,
    required this.assetName,
    required this.quantity,
    required this.unit,
    required this.assessedValue,
    required this.storageLocation,
    this.originContributionId,
    this.originDonorName,
    required this.createdAt,
  });
}
