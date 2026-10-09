import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'app_colors.dart';

/// Standar ukuran ikon aplikasi:
/// - 16: Teks kecil / dalam tombol teks
/// - 20: Navigasi, sidebar, dan tombol aksi mandiri (icon button)
/// - 24: Khusus untuk status kosong (empty state)
abstract final class AppIconSize {
  static const double small = 16.0;
  static const double medium = 20.0;
  static const double large = 24.0;
}

/// Satu pintu gerbang untuk semua ikon dalam aplikasi Sinar Harapan.
/// Menggunakan Lucide Icons dengan bobot outline reguler yang konsisten.
/// Seluruh konstanta dinamai berdasarkan FUNGSI bisnis aplikasi hotel/PMS.
abstract final class AppIcons {
  // --- Navigasi & Modul Utama ---
  static const IconData dashboard = LucideIcons.layoutDashboard;
  static const IconData room = LucideIcons.bed;
  static const IconData guest = LucideIcons.user;
  static const IconData report = LucideIcons.barChart3;
  static const IconData audit = LucideIcons.history;
  static const IconData reception = LucideIcons.userCheck;

  // --- Operasional Reservasi & Kasir ---
  static const IconData checkIn = LucideIcons.logIn;
  static const IconData checkOut = LucideIcons.logOut;
  static const IconData invoice = LucideIcons.receipt;
  static const IconData receipt = LucideIcons.receipt;
  static const IconData key = LucideIcons.key;
  static const IconData payment = LucideIcons.creditCard;
  static const IconData wallet = LucideIcons.wallet;

  // --- Aksi & Kontrol ---
  static const IconData search = LucideIcons.search;
  static const IconData filter = LucideIcons.filter;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData reset = LucideIcons.rotateCcw;
  static const IconData add = LucideIcons.plus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData clear = LucideIcons.x;
  static const IconData logout = LucideIcons.logOut;
  static const IconData login = LucideIcons.logIn;
  static const IconData openInNew = LucideIcons.externalLink;
  static const IconData send = LucideIcons.send;
  static const IconData download = LucideIcons.download;
  static const IconData print = LucideIcons.printer;

  // --- Ekspor & Berkas ---
  static const IconData pdf = LucideIcons.fileText;
  static const IconData excel = LucideIcons.fileSpreadsheet;
  static const IconData document = LucideIcons.fileText;
  static const IconData folder = LucideIcons.folder;
  static const IconData image = LucideIcons.image;
  static const IconData camera = LucideIcons.camera;

  // --- Autentikasi & Keamanan ---
  static const IconData lock = LucideIcons.lock;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData shield = LucideIcons.shieldCheck;

  // --- Pemeliharaan & Status Kamar ---
  static const IconData maintenance = LucideIcons.wrench;
  static const IconData cleaning = LucideIcons.sparkles;
  static const IconData clean = LucideIcons.sparkles;
  static const IconData broom = LucideIcons.sparkles;
  static const IconData star = LucideIcons.star;

  // --- Indikator & Feedback ---
  static const IconData info = LucideIcons.info;
  static const IconData warning = LucideIcons.alertTriangle;
  static const IconData alertTriangle = LucideIcons.alertTriangle;
  static const IconData error = LucideIcons.alertCircle;
  static const IconData success = LucideIcons.checkCircle2;
  static const IconData help = LucideIcons.helpCircle;
  static const IconData emptyState = LucideIcons.inbox;
  static const IconData clock = LucideIcons.clock;
  static const IconData calendar = LucideIcons.calendar;

  // --- Komunikasi & Lainnya ---
  static const IconData chat = LucideIcons.messageSquare;
  static const IconData phone = LucideIcons.phone;
  static const IconData location = LucideIcons.mapPin;
  static const IconData note = LucideIcons.stickyNote;
  static const IconData qrCode = LucideIcons.qrCode;
  static const IconData menu = LucideIcons.menu;
  static const IconData dropdown = LucideIcons.chevronDown;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData plus = LucideIcons.plus;
  static const IconData layers = LucideIcons.layers;
  static const IconData food = LucideIcons.utensils;
  static const IconData drink = LucideIcons.coffee;
  static const IconData terminal = LucideIcons.terminal;
  static const IconData tag = LucideIcons.tag;
}

/// Widget standar untuk merender ikon di seluruh aplikasi.
/// Menegakkan aturan ukuran sistem (16, 20, 24) dan warna netral secara default.
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final String? tooltip;
  final String? semanticLabel;

  const AppIcon(
    this.icon, {
    super.key,
    this.size = AppIconSize.medium,
    this.color,
    this.tooltip,
    this.semanticLabel,
  });

  const AppIcon.small(
    this.icon, {
    super.key,
    this.color,
    this.tooltip,
    this.semanticLabel,
  }) : size = AppIconSize.small;

  const AppIcon.medium(
    this.icon, {
    super.key,
    this.color,
    this.tooltip,
    this.semanticLabel,
  }) : size = AppIconSize.medium;

  const AppIcon.large(
    this.icon, {
    super.key,
    this.color,
    this.tooltip,
    this.semanticLabel,
  }) : size = AppIconSize.large;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? IconTheme.of(context).color ?? AppColors.textSecondary;

    Widget iconWidget = Icon(
      icon,
      size: size,
      color: effectiveColor,
      semanticLabel: semanticLabel,
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      iconWidget = Tooltip(
        message: tooltip!,
        child: iconWidget,
      );
    } else if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      iconWidget = Semantics(
        label: semanticLabel,
        child: iconWidget,
      );
    }

    return iconWidget;
  }
}
