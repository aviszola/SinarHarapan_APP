import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../auth/domain/user_model.dart';
import 'app_logout_dialog.dart';

enum FeedbackType {
  success,
  error,
  warning,
  info,
}

/// Helper profesional untuk Toast dan Notifikasi Melayang (SaaS Modern)
class AppFeedback {
  AppFeedback._();

  /// Menampilkan dialog konfirmasi logout eksplisit dan profesional (anti AI-slop)
  static Future<bool> showLogout(
    BuildContext context, {
    UserModel? user,
  }) {
    return AppLogoutDialog.show(context, user: user);
  }


  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Berhasil',
      type: FeedbackType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Terjadi Kesalahan',
      type: FeedbackType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Pemberitahuan',
      type: FeedbackType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Informasi',
      type: FeedbackType.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    required String title,
    required FeedbackType type,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final (icon, iconColor, iconBg, borderColor) = switch (type) {
      FeedbackType.success => (
        Icons.check_circle_rounded,
        AppColors.statusAvailable,
        AppColors.availableBg,
        AppColors.availableBg,
      ),
      FeedbackType.error => (
        Icons.error_outline_rounded,
        AppColors.error,
        AppColors.errorBg,
        AppColors.errorBg,
      ),
      FeedbackType.warning => (
        Icons.warning_amber_rounded,
        AppColors.orange800,
        AppColors.orange100,
        AppColors.orange100,
      ),
      FeedbackType.info => (
        Icons.info_outline_rounded,
        AppColors.navy700,
        AppColors.navy50,
        AppColors.navy100,
      ),
    };

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 6,
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: isDesktop ? screenWidth - 440 : 16,
          right: 16,
          bottom: 20,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.navy700,
                ),
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Komponen Dialog Konfirmasi Modern (Bukan Default Material 2)
class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Lanjutkan',
    this.cancelLabel = 'Batal',
    this.isDestructive = false,
    this.icon,
    this.iconColor,
    this.iconBgColor,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Lanjutkan',
    String cancelLabel = 'Batal',
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
        iconColor: iconColor,
        iconBgColor: iconBgColor,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = icon ??
        (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded);

    final effectiveIconBg = iconBgColor ??
        (isDestructive ? AppColors.errorBg : AppColors.navy50);
    final effectiveIconColor = iconColor ??
        (isDestructive ? AppColors.error : AppColors.navy700);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(effectiveIcon, size: 22, color: effectiveIconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.h3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.navy900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      backgroundColor: isDestructive ? AppColors.error : AppColors.navy700,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Komponen Tampilan Kosong Modern (Empty State)
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.navy50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.navy500),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                message,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.navy700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(actionLabel!),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Komponen Notice / Inline Banner Kontekstual
class AppInlineBanner extends StatelessWidget {
  final String message;
  final FeedbackType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppInlineBanner({
    super.key,
    required this.message,
    this.type = FeedbackType.info,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, bg, border) = switch (type) {
      FeedbackType.success => (
        Icons.check_circle_outline_rounded,
        AppColors.statusAvailable,
        AppColors.availableBg,
        AppColors.availableBg,
      ),
      FeedbackType.error => (
        Icons.error_outline_rounded,
        AppColors.error,
        AppColors.errorBg,
        AppColors.errorBg,
      ),
      FeedbackType.warning => (
        Icons.warning_amber_rounded,
        AppColors.orange800,
        AppColors.orange100,
        AppColors.orange100,
      ),
      FeedbackType.info => (
        Icons.info_outline_rounded,
        AppColors.navy700,
        AppColors.navy50,
        AppColors.navy100,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: iconColor,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
