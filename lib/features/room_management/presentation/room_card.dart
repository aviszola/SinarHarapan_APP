import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../shared_widgets/status_badge.dart';
import '../domain/room_model.dart';

/// Room Card — compact grid tile per design.md §6.2.
/// Background: always white. Color accent: 4px left stripe only.
/// Hover: border → navy500, light card shadow. No fill color changes.
class RoomCard extends StatefulWidget {
  final RoomModel room;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> with SingleTickerProviderStateMixin {
  bool _hovered = false;

  static final _currFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Color get _stripeColor {
    switch (widget.room.status) {
      case RoomStatusType.available:
        return AppColors.statusAvailable;
      case RoomStatusType.occupied:
        return AppColors.statusOccupied;
      case RoomStatusType.dirty:
        return AppColors.statusDirty;
      case RoomStatusType.maintenance:
        return AppColors.statusMaintenance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: widget.room.isMaintenance
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.roundedLg,
            border: Border.all(
              color: _hovered ? AppColors.navy500 : AppColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered ? AppElevation.card : AppElevation.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4px status stripe — only color signal (design.md §6.2)
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: _hovered ? 5 : 4,
                color: _stripeColor,
              ),

              // Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Row 1: Room number + Status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Room number & type
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.room.roomNumber,
                                  style: AppTypography.h2.copyWith(
                                    color: AppColors.navy900,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    fontSize: 21,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.room.roomType} · Lt. ${widget.room.floor}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),
                          StatusBadge(status: widget.room.status),
                        ],
                      ),

                      // Row 2: Contextual info & Quick Action Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildContextRow()),
                          const SizedBox(width: 8),
                          _buildActionPill(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill() {
    switch (widget.room.status) {
      case RoomStatusType.available:
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.orange600 : AppColors.navy100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 14,
                color: _hovered ? Colors.white : AppColors.navy700,
              ),
              const SizedBox(width: 3),
              Text(
                'Check-in',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _hovered ? Colors.white : AppColors.navy700,
                ),
              ),
            ],
          ),
        );

      case RoomStatusType.occupied:
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFDC2626) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 13,
                color: _hovered ? Colors.white : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 3),
              Text(
                'Check-out',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _hovered ? Colors.white : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        );

      case RoomStatusType.dirty:
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFD97706) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_rounded,
                size: 14,
                color: _hovered ? Colors.white : const Color(0xFFD97706),
              ),
              const SizedBox(width: 3),
              Text(
                'Bersihkan',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _hovered ? Colors.white : const Color(0xFFD97706),
                ),
              ),
            ],
          ),
        );

      case RoomStatusType.maintenance:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.border.withAlpha(80),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Perbaikan',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textDisabled,
            ),
          ),
        );
    }
  }

  Widget _buildContextRow() {
    if (widget.room.isOccupied && widget.room.activeGuestName != null) {
      final isRD = widget.room.bookingSource == 'REDDOORZ';
      return Row(
        children: [
          Icon(
            isRD ? Icons.hotel_class_rounded : Icons.person_rounded,
            size: 14,
            color: isRD ? const Color(0xFFDC2626) : AppColors.navy500,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              widget.room.activeGuestName!,
              style: AppTypography.bodySm.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isRD) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: AppRadius.roundedSm,
              ),
              child: const Text(
                'RD',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (widget.room.isDirty) {
      return Row(
        children: [
          const Icon(Icons.cleaning_services_outlined,
              size: 14, color: Color(0xFFD97706)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Perlu dibersihkan',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFD97706),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (widget.room.isMaintenance) {
      return Row(
        children: [
          Icon(Icons.build_circle_outlined,
              size: 14, color: AppColors.textDisabled),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Fasilitas off',
              style: AppTypography.caption.copyWith(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Available: show price
    return Text(
      '${_currFmt.format(widget.room.basePricePerNight)}/mlm',
      style: AppTypography.bodySm.copyWith(
        color: AppColors.navy700,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
