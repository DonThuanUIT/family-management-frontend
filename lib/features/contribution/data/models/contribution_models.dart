// ignore_for_file: constant_identifier_names

enum PaymentMethod {
  Cash('Tiền mặt'),
  BankTransfer('Chuyển khoản VietQR');

  final String displayName;
  const PaymentMethod(this.displayName);

  static PaymentMethod fromString(String? val) {
    if (val == null) return PaymentMethod.Cash;
    final lower = val.toLowerCase();
    if (lower.contains('bank') || lower.contains('transfer') || lower.contains('qr')) {
      return PaymentMethod.BankTransfer;
    }
    return PaymentMethod.Cash;
  }
}

enum ConversionMethod {
  BtcBenchmark('Định mức BTC'),
  Invoice('Theo hóa đơn thực tế'),
  Agreement('Thỏa thuận gia tộc');

  final String displayName;
  const ConversionMethod(this.displayName);

  static ConversionMethod fromString(String? val) {
    if (val == null) return ConversionMethod.Agreement;
    for (final method in ConversionMethod.values) {
      if (method.name.toLowerCase() == val.toLowerCase()) {
        return method;
      }
    }
    return ConversionMethod.Agreement;
  }
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

  static InKindProcessingStatus fromString(String? val) {
    if (val == null) return InKindProcessingStatus.Pending;
    for (final status in InKindProcessingStatus.values) {
      if (status.name.toLowerCase() == val.toLowerCase()) {
        return status;
      }
    }
    return InKindProcessingStatus.Pending;
  }
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

  factory MemberAllocationDto.fromJson(Map<String, dynamic> json) {
    return MemberAllocationDto(
      memberId: (json['memberId'] ?? '') as String,
      memberName: (json['memberName'] ?? '') as String,
      generation: (json['generation'] ?? 'Thành viên') as String,
      amount: ((json['recordedAmount'] ?? json['amount'] ?? 0) as num).toDouble(),
      percentage: ((json['percentage'] ?? 100.0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'recordedAmount': amount,
    };
  }
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

  factory ElectronicReceiptDto.fromJson(Map<String, dynamic> json) {
    final rawAlloc = json['allocations'] as List<dynamic>?;
    final allocList = rawAlloc != null
        ? rawAlloc.map((e) => MemberAllocationDto.fromJson(e as Map<String, dynamic>)).toList()
        : <MemberAllocationDto>[];

    DateTime? date;
    if (json['contributionDate'] != null) {
      date = DateTime.tryParse(json['contributionDate'].toString());
    }

    return ElectronicReceiptDto(
      receiptNumber: (json['receiptNumber'] ?? '') as String,
      contributionId: (json['contributionId'] ?? '') as String,
      eventId: (json['eventId'] ?? '') as String,
      eventName: json['eventName'] as String?,
      payerMemberId: (json['payerMemberId'] ?? '') as String,
      payerMemberName: json['payerMemberName'] as String?,
      receiverAccountId: (json['receiverAccountId'] ?? 'ACC-TREASURER-01') as String,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      amountInWords: json['amountInWords'] as String?,
      paymentMethod: PaymentMethod.fromString(json['paymentMethod']?.toString()),
      contributionDate: date,
      allocations: allocList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptNumber': receiptNumber,
      'contributionId': contributionId,
      'eventId': eventId,
      'eventName': eventName,
      'payerMemberId': payerMemberId,
      'payerMemberName': payerMemberName,
      'receiverAccountId': receiverAccountId,
      'amount': amount,
      'amountInWords': amountInWords,
      'paymentMethod': paymentMethod.name,
      'contributionDate': contributionDate?.toIso8601String(),
      'allocations': allocations.map((e) => e.toJson()).toList(),
    };
  }
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

  factory InKindElectronicReceiptDto.fromJson(Map<String, dynamic> json) {
    final rawAlloc = json['allocations'] as List<dynamic>?;
    final allocList = rawAlloc != null
        ? rawAlloc.map((e) => MemberAllocationDto.fromJson(e as Map<String, dynamic>)).toList()
        : <MemberAllocationDto>[];

    DateTime? date;
    if (json['contributionDate'] != null) {
      date = DateTime.tryParse(json['contributionDate'].toString());
    }

    return InKindElectronicReceiptDto(
      receiptNumber: (json['receiptNumber'] ?? '') as String,
      contributionId: (json['contributionId'] ?? '') as String,
      eventId: (json['eventId'] ?? '') as String,
      eventName: json['eventName'] as String?,
      payerMemberId: (json['payerMemberId'] ?? '') as String,
      payerMemberName: json['payerMemberName'] as String?,
      receiverAccountId: (json['receiverAccountId'] ?? 'ACC-TREASURER-01') as String,
      itemName: (json['itemName'] ?? '') as String,
      quantity: ((json['quantity'] ?? 1) as num).toDouble(),
      unit: (json['unit'] ?? 'món') as String,
      conversionMethod: ConversionMethod.fromString(json['conversionMethod']?.toString()),
      convertedMonetaryValue: ((json['convertedMonetaryValue'] ?? 0) as num).toDouble(),
      convertedMonetaryValueInWords: json['convertedMonetaryValueInWords'] as String?,
      processingStatus: InKindProcessingStatus.fromString(json['processingStatus']?.toString()),
      storageLocation: json['storageLocation'] as String?,
      contributionDate: date,
      allocations: allocList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptNumber': receiptNumber,
      'contributionId': contributionId,
      'eventId': eventId,
      'eventName': eventName,
      'payerMemberId': payerMemberId,
      'payerMemberName': payerMemberName,
      'receiverAccountId': receiverAccountId,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'conversionMethod': conversionMethod.name,
      'convertedMonetaryValue': convertedMonetaryValue,
      'convertedMonetaryValueInWords': convertedMonetaryValueInWords,
      'processingStatus': processingStatus.name,
      'storageLocation': storageLocation,
      'contributionDate': contributionDate?.toIso8601String(),
      'allocations': allocations.map((e) => e.toJson()).toList(),
    };
  }

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

  factory ClanAssetDto.fromJson(Map<String, dynamic> json) {
    DateTime date = DateTime.now();
    if (json['createdAt'] != null) {
      date = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

    return ClanAssetDto(
      assetId: (json['assetId'] ?? '') as String,
      assetName: (json['assetName'] ?? '') as String,
      quantity: ((json['quantity'] ?? 1) as num).toInt(),
      unit: (json['unit'] ?? 'món') as String,
      assessedValue: ((json['assessedValue'] ?? 0) as num).toDouble(),
      storageLocation: (json['storageLocation'] ?? 'Nhà thờ từ đường tổ') as String,
      originContributionId: json['originContributionId'] as String?,
      originDonorName: json['originDonorName'] as String?,
      createdAt: date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'assetName': assetName,
      'quantity': quantity,
      'unit': unit,
      'assessedValue': assessedValue,
      'storageLocation': storageLocation,
      'originContributionId': originContributionId,
      'originDonorName': originDonorName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
