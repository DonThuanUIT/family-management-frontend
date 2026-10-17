import 'package:intl/intl.dart';

/// Tiện ích định dạng tiền tệ VNĐ và ngày tháng Dương lịch / Âm lịch.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('HH:mm - dd/MM/yyyy');

  static String formatVnd(num amount) => _vndFormat.format(amount);
  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime);
}
