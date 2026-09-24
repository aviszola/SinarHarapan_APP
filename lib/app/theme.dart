import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================
/// DESIGN TOKENS — Sinar Harapan PMS
/// Strictly following design.md v1.0 (anti AI-slop policy)
/// ============================================================

class AppColors {
  AppColors._();

  // Brand Navy (structural)
  static const Color navy900 = Color(0xFF001B4E);
  static const Color navy700 = Color(0xFF0A2A6E);
  static const Color navy500 = Color(0xFF1E4499);
  static const Color navy100 = Color(0xFFE6EBF7);
  static const Color navy50  = Color(0xFFF0F3FB);

  // Single Accent Orange — max 1 dominant per viewport
  static const Color orange600 = Color(0xFFFF6600);
  static const Color orange500 = Color(0xFFFF7A1A);
  static const Color orange100 = Color(0xFFFFEBDB);
  static const Color orange50  = Color(0xFFFFF5EE);

  // Neutrals
  static const Color bg        = Color(0xFFF7F8FA);
  static const Color surface   = Color(0xFFFFFFFF);
  static const Color border    = Color(0xFFE2E5EB);
  static const Color borderFocus = Color(0xFFCCD3E0);
  static const Color textPrimary    = Color(0xFF1E2430);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color textDisabled   = Color(0xFFB0B5BE);

  // Room / Transaction Status (independent from brand)
  static const Color statusAvailable   = Color(0xFF22C55E);
  static const Color statusOccupied    = Color(0xFFEF4444);
  static const Color statusDirty       = Color(0xFFF59E0B);
  static const Color statusMaintenance = Color(0xFF9CA3AF);

  static const Color statusSuccessBg     = Color(0xFFDCFCE7);
  static const Color statusErrorBg       = Color(0xFFFEE2E2);
  static const Color statusWarningBg     = Color(0xFFFEF3C7);
  static const Color statusMaintenanceBg = Color(0xFFF3F4F6);

  // Availability badge bg (per design.md §6.3)
  static const Color availableBg    = Color(0xFFDCFCE7);
  static const Color availableText  = Color(0xFF16A34A);
  static const Color occupiedBg     = Color(0xFFFEE2E2);
  static const Color occupiedText   = Color(0xFFDC2626);
  static const Color dirtyBg        = Color(0xFFFEF3C7);
  static const Color dirtyText      = Color(0xFFD97706);
  static const Color maintenanceBg  = Color(0xFFF3F4F6);
  static const Color maintenanceText = Color(0xFF6B7280);
}

class AppSpacing {
  AppSpacing._();

  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;
}

class AppRadius {
  AppRadius._();

  static const double sm   = 6.0;
  static const double md   = 8.0;
  static const double lg   = 12.0;
  static const double xl   = 16.0;
  static const double full = 999.0;

  static const BorderRadius roundedSm   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(full));
}

class AppElevation {
  AppElevation._();

  /// No shadow — use 1px border instead (design.md §4.3)
  static const List<BoxShadow> none = [];

  /// Hover / active card lift
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D101828), // rgba(16,24,40,0.05)
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Modal / popover
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x14101828), // rgba(16,24,40,0.08)
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

class AppTypography {
  AppTypography._();

  static TextStyle get display => GoogleFonts.plusJakartaSans(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 42 / 34,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get h1 => GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 34 / 26,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 25 / 17,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: AppColors.textSecondary,
  );

  static TextStyle get overline => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.navy700,
        onPrimary: Colors.white,
        secondary: AppColors.orange600,
        onSecondary: Colors.white,
        error: AppColors.statusOccupied,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge:   AppTypography.display,
        headlineLarge:  AppTypography.h1,
        headlineMedium: AppTypography.h2,
        titleLarge:     AppTypography.h3,
        bodyLarge:      AppTypography.bodyLg,
        bodyMedium:     AppTypography.body,
        bodySmall:      AppTypography.bodySm,
        labelMedium:    AppTypography.caption,
        labelSmall:     AppTypography.overline,
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
          borderRadius: AppRadius.roundedLg,
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.navy700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.statusOccupied, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: const BorderSide(color: AppColors.statusOccupied, width: 2),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.textDisabled),
        labelStyle: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedLg,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        contentTextStyle: AppTypography.bodySm.copyWith(color: Colors.white),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navy900,
          borderRadius: AppRadius.roundedSm,
        ),
        textStyle: AppTypography.caption.copyWith(color: Colors.white),
      ),
    );
  }
}
