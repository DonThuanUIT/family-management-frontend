import 'package:flutter/material.dart';

/// Ngưỡng kích thước màn hình chuẩn theo DESIGN.md (Warm Editorial Heritage).
const double kMobileBreakpoint = 768.0;
const double kDesktopBreakpoint = 900.0;

/// Kiểm tra nhanh xem khung hình hiện tại có phải Desktop / Web màn hình rộng hay không.
bool isDesktopViewport(BuildContext context) {
  return MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;
}

/// Hiển thị biểu mẫu hoặc chi tiết thích ứng theo thiết bị:
/// - Trên Máy tính / Web (`width >= 900px`): Mở Dialog căn giữa màn hình.
/// - Trên Điện thoại / Tablet hẹp (`width < 900px`): Mở ModalBottomSheet từ dưới lên.
Future<T?> showAdaptiveSheetOrDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxDesktopWidth = 680,
  double maxDesktopHeightFactor = 0.88,
}) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= kDesktopBreakpoint) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxDesktopWidth,
              maxHeight: size.height * maxDesktopHeightFactor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: Colors.white,
                child: builder(dialogContext),
              ),
            ),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}
