import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../shared_widgets/status_badge.dart';
import '../domain/room_model.dart';

/// Kartu Kamar Hotel — Didesain ergonomis untuk kecepatan frontdesk.
/// - Terisi: Nama tamu (ellipsis + tooltip), tanggal check-out, tombol Check-out.
/// - Tersedia: Tipe kamar, harga per malam (tabular figures), tombol Check-in.
class RoomCard extends StatefulWidget {
  final RoomModel room;
  final VoidCallback onTap;
  final bool isHighlighted;

  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;
  late final FocusNode _focusNode;
  late final AnimationController _highlightController;
  late final Animation<double> _highlightAnimation;

  static final _currFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Color get _statusStripeColor {
    return switch (widget.room.status) {
      RoomStatusType.available => AppColors.statusAvailable,
      RoomStatusType.occupied => AppColors.statusOccupied,
      RoomStatusType.dirty => AppColors.statusDirty,
      RoomStatusType.maintenance => AppColors.statusMaintenance,
    };
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _highlightAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_highlightController);

    if (widget.isHighlighted) {
      _highlightController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant RoomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!disableAnimations) {
        _highlightController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      container: true,
      identifier: 'room_card_${room.roomNumber}',
      child: Focus(
        focusNode: _focusNode,
      onFocusChange: (hasF) => setState(() => _isFocused = hasF),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: room.isMaintenance ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _highlightAnimation,
            builder: (context, _) {
              final highlightVal = _highlightAnimation.value;
              final effectiveBorderColor = (_isHovered || _isFocused)
                  ? AppColors.brandNavy
                  : (highlightVal > 0.05
                      ? _statusStripeColor
                      : AppColors.border);
              final effectiveBorderWidth = (_isHovered || _isFocused || highlightVal > 0.05) ? 1.5 : 1.0;
              final effectiveBgColor = highlightVal > 0.01
                  ? (Color.lerp(
                        AppColors.surface,
                        _statusStripeColor.withValues(alpha: 0.12),
                        highlightVal,
                      ) ??
                      AppColors.surface)
                  : AppColors.surface;

              return AnimatedScale(
                scale: disableAnimations ? 1.0 : (_isPressed ? 0.98 : 1.0),
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 180 || constraints.maxHeight < 150;

                    if (isCompact) {
                      return AnimatedContainer(
                        duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 140),
                        decoration: BoxDecoration(
                          color: effectiveBgColor,
                          borderRadius: AppRadius.rounded,
                          border: Border.all(
                            color: effectiveBorderColor,
                            width: effectiveBorderWidth,
                          ),
                          boxShadow: (_isHovered || _isFocused) ? AppElevation.subtle : AppElevation.none,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedContainer(
                              duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 180),
                              curve: Curves.easeInOut,
                              width: 4,
                              color: _statusStripeColor,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Kamar ${room.roomNumber}',
                                          style: AppTextStyles.titleSmall.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.brandNavyDark,
                                            fontSize: 16,
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                          ),
                                          maxLines: 1,
                                        ),
                                        StatusBadge(status: room.status, compact: true),
                                      ],
                                    ),
                                    Text(
                                      room.facilities.isNotEmpty
                                          ? room.facilities.join(', ')
                                          : '${room.roomType} · Lt. ${room.floor}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      room.isAvailable
                                          ? '${_currFmt.format(room.basePricePerNight)} / malam'
                                          : (room.activeGuestName ?? _getStatusName(room.status)),
                                      style: AppTextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: room.isAvailable ? AppColors.brandNavy : AppColors.textPrimary,
                                        fontSize: 12,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: _buildCompactActionButton(room),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return AnimatedContainer(
                      duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        color: effectiveBgColor,
                        borderRadius: AppRadius.rounded,
                        border: Border.all(
                          color: effectiveBorderColor,
                          width: effectiveBorderWidth,
                        ),
                        boxShadow: (_isHovered || _isFocused) ? AppElevation.subtle : AppElevation.none,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Garis Status 4px di Sisi Kiri
                          AnimatedContainer(
                            duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 180),
                            curve: Curves.easeInOut,
                            width: 4,
                            color: _statusStripeColor,
                          ),

                          // Konten Kartu
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Header Kartu: Nomor Kamar & Status Badge
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Kamar ${room.roomNumber}',
                                              style: AppTextStyles.titleSmall.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.brandNavyDark,
                                                fontSize: 18,
                                                fontFeatures: const [FontFeature.tabularFigures()],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${room.roomType} · Lt. ${room.floor}',
                                              style: AppTextStyles.caption.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      StatusBadge(status: room.status),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Konten Spesifik Status
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SingleChildScrollView(
                                        physics: const NeverScrollableScrollPhysics(),
                                        child: _buildStatusSpecificContent(room),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Tombol Aksi Cepat
                                  _buildActionButton(room),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStatusSpecificContent(RoomModel room) {
    if (room.isOccupied) {
      final guestName = (room.activeGuestName != null && room.activeGuestName!.trim().isNotEmpty)
          ? room.activeGuestName!
          : '-';
      final isRedDoorz = room.bookingSource == 'REDDOORZ';
      final checkOutStr = room.expectedCheckOutTime != null
          ? DateFormat('d MMM, HH:mm', 'id').format(room.expectedCheckOutTime!)
          : '-';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nama Tamu dengan Ellipsis & Tooltip
          Row(
            children: [
              const AppIcon.small(
                AppIcons.guest,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: guestName,
                  child: Text(
                    guestName,
                    style: AppTextStyles.bodyMediumMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (isRedDoorz) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrangeTint,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    'RD',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.brandOrange,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Tanggal Check-out
          Row(
            children: [
              const AppIcon.small(
                AppIcons.calendar,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Keluar: $checkOutStr',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (room.isAvailable) {
      final facilityText = room.facilities.isNotEmpty
          ? room.facilities.join(', ')
          : '${room.roomType} · Lt. ${room.floor}';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            facilityText,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${_currFmt.format(room.basePricePerNight)} / malam',
            style: AppTextStyles.numberLarge.copyWith(
              color: AppColors.brandNavy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (room.isDirty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const AppIcon.small(
                AppIcons.clean,
                color: AppColors.statusDirtyText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Perlu pembersihan staf',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.statusDirtyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Kamar selesai dihuni tamu.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    // Status Maintenance
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            const AppIcon.small(
              AppIcons.maintenance,
              color: AppColors.statusMaintenanceText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Perawatan fasilitas',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.statusMaintenanceText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Tidak dapat dipesan sementara.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButton(RoomModel room) {
    if (room.isAvailable) {
      return Semantics(
        container: true,
        button: true,
        identifier: 'room_action_checkin_button',
        child: SizedBox(
          width: double.infinity,
          height: 34,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandOrange,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.roundedSm,
              ),
            ),
            onPressed: widget.onTap,
            icon: const AppIcon.small(AppIcons.checkIn),
            label: const Text('Check-in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    if (room.isOccupied) {
      return Semantics(
        container: true,
        button: true,
        identifier: 'room_action_checkout_button',
        child: SizedBox(
          width: double.infinity,
          height: 34,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusOccupiedText,
              side: const BorderSide(color: AppColors.statusOccupied),
              backgroundColor: AppColors.statusOccupiedBg.withAlpha(80),
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.roundedSm,
              ),
            ),
            onPressed: widget.onTap,
            icon: const AppIcon.small(AppIcons.checkOut),
            label: const Text('Check-out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    if (room.isDirty) {
      return Semantics(
        container: true,
        button: true,
        identifier: 'room_action_clean_button',
        child: SizedBox(
          width: double.infinity,
          height: 34,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusDirtyText,
              side: const BorderSide(color: AppColors.statusDirty),
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.roundedSm,
              ),
            ),
            onPressed: widget.onTap,
            icon: const AppIcon.small(AppIcons.check),
            label: const Text('Tandai Siap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 34,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.border),
          padding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.roundedSm,
          ),
        ),
        onPressed: widget.onTap,
        child: const Text('Detail Status', style: TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildCompactActionButton(RoomModel room) {
    if (room.isAvailable) {
      return Semantics(
        container: true,
        button: true,
        identifier: 'room_action_checkin_button',
        child: SizedBox(
          height: 30,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandOrange,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
            ),
            onPressed: widget.onTap,
            child: const Text('Check-in', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    if (room.isOccupied) {
      return Semantics(
        container: true,
        button: true,
        identifier: 'room_action_checkout_button',
        child: SizedBox(
          height: 30,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusOccupiedText,
              side: const BorderSide(color: AppColors.statusOccupied),
              backgroundColor: AppColors.statusOccupiedBg,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
            ),
            onPressed: widget.onTap,
            child: const Text('Check-out', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    if (room.isDirty) {
      return Semantics(
        container: true,
        button: true,
        identifier: 'room_action_clean_button',
        child: SizedBox(
          height: 30,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusDirtyText,
              side: const BorderSide(color: AppColors.statusDirty),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
            ),
            onPressed: widget.onTap,
            child: const Text('Bersihkan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
        ),
        onPressed: widget.onTap,
        child: const Text('Detail', style: TextStyle(fontSize: 11.5)),
      ),
    );
  }

  String _getStatusName(RoomStatusType status) {
    switch (status) {
      case RoomStatusType.available:
        return 'Tersedia';
      case RoomStatusType.occupied:
        return 'Terisi';
      case RoomStatusType.dirty:
        return 'Kotor';
      case RoomStatusType.maintenance:
        return 'Perawatan';
    }
  }
}
