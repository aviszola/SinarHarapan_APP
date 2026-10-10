import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

enum RoomStatusType { available, occupied, dirty, maintenance }

/// Status badge — dot indikator + label Bahasa Indonesia.
/// Menggunakan radius konsisten (6px) dan border 1px halus.
class StatusBadge extends StatelessWidget {
  final RoomStatusType status;
  final String? customLabel;
  final bool compact; // Hanya dot jika true

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.compact = false,
  });

  _BadgeStyle get _style {
    return switch (status) {
      RoomStatusType.available => const _BadgeStyle(
          bg: AppColors.statusAvailableBg,
          fg: AppColors.statusAvailableText,
          label: 'Tersedia',
        ),
      RoomStatusType.occupied => const _BadgeStyle(
          bg: AppColors.statusOccupiedBg,
          fg: AppColors.statusOccupiedText,
          label: 'Terisi',
        ),
      RoomStatusType.dirty => const _BadgeStyle(
          bg: AppColors.statusDirtyBg,
          fg: AppColors.statusDirtyText,
          label: 'Kotor',
        ),
      RoomStatusType.maintenance => const _BadgeStyle(
          bg: AppColors.statusMaintenanceBg,
          fg: AppColors.statusMaintenanceText,
          label: 'Perawatan',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final label = customLabel ?? s.label;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final animDuration = disableAnimations ? Duration.zero : const Duration(milliseconds: 180);

    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedContainer(
        duration: animDuration,
        curve: Curves.easeInOut,
        padding: compact
            ? const EdgeInsets.all(5)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: s.bg,
          borderRadius: AppRadius.roundedSm,
          border: Border.all(color: s.fg.withAlpha(40), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: animDuration,
              curve: Curves.easeInOut,
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: s.fg,
                shape: BoxShape.circle,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: animDuration,
                curve: Curves.easeInOut,
                style: AppTextStyles.badge.copyWith(
                  color: s.fg,
                  fontSize: 12,
                ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BadgeStyle {
  final Color bg;
  final Color fg;
  final String label;
  const _BadgeStyle({required this.bg, required this.fg, required this.label});
}
