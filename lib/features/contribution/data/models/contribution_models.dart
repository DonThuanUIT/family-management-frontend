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

/// DTO Lịch sử đóng góp cá nhân & gia đình (US-49, Task #175)
class MemberContributionHistoryResponseDto {
  final String memberId;
  final String memberName;
  final String? branchId;
  final String? branchName;
  final String? clanId;
  final double totalPersonalContributed;
  final double totalAllocated;
  final List<MemberContributionHistoryItemDto> items;

  const MemberContributionHistoryResponseDto({
    required this.memberId,
    required this.memberName,
    this.branchId,
    this.branchName,
    this.clanId,
    required this.totalPersonalContributed,
    required this.totalAllocated,
    required this.items,
  });

  factory MemberContributionHistoryResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return MemberContributionHistoryResponseDto(
      memberId: (json['memberId'] ?? '') as String,
      memberName: (json['memberName'] ?? '') as String,
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      clanId: json['clanId'] as String?,
      totalPersonalContributed: ((json['totalPersonalContributed'] ?? 0) as num).toDouble(),
      totalAllocated: ((json['totalAllocated'] ?? 0) as num).toDouble(),
      items: rawItems.map((e) => MemberContributionHistoryItemDto.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class MemberContributionHistoryItemDto {
  final String contributionId;
  final String receiptNumber;
  final String eventId;
  final String? eventName;
  final String payerMemberId;
  final String? payerMemberName;
  final String contributionType;
  final PaymentMethod paymentMethod;
  final String? itemName;
  final double quantity;
  final String? unit;
  final double totalMonetaryValue;
  final double myAllocatedAmount;
  final String status;
  final DateTime? contributionDate;

  const MemberContributionHistoryItemDto({
    required this.contributionId,
    required this.receiptNumber,
    required this.eventId,
    this.eventName,
    required this.payerMemberId,
    this.payerMemberName,
    required this.contributionType,
    required this.paymentMethod,
    this.itemName,
    required this.quantity,
    this.unit,
    required this.totalMonetaryValue,
    required this.myAllocatedAmount,
    required this.status,
    this.contributionDate,
  });

  factory MemberContributionHistoryItemDto.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    if (json['contributionDate'] != null) {
      date = DateTime.tryParse(json['contributionDate'].toString());
    }

    return MemberContributionHistoryItemDto(
      contributionId: (json['contributionId'] ?? '') as String,
      receiptNumber: (json['receiptNumber'] ?? '') as String,
      eventId: (json['eventId'] ?? '') as String,
      eventName: json['eventName'] as String?,
      payerMemberId: (json['payerMemberId'] ?? '') as String,
      payerMemberName: json['payerMemberName'] as String?,
      contributionType: (json['contributionType'] ?? 'Cash') as String,
      paymentMethod: PaymentMethod.fromString(json['paymentMethod']?.toString()),
      itemName: json['itemName'] as String?,
      quantity: ((json['quantity'] ?? 1) as num).toDouble(),
      unit: json['unit'] as String?,
      totalMonetaryValue: ((json['totalMonetaryValue'] ?? 0) as num).toDouble(),
      myAllocatedAmount: ((json['myAllocatedAmount'] ?? 0) as num).toDouble(),
      status: (json['status'] ?? 'Completed') as String,
      contributionDate: date,
    );
  }
}

/// DTO Giao dịch chuyển khoản chưa đối soát (US-50, Task #178)
class UnreconciledContributionDto {
  final String contributionId;
  final String receiptNumber;
  final String eventId;
  final String? eventName;
  final String payerMemberId;
  final String? payerMemberName;
  final double amount;
  final String? amountInWords;
  final DateTime? contributionDate;
  final String? bankTransactionCode;
  final String? transferProofUrl;
  final bool isReconciled;

  const UnreconciledContributionDto({
    required this.contributionId,
    required this.receiptNumber,
    required this.eventId,
    this.eventName,
    required this.payerMemberId,
    this.payerMemberName,
    required this.amount,
    this.amountInWords,
    this.contributionDate,
    this.bankTransactionCode,
    this.transferProofUrl,
    this.isReconciled = false,
  });

  factory UnreconciledContributionDto.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    if (json['contributionDate'] != null) {
      date = DateTime.tryParse(json['contributionDate'].toString());
    }

    return UnreconciledContributionDto(
      contributionId: (json['contributionId'] ?? '') as String,
      receiptNumber: (json['receiptNumber'] ?? '') as String,
      eventId: (json['eventId'] ?? '') as String,
      eventName: json['eventName'] as String?,
      payerMemberId: (json['payerMemberId'] ?? '') as String,
      payerMemberName: json['payerMemberName'] as String?,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      amountInWords: json['amountInWords'] as String?,
      contributionDate: date,
      bankTransactionCode: json['bankTransactionCode'] as String?,
      transferProofUrl: json['transferProofUrl'] as String?,
      isReconciled: json['isReconciled'] == true,
    );
  }
}

/// Request DTO Xác nhận đối soát ngân hàng (US-50, Task #178)
class ReconcileContributionRequestDto {
  final String bankTransactionCode;
  final String? transferProofUrl;
  final String? note;

  const ReconcileContributionRequestDto({
    required this.bankTransactionCode,
    this.transferProofUrl,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'bankTransactionCode': bankTransactionCode.trim(),
      if (transferProofUrl != null && transferProofUrl!.trim().isNotEmpty)
        'transferProofUrl': transferProofUrl!.trim()
      else
        'transferProofUrl': null,
      if (note != null && note!.trim().isNotEmpty)
        'note': note!.trim()
      else
        'note': null,
    };
  }
}

/// Request DTO Cập nhật kiểm kê tài sản định kỳ (US-52, Task #184)
class AuditClanAssetRequestDto {
  final int actualQuantity;
  final String conditionStatus;
  final String? storageLocation;
  final String? notes;

  const AuditClanAssetRequestDto({
    required this.actualQuantity,
    required this.conditionStatus,
    this.storageLocation,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'actualQuantity': actualQuantity,
      'conditionStatus': conditionStatus.trim(),
      if (storageLocation != null && storageLocation!.trim().isNotEmpty)
        'storageLocation': storageLocation!.trim()
      else
        'storageLocation': null,
      if (notes != null && notes!.trim().isNotEmpty)
        'notes': notes!.trim()
      else
        'notes': null,
    };
  }
}

/// DTO Lịch sử kiểm kê tài sản (US-52, Task #184)
class ClanAssetAuditResponseDto {
  final String auditId;
  final String assetId;
  final DateTime? auditDate;
  final int previousQuantity;
  final int actualQuantity;
  final String previousCondition;
  final String conditionStatus;
  final String? storageLocation;
  final String? auditorAccountId;
  final String? notes;
  final DateTime? createdAt;

  const ClanAssetAuditResponseDto({
    required this.auditId,
    required this.assetId,
    this.auditDate,
    required this.previousQuantity,
    required this.actualQuantity,
    required this.previousCondition,
    required this.conditionStatus,
    this.storageLocation,
    this.auditorAccountId,
    this.notes,
    this.createdAt,
  });

  factory ClanAssetAuditResponseDto.fromJson(Map<String, dynamic> json) {
    DateTime? aDate;
    if (json['auditDate'] != null) {
      aDate = DateTime.tryParse(json['auditDate'].toString());
    }
    DateTime? cDate;
    if (json['createdAt'] != null) {
      cDate = DateTime.tryParse(json['createdAt'].toString());
    }

    return ClanAssetAuditResponseDto(
      auditId: (json['auditId'] ?? '') as String,
      assetId: (json['assetId'] ?? '') as String,
      auditDate: aDate,
      previousQuantity: ((json['previousQuantity'] ?? 0) as num).toInt(),
      actualQuantity: ((json['actualQuantity'] ?? 0) as num).toInt(),
      previousCondition: (json['previousCondition'] ?? 'Good') as String,
      conditionStatus: (json['conditionStatus'] ?? 'Good') as String,
      storageLocation: json['storageLocation'] as String?,
      auditorAccountId: json['auditorAccountId'] as String?,
      notes: json['notes'] as String?,
      createdAt: cDate,
    );
  }
}

/// Request DTO Sinh mã VietQR động đóng góp trực tuyến (US-53, Task #187)
class GenerateVietQrRequestDto {
  final String eventId;
  final String? memberId;
  final double amount;
  final String? note;

  const GenerateVietQrRequestDto({
    required this.eventId,
    this.memberId,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId.trim(),
      if (memberId != null && memberId!.trim().isNotEmpty)
        'memberId': memberId!.trim()
      else
        'memberId': null,
      'amount': amount,
      if (note != null && note!.trim().isNotEmpty)
        'note': note!.trim()
      else
        'note': null,
    };
  }
}

/// DTO Chi tiết mã VietQR sinh ra (US-53, Task #187)
class VietQrResponseDto {
  final String qrCodeUrl;
  final String qrPayload;
  final String bankBin;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final double amount;
  final String transferContent;
  final String eventId;
  final String? eventName;
  final String? memberId;
  final String? memberName;

  const VietQrResponseDto({
    required this.qrCodeUrl,
    required this.qrPayload,
    required this.bankBin,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.transferContent,
    required this.eventId,
    this.eventName,
    this.memberId,
    this.memberName,
  });

  factory VietQrResponseDto.fromJson(Map<String, dynamic> json) {
    return VietQrResponseDto(
      qrCodeUrl: (json['qrCodeUrl'] ?? '') as String,
      qrPayload: (json['qrPayload'] ?? '') as String,
      bankBin: (json['bankBin'] ?? '') as String,
      bankName: (json['bankName'] ?? '') as String,
      accountNumber: (json['accountNumber'] ?? '') as String,
      accountName: (json['accountName'] ?? '') as String,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      transferContent: (json['transferContent'] ?? '') as String,
      eventId: (json['eventId'] ?? '') as String,
      eventName: json['eventName'] as String?,
      memberId: json['memberId'] as String?,
      memberName: json['memberName'] as String?,
    );
  }
}

/// DTO Kiểm tra chốt hiện vật sự kiện (US-51, Task #181)
class EventPendingInKindCheckResponseDto {
  final String eventId;
  final String? eventName;
  final bool hasPendingItems;
  final int pendingCount;
  final String warningMessage;

  const EventPendingInKindCheckResponseDto({
    required this.eventId,
    this.eventName,
    required this.hasPendingItems,
    required this.pendingCount,
    required this.warningMessage,
  });

  factory EventPendingInKindCheckResponseDto.fromJson(Map<String, dynamic> json) {
    return EventPendingInKindCheckResponseDto(
      eventId: (json['eventId'] ?? '') as String,
      eventName: json['eventName'] as String?,
      hasPendingItems: json['hasPendingItems'] == true,
      pendingCount: ((json['pendingCount'] ?? 0) as num).toInt(),
      warningMessage: (json['warningMessage'] ?? '') as String,
    );
  }
}

