import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../shared_widgets/status_badge.dart';
import 'room_controller.dart';

/// Bar Filter Kamar & Ringkasan Okupansi yang tenang dan informatif.
/// Satu baris statistik sederhana, label Bahasa Indonesia, padding konsisten dengan grid kamar.
class RoomFilterBar extends ConsumerStatefulWidget {
  final VoidCallback? onRefresh;
  final bool isRefreshing;

  const RoomFilterBar({
    super.key,
    this.onRefresh,
    this.isRefreshing = false,
  });

  @override
  ConsumerState<RoomFilterBar> createState() => _RoomFilterBarState();
}

class _RoomFilterBarState extends ConsumerState<RoomFilterBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _refreshController;
  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (widget.isRefreshing) {
      _refreshController.repeat();
    }
    _searchController = TextEditingController(
      text: ref.read(roomFilterProvider).searchQuery,
    );
  }

  @override
  void didUpdateWidget(RoomFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _refreshController.repeat();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      _refreshController.animateTo(1.0, duration: const Duration(milliseconds: 200)).then((_) {
        if (mounted) _refreshController.reset();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(roomFilterProvider);
    final notifier = ref.read(roomFilterProvider.notifier);
    final stats = ref.watch(roomStatsProvider);
    final totalRooms = stats.values.fold<int>(0, (a, b) => a + b);

    // Sinkronkan text controller jika filter di-reset dari luar
    if (_searchController.text != filter.searchQuery && _debounceTimer?.isActive != true) {
      _searchController.text = filter.searchQuery;
    }

    final available = stats[RoomStatusType.available] ?? 0;
    final occupied = stats[RoomStatusType.occupied] ?? 0;
    final dirty = stats[RoomStatusType.dirty] ?? 0;
    final maintenance = stats[RoomStatusType.maintenance] ?? 0;
    final occupancyRate = totalRooms > 0 ? (occupied / totalRooms * 100).round() : 0;

    final hasActiveFilter = filter.searchQuery.isNotEmpty ||
        filter.roomType != 'ALL' ||
        filter.floor != 0 ||
        filter.status != null;

    // Satu baris statistik ringkasan hunian (bukan kumpulan pill warna-warni)
    Widget buildStatsLine() {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hunian: ',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$occupancyRate%',
                style: AppTextStyles.numberMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavyDark,
                ),
              ),
              Text(
                ' ($occupied/$totalRooms kamar)',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          Text('·', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          _buildStatCount('$available', 'Tersedia', AppColors.statusAvailableText),
          Text('·', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          _buildStatCount('$occupied', 'Terisi', AppColors.statusOccupiedText),
          Text('·', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          _buildStatCount('$dirty', 'Kotor', AppColors.statusDirtyText),
          Text('·', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          _buildStatCount('$maintenance', 'Perawatan', AppColors.statusMaintenanceText),
        ],
      );
    }

    // Dropdown Tipe Kamar
    final roomTypeDropdown = _buildFilterDropdown<String>(
      value: filter.roomType,
      label: filter.roomType == 'ALL' ? 'Semua Tipe' : filter.roomType,
      isActive: filter.roomType != 'ALL',
      items: const [
        DropdownMenuItem(value: 'ALL', child: Text('Semua Tipe')),
        DropdownMenuItem(value: 'Standard', child: Text('Standard')),
        DropdownMenuItem(value: 'Superior', child: Text('Superior')),
        DropdownMenuItem(value: 'Deluxe', child: Text('Deluxe')),
        DropdownMenuItem(value: 'Family', child: Text('Family')),
      ],
      onChanged: (val) {
        if (val != null) notifier.state = filter.copyWith(roomType: val);
      },
    );

    // Dropdown Lantai
    final floorDropdown = _buildFilterDropdown<int>(
      value: filter.floor,
      label: filter.floor == 0 ? 'Semua Lantai' : 'Lantai ${filter.floor}',
      isActive: filter.floor != 0,
      items: const [
        DropdownMenuItem(value: 0, child: Text('Semua Lantai')),
        DropdownMenuItem(value: 1, child: Text('Lantai 1')),
        DropdownMenuItem(value: 2, child: Text('Lantai 2')),
        DropdownMenuItem(value: 3, child: Text('Lantai 3')),
      ],
      onChanged: (val) {
        if (val != null) notifier.state = filter.copyWith(floor: val);
      },
    );

    // Dropdown Status (Bahasa Indonesia)
    final statusDropdown = _buildFilterDropdown<RoomStatusType?>(
      value: filter.status,
      label: _getStatusLabel(filter.status),
      isActive: filter.status != null,
      items: const [
        DropdownMenuItem(value: null, child: Text('Semua Status')),
        DropdownMenuItem(value: RoomStatusType.available, child: Text('Tersedia')),
        DropdownMenuItem(value: RoomStatusType.occupied, child: Text('Terisi')),
        DropdownMenuItem(value: RoomStatusType.dirty, child: Text('Kotor')),
        DropdownMenuItem(value: RoomStatusType.maintenance, child: Text('Perawatan')),
      ],
      onChanged: (val) {
        if (val == null) {
          notifier.state = filter.copyWith(clearStatus: true);
        } else {
          notifier.state = filter.copyWith(status: val);
        }
      },
    );

    // Input Pencarian
    Widget buildSearchField({double? width}) {
      return SizedBox(
        width: width,
        height: 36,
        child: TextField(
          controller: _searchController,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Cari kamar / tamu...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            prefixIcon: const AppIcon.small(AppIcons.search, color: AppColors.textSecondary),
            suffixIcon: filter.searchQuery.isNotEmpty
                ? IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Hapus pencarian',
                    icon: const AppIcon.small(AppIcons.close, color: AppColors.textSecondary),
                    onPressed: () {
                      _debounceTimer?.cancel();
                      _searchController.clear();
                      notifier.state = filter.copyWith(searchQuery: '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            fillColor: AppColors.surface,
            filled: true,
          ),
          onChanged: (val) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 150), () {
              notifier.state = filter.copyWith(searchQuery: val);
            });
          },
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;

          if (isDesktop) {
            return Row(
              children: [
                // Ringkasan Statistik Rata Kiri
                Expanded(child: buildStatsLine()),
                const SizedBox(width: 16),
                // Kontrol Filter Rata Kanan
                buildSearchField(width: 240),
                const SizedBox(width: 8),
                roomTypeDropdown,
                const SizedBox(width: 8),
                floorDropdown,
                const SizedBox(width: 8),
                statusDropdown,
                if (hasActiveFilter) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.errorText,
                    ),
                    icon: const AppIcon.small(AppIcons.close),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _debounceTimer?.cancel();
                      _searchController.clear();
                      notifier.state = const RoomFilterState();
                    },
                  ),
                ],
                if (widget.onRefresh != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: AppColors.brandNavy,
                    ),
                    icon: RotationTransition(
                      turns: _refreshController,
                      child: const AppIcon.small(AppIcons.refresh),
                    ),
                    label: const Text('Segarkan', style: TextStyle(fontSize: 12)),
                    onPressed: widget.isRefreshing ? null : widget.onRefresh,
                  ),
                ],
              ],
            );
          }

          // Tablet / Layar Kecil
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildStatsLine(),
              const SizedBox(height: 10),
              buildSearchField(),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    roomTypeDropdown,
                    const SizedBox(width: 8),
                    floorDropdown,
                    const SizedBox(width: 8),
                    statusDropdown,
                    if (hasActiveFilter) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.errorText,
                        ),
                        icon: const AppIcon.small(AppIcons.close),
                        label: const Text('Reset', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          _debounceTimer?.cancel();
                          _searchController.clear();
                          notifier.state = const RoomFilterState();
                        },
                      ),
                    ],
                    if (widget.onRefresh != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          foregroundColor: AppColors.brandNavy,
                        ),
                        icon: RotationTransition(
                          turns: _refreshController,
                          child: const AppIcon.small(AppIcons.refresh),
                        ),
                        label: const Text('Segarkan', style: TextStyle(fontSize: 12)),
                        onPressed: widget.isRefreshing ? null : widget.onRefresh,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCount(String count, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: AppTextStyles.numberSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _getStatusLabel(RoomStatusType? status) {
    return switch (status) {
      RoomStatusType.available => 'Tersedia',
      RoomStatusType.occupied => 'Terisi',
      RoomStatusType.dirty => 'Kotor',
      RoomStatusType.maintenance => 'Perawatan',
      null => 'Semua Status',
    };
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required String label,
    required bool isActive,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.brandNavyTint : AppColors.surface,
        borderRadius: AppRadius.rounded,
        border: Border.all(
          color: isActive ? AppColors.brandNavy : AppColors.border,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const AppIcon.small(AppIcons.chevronDown, color: AppColors.textSecondary),
          isDense: true,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? AppColors.brandNavy : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
