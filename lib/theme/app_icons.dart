import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
/// Menggunakan Phosphor Icons dengan bobot outline reguler yang konsisten.
/// Seluruh konstanta dinamai berdasarkan FUNGSI bisnis aplikasi hotel/PMS.
abstract final class AppIcons {
  // --- Navigasi & Modul Utama ---
  static const IconData dashboard = PhosphorIcons.chartLine;
  static const IconData room = PhosphorIcons.bed;
  static const IconData guest = PhosphorIcons.user;
  static const IconData report = PhosphorIcons.chartBar;
  static const IconData audit = PhosphorIcons.clockCounterClockwise;
  static const IconData reception = PhosphorIcons.identificationCard;

  // --- Operasional Reservasi & Kasir ---
  static const IconData checkIn = PhosphorIcons.signIn;
  static const IconData checkOut = PhosphorIcons.signOut;
  static const IconData invoice = PhosphorIcons.receipt;
  static const IconData receipt = PhosphorIcons.receipt;
  static const IconData key = PhosphorIcons.key;
  static const IconData payment = PhosphorIcons.creditCard;
  static const IconData wallet = PhosphorIcons.wallet;

  // --- Aksi & Kontrol ---
  static const IconData search = PhosphorIcons.magnifyingGlass;
  static const IconData filter = PhosphorIcons.funnel;
  static const IconData refresh = PhosphorIcons.arrowsClockwise;
  static const IconData reset = PhosphorIcons.arrowCounterClockwise;
  static const IconData add = PhosphorIcons.plus;
  static const IconData edit = PhosphorIcons.pencilSimple;
  static const IconData delete = PhosphorIcons.trash;
  static const IconData close = PhosphorIcons.x;
  static const IconData check = PhosphorIcons.check;
  static const IconData clear = PhosphorIcons.x;
  static const IconData logout = PhosphorIcons.signOut;
  static const IconData login = PhosphorIcons.signIn;
  static const IconData openInNew = PhosphorIcons.arrowSquareOut;
  static const IconData send = PhosphorIcons.paperPlaneRight;
  static const IconData download = PhosphorIcons.downloadSimple;
  static const IconData print = PhosphorIcons.printer;

  // --- Ekspor & Berkas ---
  static const IconData pdf = PhosphorIcons.filePdf;
  static const IconData excel = PhosphorIcons.fileXls;
  static const IconData document = PhosphorIcons.fileText;
  static const IconData folder = PhosphorIcons.folder;
  static const IconData image = PhosphorIcons.image;
  static const IconData camera = PhosphorIcons.camera;

  // --- Autentikasi & Keamanan ---
  static const IconData lock = PhosphorIcons.lock;
  static const IconData eye = PhosphorIcons.eye;
  static const IconData eyeOff = PhosphorIcons.eyeSlash;
  static const IconData shield = PhosphorIcons.shieldCheck;

  // --- Pemeliharaan & Status Kamar ---
  static const IconData maintenance = PhosphorIcons.wrench;
  static const IconData cleaning = PhosphorIcons.sparkle;
  static const IconData broom = PhosphorIcons.broom;
  static const IconData star = PhosphorIcons.star;

  // --- Indikator & Feedback ---
  static const IconData info = PhosphorIcons.info;
  static const IconData warning = PhosphorIcons.warning;
  static const IconData error = PhosphorIcons.warningCircle;
  static const IconData success = PhosphorIcons.checkCircle;
  static const IconData help = PhosphorIcons.question;
  static const IconData emptyState = PhosphorIcons.tray;
  static const IconData clock = PhosphorIcons.clock;
  static const IconData calendar = PhosphorIcons.calendar;

  // --- Komunikasi & Lainnya ---
  static const IconData chat = PhosphorIcons.chatCircleDots;
  static const IconData phone = PhosphorIcons.phone;
  static const IconData location = PhosphorIcons.mapPin;
  static const IconData note = PhosphorIcons.note;
  static const IconData qrCode = PhosphorIcons.qrCode;
  static const IconData menu = PhosphorIcons.list;
  static const IconData dropdown = PhosphorIcons.caretDown;
  static const IconData layers = PhosphorIcons.stack;
  static const IconData food = PhosphorIcons.forkKnife;
  static const IconData drink = PhosphorIcons.drop;
  static const IconData terminal = PhosphorIcons.terminal;
  static const IconData tag = PhosphorIcons.tag;
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
  }) : assert(
          size == AppIconSize.small ||
              size == AppIconSize.medium ||
              size == AppIconSize.large,
          'Ukuran AppIcon harus salah satu dari: 16 (small), 20 (medium), atau 24 (large)',
        );

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
