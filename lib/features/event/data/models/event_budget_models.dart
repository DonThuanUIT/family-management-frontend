import 'package:intl/intl.dart';

/// DTO phản hồi tình hình ngân sách ở cấp từng hạng mục công việc (US-37).
class TaskBudgetBreakdownModel {
  final String taskId;
  final String taskName;
  final String taskStatus;
  final String? assignedMemberId;
  final String? assignedBranchId;
  final double advanceBudget;
  final double advanceAmount;
  final double actualExpenseAmount;
  final double verifiedActualExpenseAmount;
  final int advanceVoucherCount;
  final int settlementVoucherCount;
  final int needsExplanationCount;
  final double advanceVariance;
  final double actualExpenseVariance;
  final bool isAdvanceOverTaskBudget;
  final bool isActualExpenseOverTaskBudget;
  final bool isOverTaskBudget;

  const TaskBudgetBreakdownModel({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    this.assignedMemberId,
    this.assignedBranchId,
    required this.advanceBudget,
    required this.advanceAmount,
    required this.actualExpenseAmount,
    required this.verifiedActualExpenseAmount,
    required this.advanceVoucherCount,
    required this.settlementVoucherCount,
    required this.needsExplanationCount,
    required this.advanceVariance,
    required this.actualExpenseVariance,
    required this.isAdvanceOverTaskBudget,
    required this.isActualExpenseOverTaskBudget,
    required this.isOverTaskBudget,
  });

  /// Tính tổng số tiền đã tiêu dùng hoặc tạm ứng của task này
  double get totalCommitted => advanceAmount + actualExpenseAmount;

  /// Tỷ lệ phần trăm sử dụng so với định mức của task (advanceBudget)
  double get utilizationPercent {
    if (advanceBudget <= 0) {
      return (totalCommitted > 0) ? 100.0 : 0.0;
    }
    final raw = (totalCommitted / advanceBudget) * 100.0;
    return (raw * 10).roundToDouble() / 10;
  }

  /// Trạng thái phân loại: 'CRITICAL', 'WARNING' (>90%), 'SAFE'
  String get alertCategory {
    if (isOverTaskBudget || utilizationPercent > 100.0) {
      return 'CRITICAL';
    }
    if (utilizationPercent >= 90.0) {
      return 'WARNING';
    }
    return 'SAFE';
  }

  String get formattedBudget => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(advanceBudget);
  String get formattedActual => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(actualExpenseAmount);
  String get formattedAdvance => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(advanceAmount);

  factory TaskBudgetBreakdownModel.fromJson(Map<String, dynamic> json) {
    return TaskBudgetBreakdownModel(
      taskId: json['taskId']?.toString() ?? '',
      taskName: json['taskName']?.toString() ?? '',
      taskStatus: json['taskStatus']?.toString() ?? '',
      assignedMemberId: json['assignedMemberId']?.toString(),
      assignedBranchId: json['assignedBranchId']?.toString(),
      advanceBudget: (json['advanceBudget'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (json['advanceAmount'] as num?)?.toDouble() ?? 0.0,
      actualExpenseAmount: (json['actualExpenseAmount'] as num?)?.toDouble() ?? 0.0,
      verifiedActualExpenseAmount: (json['verifiedActualExpenseAmount'] as num?)?.toDouble() ?? 0.0,
      advanceVoucherCount: (json['advanceVoucherCount'] as num?)?.toInt() ?? 0,
      settlementVoucherCount: (json['settlementVoucherCount'] as num?)?.toInt() ?? 0,
      needsExplanationCount: (json['needsExplanationCount'] as num?)?.toInt() ?? 0,
      advanceVariance: (json['advanceVariance'] as num?)?.toDouble() ?? 0.0,
      actualExpenseVariance: (json['actualExpenseVariance'] as num?)?.toDouble() ?? 0.0,
      isAdvanceOverTaskBudget: json['isAdvanceOverTaskBudget'] == true,
      isActualExpenseOverTaskBudget: json['isActualExpenseOverTaskBudget'] == true,
      isOverTaskBudget: json['isOverTaskBudget'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskName': taskName,
      'taskStatus': taskStatus,
      'assignedMemberId': assignedMemberId,
      'assignedBranchId': assignedBranchId,
      'advanceBudget': advanceBudget,
      'advanceAmount': advanceAmount,
      'actualExpenseAmount': actualExpenseAmount,
      'verifiedActualExpenseAmount': verifiedActualExpenseAmount,
      'advanceVoucherCount': advanceVoucherCount,
      'settlementVoucherCount': settlementVoucherCount,
      'needsExplanationCount': needsExplanationCount,
      'advanceVariance': advanceVariance,
      'actualExpenseVariance': actualExpenseVariance,
      'isAdvanceOverTaskBudget': isAdvanceOverTaskBudget,
      'isActualExpenseOverTaskBudget': isActualExpenseOverTaskBudget,
      'isOverTaskBudget': isOverTaskBudget,
    };
  }
}

/// DTO tổng hợp và đối chiếu toàn diện ngân sách sự kiện với tạm ứng và thực chi (US-37).
class EventBudgetSummaryModel {
  final String eventId;
  final String eventName;
  final String eventStatus;
  final double estimatedBudget;
  final double totalAdvanceBudget;
  final double totalAdvanceAmount;
  final double totalActualExpenseAmount;
  final double verifiedActualExpenseAmount;
  final double unallocatedBudget;
  final double remainingBudgetByAdvance;
  final double remainingBudgetByActualExpense;
  final double overrunAmount;
  final double taskBudgetUtilizationPercent;
  final double advanceUtilizationPercent;
  final double actualExpenseUtilizationPercent;
  final bool isOverBudget;
  final bool isAdvanceOverEstimated;
  final bool isActualExpenseOverEstimated;
  final bool isTaskBudgetOverEstimated;
  final bool hasTaskOverBudget;
  final String warningLevel;
  final List<String> warningMessages;
  final int totalTaskCount;
  final int totalAdvanceVoucherCount;
  final int totalSettlementVoucherCount;
  final int needsExplanationVoucherCount;
  final List<TaskBudgetBreakdownModel> taskBreakdowns;

  const EventBudgetSummaryModel({
    required this.eventId,
    required this.eventName,
    required this.eventStatus,
    required this.estimatedBudget,
    required this.totalAdvanceBudget,
    required this.totalAdvanceAmount,
    required this.totalActualExpenseAmount,
    required this.verifiedActualExpenseAmount,
    required this.unallocatedBudget,
    required this.remainingBudgetByAdvance,
    required this.remainingBudgetByActualExpense,
    required this.overrunAmount,
    required this.taskBudgetUtilizationPercent,
    required this.advanceUtilizationPercent,
    required this.actualExpenseUtilizationPercent,
    required this.isOverBudget,
    required this.isAdvanceOverEstimated,
    required this.isActualExpenseOverEstimated,
    required this.isTaskBudgetOverEstimated,
    required this.hasTaskOverBudget,
    required this.warningLevel,
    required this.warningMessages,
    required this.totalTaskCount,
    required this.totalAdvanceVoucherCount,
    required this.totalSettlementVoucherCount,
    required this.needsExplanationVoucherCount,
    required this.taskBreakdowns,
  });

  /// Tổng số tiền thực chi cộng với tạm ứng lưu động đang giải ngân
  double get totalCommittedAmount => totalActualExpenseAmount + totalAdvanceAmount;

  /// Tỷ lệ tiêu dùng tổng thể so với dự toán (estimatedBudget)
  double get totalUtilizationPercent {
    if (estimatedBudget <= 0) {
      return (totalCommittedAmount > 0) ? 100.0 : 0.0;
    }
    final raw = (totalCommittedAmount / estimatedBudget) * 100.0;
    return (raw * 10).roundToDouble() / 10;
  }

  /// Số tiền chênh lệch khả dụng: nếu âm tức là vượt trần
  double get netRemainingBudget => estimatedBudget - totalCommittedAmount;

  String get formattedEstimated => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(estimatedBudget);
  String get formattedActual => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalActualExpenseAmount);
  String get formattedAdvance => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalAdvanceAmount);
  String get formattedOverrun => NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(overrunAmount);

  factory EventBudgetSummaryModel.fromJson(Map<String, dynamic> json) {
    var rawTasks = json['taskBreakdowns'] as List<dynamic>?;
    List<TaskBudgetBreakdownModel> parsedTasks = [];
    if (rawTasks != null) {
      parsedTasks = rawTasks
          .map((item) => TaskBudgetBreakdownModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    var rawWarnings = json['warningMessages'] as List<dynamic>?;
    List<String> parsedWarnings = [];
    if (rawWarnings != null) {
      parsedWarnings = rawWarnings.map((w) => w.toString()).toList();
    }

    return EventBudgetSummaryModel(
      eventId: json['eventId']?.toString() ?? '',
      eventName: json['eventName']?.toString() ?? '',
      eventStatus: json['eventStatus']?.toString() ?? '',
      estimatedBudget: (json['estimatedBudget'] as num?)?.toDouble() ?? 0.0,
      totalAdvanceBudget: (json['totalAdvanceBudget'] as num?)?.toDouble() ?? 0.0,
      totalAdvanceAmount: (json['totalAdvanceAmount'] as num?)?.toDouble() ?? 0.0,
      totalActualExpenseAmount: (json['totalActualExpenseAmount'] as num?)?.toDouble() ?? 0.0,
      verifiedActualExpenseAmount: (json['verifiedActualExpenseAmount'] as num?)?.toDouble() ?? 0.0,
      unallocatedBudget: (json['unallocatedBudget'] as num?)?.toDouble() ?? 0.0,
      remainingBudgetByAdvance: (json['remainingBudgetByAdvance'] as num?)?.toDouble() ?? 0.0,
      remainingBudgetByActualExpense: (json['remainingBudgetByActualExpense'] as num?)?.toDouble() ?? 0.0,
      overrunAmount: (json['overrunAmount'] as num?)?.toDouble() ?? 0.0,
      taskBudgetUtilizationPercent: (json['taskBudgetUtilizationPercent'] as num?)?.toDouble() ?? 0.0,
      advanceUtilizationPercent: (json['advanceUtilizationPercent'] as num?)?.toDouble() ?? 0.0,
      actualExpenseUtilizationPercent: (json['actualExpenseUtilizationPercent'] as num?)?.toDouble() ?? 0.0,
      isOverBudget: json['isOverBudget'] == true,
      isAdvanceOverEstimated: json['isAdvanceOverEstimated'] == true,
      isActualExpenseOverEstimated: json['isActualExpenseOverEstimated'] == true,
      isTaskBudgetOverEstimated: json['isTaskBudgetOverEstimated'] == true,
      hasTaskOverBudget: json['hasTaskOverBudget'] == true,
      warningLevel: json['warningLevel']?.toString() ?? 'NORMAL',
      warningMessages: parsedWarnings,
      totalTaskCount: (json['totalTaskCount'] as num?)?.toInt() ?? 0,
      totalAdvanceVoucherCount: (json['totalAdvanceVoucherCount'] as num?)?.toInt() ?? 0,
      totalSettlementVoucherCount: (json['totalSettlementVoucherCount'] as num?)?.toInt() ?? 0,
      needsExplanationVoucherCount: (json['needsExplanationVoucherCount'] as num?)?.toInt() ?? 0,
      taskBreakdowns: parsedTasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'eventStatus': eventStatus,
      'estimatedBudget': estimatedBudget,
      'totalAdvanceBudget': totalAdvanceBudget,
      'totalAdvanceAmount': totalAdvanceAmount,
      'totalActualExpenseAmount': totalActualExpenseAmount,
      'verifiedActualExpenseAmount': verifiedActualExpenseAmount,
      'unallocatedBudget': unallocatedBudget,
      'remainingBudgetByAdvance': remainingBudgetByAdvance,
      'remainingBudgetByActualExpense': remainingBudgetByActualExpense,
      'overrunAmount': overrunAmount,
      'taskBudgetUtilizationPercent': taskBudgetUtilizationPercent,
      'advanceUtilizationPercent': advanceUtilizationPercent,
      'actualExpenseUtilizationPercent': actualExpenseUtilizationPercent,
      'isOverBudget': isOverBudget,
      'isAdvanceOverEstimated': isAdvanceOverEstimated,
      'isActualExpenseOverEstimated': isActualExpenseOverEstimated,
      'isTaskBudgetOverEstimated': isTaskBudgetOverEstimated,
      'hasTaskOverBudget': hasTaskOverBudget,
      'warningLevel': warningLevel,
      'warningMessages': warningMessages,
      'totalTaskCount': totalTaskCount,
      'totalAdvanceVoucherCount': totalAdvanceVoucherCount,
      'totalSettlementVoucherCount': totalSettlementVoucherCount,
      'needsExplanationVoucherCount': needsExplanationVoucherCount,
      'taskBreakdowns': taskBreakdowns.map((t) => t.toJson()).toList(),
    };
  }
}
