import 'package:flutter/material.dart';

/// ============================================================
/// DESIGN TOKENS — Sinar Harapan PMS (lib/theme/app_colors.dart)
/// Anti AI-slop design tokens.
/// ============================================================

class AppColors {
  AppColors._();

  // ==========================================================
  // WARNA BRAND TERKUNCI (Sesuai instruksi brand PMS Sinar Harapan)
  // NILAI TERKUNCI — JANGAN DIUBAH!
  // ==========================================================
  /// Biru Navy struktur (dipakai di sidebar, header resepsionis, teks judul, tombol sekunder)
  static const Color brandNavy = Color(0xFF0A2A6E);      // Hex: #0A2A6E (Navy 700)
  /// Varian Navy gelap untuk sidebar / background struktur terdalam
  static const Color brandNavyDark = Color(0xFF001B4E);  // Hex: #001B4E (Navy 900)
  /// Varian Navy terang / interaksi
  static const Color brandNavyLight = Color(0xFF1E4499); // Hex: #1E4499 (Navy 500)
  /// Varian tint Navy untuk hover / latar aksen lembut
  static const Color brandNavyTint = Color(0xFFEEF2F9);  // Navy subtle tint
  static const Color brandNavyBorder = Color(0xFFD0DAEB);// Navy light border

  /// Oranye brand (dipakai di tombol aksi utama, logo SH, dan state aktif terpilih)
  static const Color brandOrange = Color(0xFFFF6600);    // Hex: #FF6600 (Orange 600)
  /// Varian Oranye hover/pressed/tint
  static const Color brandOrangeHover = Color(0xFFE65C00); // Sedikit lebih pekat saat hover
  static const Color brandOrangeTint = Color(0xFFFFF4EB);  // Oranye lembut latar badge/tag
  static const Color brandOrangeBorder = Color(0xFFFFD9BF);// Border oranye tipis

  // ==========================================================
  // NETRAL HANGAT (Warm Neutrals untuk UI desktop profesional)
  // ==========================================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF7F8FA);           // Canvas latar belakang hangat & bersih
  static const Color bgSubtle = Color(0xFFF1F3F6);     // Area input/disabled background
  static const Color border = Color(0xFFE2E4E8);       // Border 1px halus
  static const Color borderFocus = Color(0xFF0A2A6E);  // Focus ring navy
  
  // Teks Netral Berkualitas (WCAG AA compliant)
  static const Color textPrimary = Color(0xFF1A1F2C);   // Sangat kontras & tajam
  static const Color textSecondary = Color(0xFF505A69); // Teks penjelasan, label, instruksi
  static const Color textMuted = Color(0xFF8690A0);     // Placeholder, hint
  static const Color textDisabled = Color(0xFFA8B1BF);

  // ==========================================================
  // STATUS OPERASIONAL (Semantic Status — hanya untuk status)
  // ==========================================================
  // Tersedia (Hijau Bersih)
  static const Color statusAvailable = Color(0xFF16A34A);
  static const Color statusAvailableBg = Color(0xFFDCFCE7);
  static const Color statusAvailableText = Color(0xFF166534);

  // Terisi (Merah Tegas)
  static const Color statusOccupied = Color(0xFFDC2626);
  static const Color statusOccupiedBg = Color(0xFFFEE2E2);
  static const Color statusOccupiedText = Color(0xFFB91C1C);

  // Kotor / Menunggu Pembersihan (Amber Hangat)
  static const Color statusDirty = Color(0xFFD97706);
  static const Color statusDirtyBg = Color(0xFFFEF3C7);
  static const Color statusDirtyText = Color(0xFF92400E);

  // Perawatan / Maintenance (Abu-abu Netral)
  static const Color statusMaintenance = Color(0xFF6B7280);
  static const Color statusMaintenanceBg = Color(0xFFF3F4F6);
  static const Color statusMaintenanceText = Color(0xFF4B5563);

  // System alerts / Error
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorText = Color(0xFF991B1B);

  // External Integration (mis. WhatsApp)
  static const Color whatsapp = Color(0xFF25D366);

  // ==========================================================
  // KONSTANTA KOMPATIBILITAS (Mencegah breaking changes di legacy code)
  // ==========================================================
  static const Color navy900 = brandNavyDark;
  static const Color navy700 = brandNavy;
  static const Color navy500 = brandNavyLight;
  static const Color navy100 = brandNavyTint;
  static const Color navy50  = Color(0xFFF6F8FC);
  static const Color orange600 = brandOrange;
  static const Color orange500 = Color(0xFFFF7A1A);
  static const Color orange100 = brandOrangeTint;
  static const Color orange50  = Color(0xFFFFF9F5);
  static const Color orange800 = Color(0xFF9A3412);
  static const Color amber800  = Color(0xFF92400E);
  static const Color availableBg = statusAvailableBg;
  static const Color availableText = statusAvailableText;
  static const Color availableDark = statusAvailable;
  static const Color statusSuccessBg = statusAvailableBg;
  static const Color statusWarningBg = statusDirtyBg;
  static const Color statusErrorBg = statusOccupiedBg;
  static const Color occupiedBg = statusOccupiedBg;
  static const Color occupiedText = statusOccupiedText;
  static const Color occupiedLight = Color(0xFFFCA5A5);
  static const Color dirtyBg = statusDirtyBg;
  static const Color dirtyText = statusDirtyText;
  static const Color maintenanceBg = statusMaintenanceBg;
  static const Color maintenanceText = statusMaintenanceText;
}
