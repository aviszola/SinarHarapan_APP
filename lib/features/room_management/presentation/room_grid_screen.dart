import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../checkout/presentation/check_out_dialog.dart';
import '../../reservation/presentation/active_guests_modal.dart';
import '../../reservation/presentation/check_in_modal.dart';
import '../../shared_widgets/app_feedback.dart';
import '../../shared_widgets/app_header.dart';
import '../domain/room_model.dart';
import 'room_card.dart';
import 'room_controller.dart';
import 'room_filter_bar.dart';

class RoomGridScreen extends ConsumerStatefulWidget {
  final DateTime? fixedTime;
  const RoomGridScreen({super.key, this.fixedTime});

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

  void _showDirtyDialog(RoomModel room) async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      icon: Icons.cleaning_services_rounded,
      iconColor: AppColors.orange600,
      iconBgColor: AppColors.orange50,
      title: 'Pembersihan Kamar ${room.roomNumber}',
      message:
          'Kamar baru saja ditinggalkan tamu. Apakah housekeeping sudah selesai dan kamar siap dihuni kembali?',
      confirmLabel: 'Tandai Tersedia',
      cancelLabel: 'Nanti',
    );

    if (confirmed == true && mounted) {
      await ref.read(roomListProvider.notifier).markRoomCleaned(room.id);
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: 'Kamar Siap Huni',
          message: 'Kamar ${room.roomNumber} kini berstatus Available.',
        );
      }
    }
  }

  void _showMaintenanceDialog(RoomModel room) {
    AppConfirmationDialog.show(
      context,
      icon: Icons.construction_rounded,
      iconColor: AppColors.textDisabled,
      iconBgColor: AppColors.surface,
      title: 'Kamar ${room.roomNumber} Dalam Perbaikan',
      message:
          'Kamar ini sedang dinonaktifkan untuk renovasi/pemeliharaan. Pengaturan status dapat dilakukan melalui panel Manajer.',
      cancelLabel: 'Tutup',
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userName  = authState.user?.fullName ?? 'Resepsionis';
    final userRole  = authState.user?.isManager == true ? 'MANAGER' : 'RECEPTIONIST';

    final filteredRooms = ref.watch(filteredRoomsProvider);
    final stats         = ref.watch(roomStatsProvider);
    final occupiedCount = stats[RoomStatusType.occupied] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Banner DATA CONTOH jika mode mock aktif
          if (AppConfig.useMock)
            Container(
              width: double.infinity,
              color: AppColors.orange800,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Center(
                child: Text(
                  '⚠️ DATA CONTOH (MOCK MODE AKTIF) - JANGAN GUNAKAN UNTUK TRANSAKSI ASLI',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ),

          // ── Top Bar ─────────────────────────────────────────────
          ReceptionistTopBar(
            userName: userName,
            userRole: userRole,
            activeWaCount: occupiedCount,
            fixedTime: widget.fixedTime,
            onLogout: _handleLogout,
            onOpenActiveGuests: _handleOpenActiveGuests,
            // Sembunyikan portal Manajer jika login sebagai Resepsionis
            onOpenManagerPortal: authState.user?.isManager == true
                ? () => context.go('/manager/dashboard')
                : null,
          ),

          // ── Unified Command Bar (Stats + Filters + Refresh) ───────
          RoomFilterBar(
            onRefresh: _handleRefresh,
            isRefreshing: _isRefreshing,
          ),

          // ── Room Grid ─────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.navy700,
              child: filteredRooms.isEmpty
                  ? Center(
                      child: AppEmptyState(
                        icon: Icons.meeting_room_outlined,
                        title: 'Tidak Ada Kamar Ditemukan',
                        message:
                            'Tidak ada unit kamar yang sesuai dengan filter atau kata kunci saat ini.',
                        actionLabel: 'Reset Filter',
                        onAction: () {
                          ref.read(roomFilterProvider.notifier).state =
                              const RoomFilterState();
                        },
                      ),
                    )
                  : _RoomGrid(rooms: filteredRooms, onTap: _handleRoomTap),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Room Grid (Organized by Floor) ───────────────────────────────────
class _RoomGrid extends StatelessWidget {
  final List<RoomModel> rooms;
  final void Function(RoomModel) onTap;

  const _RoomGrid({required this.rooms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Group rooms by floor for clear physical spatial awareness
    final Map<int, List<RoomModel>> roomsByFloor = {};
    for (final r in rooms) {
      roomsByFloor.putIfAbsent(r.floor, () => []).add(r);
    }
    final sortedFloors = roomsByFloor.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = 4;
        if (constraints.maxWidth >= 1500) {
          cols = 5;
        } else if (constraints.maxWidth >= 1150) {
          cols = 4;
        } else if (constraints.maxWidth >= 820) {
          cols = 3;
        } else if (constraints.maxWidth >= 540) {
          cols = 2;
        } else {
          cols = 1;
        }

        final isCompact = constraints.maxWidth < 600;

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppSpacing.sm + 4 : AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: sortedFloors.length,
          itemBuilder: (context, floorIndex) {
            final floor = sortedFloors[floorIndex];
            final floorRooms = roomsByFloor[floor]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.navy100,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: const Icon(Icons.layers_rounded, size: 14, color: AppColors.navy700),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lantai $floor',
                        style: AppTypography.h3.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.navy50,
                          borderRadius: AppRadius.roundedSm,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${floorRooms.length} Unit',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: isCompact ? 8 : AppSpacing.md,
                    mainAxisSpacing: isCompact ? 8 : AppSpacing.md,
                    mainAxisExtent: isCompact ? (cols == 1 ? 120 : 134) : 132,
                  ),
                  itemCount: floorRooms.length,
                  itemBuilder: (context, index) {
                    return RoomCard(
                      room: floorRooms[index],
                      onTap: () => onTap(floorRooms[index]),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

