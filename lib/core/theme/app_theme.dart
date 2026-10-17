import 'package:flutter/material.dart';

/// Thiết kế giao diện Material 3 thích ứng cho cả Mobile App và Web App,
/// kết hợp bản sắc truyền thống Gia phả (Đỏ son / Vàng đồng ấm) và sự minh bạch Tài chính.
class AppTheme {
  AppTheme._();

  static const Color primaryCrimson = Color(0xFF8B1E1E);
  static const Color secondaryGold = Color(0xFFB8860B);
  static const Color immutableLedgerTeal = Color(0xFF0F766E);
  static const Color warningExplanationAmber = Color(0xFFD97706);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryCrimson,
      primary: primaryCrimson,
      secondary: secondaryGold,
      tertiary: immutableLedgerTeal,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF9F8F6),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(120)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
