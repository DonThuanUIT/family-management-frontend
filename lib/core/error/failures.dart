/// Các lớp biểu diễn lỗi nghiệp vụ và hạ tầng trong tầng Domain (Clean Architecture).
sealed class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng.',
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ.',
    super.statusCode = 401,
  });
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    super.message = 'Bạn không có quyền thực hiện thao tác này (Dual-RBAC).',
    super.statusCode = 403,
  });
}

/// Lỗi vi phạm ràng buộc cứng nghiệp vụ (ví dụ: Chặn khóa sổ sự kiện khi còn
/// khoản quyết toán ở trạng thái `NeedsExplanation` hoặc chu trình cây phả hệ).
class BusinessInvariantFailure extends Failure {
  const BusinessInvariantFailure({
    required super.message,
    super.statusCode = 400,
  });
}
