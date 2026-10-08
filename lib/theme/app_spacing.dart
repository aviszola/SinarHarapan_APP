import 'package:flutter/material.dart';

/// ============================================================
/// DESIGN TOKENS — Sinar Harapan PMS (lib/theme/app_spacing.dart)
/// Grid 4/8/16/24/32px.
/// Radius seragam 8px (maksimal 10px) di seluruh aplikasi.
/// ============================================================

class AppSpacing {
  AppSpacing._();

  static const double xxs  = 2.0;
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
}

class AppRadius {
  AppRadius._();

  /// Radius seragam 8px untuk seluruh card, modal, button, dan input
  static const double radius = 8.0;
  
  /// Radius kecil untuk status badge / tags (6px)
  static const double small = 6.0;

  // BorderRadius instances seragam
  static const BorderRadius rounded = BorderRadius.all(Radius.circular(radius));
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(small));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radius));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radius)); // Disamakan ke 8px
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radius)); // Disamakan ke 8px
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(999.0));

  // Legacy compat
  static const double sm = small;
  static const double md = radius;
  static const double lg = radius;
  static const double xl = radius;
  static const double full = 999.0;
}

class AppElevation {
  AppElevation._();

  /// Border 1px halus diutamakan daripada shadow (anti-slop rule)
  static const List<BoxShadow> none = [];

  /// Hover subtil kartu (blur 4px, opacity sangat rendah)
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A000000), // ~4% opacity
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  /// Popover / dialog ringan
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x140A2A6E), // 8% navy tint
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Legacy compat
  static const List<BoxShadow> card = subtle;
}
