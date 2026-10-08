import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ============================================================
/// DESIGN TOKENS — Sinar Harapan PMS (lib/theme/app_text_styles.dart)
/// Tipografi terstandarisasi: Plus Jakarta Sans, skala tegas (12/14/16/20/28).
/// Angka uang & statistik dilengkapi tabular figures (FontFeature.tabularFigures()).
/// ============================================================

class AppTextStyles {
  AppTextStyles._();

  // Skala Tipografi Utama
  // 28px - Judul Halaman Utama / Hero KPI
  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  // 20px - Subjudul Halaman / Modal Title / Section Header
  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // 16px - Card Header / Tab Label / Emphasized Body
  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  // 16px - Standard Body
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  // 14px - Default Table / Form Input / Standard UI Body
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  // 14px Medium - Button Label / Form Header
  static TextStyle get bodyMediumMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: AppColors.textPrimary,
  );

  // 12px - Caption / Secondary metadata / Timestamp
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  // 12px Medium / Semi-bold - Badges / Status Pills / Overline
  static TextStyle get badge => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  // ==========================================================
  // TABULAR FIGURES — Untuk Angka Finansial, Okupansi, Jam, & Statistik
  // Memastikan lebar tiap angka sama persis agar mudah dipindai di tabel/dashboard.
  // ==========================================================

  /// Angka KPI Utama (Besar)
  static TextStyle get numberHero => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Angka Sub-KPI / Harga Kamar / Total Transaksi
  static TextStyle get numberLarge => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 26 / 20,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Angka Tabel / List / Nominal Sedang
  static TextStyle get numberMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Angka Kecil / Persentase / Tanggal & Jam
  static TextStyle get numberSmall => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.textSecondary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Alias kompatibilitas AppTypography agar kode legacy tetap bekerja
class AppTypography {
  AppTypography._();

  static TextStyle get display => AppTextStyles.titleLarge;
  static TextStyle get h1 => AppTextStyles.titleLarge;
  static TextStyle get h2 => AppTextStyles.titleMedium;
  static TextStyle get h3 => AppTextStyles.titleSmall;
  static TextStyle get bodyLg => AppTextStyles.bodyLarge;
  static TextStyle get body => AppTextStyles.bodyMedium;
  static TextStyle get bodySm => AppTextStyles.bodyMediumMedium;
  static TextStyle get caption => AppTextStyles.caption;
  static TextStyle get overline => AppTextStyles.badge;
}
