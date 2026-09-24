import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum RoomStatusType { available, occupied, dirty, maintenance }

/// Status badge — dot + label pill. Per design.md §6.3.
/// dot 8px + caption bold, padding 4px 10px, radius full.
class StatusBadge extends StatelessWidget {
  final RoomStatusType status;
  final String? customLabel;
  final bool compact; // Shows dot only (no label) when true

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.compact = false,
  });

  _BadgeStyle get _style {
    return switch (status) {
      RoomStatusType.available   => const _BadgeStyle(
          bg:   Color(0xFFDCFCE7),
          fg:   Color(0xFF16A34A),
          label: 'Available',
        ),
      RoomStatusType.occupied    => const _BadgeStyle(
          bg:   Color(0xFFFEE2E2),
          fg:   Color(0xFFDC2626),
          label: 'Occupied',
        ),
      RoomStatusType.dirty       => const _BadgeStyle(
          bg:   Color(0xFFFEF3C7),
          fg:   Color(0xFFD97706),
          label: 'Dirty',
        ),
      RoomStatusType.maintenance => const _BadgeStyle(
          bg:   Color(0xFFF3F4F6),
          fg:   Color(0xFF6B7280),
          label: 'Maintenance',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final label = customLabel ?? s.label;

    return Container(
      padding: compact
          ? const EdgeInsets.all(6)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: AppRadius.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: s.fg, shape: BoxShape.circle),
          ),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: s.fg,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ],
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
