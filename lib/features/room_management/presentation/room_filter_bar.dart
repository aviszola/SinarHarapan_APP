import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../shared_widgets/status_badge.dart';
import 'room_controller.dart';

class RoomFilterBar extends ConsumerWidget {
  const RoomFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(roomFilterProvider);
    final notifier = ref.read(roomFilterProvider.notifier);
    final stats = ref.watch(roomStatsProvider);
    final totalRooms = stats.values.fold<int>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Search Input Field
            SizedBox(
              width: 240,
              height: 38,
              child: TextField(
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Cari nomor kamar / tamu...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                  suffixIcon: filter.searchQuery.isNotEmpty
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.clear, size: 16, color: AppColors.textSecondary),
                          onPressed: () => notifier.state = filter.copyWith(searchQuery: ''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.navy700, width: 1.5),
                  ),
                ),
                onChanged: (val) => notifier.state = filter.copyWith(searchQuery: val),
              ),
            ),

            const SizedBox(
              height: 24,
              child: VerticalDivider(color: AppColors.border, width: 20),
            ),

            // Room Type Pills
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tipe: ',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Semua',
                  isSelected: filter.roomType == 'ALL',
                  onTap: () => notifier.state = filter.copyWith(roomType: 'ALL'),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Standard',
                  isSelected: filter.roomType == 'Standard',
                  onTap: () => notifier.state = filter.copyWith(roomType: 'Standard'),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Superior',
                  isSelected: filter.roomType == 'Superior',
                  onTap: () => notifier.state = filter.copyWith(roomType: 'Superior'),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Deluxe',
                  isSelected: filter.roomType == 'Deluxe',
                  onTap: () => notifier.state = filter.copyWith(roomType: 'Deluxe'),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Family',
                  isSelected: filter.roomType == 'Family',
                  onTap: () => notifier.state = filter.copyWith(roomType: 'Family'),
                ),
              ],
            ),

            const SizedBox(
              height: 24,
              child: VerticalDivider(color: AppColors.border, width: 24),
            ),

            // Floor Pills
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lantai: ',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Semua',
                  isSelected: filter.floor == 0,
                  onTap: () => notifier.state = filter.copyWith(floor: 0),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Lt 1',
                  isSelected: filter.floor == 1,
                  onTap: () => notifier.state = filter.copyWith(floor: 1),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Lt 2',
                  isSelected: filter.floor == 2,
                  onTap: () => notifier.state = filter.copyWith(floor: 2),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Lt 3',
                  isSelected: filter.floor == 3,
                  onTap: () => notifier.state = filter.copyWith(floor: 3),
                ),
              ],
            ),

            const SizedBox(
              height: 24,
              child: VerticalDivider(color: AppColors.border, width: 24),
            ),

            // Status Pills with Live Counts
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Status: ',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Semua ($totalRooms)',
                  isSelected: filter.status == null,
                  onTap: () => notifier.state = filter.copyWith(clearStatus: true),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Available (${stats[RoomStatusType.available] ?? 0})',
                  dotColor: AppColors.statusAvailable,
                  isSelected: filter.status == RoomStatusType.available,
                  onTap: () => notifier.state = filter.copyWith(status: RoomStatusType.available),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Occupied (${stats[RoomStatusType.occupied] ?? 0})',
                  dotColor: AppColors.statusOccupied,
                  isSelected: filter.status == RoomStatusType.occupied,
                  onTap: () => notifier.state = filter.copyWith(status: RoomStatusType.occupied),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Dirty (${stats[RoomStatusType.dirty] ?? 0})',
                  dotColor: AppColors.statusDirty,
                  isSelected: filter.status == RoomStatusType.dirty,
                  onTap: () => notifier.state = filter.copyWith(status: RoomStatusType.dirty),
                ),
                const SizedBox(width: 6),
                _buildFilterPill(
                  label: 'Maint. (${stats[RoomStatusType.maintenance] ?? 0})',
                  dotColor: AppColors.statusMaintenance,
                  isSelected: filter.status == RoomStatusType.maintenance,
                  onTap: () => notifier.state = filter.copyWith(status: RoomStatusType.maintenance),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? dotColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedFull,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy700 : Colors.transparent,
          borderRadius: AppRadius.roundedFull,
          border: Border.all(
            color: isSelected ? AppColors.navy700 : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
