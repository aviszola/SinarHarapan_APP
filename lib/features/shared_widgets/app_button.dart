import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

/// Touch-friendly button — min height 48px (design.md §6.1).
/// Hover state handled via InkWell splash/highlight.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    final (Color bg, Color fg, BorderSide border, Color splash) = switch (variant) {
      AppButtonVariant.primary     => (
          AppColors.orange600,
          Colors.white,
          BorderSide.none,
          AppColors.orange500,
        ),
      AppButtonVariant.secondary   => (
          AppColors.navy700,
          Colors.white,
          BorderSide.none,
          AppColors.navy500,
        ),
      AppButtonVariant.outline     => (
          Colors.transparent,
          AppColors.navy700,
          const BorderSide(color: AppColors.navy700, width: 1.5),
          AppColors.navy100,
        ),
      AppButtonVariant.ghost       => (
          Colors.transparent,
          AppColors.navy700,
          BorderSide.none,
          AppColors.navy100,
        ),
      AppButtonVariant.destructive => (
          AppColors.statusOccupied,
          Colors.white,
          BorderSide.none,
          const Color(0xFFDC2626),
        ),
    };

    return SizedBox(
      height: 50,
      width: width,
      child: Material(
        color: isEnabled
            ? bg
            : (variant == AppButtonVariant.outline
                ? Colors.transparent
                : AppColors.textDisabled.withAlpha(40)),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedMd,
          side: isEnabled
              ? border
              : const BorderSide(color: AppColors.border, width: 1),
        ),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: AppRadius.roundedMd,
          splashColor: splash.withAlpha(60),
          highlightColor: splash.withAlpha(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 19,
                              color: isEnabled ? fg : AppColors.textDisabled),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: AppTypography.body.copyWith(
                              color: isEnabled ? fg : AppColors.textDisabled,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
