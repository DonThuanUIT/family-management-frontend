import 'package:flutter/material.dart';

/// Chuyển đổi các ngoại lệ hệ thống (DioException, Exception, Socket...) thành thông điệp thân thiện với người dùng
String formatErrorMessage(dynamic error) {
  if (error == null) return 'Đã có lỗi không xác định xảy ra.';
  if (error is String) return error;

  final str = error.toString();
  // Nhận diện mã HTTP phổ biến từ DioException
  if (str.contains('401')) {
    return 'Phiên đăng nhập đã hết hạn hoặc tài khoản chưa được phân quyền (Mã 401).\nVui lòng đăng nhập lại để tiếp tục!';
  }
  if (str.contains('403')) {
    return 'Bạn không có quyền thực hiện thao tác này (Mã 403).\nVui lòng liên hệ Trưởng tộc hoặc Ban quản trị dòng họ!';
  }
  if (str.contains('404')) {
    return 'Không tìm thấy dữ liệu yêu cầu trên hệ thống máy chủ (Mã 404).';
  }
  if (str.contains('500')) {
    return 'Máy chủ đang gặp sự cố nội bộ khi xử lý (Mã 500).\nVui lòng thử lại sau giây lát!';
  }
  if (str.contains('SocketException') ||
      str.contains('Connection refused') ||
      str.contains('Failed host lookup') ||
      str.contains('Network is unreachable')) {
    return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng!';
  }
  if (str.startsWith('Exception: ')) {
    return str.substring('Exception: '.length);
  }
  return str;
}

/// Hộp thoại MessageBox hiển thị thông báo lỗi tiêu chuẩn (Warm Editorial Heritage)
Future<void> showErrorMessageBox({
  required BuildContext context,
  String title = 'Thông Báo Lỗi',
  required dynamic error,
  String positiveText = 'Đã hiểu',
  VoidCallback? onConfirm,
}) {
  final cleanMessage = formatErrorMessage(error);

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFBA1A1A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1A),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        cleanMessage,
        style: const TextStyle(
          fontFamily: 'Be Vietnam Pro',
          fontSize: 13.5,
          color: Color(0xFF4A3E39),
          height: 1.45,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E1E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: Text(
            positiveText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

/// Hộp thoại MessageBox cảnh báo nghiệp vụ (màu cam/vàng)
Future<void> showWarningMessageBox({
  required BuildContext context,
  String title = 'Cảnh Báo',
  required String message,
  String positiveText = 'Đã hiểu',
  VoidCallback? onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD97706),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1A),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Be Vietnam Pro',
          fontSize: 13.5,
          color: Color(0xFF4A3E39),
          height: 1.45,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: Text(
            positiveText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
