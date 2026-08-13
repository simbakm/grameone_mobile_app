import 'package:flutter/material.dart';

/// STRICT RULE: Centralized color and theme definition.
/// NO color literals (e.g. Color(0x...), Colors.red, etc.) are allowed outside this file.
class AppColors {
  AppColors._();

  // Core Brand Colors (Green, Gold, Maroon combination)
  static const Color emeraldGreen = Color(0xFF15803D); // Primary Green
  static const Color forestGreenDark = Color(0xFF0F5128);
  static const Color lightGreen = Color(0xFFDCFCE7);

  static const Color royalGold = Color(0xFFD97706); // Accent Gold
  static const Color brightGold = Color(0xFFF59E0B);
  static const Color lightGold = Color(0xFFFEF3C7);

  static const Color deepMaroon = Color(0xFF800020); // Accent Maroon
  static const Color maroonDark = Color(0xFF580016);
  static const Color lightMaroon = Color(0xFFFEE2E2);

  // Neutral Colors (Light Theme)
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color shadowLight = Color(0x0F000000);

  // Neutral Colors (Dark Theme)
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color borderDark = Color(0xFF334155);

  // Functional & Feedback Colors
  static const Color correctGreen = Color(0xFF16A34A);
  static const Color incorrectRed = Color(0xFFDC2626);
  static const Color warningOrange = Color(0xFFEA580C);
  static const Color badgeLocked = Color(0xFF94A3B8);
  static const Color badgeUnlocked = Color(0xFFF59E0B);

  // Subject / Grade Accent Palettes
  static const Color mathBlue = Color(0xFF2563EB);
  static const Color scienceTeal = Color(0xFF0D9488);
  static const Color englishPurple = Color(0xFF7C3AED);
  static const Color socialRose = Color(0xFFE11D48);

  // Subject Card Background Colors
  static const Color bgScience = Color(0xFFE6FFFA);
  static const Color bgMath = Color(0xFFEFF6FF);
  static const Color bgEnglish = Color(0xFFF5F3FF);
  static const Color bgSocial = Color(0xFFFFF1F2);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.emeraldGreen,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.emeraldGreen,
        onPrimary: AppColors.surfaceLight,
        secondary: AppColors.royalGold,
        onSecondary: AppColors.textPrimaryLight,
        tertiary: AppColors.deepMaroon,
        onTertiary: AppColors.surfaceLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.incorrectRed,
        onError: AppColors.surfaceLight,
        shadow: AppColors.shadowLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepMaroon,
        foregroundColor: AppColors.surfaceLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.surfaceLight,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceLight,
        elevation: 2,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emeraldGreen,
          foregroundColor: AppColors.surfaceLight,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emeraldGreen,
          side: const BorderSide(color: AppColors.emeraldGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.royalGold,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.emeraldGreen,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emeraldGreen,
        onPrimary: AppColors.surfaceLight,
        secondary: AppColors.royalGold,
        onSecondary: AppColors.textPrimaryDark,
        tertiary: AppColors.deepMaroon,
        onTertiary: AppColors.surfaceLight,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.incorrectRed,
        onError: AppColors.surfaceLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emeraldGreen,
          foregroundColor: AppColors.surfaceLight,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
    );
  }
}
