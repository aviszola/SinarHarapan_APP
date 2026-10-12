import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../../core/config/app_config.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../checkout/presentation/check_out_dialog.dart';
import '../../reservation/presentation/active_guests_modal.dart';
import '../../reservation/presentation/check_in_modal.dart';
import '../../shared_widgets/app_feedback.dart';
import '../../shared_widgets/app_header.dart';
import '../../shared_widgets/empty_state.dart';
import '../data/room_seed_data.dart';
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

  Future<T?> _showRoomDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = false,
  }) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: builder,
      );
    }

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Tutup Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (ctx, _, _) => builder(ctx),
      transitionBuilder: (ctx, anim1, _, child) {
        final curveValue = Curves.easeOutCubic.transform(anim1.value);
        final scale = 0.96 + (0.04 * curveValue);
        return Opacity(
          opacity: anim1.value,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
    );
  }

  void _handleRoomTap(RoomModel room) async {
    final highlightNotifier = ref.read(highlightedRoomIdProvider.notifier);

    if (room.isAvailable) {
      final isSuccess = await _showRoomDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CheckInModal(room: room),
      );

      if (isSuccess == true && mounted) {
        final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        if (!disableAnimations) {
          // Tunggu transisi exit dialog 150ms selesai
          await Future.delayed(const Duration(milliseconds: 150));
        }

        if (mounted) {
          highlightNotifier.state = room.id;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (highlightNotifier.state == room.id) {
              highlightNotifier.state = null;
            }
          });
          AppFeedback.showSuccess(
            context,
            title: 'Check-in Berhasil & Lunas',
            message: 'Kamar ${room.roomNumber} berhasil check-in.',
          );
        }
      }
    } else if (room.isOccupied) {
      final isSuccess = await _showRoomDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CheckOutDialog(room: room),
      );

      if (isSuccess == true && mounted) {
        final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        if (!disableAnimations) {
          await Future.delayed(const Duration(milliseconds: 150));
        }

        if (mounted) {
          highlightNotifier.state = room.id;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (highlightNotifier.state == room.id) {
              highlightNotifier.state = null;
            }
          });
        }
      }
    } else if (room.isDirty) {
      _showDirtyDialog(room);
    } else if (room.isMaintenance) {
      _showMaintenanceDialog(room);
    }
  }

  void _showDirtyDialog(RoomModel room) async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      icon: AppIcons.clean,
      iconColor: AppColors.statusDirty,
      iconBgColor: AppColors.statusDirtyBg,
      title: 'Pembersihan Kamar ${room.roomNumber}',
      message:
          'Kamar baru saja selesai dihuni tamu. Apakah staf pembersih sudah selesai menyiapkan kamar untuk tamu berikutnya?',
      confirmLabel: 'Tandai Siap Huni',
      cancelLabel: 'Nanti Dulu',
    );

    if (confirmed == true && mounted) {
      await ref.read(roomListProvider.notifier).markRoomCleaned(room.id);
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: 'Kamar Siap Huni',
          message: 'Kamar ${room.roomNumber} telah diperbarui ke status Tersedia.',
        );
      }
    }
  }

  void _showMaintenanceDialog(RoomModel room) {
    AppConfirmationDialog.show(
      context,
      icon: AppIcons.maintenance,
      iconColor: AppColors.textDisabled,
      iconBgColor: AppColors.surface,
      title: 'Kamar ${room.roomNumber} Dalam Perawatan',
      message:
          'Kamar ini sedang dalam proses pemeliharaan fasilitas. Pengaturan kamar dapat diubah melalui menu pengaturan manajer.',
      cancelLabel: 'Tutup',
    );
  }

  void _handleOpenActiveGuests() {
    final rooms = ref.read(roomListProvider).value ?? [];
    final occupied = rooms.where((r) => r.isOccupied).toList();
    _showRoomDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ActiveGuestsModal(occupiedRooms: occupied),
    );
  }

  void _handleLogout() async {
    final user = ref.read(authStateProvider).user;
    final confirmed = await AppFeedback.showLogout(context, user: user);
    if (confirmed && mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
        AppFeedback.showInfo(
          context,
          title: 'Sesi Berakhir',
          message: 'Anda telah berhasil keluar dari sistem.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userName  = authState.user?.fullName ?? 'Resepsionis';
    final userRole  = authState.user?.isManager == true ? 'MANAJER' : 'RESEPSIONIS';

    final roomListAsync = ref.watch(roomListProvider);
    final filteredRooms = ref.watch(filteredRoomsProvider);
    final stats         = ref.watch(roomStatsProvider);
    final occupiedCount = stats[RoomStatusType.occupied] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Peringatan Mock Mode jika aktif
          if (AppConfig.useMock)
            Container(
              width: double.infinity,
              color: AppColors.brandOrange,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Center(
                child: Text(
                  'Mode Data Simulasi Aktif',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

          // Header Resepsionis Rapi
          ReceptionistTopBar(
            userName: userName,
            userRole: userRole,
            activeWaCount: occupiedCount,
            fixedTime: widget.fixedTime,
            onLogout: _handleLogout,
            onOpenActiveGuests: _handleOpenActiveGuests,
            onOpenManagerPortal: authState.user?.isManager == true
                ? () => context.go('/manager/dashboard')
                : null,
          ),

          // Bar Filter & Ringkasan Okupansi
          RoomFilterBar(
            onRefresh: _handleRefresh,
            isRefreshing: _isRefreshing,
          ),

          // Area Grid Kamar dengan Padding Konsisten
          Expanded(
            child: roomListAsync.when(
              loading: () => const _RoomGridSkeleton(),
              error: (err, _) => Center(
                child: EmptyStateWidget(
                  icon: AppIcons.alertTriangle,
                  title: 'Gagal Memuat Data Kamar',
                  message: 'Terjadi kendala saat menghubungkan ke database: $err',
                  action: ElevatedButton(
                    onPressed: _handleRefresh,
                    child: const Text('Coba Lagi'),
                  ),
                ),
              ),
              data: (_) {
                final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
                final filter = ref.watch(roomFilterProvider);

                return AnimatedSwitcher(
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 150),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      ...previousChildren,
                      ?currentChild,
                    ],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: filteredRooms.isEmpty
                      ? Center(
                          key: const ValueKey('empty_room_state'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tidak ada kamar yang cocok.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.brandNavy, width: 1),
                                    foregroundColor: AppColors.brandNavy,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: AppRadius.roundedSm,
                                    ),
                                  ),
                                  onPressed: () {
                                    ref.read(roomFilterProvider.notifier).state =
                                        const RoomFilterState();
                                  },
                                  child: const Text('Reset filter'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _RoomGrid(
                          key: ValueKey(
                            'room_grid_${filter.searchQuery}_${filter.roomType}_${filter.floor}_${filter.status}_${filteredRooms.length}',
                          ),
                          rooms: filteredRooms,
                          onTap: _handleRoomTap,
                          onRefresh: _handleRefresh,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Room Grid Berdasarkan Lantai dengan MaxCrossAxisExtent ───────────
class _RoomGrid extends ConsumerWidget {
  final List<RoomModel> rooms;
  final void Function(RoomModel) onTap;
  final Future<void> Function() onRefresh;

  const _RoomGrid({
    super.key,
    required this.rooms,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightedId = ref.watch(highlightedRoomIdProvider);

    // Kelompokkan kamar berdasarkan lantai
    final Map<int, List<RoomModel>> roomsByFloor = {};
    for (final r in rooms) {
      roomsByFloor.putIfAbsent(r.floor, () => []).add(r);
    }
    final sortedFloors = roomsByFloor.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.brandNavy,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: sortedFloors.length,
        itemBuilder: (context, floorIndex) {
          final floor = sortedFloors[floorIndex];
          final floorRooms = roomsByFloor[floor]!..sort(compareRooms);

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Lantai
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Lantai $floor · ${floorRooms.length} kamar',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.brandNavyDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Grid Kamar Responsif (MaxCrossAxisExtent 280-300px)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 290,
                    mainAxisExtent: 184,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: floorRooms.length,
                  itemBuilder: (context, index) {
                    final room = floorRooms[index];
                    return RoomCard(
                      key: ValueKey('room_card_${room.id}'),
                      room: room,
                      isHighlighted: highlightedId == room.id,
                      onTap: () => onTap(room),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Skeleton Loader untuk Transisi Halus ────────────────────────────
class _RoomGridSkeleton extends StatelessWidget {
  const _RoomGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SkeletonBox(width: 80, height: 20),
              SizedBox(width: 8),
              SkeletonBox(width: 50, height: 16),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 290,
                mainAxisExtent: 156,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.rounded,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: SkeletonBox(width: 55, height: 16)),
                          SizedBox(width: 6),
                          SkeletonBox(width: 44, height: 18),
                        ],
                      ),
                      SkeletonBox(width: 80, height: 14),
                      SkeletonBox(width: double.infinity, height: 32),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
