import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../shared_widgets/status_badge.dart';
import 'room_controller.dart';

enum _RefreshState { idle, loading, success, error }

/// Toolbar filter dan ringkasan hunian kamar terintegrasi.
/// Dirancang kokoh, cepat, aksesibel, dan responsif untuk operasional frontdesk.
class RoomFilterBar extends ConsumerStatefulWidget {
  final FutureOr<void> Function()? onRefresh;
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
  late final FocusNode _searchFocusNode;
  Timer? _debounceTimer;
  Timer? _successResetTimer;

  _RefreshState _refreshState = _RefreshState.idle;
  DateTime? _lastSuccessTime;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    if (widget.isRefreshing) {
      _refreshController.repeat();
      _refreshState = _RefreshState.loading;
    }
    _searchController = TextEditingController(
      text: ref.read(roomFilterProvider).searchQuery,
    );
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(RoomFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _refreshState = _RefreshState.loading;
      _refreshController.repeat();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      _refreshState = _RefreshState.idle;
      _refreshController.reset();
    }
  }

  void _scheduleResetSuccess() {
    _successResetTimer?.cancel();
    _successResetTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && _refreshState == _RefreshState.success) {
        setState(() => _refreshState = _RefreshState.idle);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _successResetTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefreshAction() async {
    if (_refreshState == _RefreshState.loading) return;

    setState(() => _refreshState = _RefreshState.loading);
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!disableAnimations) {
      _refreshController.repeat();
    }

    try {
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }
      if (mounted) {
        setState(() {
          _refreshState = _RefreshState.success;
          _lastSuccessTime = DateTime.now();
        });
        _scheduleResetSuccess();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _refreshState = _RefreshState.error);
      }
    } finally {
      if (mounted) {
        if (!disableAnimations) {
          _refreshController
              .animateTo(1.0, duration: const Duration(milliseconds: 150))
              .then((_) {
            if (mounted) _refreshController.reset();
          });
        }
        if (_refreshState == _RefreshState.loading) {
          setState(() => _refreshState = _RefreshState.idle);
        }
      }
    }
  }

  void _handleResetAll() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(roomFilterProvider.notifier).state = const RoomFilterState();
  }

  void _handleClearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    ref.read(roomFilterProvider.notifier).state =
        ref.read(roomFilterProvider).copyWith(searchQuery: '');
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(roomFilterProvider);
    final notifier = ref.read(roomFilterProvider.notifier);
    final stats = ref.watch(roomStatsProvider);
    final typeCounts = ref.watch(roomTypeCountsProvider);
    final floorCounts = ref.watch(floorCountsProvider);
    final statusCounts = ref.watch(statusCountsProvider);

    final totalRooms = stats.values.fold<int>(0, (a, b) => a + b);
    final occupied = stats[RoomStatusType.occupied] ?? 0;
    final occupancyRate = totalRooms > 0 ? (occupied / totalRooms * 100).round() : 0;
    final activeFilterCount = filter.activeFilterCount;

    // Sinkronkan text controller jika filter di-reset dari luar
    if (_searchController.text != filter.searchQuery && _debounceTimer?.isActive != true) {
      _searchController.text = filter.searchQuery;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          // Hanya fokuskan pencarian jika tidak ada modal dialog yang aktif
          if (ModalRoute.of(context)?.isCurrent == true) {
            _searchFocusNode.requestFocus();
          }
        },
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = width < 600 ? 12.0 : 24.0;

          Widget content;
          if (width >= 1400) {
            content = _buildDesktopSingleRow(
              context,
              filter: filter,
              notifier: notifier,
              occupancyRate: occupancyRate,
              occupied: occupied,
              totalRooms: totalRooms,
              statusCounts: statusCounts,
              typeCounts: typeCounts,
              floorCounts: floorCounts,
              activeFilterCount: activeFilterCount,
            );
          } else if (width >= 900) {
            content = _buildDesktopTwoRows(
              context,
              filter: filter,
              notifier: notifier,
              occupancyRate: occupancyRate,
              occupied: occupied,
              totalRooms: totalRooms,
              statusCounts: statusCounts,
              typeCounts: typeCounts,
              floorCounts: floorCounts,
              activeFilterCount: activeFilterCount,
            );
          } else {
            content = _buildMobileThreeRows(
              context,
              filter: filter,
              notifier: notifier,
              occupancyRate: occupancyRate,
              occupied: occupied,
              totalRooms: totalRooms,
              statusCounts: statusCounts,
              typeCounts: typeCounts,
              floorCounts: floorCounts,
              activeFilterCount: activeFilterCount,
            );
          }

          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: content,
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LAYOUT VARIANTS
  // ──────────────────────────────────────────────────────────────────────────

  /// >= 1400px: Satu baris utuh
  Widget _buildDesktopSingleRow(
    BuildContext context, {
    required RoomFilterState filter,
    required StateController<RoomFilterState> notifier,
    required int occupancyRate,
    required int occupied,
    required int totalRooms,
    required Map<RoomStatusType?, int> statusCounts,
    required Map<String, int> typeCounts,
    required Map<int, int> floorCounts,
    required int activeFilterCount,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Kiri: Hunian & Chip status
        _buildOccupancyBlock(context, occupancyRate, occupied, totalRooms),
        const SizedBox(width: 12),
        _buildStatusChips(filter, notifier, statusCounts),
        const SizedBox(width: 12),
        // Kanan: Kontrol Filter fleksibel
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
                  child: _buildSearchField(),
                ),
              ),
              const SizedBox(width: 6),
              _buildRoomTypeMenu(filter, notifier, typeCounts),
              const SizedBox(width: 6),
              _buildFloorMenu(filter, notifier, floorCounts),
              if (activeFilterCount > 0) ...[
                const SizedBox(width: 6),
                _buildResetButton(activeFilterCount),
              ],
              if (_lastSuccessTime != null && _refreshState != _RefreshState.error) ...[
                const SizedBox(width: 6),
                _buildLastUpdatedText(),
              ],
              const SizedBox(width: 6),
              _buildRefreshButton(),
            ],
          ),
        ),
      ],
    );
  }

  /// 900–1399px: Dua baris
  Widget _buildDesktopTwoRows(
    BuildContext context, {
    required RoomFilterState filter,
    required StateController<RoomFilterState> notifier,
    required int occupancyRate,
    required int occupied,
    required int totalRooms,
    required Map<RoomStatusType?, int> statusCounts,
    required Map<String, int> typeCounts,
    required Map<int, int> floorCounts,
    required int activeFilterCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Baris 1: Hunian & Chip status
        Row(
          children: [
            _buildOccupancyBlock(context, occupancyRate, occupied, totalRooms),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildStatusChips(filter, notifier, statusCounts),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Baris 2: Cari + Dropdowns + Reset + Refresh
        Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
                child: _buildSearchField(),
              ),
            ),
            const SizedBox(width: 8),
            _buildRoomTypeMenu(filter, notifier, typeCounts),
            const SizedBox(width: 8),
            _buildFloorMenu(filter, notifier, floorCounts),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: 8),
              _buildResetButton(activeFilterCount),
            ],
            if (_lastSuccessTime != null && _refreshState != _RefreshState.error) ...[
              const SizedBox(width: 8),
              _buildLastUpdatedText(),
            ],
            const SizedBox(width: 8),
            _buildRefreshButton(),
          ],
        ),
      ],
    );
  }

  /// < 900px: Tiga baris untuk mobile dan tablet kecil
  Widget _buildMobileThreeRows(
    BuildContext context, {
    required RoomFilterState filter,
    required StateController<RoomFilterState> notifier,
    required int occupancyRate,
    required int occupied,
    required int totalRooms,
    required Map<RoomStatusType?, int> statusCounts,
    required Map<String, int> typeCounts,
    required Map<int, int> floorCounts,
    required int activeFilterCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Baris 1: Cari + Refresh (kompak)
        Row(
          children: [
            Expanded(child: _buildSearchField()),
            const SizedBox(width: 8),
            _buildRefreshButton(compact: true),
          ],
        ),
        const SizedBox(height: 10),
        // Baris 2: Ringkasan hunian & Chip status horizontal scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOccupancyBlock(context, occupancyRate, occupied, totalRooms, compact: true),
              const SizedBox(width: 12),
              _buildStatusChips(filter, notifier, statusCounts),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Baris 3: Dropdown Tipe & Lantai berdampingan sama lebar
        Row(
          children: [
            Expanded(child: _buildRoomTypeMenu(filter, notifier, typeCounts, expand: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildFloorMenu(filter, notifier, floorCounts, expand: true)),
            if (activeFilterCount > 0) ...[
              const SizedBox(width: 8),
              _buildResetButton(activeFilterCount),
            ],
          ],
        ),
        if (_lastSuccessTime != null && _refreshState != _RefreshState.error) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: _buildLastUpdatedText(),
          ),
        ],
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SUB-KOMPONEN UI
  // ──────────────────────────────────────────────────────────────────────────

  /// Blok Ringkasan Hunian: Label, Persen tebal, Bar tipis 4px, dan "X dari Y kamar"
  Widget _buildOccupancyBlock(
    BuildContext context,
    int occupancyRate,
    int occupied,
    int totalRooms, {
    bool compact = false,
  }) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ratio = totalRooms > 0 ? (occupied / totalRooms).clamp(0.0, 1.0) : 0.0;
    const barWidth = 48.0;

    return Semantics(
      label: 'Tingkat hunian $occupancyRate persen, $occupied dari $totalRooms kamar',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Hunian',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$occupancyRate%',
            style: AppTextStyles.numberMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavyDark,
            ),
          ),
          const SizedBox(width: 8),
          // Bar tipis 4px
          Container(
            width: barWidth,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: ratio),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Container(
                  width: barWidth * value,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.brandNavy,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            Text(
              '$occupied dari $totalRooms kamar',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Chip status: Semua, Tersedia, Terisi, Kotor, Perawatan (Single-select)
  Widget _buildStatusChips(
    RoomFilterState filter,
    StateController<RoomFilterState> notifier,
    Map<RoomStatusType?, int> statusCounts,
  ) {
    final options = [
      (
        label: 'Semua',
        status: null,
        count: statusCounts[null] ?? 0,
        dotColor: AppColors.brandNavy,
        activeBg: AppColors.brandNavyTint,
        activeBorder: AppColors.brandNavy,
      ),
      (
        label: 'Tersedia',
        status: RoomStatusType.available,
        count: statusCounts[RoomStatusType.available] ?? 0,
        dotColor: AppColors.statusAvailable,
        activeBg: AppColors.statusAvailableBg,
        activeBorder: AppColors.statusAvailable,
      ),
      (
        label: 'Terisi',
        status: RoomStatusType.occupied,
        count: statusCounts[RoomStatusType.occupied] ?? 0,
        dotColor: AppColors.statusOccupied,
        activeBg: AppColors.statusOccupiedBg,
        activeBorder: AppColors.statusOccupied,
      ),
      (
        label: 'Kotor',
        status: RoomStatusType.dirty,
        count: statusCounts[RoomStatusType.dirty] ?? 0,
        dotColor: AppColors.statusDirty,
        activeBg: AppColors.statusDirtyBg,
        activeBorder: AppColors.statusDirty,
      ),
      (
        label: 'Perawatan',
        status: RoomStatusType.maintenance,
        count: statusCounts[RoomStatusType.maintenance] ?? 0,
        dotColor: AppColors.statusMaintenance,
        activeBg: AppColors.statusMaintenanceBg,
        activeBorder: AppColors.statusMaintenance,
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _buildSingleStatusChip(
            label: options[i].label,
            status: options[i].status,
            count: options[i].count,
            dotColor: options[i].dotColor,
            activeBg: options[i].activeBg,
            activeBorder: options[i].activeBorder,
            isSelected: filter.status == options[i].status,
            onTap: () {
              if (options[i].status == null) {
                notifier.state = filter.copyWith(clearStatus: true);
              } else {
                notifier.state = filter.copyWith(status: options[i].status);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSingleStatusChip({
    required String label,
    required RoomStatusType? status,
    required int count,
    required Color dotColor,
    required Color activeBg,
    required Color activeBorder,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isZero = count == 0;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$label, $count kamar',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? activeBg : AppColors.surface,
              borderRadius: AppRadius.roundedSm,
              border: Border.all(
                color: isSelected ? activeBorder : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: AppRadius.roundedSm,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Titik kecil berwarna sebagai penanda tambahan
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.brandNavyDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isZero
                              ? AppColors.textDisabled
                              : (isSelected ? AppColors.brandNavyDark : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kolom Pencarian: Tinggi 40px, icon kiri jarak 8px, tombol ✕ clear, Ctrl+F support, debounce 250 ms
  Widget _buildSearchField() {
    final filter = ref.watch(roomFilterProvider);
    final notifier = ref.read(roomFilterProvider.notifier);

    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Cari kamar / tamu...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.75),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: AppIcon.small(AppIcons.search, color: AppColors.textSecondary),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Hapus pencarian',
                  icon: const AppIcon.small(AppIcons.close, color: AppColors.textSecondary),
                  onPressed: _handleClearSearch,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fillColor: AppColors.surface,
          filled: true,
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.roundedSm,
            borderSide: BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.roundedSm,
            borderSide: BorderSide(color: AppColors.borderFocus, width: 1.5),
          ),
        ),
        onChanged: (val) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 250), () {
            if (mounted) {
              notifier.state = filter.copyWith(searchQuery: val);
            }
          });
          setState(() {}); // Update ikon clear ✕
        },
      ),
    );
  }

  /// Dropdown Tipe Kamar kustom memakai MenuAnchor + MenuItemButton
  Widget _buildRoomTypeMenu(
    RoomFilterState filter,
    StateController<RoomFilterState> notifier,
    Map<String, int> typeCounts, {
    bool expand = false,
  }) {
    final isActive = filter.roomType != 'ALL';
    final buttonLabel = isActive ? 'Tipe: ${filter.roomType}' : 'Semua Tipe';

    final items = [
      (value: 'ALL', label: 'Semua Tipe'),
      (value: 'Kipas', label: 'Kipas'),
      (value: 'AC', label: 'AC'),
      (value: 'AC Twin', label: 'AC Twin'),
    ];

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(1),
        shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.1)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: AppRadius.roundedSm,
            side: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
      ),
      menuChildren: [
        for (final item in items)
          _buildMenuItem(
            label: item.label,
            count: typeCounts[item.value] ?? 0,
            isSelected: filter.roomType == item.value,
            onPressed: () {
              notifier.state = filter.copyWith(roomType: item.value);
            },
          ),
      ],
      builder: (context, controller, child) {
        return _buildDropdownTriggerButton(
          label: buttonLabel,
          isActive: isActive,
          isOpen: controller.isOpen,
          expand: expand,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          semanticsLabel: 'Filter Tipe Kamar, terpilih: $buttonLabel',
        );
      },
    );
  }

  /// Dropdown Lantai kustom memakai MenuAnchor + MenuItemButton
  Widget _buildFloorMenu(
    RoomFilterState filter,
    StateController<RoomFilterState> notifier,
    Map<int, int> floorCounts, {
    bool expand = false,
  }) {
    final isActive = filter.floor != 0;
    final buttonLabel = isActive ? 'Lantai: ${filter.floor}' : 'Semua Lantai';

    final items = [
      (value: 0, label: 'Semua Lantai'),
      (value: 1, label: 'Lantai 1'),
      (value: 2, label: 'Lantai 2'),
    ];

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(1),
        shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.1)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: AppRadius.roundedSm,
            side: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
      ),
      menuChildren: [
        for (final item in items)
          _buildMenuItem(
            label: item.label,
            count: floorCounts[item.value] ?? 0,
            isSelected: filter.floor == item.value,
            onPressed: () {
              notifier.state = filter.copyWith(floor: item.value);
            },
          ),
      ],
      builder: (context, controller, child) {
        return _buildDropdownTriggerButton(
          label: buttonLabel,
          isActive: isActive,
          isOpen: controller.isOpen,
          expand: expand,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          semanticsLabel: 'Filter Lantai, terpilih: $buttonLabel',
        );
      },
    );
  }

  /// Item menu dropdown: Baris 40px, teks 14px, jumlah kamar di kanan, centang jika terpilih
  Widget _buildMenuItem({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    final isZero = count == 0;

    return MenuItemButton(
      onPressed: onPressed,
      style: MenuItemButton.styleFrom(
        minimumSize: const Size(180, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: isSelected ? AppColors.brandNavyTint : AppColors.surface,
        foregroundColor: isSelected ? AppColors.brandNavyDark : AppColors.textPrimary,
        overlayColor: AppColors.brandNavyTint.withValues(alpha: 0.5),
      ),
      child: SizedBox(
        width: 170,
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.brandNavyDark : AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isZero
                    ? AppColors.textDisabled
                    : (isSelected ? AppColors.brandNavyDark : AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: isSelected
                  ? const AppIcon.small(AppIcons.check, color: AppColors.brandNavy)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Tombol trigger dropdown
  Widget _buildDropdownTriggerButton({
    required String label,
    required bool isActive,
    required bool isOpen,
    required bool expand,
    required VoidCallback onPressed,
    required String semanticsLabel,
  }) {
    final child = Container(
      height: 40,
      constraints: BoxConstraints(minWidth: expand ? 0 : 130),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.brandNavyTint : AppColors.surface,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(
          color: isActive ? AppColors.brandNavy : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.roundedSm,
          onTap: onPressed,
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppColors.brandNavyDark : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const AppIcon.small(AppIcons.chevronDown, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: child,
    );
  }

  /// Tombol Reset (n)
  Widget _buildResetButton(int count) {
    return Semantics(
      button: true,
      label: 'Reset $count filter aktif',
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: const BorderSide(color: AppColors.error, width: 1),
          foregroundColor: AppColors.errorText,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
        ),
        icon: const AppIcon.small(AppIcons.close, color: AppColors.errorText),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Reset',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              ' ($count)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        onPressed: _handleResetAll,
      ),
    );
  }

  /// Teks kecil "Diperbarui HH:mm"
  Widget _buildLastUpdatedText() {
    if (_lastSuccessTime == null) return const SizedBox.shrink();
    final time = _lastSuccessTime!;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');

    return Text(
      'Diperbarui $hh:$mm',
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Tombol Segarkan dengan 3 state: Memuat, Sukses (centang 1 detik), Gagal (inline error)
  Widget _buildRefreshButton({bool compact = false}) {
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final isLoading = _refreshState == _RefreshState.loading || widget.isRefreshing;
    final isSuccess = _refreshState == _RefreshState.success && !widget.isRefreshing;
    final isError = _refreshState == _RefreshState.error && !widget.isRefreshing;

    if (isError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gagal memuat. Coba lagi.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.errorText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Coba Segarkan Kembali',
            icon: const AppIcon.small(AppIcons.refresh, color: AppColors.errorText),
            onPressed: _handleRefreshAction,
          ),
        ],
      );
    }

    Widget iconWidget;
    if (isSuccess) {
      iconWidget = const AppIcon.small(AppIcons.check, color: AppColors.statusAvailable);
    } else if (isLoading) {
      if (disableAnimations) {
        iconWidget = const AppIcon.small(AppIcons.refresh, color: AppColors.brandNavy);
      } else {
        iconWidget = RotationTransition(
          turns: _refreshController,
          child: const AppIcon.small(AppIcons.refresh, color: AppColors.brandNavy),
        );
      }
    } else {
      iconWidget = const AppIcon.small(AppIcons.refresh, color: AppColors.brandNavy);
    }

    if (compact) {
      return Semantics(
        button: true,
        identifier: 'room_toolbar_refresh_button',
        label: isLoading ? 'Sedang menyegarkan data' : 'Segarkan data kamar',
        child: SizedBox(
          height: 40,
          width: 40,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: const BorderSide(color: AppColors.border, width: 1),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
            ),
            onPressed: isLoading ? null : _handleRefreshAction,
            child: Stack(
              alignment: Alignment.center,
              children: [
                iconWidget,
                const SizedBox(
                  width: 0,
                  height: 0,
                  child: Text(
                    'Segarkan',
                    style: TextStyle(fontSize: 0.01),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      identifier: 'room_toolbar_refresh_button',
      label: isLoading ? 'Sedang menyegarkan data' : 'Segarkan data kamar',
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: const BorderSide(color: AppColors.border, width: 1),
          foregroundColor: AppColors.brandNavy,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
        ),
        icon: iconWidget,
        label: const Text(
          'Segarkan',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        onPressed: isLoading ? null : _handleRefreshAction,
      ),
    );
  }
}
