import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../checkout/presentation/check_out_dialog.dart';
import '../../reservation/presentation/active_guests_modal.dart';
import '../../reservation/presentation/check_in_modal.dart';
import '../../shared_widgets/app_header.dart';
import '../../shared_widgets/status_badge.dart';
import '../domain/room_model.dart';
import 'room_card.dart';
import 'room_controller.dart';
import 'room_filter_bar.dart';

class RoomGridScreen extends ConsumerStatefulWidget {
  const RoomGridScreen({super.key});

  @override
  ConsumerState<RoomGridScreen> createState() => _RoomGridScreenState();
}

class _RoomGridScreenState extends ConsumerState<RoomGridScreen> {
  Timer? _pollTimer;
  int _pollCountdown = 15;

  @override
  void initState() {
    super.initState();
    _startPollTicker();
  }

  void _startPollTicker() {
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_pollCountdown <= 1) {
          _pollCountdown = 15;
          ref.read(roomListProvider.notifier).loadRooms();
        } else {
          _pollCountdown--;
        }
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _handleRoomTap(RoomModel room) {
    if (room.isAvailable) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CheckInModal(room: room),
      );
    } else if (room.isOccupied) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CheckOutDialog(room: room),
      );
    } else if (room.isDirty) {
      _showDirtyDialog(room);
    } else if (room.isMaintenance) {
      _showMaintenanceDialog(room);
    }
  }

  void _showDirtyDialog(RoomModel room) {
    showDialog(
      context: context,
      builder: (ctx) => _SimpleDialog(
        icon: Icons.cleaning_services_outlined,
        iconColor: const Color(0xFFD97706),
        title: 'Pembersihan Kamar ${room.roomNumber}',
        body:
            'Kamar baru saja ditinggalkan tamu. Apakah housekeeping sudah selesai dan kamar siap dihuni kembali?',
        cancelLabel: 'Nanti',
        confirmLabel: 'Tandai Tersedia',
        confirmVariant: _ConfirmVariant.primary,
        onConfirm: () async {
          Navigator.of(ctx).pop();
          await ref.read(roomListProvider.notifier).markRoomCleaned(room.id);
          if (mounted) {
            _showSnack(
              'Kamar ${room.roomNumber} kini berstatus Available.',
              AppColors.statusAvailable,
            );
          }
        },
      ),
    );
  }

  void _showMaintenanceDialog(RoomModel room) {
    showDialog(
      context: context,
      builder: (ctx) => _SimpleDialog(
        icon: Icons.build_circle_outlined,
        iconColor: AppColors.textDisabled,
        title: 'Kamar ${room.roomNumber} Dalam Perbaikan',
        body:
            'Kamar ini sedang dinonaktifkan untuk renovasi. Pengaturan status dapat dilakukan melalui panel Manajer.',
        cancelLabel: 'Tutup',
        onConfirm: null,
      ),
    );
  }

  void _handleOpenActiveGuests() {
    final rooms = ref.read(roomListProvider).value ?? [];
    final occupied = rooms.where((r) => r.isOccupied).toList();
    showDialog(
      context: context,
      builder: (_) => ActiveGuestsModal(occupiedRooms: occupied),
    );
  }

  void _handleLogout() {
    ref.read(authStateProvider.notifier).logout();
    context.go('/login');
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: color, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userName  = authState.user?.fullName ?? 'Resepsionis';
    final userRole  = authState.user?.isManager == true ? 'MANAGER' : 'RECEPTIONIST';

    final filteredRooms = ref.watch(filteredRoomsProvider);
    final stats         = ref.watch(roomStatsProvider);
    final totalRooms    = stats.values.fold<int>(0, (a, b) => a + b);
    final occupiedCount = stats[RoomStatusType.occupied] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Top Bar ─────────────────────────────────────────────
          ReceptionistTopBar(
            userName: userName,
            userRole: userRole,
            activeWaCount: occupiedCount,
            onLogout: _handleLogout,
            onOpenActiveGuests: _handleOpenActiveGuests,
            onOpenManagerPortal: () => context.go('/manager/dashboard'),
          ),

          // ── Stats Ribbon ─────────────────────────────────────────
          _StatsRibbon(
            stats: stats,
            totalRooms: totalRooms,
            pollCountdown: _pollCountdown,
          ),

          // ── Filter Bar ────────────────────────────────────────────
          const RoomFilterBar(),

          // ── Room Grid ─────────────────────────────────────────────
          Expanded(
            child: filteredRooms.isEmpty
                ? _EmptyState()
                : _RoomGrid(rooms: filteredRooms, onTap: _handleRoomTap),
          ),
        ],
      ),
    );
  }
}

// ── Stats Ribbon ─────────────────────────────────────────────────────
class _StatsRibbon extends StatelessWidget {
  final Map<RoomStatusType, int> stats;
  final int totalRooms;
  final int pollCountdown;

  const _StatsRibbon({
    required this.stats,
    required this.totalRooms,
    required this.pollCountdown,
  });

  @override
  Widget build(BuildContext context) {
    final available   = stats[RoomStatusType.available]   ?? 0;
    final occupied    = stats[RoomStatusType.occupied]    ?? 0;
    final dirty       = stats[RoomStatusType.dirty]       ?? 0;
    final maintenance = stats[RoomStatusType.maintenance] ?? 0;

    final occupancyRate = totalRooms > 0
        ? (occupied / totalRooms * 100).round()
        : 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Occupancy pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navy900,
                borderRadius: AppRadius.roundedMd,
              ),
              child: Row(
                children: [
                  Text(
                    'Hunian',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.navy100.withAlpha(160),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$occupancyRate%',
                    style: AppTypography.h3.copyWith(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($occupied/$totalRooms)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.navy100.withAlpha(120),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Status dots
            _StatusDot(color: AppColors.statusAvailable, label: 'Available', count: available),
            const SizedBox(width: AppSpacing.md),
            _StatusDot(color: AppColors.statusOccupied,  label: 'Occupied',  count: occupied),
            const SizedBox(width: AppSpacing.md),
            _StatusDot(color: AppColors.statusDirty,     label: 'Dirty',     count: dirty),
            const SizedBox(width: AppSpacing.md),
            _StatusDot(color: AppColors.statusMaintenance, label: 'Maintenance', count: maintenance),

            const SizedBox(width: AppSpacing.lg),

            // Live sync indicator
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: pollCountdown <= 3
                        ? AppColors.orange600
                        : const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Sinkron ${pollCountdown}s',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _StatusDot({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          '$label · $count',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

// ── Room Grid ────────────────────────────────────────────────────────
class _RoomGrid extends StatelessWidget {
  final List<RoomModel> rooms;
  final void Function(RoomModel) onTap;

  const _RoomGrid({required this.rooms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = 4;
        if (constraints.maxWidth >= 1400) {
          cols = 6;
        } else if (constraints.maxWidth >= 1100) {
          cols = 5;
        } else if (constraints.maxWidth >= 850) {
          cols = 4;
        } else if (constraints.maxWidth >= 550) {
          cols = 3;
        } else if (constraints.maxWidth >= 360) {
          cols = 2;
        } else {
          cols = 1;
        }

        final isCompact = constraints.maxWidth < 600;

        return GridView.builder(
          padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: isCompact ? AppSpacing.sm : AppSpacing.md,
            mainAxisSpacing: isCompact ? AppSpacing.sm : AppSpacing.md,
            mainAxisExtent: 126,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            return RoomCard(
              room: rooms[index],
              onTap: () => onTap(rooms[index]),
            );
          },
        );
      },
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.navy50,
              borderRadius: AppRadius.roundedLg,
            ),
            child: const Icon(
              Icons.meeting_room_outlined,
              size: 32,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tidak ada kamar yang cocok',
            style: AppTypography.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Coba ubah filter yang dipilih',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

// ── Simple Dialog ─────────────────────────────────────────────────────
enum _ConfirmVariant { primary, destructive }

class _SimpleDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String? cancelLabel;
  final String? confirmLabel;
  final _ConfirmVariant? confirmVariant;
  final VoidCallback? onConfirm;

  const _SimpleDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.cancelLabel,
    this.confirmLabel,
    this.confirmVariant,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: AppTypography.h3),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Text(body, style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              )),

              const SizedBox(height: AppSpacing.xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cancelLabel != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        cancelLabel!,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (onConfirm != null && confirmLabel != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: confirmVariant == _ConfirmVariant.destructive
                            ? AppColors.statusOccupied
                            : AppColors.orange600,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.roundedMd,
                        ),
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onPressed: onConfirm,
                      child: Text(
                        confirmLabel!,
                        style: AppTypography.bodySm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
