import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../checkout/presentation/check_out_dialog.dart';
import '../../reservation/presentation/active_guests_modal.dart';
import '../../reservation/presentation/check_in_modal.dart';
import '../../shared_widgets/app_header.dart';
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
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await ref.read(roomListProvider.notifier).loadRooms();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
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

  void _handleLogout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
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
          // Banner DATA CONTOH jika mode mock aktif
          if (AppConfig.useMock)
            Container(
              width: double.infinity,
              color: Colors.amber.shade800,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Center(
                child: Text(
                  '⚠️ DATA CONTOH (MOCK MODE AKTIF) - JANGAN GUNAKAN UNTUK TRANSAKSI ASLI',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),

          // ── Top Bar ─────────────────────────────────────────────
          ReceptionistTopBar(
            userName: userName,
            userRole: userRole,
            activeWaCount: occupiedCount,
            onLogout: _handleLogout,
            onOpenActiveGuests: _handleOpenActiveGuests,
            // Sembunyikan portal Manajer jika login sebagai Resepsionis
            onOpenManagerPortal: authState.user?.isManager == true
                ? () => context.go('/manager/dashboard')
                : null,
          ),

          // ── Stats Ribbon ─────────────────────────────────────────
          _StatsRibbon(
            stats: stats,
            totalRooms: totalRooms,
            onRefresh: _handleRefresh,
            isRefreshing: _isRefreshing,
          ),

          // ── Filter Bar ────────────────────────────────────────────
          const RoomFilterBar(),

          // ── Room Grid ─────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.navy700,
              child: filteredRooms.isEmpty
                  ? _EmptyState()
                  : _RoomGrid(rooms: filteredRooms, onTap: _handleRoomTap),
            ),
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
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const _StatsRibbon({
    required this.stats,
    required this.totalRooms,
    required this.onRefresh,
    required this.isRefreshing,
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

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.sm + 4 : AppSpacing.md,
          vertical: AppSpacing.sm + 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Occupancy pill - airy, modern, lightweight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Text(
                    'Hunian',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$occupancyRate%',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.navy900,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '($occupied/$totalRooms)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 11.5,
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

            // Manual Refresh button — replaces heavy auto-sync timer
            InkWell(
              onTap: isRefreshing ? null : onRefresh,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRefreshing)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy700,
                        ),
                      )
                    else
                      const Icon(
                        Icons.refresh_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    const SizedBox(width: 5),
                    Text(
                      isRefreshing ? 'Memuat...' : 'Segarkan',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.navy900,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
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
          padding: EdgeInsets.all(isCompact ? AppSpacing.sm + 4 : AppSpacing.lg),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: isCompact ? 8 : AppSpacing.md,
            mainAxisSpacing: isCompact ? 8 : AppSpacing.md,
            mainAxisExtent: isCompact ? (cols == 1 ? 116 : 130) : 126,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(440.0, screenWidth - 32),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: (isMobile ? AppTypography.bodyLg : AppTypography.h3).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
