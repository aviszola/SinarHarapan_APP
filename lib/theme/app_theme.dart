import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

/// ============================================================
/// THEME DATA — Sinar Harapan PMS (lib/theme/app_theme.dart)
/// Konfigurasi tema material3 terpadu.
/// ============================================================

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.brandNavy,
        onPrimary: AppColors.white,
        secondary: AppColors.brandOrange,
        onSecondary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge:   AppTextStyles.titleLarge,
        headlineLarge:  AppTextStyles.titleLarge,
        headlineMedium: AppTextStyles.titleMedium,
        titleLarge:     AppTextStyles.titleSmall,
        bodyLarge:      AppTextStyles.bodyLarge,
        bodyMedium:     AppTextStyles.bodyMedium,
        bodySmall:      AppTextStyles.caption,
        labelLarge:     AppTextStyles.bodyMediumMedium,
        labelMedium:    AppTextStyles.caption,
        labelSmall:     AppTextStyles.badge,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border, width: 1),
          borderRadius: AppRadius.rounded,
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 40), // Target klik min 40px tinggi
          backgroundColor: AppColors.brandOrange,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.rounded,
          ),
          textStyle: AppTextStyles.bodyMediumMedium.copyWith(color: AppColors.white),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 40),
          foregroundColor: AppColors.brandNavy,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.rounded,
          ),
          textStyle: AppTextStyles.bodyMediumMedium,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.rounded,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rounded,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rounded,
          borderSide: const BorderSide(color: AppColors.brandNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rounded,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.rounded,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border, width: 1),
          borderRadius: AppRadius.rounded,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.rounded,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        backgroundColor: AppColors.brandNavyDark,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.brandNavyDark,
          borderRadius: AppRadius.roundedSm,
        ),
        textStyle: AppTextStyles.caption.copyWith(color: AppColors.white),
      ),
    );
  }
}
