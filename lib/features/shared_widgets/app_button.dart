import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../theme/app_icons.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

/// Touch-friendly button — min height 48px (design.md §6.1).
/// Hover state handled via InkWell splash/highlight.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isSuccess;
  final String? loadingLabel;
  final String? successLabel;
  final double? width;
  final double? minWidth;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.isSuccess = false,
    this.successLabel,
    this.width,
    this.minWidth,
    this.height,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading && !isSuccess;

    final (Color bg, Color fg, BorderSide border, Color splash) = switch (variant) {
      AppButtonVariant.primary     => (
          AppColors.orange600,
          AppColors.navy900,  // Updated to AppColors.navy900 (5.65:1 on orange600)
          BorderSide.none,
          AppColors.orange500,
        ),
      AppButtonVariant.secondary   => (
          AppColors.navy700,
          AppColors.white,
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
          AppColors.error,
          AppColors.white,
          BorderSide.none,
          AppColors.errorText,
        ),
    };

    final effectiveRadius = borderRadius ?? AppRadius.roundedMd;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0,
      ),
      child: SizedBox(
        height: height ?? 50,
        width: width,
        child: Semantics(
          button: true,
          enabled: isEnabled,
          label: label,
          child: Material(
            color: isEnabled
                ? bg
                : (variant == AppButtonVariant.outline
                    ? Colors.transparent
                    : AppColors.textDisabled.withAlpha(40)),
            shape: RoundedRectangleBorder(
              borderRadius: effectiveRadius,
              side: isEnabled
                  ? border
                  : const BorderSide(color: AppColors.border, width: 1),
            ),
            child: InkWell(
              mouseCursor:
                  isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
              onTap: isEnabled ? onPressed : null,
              borderRadius: effectiveRadius,
              splashColor: splash.withAlpha(60),
              highlightColor: splash.withAlpha(30),
              hoverColor: splash.withAlpha(25),
              child: Padding(
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(fg),
                              ),
                            ),
                            if (loadingLabel != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  loadingLabel!,
                                  style: AppTypography.body.copyWith(
                                    color: fg,
                                    fontWeight: fontWeight ?? FontWeight.w600,
                                    fontSize: fontSize ?? 14.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        )
                      : isSuccess
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppIcon.small(AppIcons.check, color: fg),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    successLabel ?? 'Berhasil',
                                    style: AppTypography.body.copyWith(
                                      color: fg,
                                      fontWeight: fontWeight ?? FontWeight.w600,
                                      fontSize: fontSize ?? 14.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (icon != null) ...[
                                AppIcon.small(icon!,
                                    color: isEnabled ? fg : AppColors.textDisabled),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  label,
                                  style: AppTypography.body.copyWith(
                                    color: isEnabled ? fg : AppColors.textDisabled,
                                    fontWeight: fontWeight ?? FontWeight.w600,
                                    fontSize: fontSize ?? 14.5,
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
        ),
      ),
    );
  }
}
