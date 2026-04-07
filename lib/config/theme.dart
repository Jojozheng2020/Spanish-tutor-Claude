import 'package:flutter/material.dart';

// ============================================================
// 风格一：深色 Material Design — 海军蓝 + 橙色
// ============================================================

class AppTheme {
  // 主色：橙色
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFE55A25);
  static const Color primaryLight = Color(0xFFFF8C5A);

  // 背景：深海军蓝系
  static const Color bgDark = Color(0xFF0D1B2A);
  static const Color bgMedium = Color(0xFF1B2D40);
  static const Color bgCard = Color(0xFF243447);
  static const Color bgCardLight = Color(0xFF2E4058);

  // 文字
  static const Color textPrimary = Color(0xFFEAEEF4);
  static const Color textSecondary = Color(0xFF8FA8C0);
  static const Color textHint = Color(0xFF4E6478);

  // 强调色：青绿
  static const Color accent = Color(0xFF00C9A7);
  static const Color accentLight = Color(0xFF33D4B5);

  // 状态色
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFC107);

  // 级别颜色
  static const Color levelA1 = Color(0xFF4CAF50);
  static const Color levelA2 = Color(0xFF2196F3);
  static const Color levelB1 = Color(0xFF9C27B0);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgMedium,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgMedium,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: bgCardLight,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgCardLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bgCardLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textHint),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary, fontSize: 28, fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
        bodySmall: TextStyle(color: textHint, fontSize: 12),
      ),
    );
  }
}
