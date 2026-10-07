import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../shared_widgets/status_badge.dart';
import 'room_controller.dart';

/// Clean, unified property command bar following modern SaaS design (Linear / Stripe style).
/// Integrates live property pulse (occupancy & status breakdown) with ergonomic search & filtering.
class RoomFilterBar extends ConsumerWidget {
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  const RoomFilterBar({
    super.key,
    this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(roomFilterProvider);
    final notifier = ref.read(roomFilterProvider.notifier);
    final stats = ref.watch(roomStatsProvider);
    final totalRooms = stats.values.fold<int>(0, (a, b) => a + b);

    final available = stats[RoomStatusType.available] ?? 0;
    final occupied = stats[RoomStatusType.occupied] ?? 0;
    final dirty = stats[RoomStatusType.dirty] ?? 0;
    final maintenance = stats[RoomStatusType.maintenance] ?? 0;
    final occupancyRate = totalRooms > 0 ? (occupied / totalRooms * 100).round() : 0;

    final hasActiveFilter = filter.searchQuery.isNotEmpty ||
        filter.roomType != 'ALL' ||
        filter.floor != 0 ||
        filter.status != null;

    final roomTypeDropdown = _buildFilterDropdown<String>(
      value: filter.roomType,
      icon: Icon(
        Icons.king_bed_outlined,
        size: 15,
        color: filter.roomType != 'ALL' ? AppColors.navy700 : AppColors.textSecondary,
      ),
      label: filter.roomType == 'ALL' ? 'Semua Tipe' : filter.roomType,
      isActive: filter.roomType != 'ALL',
      items: const [
        DropdownMenuItem(
          value: 'ALL',
          child: Text('Semua Tipe', style: TextStyle(fontSize: 12.5)),
        ),
        DropdownMenuItem(
          value: 'Standard',
          child: Text('Standard', style: TextStyle(fontSize: 12.5)),
        ),
        DropdownMenuItem(
          value: 'Superior',
          child: Text('Superior', style: TextStyle(fontSize: 12.5)),
        ),
        DropdownMenuItem(
          value: 'Deluxe',
          child: Text('Deluxe', style: TextStyle(fontSize: 12.5)),
        ),
        DropdownMenuItem(
          value: 'Family',
          child: Text('Family', style: TextStyle(fontSize: 12.5)),
        ),
      ],
      onChanged: (val) {
        if (val != null) {
          notifier.state = filter.copyWith(roomType: val);
        }
      },
    );

    final floorDropdown = _buildFilterDropdown<int>(
      value: filter.floor,
      icon: Icon(
        Icons.layers_outlined,
        size: 15,
        color: filter.floor != 0 ? AppColors.navy700 : AppColors.textSecondary,
      ),
      label: filter.floor == 0 ? 'Semua Lantai' : 'Lantai ${filter.floor}',
      isActive: filter.floor != 0,
      items: const [
        DropdownMenuItem(
          value: 0,
          child: Text('Semua Lantai', style: TextStyle(fontSize: 12.5)),
        ),
        DropdownMenuItem(
          value: 1,
          child: Text('Lantai 1', style: TextStyle(fontSize: 12.5)),
        ),
        DropdownMenuItem(
          value: 2,
          child: Text('Lantai 2', style: TextStyle(fontSize: 12.5)),
        ),
        DropdownMenuItem(
          value: 3,
          child: Text('Lantai 3', style: TextStyle(fontSize: 12.5)),
        ),
      ],
      onChanged: (val) {
        if (val != null) {
          notifier.state = filter.copyWith(floor: val);
        }
      },
    );

    final statusDropdown = _buildFilterDropdown<RoomStatusType?>(
      value: filter.status,
      icon: _getStatusDotOrIcon(filter.status),
      label: _getStatusLabel(filter.status, stats, totalRooms),
      isActive: filter.status != null,
      items: [
        DropdownMenuItem(
          value: null,
          child: Text('Semua Status ($totalRooms)', style: const TextStyle(fontSize: 12.5)),
        ),
        DropdownMenuItem(
          value: RoomStatusType.available,
          child: Row(
            children: [
              _buildDot(AppColors.statusAvailable),
              const SizedBox(width: 8),
              Text('Available (${stats[RoomStatusType.available] ?? 0})',
                  style: const TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        DropdownMenuItem(
          value: RoomStatusType.occupied,
          child: Row(
            children: [
              _buildDot(AppColors.statusOccupied),
              const SizedBox(width: 8),
              Text('Occupied (${stats[RoomStatusType.occupied] ?? 0})',
                  style: const TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        DropdownMenuItem(
          value: RoomStatusType.dirty,
          child: Row(
            children: [
              _buildDot(AppColors.statusDirty),
              const SizedBox(width: 8),
              Text('Dirty (${stats[RoomStatusType.dirty] ?? 0})',
                  style: const TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
        DropdownMenuItem(
          value: RoomStatusType.maintenance,
          child: Row(
            children: [
              _buildDot(AppColors.statusMaintenance),
              const SizedBox(width: 8),
              Text('Maintenance (${stats[RoomStatusType.maintenance] ?? 0})',
                  style: const TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
      ],
      onChanged: (val) {
        if (val == null) {
          notifier.state = filter.copyWith(clearStatus: true);
        } else {
          notifier.state = filter.copyWith(status: val);
        }
      },
    );

    Widget buildResetButton() {
      return InkWell(
        onTap: () => notifier.state = const RoomFilterState(),
        borderRadius: AppRadius.roundedSm,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.errorBg,
            borderRadius: AppRadius.roundedSm,
            border: Border.all(
              color: AppColors.error.withAlpha(80),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded, size: 14, color: AppColors.errorText),
              SizedBox(width: 4),
              Text(
                'Reset Filter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.errorText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildSearchField({double? width}) {
      return SizedBox(
        width: width,
        height: 36,
        child: TextField(
          style: const TextStyle(fontSize: 13),
          scrollPadding: const EdgeInsets.only(bottom: 120, top: 20),
          scrollPhysics: const ClampingScrollPhysics(),
          decoration: InputDecoration(
            hintText: 'Cari kamar / tamu...',
            hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textSecondary),
            suffixIcon: filter.searchQuery.isNotEmpty
                ? IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.clear, size: 15, color: AppColors.textSecondary),
                    onPressed: () => notifier.state = filter.copyWith(searchQuery: ''),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: AppColors.bg,
            border: OutlineInputBorder(
              borderRadius: AppRadius.roundedSm,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.roundedSm,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.roundedSm,
              borderSide: BorderSide(color: AppColors.navy700, width: 1.5),
            ),
          ),
          onChanged: (val) => notifier.state = filter.copyWith(searchQuery: val),
        ),
      );
    }

    Widget buildOccupancyPill() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.navy50,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(width: 4),
            Text(
              '($occupied/$totalRooms)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textDisabled,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildStatusDots() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDotWithLabel(AppColors.statusAvailable, 'Available', available),
          const SizedBox(width: 10),
          _buildDotWithLabel(AppColors.statusOccupied, 'Occupied', occupied),
          const SizedBox(width: 10),
          _buildDotWithLabel(AppColors.statusDirty, 'Dirty', dirty),
          const SizedBox(width: 10),
          _buildDotWithLabel(AppColors.statusMaintenance, 'Maint.', maintenance),
        ],
      );
    }

    Widget buildRefreshButton() {
      if (onRefresh == null) return const SizedBox.shrink();
      return Tooltip(
        message: 'Segarkan data kamar',
        child: InkWell(
          onTap: isRefreshing ? null : onRefresh,
          borderRadius: AppRadius.roundedMd,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isRefreshing
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy700),
                      )
                    : const Icon(Icons.refresh_rounded, size: 15, color: AppColors.navy700),
                const SizedBox(width: 5),
                Text(
                  'Segarkan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1060;
        final isCompact = constraints.maxWidth < 640;

        if (isDesktop) {
          // Unified 1-line SaaS Command Bar (Linear / Stripe style)
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                buildOccupancyPill(),
                const SizedBox(width: 12),
                buildStatusDots(),
                const Spacer(),
                buildSearchField(width: 200),
                const SizedBox(width: 8),
                roomTypeDropdown,
                const SizedBox(width: 8),
                floorDropdown,
                const SizedBox(width: 8),
                statusDropdown,
                if (hasActiveFilter) ...[
                  const SizedBox(width: 8),
                  buildResetButton(),
                ],
                if (onRefresh != null) ...[
                  const SizedBox(width: 8),
                  buildRefreshButton(),
                ],
              ],
            ),
          );
        }

        if (isCompact) {
          // Ergonomic 2-line layout for mobile phones
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      buildOccupancyPill(),
                      const SizedBox(width: 10),
                      buildStatusDots(),
                      if (onRefresh != null) ...[
                        const SizedBox(width: 8),
                        buildRefreshButton(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                buildSearchField(),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      roomTypeDropdown,
                      const SizedBox(width: 8),
                      floorDropdown,
                      const SizedBox(width: 8),
                      statusDropdown,
                      if (hasActiveFilter) ...[
                        const SizedBox(width: 8),
                        buildResetButton(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Tablet layout
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  buildOccupancyPill(),
                  const SizedBox(width: 12),
                  buildStatusDots(),
                  const Spacer(),
                  if (onRefresh != null) buildRefreshButton(),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    buildSearchField(width: 220),
                    const SizedBox(width: 8),
                    roomTypeDropdown,
                    const SizedBox(width: 8),
                    floorDropdown,
                    const SizedBox(width: 8),
                    statusDropdown,
                    if (hasActiveFilter) ...[
                      const SizedBox(width: 8),
                      buildResetButton(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required Widget icon,
    required String label,
    required bool isActive,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? AppColors.navy50 : AppColors.surface,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(
          color: isActive ? AppColors.navy700 : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: isActive ? AppColors.navy700 : AppColors.textSecondary,
          ),
          dropdownColor: AppColors.surface,
          borderRadius: AppRadius.roundedMd,
          selectedItemBuilder: (context) {
            return items.map((_) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.navy900 : AppColors.textPrimary,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDotWithLabel(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(color),
        const SizedBox(width: 5),
        Text(
          '$label · $count',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _getStatusDotOrIcon(RoomStatusType? status) {
    if (status == null) {
      return const Icon(Icons.tune_rounded, size: 14, color: AppColors.textSecondary);
    }
    final color = switch (status) {
      RoomStatusType.available => AppColors.statusAvailable,
      RoomStatusType.occupied => AppColors.statusOccupied,
      RoomStatusType.dirty => AppColors.statusDirty,
      RoomStatusType.maintenance => AppColors.statusMaintenance,
    };
    return _buildDot(color);
  }

  String _getStatusLabel(RoomStatusType? status, Map<RoomStatusType, int> stats, int total) {
    if (status == null) {
      return 'Semua Status ($total)';
    }
    return switch (status) {
      RoomStatusType.available => 'Available (${stats[RoomStatusType.available] ?? 0})',
      RoomStatusType.occupied => 'Occupied (${stats[RoomStatusType.occupied] ?? 0})',
      RoomStatusType.dirty => 'Dirty (${stats[RoomStatusType.dirty] ?? 0})',
      RoomStatusType.maintenance => 'Maint. (${stats[RoomStatusType.maintenance] ?? 0})',
    };
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
