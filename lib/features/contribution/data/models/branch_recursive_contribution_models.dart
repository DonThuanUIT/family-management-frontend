// Model DTO ánh xạ dữ liệu tính toán đệ quy công đức từ Backend (US-11: tinhTongDongGopDeQuy).

class BranchRecursiveContributionDto {
  final String branchId;
  final String branchName;
  final int? generationLevel;
  final String? parentBranchId;
  final String? representativeId;
  final String? representativeName;
  final String? eventId;
  final String? eventName;
  final int? year;
  final int directMemberCount;
  final int totalRecursiveMemberCount;
  final int directContributingMemberCount;
  final int totalRecursiveContributingMemberCount;
  final int directContributionCount;
  final double directCashAmount;
  final double directInKindAmount;
  final double directTotalAmount;
  final double descendantsCashAmount;
  final double descendantsInKindAmount;
  final double descendantsTotalAmount;
  final double totalRecursiveCashAmount;
  final double totalRecursiveInKindAmount;
  final double totalRecursiveAmount;
  final String? totalRecursiveAmountInWords;
  final List<BranchRecursiveContributionDto> childBranches;

  const BranchRecursiveContributionDto({
    required this.branchId,
    required this.branchName,
    this.generationLevel,
    this.parentBranchId,
    this.representativeId,
    this.representativeName,
    this.eventId,
    this.eventName,
    this.year,
    this.directMemberCount = 0,
    this.totalRecursiveMemberCount = 0,
    this.directContributingMemberCount = 0,
    this.totalRecursiveContributingMemberCount = 0,
    this.directContributionCount = 0,
    this.directCashAmount = 0.0,
    this.directInKindAmount = 0.0,
    this.directTotalAmount = 0.0,
    this.descendantsCashAmount = 0.0,
    this.descendantsInKindAmount = 0.0,
    this.descendantsTotalAmount = 0.0,
    this.totalRecursiveCashAmount = 0.0,
    this.totalRecursiveInKindAmount = 0.0,
    this.totalRecursiveAmount = 0.0,
    this.totalRecursiveAmountInWords,
    this.childBranches = const [],
  });

  /// Tính phần trăm đóng góp trực tiếp của nhánh tự thân so với tổng đệ quy
  double get directPercentage {
    if (totalRecursiveAmount <= 0) return 0.0;
    return (directTotalAmount / totalRecursiveAmount) * 100.0;
  }

  /// Tính phần trăm đóng góp của các nhánh con cộng dồn so với tổng đệ quy
  double get descendantsPercentage {
    if (totalRecursiveAmount <= 0) return 0.0;
    return (descendantsTotalAmount / totalRecursiveAmount) * 100.0;
  }

  /// Kiểm tra xem nhánh có phát sinh đóng góp nào hay không
  bool get hasContribution => totalRecursiveAmount > 0;

  /// Kiểm tra xem nhánh có các nhánh con trực thuộc hay là nhánh lá
  bool get hasChildBranches => childBranches.isNotEmpty;

  factory BranchRecursiveContributionDto.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['childBranches'] as List<dynamic>?;
    final children = rawChildren != null
        ? rawChildren
            .map((e) => BranchRecursiveContributionDto.fromJson(e as Map<String, dynamic>))
            .toList()
        : <BranchRecursiveContributionDto>[];

    return BranchRecursiveContributionDto(
      branchId: (json['branchId'] ?? '') as String,
      branchName: (json['branchName'] ?? '') as String,
      generationLevel: json['generationLevel'] as int?,
      parentBranchId: json['parentBranchId'] as String?,
      representativeId: json['representativeId'] as String?,
      representativeName: json['representativeName'] as String?,
      eventId: json['eventId'] as String?,
      eventName: json['eventName'] as String?,
      year: json['year'] as int?,
      directMemberCount: ((json['directMemberCount'] ?? 0) as num).toInt(),
      totalRecursiveMemberCount: ((json['totalRecursiveMemberCount'] ?? 0) as num).toInt(),
      directContributingMemberCount: ((json['directContributingMemberCount'] ?? 0) as num).toInt(),
      totalRecursiveContributingMemberCount: ((json['totalRecursiveContributingMemberCount'] ?? 0) as num).toInt(),
      directContributionCount: ((json['directContributionCount'] ?? 0) as num).toInt(),
      directCashAmount: ((json['directCashAmount'] ?? 0) as num).toDouble(),
      directInKindAmount: ((json['directInKindAmount'] ?? 0) as num).toDouble(),
      directTotalAmount: ((json['directTotalAmount'] ?? 0) as num).toDouble(),
      descendantsCashAmount: ((json['descendantsCashAmount'] ?? 0) as num).toDouble(),
      descendantsInKindAmount: ((json['descendantsInKindAmount'] ?? 0) as num).toDouble(),
      descendantsTotalAmount: ((json['descendantsTotalAmount'] ?? 0) as num).toDouble(),
      totalRecursiveCashAmount: ((json['totalRecursiveCashAmount'] ?? 0) as num).toDouble(),
      totalRecursiveInKindAmount: ((json['totalRecursiveInKindAmount'] ?? 0) as num).toDouble(),
      totalRecursiveAmount: ((json['totalRecursiveAmount'] ?? 0) as num).toDouble(),
      totalRecursiveAmountInWords: json['totalRecursiveAmountInWords'] as String?,
      childBranches: children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'generationLevel': generationLevel,
      'parentBranchId': parentBranchId,
      'representativeId': representativeId,
      'representativeName': representativeName,
      'eventId': eventId,
      'eventName': eventName,
      'year': year,
      'directMemberCount': directMemberCount,
      'totalRecursiveMemberCount': totalRecursiveMemberCount,
      'directContributingMemberCount': directContributingMemberCount,
      'totalRecursiveContributingMemberCount': totalRecursiveContributingMemberCount,
      'directContributionCount': directContributionCount,
      'directCashAmount': directCashAmount,
      'directInKindAmount': directInKindAmount,
      'directTotalAmount': directTotalAmount,
      'descendantsCashAmount': descendantsCashAmount,
      'descendantsInKindAmount': descendantsInKindAmount,
      'descendantsTotalAmount': descendantsTotalAmount,
      'totalRecursiveCashAmount': totalRecursiveCashAmount,
      'totalRecursiveInKindAmount': totalRecursiveInKindAmount,
      'totalRecursiveAmount': totalRecursiveAmount,
      'totalRecursiveAmountInWords': totalRecursiveAmountInWords,
      'childBranches': childBranches.map((e) => e.toJson()).toList(),
    };
  }
}
