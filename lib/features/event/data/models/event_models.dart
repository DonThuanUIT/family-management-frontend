import 'package:intl/intl.dart';
import '../../../../core/security/rbac_models.dart';

/// Model nhân sự ban tổ chức được chỉ định cho sự kiện (`event_personnel`).
class EventPersonnelModel {
  final String memberId;
  final String? memberName;
  final String eventRole; // 'HeadOfOrganizer', 'EventTreasurer', 'OrganizerMember'
  final bool isReadOnly;
  final DateTime? assignedAt;

  const EventPersonnelModel({
    required this.memberId,
    this.memberName,
    required this.eventRole,
    this.isReadOnly = false,
    this.assignedAt,
  });

  EventContextualRole? get roleEnum => EventContextualRole.fromCode(eventRole);

  String get roleDisplayName {
    return roleEnum?.displayName ?? eventRole;
  }

  factory EventPersonnelModel.fromJson(Map<String, dynamic> json) {
    return EventPersonnelModel(
      memberId: (json['memberId'] as String?) ?? '',
      memberName: json['memberName'] as String?,
      eventRole: (json['eventRole'] as String?) ?? '',
      isReadOnly: (json['isReadOnly'] as bool?) ?? false,
      assignedAt: json['assignedAt'] != null
          ? DateTime.tryParse(json['assignedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'eventRole': eventRole,
      };
}

/// Model bản ghi thông báo sự kiện (`event_notifications` - US-22).
class EventNotificationModel {
  final String notificationId;
  final String eventId;
  final String title;
  final String? contentChanges;
  final DateTime sentTime;
  final String? triggeredBy;

  const EventNotificationModel({
    required this.notificationId,
    required this.eventId,
    required this.title,
    this.contentChanges,
    required this.sentTime,
    this.triggeredBy,
  });

  factory EventNotificationModel.fromJson(Map<String, dynamic> json) {
    return EventNotificationModel(
      notificationId: (json['notificationId'] as String?) ?? '',
      eventId: (json['eventId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      contentChanges: json['contentChanges'] as String?,
      sentTime: json['sentTime'] != null
          ? DateTime.tryParse(json['sentTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      triggeredBy: json['triggeredBy'] as String?,
    );
  }

  String get formattedSentTime {
    return DateFormat('HH:mm - dd/MM/yyyy').format(sentTime);
  }
}

/// Model Sự Kiện Dòng Họ (`events`).
class EventModel {
  final String eventId;
  final String eventName;
  final String? description;
  final DateTime eventDatetime;
  final String? eventDateLunar;
  final String location;
  final double estimatedBudget;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final List<EventPersonnelModel> personnel;

  // Metadata mở rộng phục vụ hiển thị UI sinh động
  final int registeredHouseholds;
  final int banquetTables;
  final int completedTasks;
  final int totalTasks;
  final double donatedAmount;

  const EventModel({
    required this.eventId,
    required this.eventName,
    this.description,
    required this.eventDatetime,
    this.eventDateLunar,
    required this.location,
    this.estimatedBudget = 0.0,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
    this.personnel = const [],
    this.registeredHouseholds = 0,
    this.banquetTables = 0,
    this.completedTasks = 0,
    this.totalTasks = 0,
    this.donatedAmount = 0.0,
  });

  EventLifecycleStatus get lifecycleStatus =>
      EventLifecycleStatus.fromCode(status);

  bool get isClosed => lifecycleStatus == EventLifecycleStatus.closed;

  String get formattedSolarDate {
    return DateFormat('dd/MM/yyyy').format(eventDatetime);
  }

  String get formattedSolarTime {
    return DateFormat('HH:mm').format(eventDatetime);
  }

  String get formattedSolarDayMonth {
    return DateFormat('dd/MM').format(eventDatetime);
  }

  String get formattedBudgetMillion {
    if (estimatedBudget <= 0) return '0 Tr';
    final million = estimatedBudget / 1000000;
    return '${million.toStringAsFixed(million.truncateToDouble() == million ? 0 : 1)} Tr';
  }

  String get formattedDonatedMillion {
    if (donatedAmount <= 0) return '0 Tr';
    final million = donatedAmount / 1000000;
    return '${million.toStringAsFixed(million.truncateToDouble() == million ? 0 : 1)} Tr';
  }

  double get taskProgress {
    if (totalTasks <= 0) return 0.0;
    return (completedTasks / totalTasks).clamp(0.0, 1.0);
  }

  /// Tìm Trưởng Ban Tổ Chức
  EventPersonnelModel? get headOfOrganizer {
    for (final p in personnel) {
      if (p.eventRole == 'HeadOfOrganizer') return p;
    }
    return null;
  }

  /// Tìm Thủ Quỹ Sự Kiện
  EventPersonnelModel? get eventTreasurer {
    for (final p in personnel) {
      if (p.eventRole == 'EventTreasurer') return p;
    }
    return null;
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final personnelList = (json['personnel'] as List<dynamic>?)
            ?.map((e) => EventPersonnelModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final estimatedBudgetNum = json['estimatedBudget'];
    final double budget = estimatedBudgetNum is num
        ? estimatedBudgetNum.toDouble()
        : double.tryParse(estimatedBudgetNum?.toString() ?? '0') ?? 0.0;

    return EventModel(
      eventId: (json['eventId'] as String?) ?? '',
      eventName: (json['eventName'] as String?) ?? '',
      description: json['description'] as String?,
      eventDatetime: json['eventDatetime'] != null
          ? DateTime.tryParse(json['eventDatetime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      eventDateLunar: json['eventDateLunar'] as String?,
      location: (json['location'] as String?) ?? '',
      estimatedBudget: budget,
      status: (json['status'] as String?) ?? 'Draft',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      personnel: personnelList,
      registeredHouseholds: (json['registeredHouseholds'] as num?)?.toInt() ?? 0,
      banquetTables: (json['banquetTables'] as num?)?.toInt() ?? 0,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? 0,
      donatedAmount: (json['donatedAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventName': eventName,
        'description': description,
        'eventDatetime': eventDatetime.toIso8601String(),
        'eventDateLunar': eventDateLunar,
        'location': location,
        'estimatedBudget': estimatedBudget,
        'status': status,
      };

  EventModel copyWith({
    String? eventName,
    String? description,
    DateTime? eventDatetime,
    String? eventDateLunar,
    String? location,
    double? estimatedBudget,
    String? status,
    List<EventPersonnelModel>? personnel,
    int? registeredHouseholds,
    int? banquetTables,
    int? completedTasks,
    int? totalTasks,
    double? donatedAmount,
  }) {
    return EventModel(
      eventId: eventId,
      eventName: eventName ?? this.eventName,
      description: description ?? this.description,
      eventDatetime: eventDatetime ?? this.eventDatetime,
      eventDateLunar: eventDateLunar ?? this.eventDateLunar,
      location: location ?? this.location,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      closedAt: status == 'Closed' ? (closedAt ?? DateTime.now()) : closedAt,
      personnel: personnel ?? this.personnel,
      registeredHouseholds: registeredHouseholds ?? this.registeredHouseholds,
      banquetTables: banquetTables ?? this.banquetTables,
      completedTasks: completedTasks ?? this.completedTasks,
      totalTasks: totalTasks ?? this.totalTasks,
      donatedAmount: donatedAmount ?? this.donatedAmount,
    );
  }
}

/// DTO khởi tạo sự kiện mới (`POST /api/v1/events`).
class CreateEventRequestDto {
  final String eventName;
  final String? description;
  final DateTime eventDatetime;
  final String? eventDateLunar;
  final String location;
  final double estimatedBudget;
  final String? headOfOrganizerMemberId;
  final String? treasurerMemberId;

  const CreateEventRequestDto({
    required this.eventName,
    this.description,
    required this.eventDatetime,
    this.eventDateLunar,
    required this.location,
    this.estimatedBudget = 0.0,
    this.headOfOrganizerMemberId,
    this.treasurerMemberId,
  });

  Map<String, dynamic> toJson() => {
        'eventName': eventName.trim(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        'eventDatetime': eventDatetime.toUtc().toIso8601String(),
        if (eventDateLunar != null && eventDateLunar!.trim().isNotEmpty)
          'eventDateLunar': eventDateLunar!.trim(),
        'location': location.trim(),
        'estimatedBudget': estimatedBudget,
      };
}

/// DTO cập nhật sự kiện (`PUT /api/v1/events/{eventId}` - US-22).
class UpdateEventRequestDto {
  final String eventName;
  final String? description;
  final DateTime eventDatetime;
  final String? eventDateLunar;
  final String location;
  final double estimatedBudget;

  const UpdateEventRequestDto({
    required this.eventName,
    this.description,
    required this.eventDatetime,
    this.eventDateLunar,
    required this.location,
    this.estimatedBudget = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'eventName': eventName.trim(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
        'eventDatetime': eventDatetime.toUtc().toIso8601String(),
        if (eventDateLunar != null && eventDateLunar!.trim().isNotEmpty)
          'eventDateLunar': eventDateLunar!.trim(),
        'location': location.trim(),
        'estimatedBudget': estimatedBudget,
      };
}

/// DTO chuyển đổi trạng thái vòng đời (`PATCH /api/v1/events/{eventId}/status`).
class UpdateEventStatusRequestDto {
  final String newStatus;

  const UpdateEventStatusRequestDto({required this.newStatus});

  Map<String, dynamic> toJson() => {
        'newStatus': newStatus,
      };
}

/// DTO chỉ định nhân sự (`POST /api/v1/events/{eventId}/personnel`).
class AssignPersonnelRequestDto {
  final String memberId;
  final String eventRole;

  const AssignPersonnelRequestDto({
    required this.memberId,
    required this.eventRole,
  });

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'eventRole': eventRole,
      };
}
