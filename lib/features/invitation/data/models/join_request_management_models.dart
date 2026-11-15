import '../../../auth/data/models/auth_models.dart';

/// DTO gửi lên khi phê duyệt đơn xin gia nhập dòng họ (US-17 & US-33).
/// Cho phép Trưởng tộc / Trưởng chi nhánh điều chỉnh lại chi nhánh đích hoặc tên nhánh mới nếu ứng viên chọn nhầm.
class ApproveJoinRequestDto {
  final String? targetBranchId;
  final String? proposedNewBranchName;

  const ApproveJoinRequestDto({
    this.targetBranchId,
    this.proposedNewBranchName,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (targetBranchId != null && targetBranchId!.trim().isNotEmpty) {
      map['targetBranchId'] = targetBranchId!.trim();
    }
    if (proposedNewBranchName != null && proposedNewBranchName!.trim().isNotEmpty) {
      map['proposedNewBranchName'] = proposedNewBranchName!.trim();
    }
    return map;
  }
}

/// DTO gửi lên khi từ chối đơn xin gia nhập dòng họ (US-17 & US-33).
/// Bắt buộc phải có lý do từ chối (1 - 500 ký tự).
class RejectJoinRequestDto {
  final String rejectionReason;

  const RejectJoinRequestDto({
    required this.rejectionReason,
  });

  Map<String, dynamic> toJson() => {
        'rejectionReason': rejectionReason.trim(),
      };
}

/// Phân trang dữ liệu phản hồi từ Backend Spring Boot cho danh sách đơn gia nhập (`Page<JoinRequestResponse>`).
class JoinRequestPageDto {
  final List<JoinRequestResponseDto> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final int size;

  const JoinRequestPageDto({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });

  factory JoinRequestPageDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['content'];
    final List<JoinRequestResponseDto> items = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          items.add(JoinRequestResponseDto.fromJson(item));
        }
      }
    }

    return JoinRequestPageDto(
      content: items,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? items.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
    );
  }
}

/// Helper biểu diễn một lựa chọn phân nhánh phẳng cho dropdown
class FlattenedBranchOption {
  final String branchId;
  final String branchName;
  final int generationLevel;
  final String? representativeName;
  final int depth;

  const FlattenedBranchOption({
    required this.branchId,
    required this.branchName,
    required this.generationLevel,
    this.representativeName,
    this.depth = 0,
  });

  String get displayName {
    final indent = '  ' * depth;
    final prefix = depth > 0 ? '$indent└─ ' : '';
    return '$prefix$branchName (Đời $generationLevel)';
  }
}
