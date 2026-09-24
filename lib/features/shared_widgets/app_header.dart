import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

/// Top navigation bar for the Receptionist view.
/// Height: 64px, background: navy900. Per design.md §6.9.
class ReceptionistTopBar extends StatefulWidget {
  final String userName;
  final String userRole;
  final VoidCallback onLogout;
  final VoidCallback? onOpenActiveGuests;
  final VoidCallback? onOpenManagerPortal;
  final int activeWaCount;

  const ReceptionistTopBar({
    super.key,
    required this.userName,
    required this.onLogout,
    this.userRole = 'RECEPTIONIST',
    this.onOpenActiveGuests,
    this.onOpenManagerPortal,
    this.activeWaCount = 0,
  });

  @override
  State<ReceptionistTopBar> createState() => _ReceptionistTopBarState();
}

class _ReceptionistTopBarState extends State<ReceptionistTopBar> {
  late Timer _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Tick every second for live clock
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width     = MediaQuery.of(context).size.width;
    final isMobile  = width < 600;
    final isTablet  = width >= 600 && width < 900;

    final timeStr   = DateFormat('HH:mm:ss').format(_now);
    final dateStr   = DateFormat('EEE, d MMM yyyy', 'id').format(_now);
    final initials  = _initials(widget.userName);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.navy900,
        border: Border(bottom: BorderSide(color: Color(0xFF0A2A6E), width: 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.lg),
      child: Row(
        children: [
          // ── Brand ──────────────────────────────────────────────
          _BrandMark(compact: isMobile),

          if (!isMobile) ...[
            SizedBox(width: isTablet ? AppSpacing.md : AppSpacing.lg),
            _VDivider(),
            SizedBox(width: isTablet ? AppSpacing.md : AppSpacing.lg),

            // ── Live Date + Clock ──────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontSize: isTablet ? 16 : 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                if (!isTablet)
                  Text(
                    dateStr,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.navy100.withAlpha(160),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],

          const Spacer(),

          // ── Active Guests Indicator ────────────────────────────
          if (widget.onOpenActiveGuests != null)
            _ActiveGuestsChip(
              count: widget.activeWaCount,
              onTap: widget.onOpenActiveGuests!,
              compact: isMobile,
            ),

          if (widget.onOpenManagerPortal != null) ...[
            SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
            if (isMobile)
              IconButton(
                tooltip: 'Portal Manajer & Inventaris Kamar',
                icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 20),
                onPressed: widget.onOpenManagerPortal,
              )
            else
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.navy700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                ),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.orange500),
                label: Text(
                  'Portal Manajer (Inventaris)',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: widget.onOpenManagerPortal,
              ),
          ],

          SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.md),

          // ── User Info + Logout ─────────────────────────────────
          _UserChip(
            initials: initials,
            name: widget.userName,
            role: widget.userRole,
            onLogout: widget.onLogout,
            compact: isMobile || isTablet,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}

// ── Brand mark ─────────────────────────────────────────────────────
class _BrandMark extends StatelessWidget {
  final bool compact;
  const _BrandMark({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.orange600,
            borderRadius: AppRadius.roundedMd,
          ),
          child: const Center(
            child: Text(
              'SH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sinar Harapan',
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withAlpha(50),
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: const Text(
                      'RedDoorz',
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'PMS',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.navy100.withAlpha(140),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Vertical Divider ────────────────────────────────────────────────
class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: Colors.white.withAlpha(20),
    );
  }
}

// ── Active Guests Chip ──────────────────────────────────────────────
class _ActiveGuestsChip extends StatefulWidget {
  final int count;
  final VoidCallback onTap;
  final bool compact;

  const _ActiveGuestsChip({
    required this.count,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_ActiveGuestsChip> createState() => _ActiveGuestsChipState();
}

class _ActiveGuestsChipState extends State<_ActiveGuestsChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasGuests = widget.count > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_)  => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: hasGuests
                ? (_hovered ? AppColors.orange600 : AppColors.orange600.withAlpha(30))
                : (_hovered ? AppColors.navy700 : AppColors.navy700.withAlpha(180)),
            borderRadius: AppRadius.roundedMd,
            border: Border.all(
              color: hasGuests
                  ? AppColors.orange600.withAlpha(_hovered ? 255 : 100)
                  : Colors.white.withAlpha(20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: hasGuests ? AppColors.orange600 : Colors.white70,
              ),
              if (!widget.compact) ...[
                const SizedBox(width: 6),
                Text(
                  'Tamu Aktif',
                  style: AppTypography.caption.copyWith(
                    color: hasGuests ? AppColors.orange600 : Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
              if (hasGuests) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orange600,
                    borderRadius: AppRadius.roundedFull,
                  ),
                  child: Text(
                    '${widget.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── User Chip ───────────────────────────────────────────────────────
class _UserChip extends StatefulWidget {
  final String initials;
  final String name;
  final String role;
  final VoidCallback onLogout;
  final bool compact;

  const _UserChip({
    required this.initials,
    required this.name,
    required this.role,
    required this.onLogout,
    this.compact = false,
  });

  @override
  State<_UserChip> createState() => _UserChipState();
}

class _UserChipState extends State<_UserChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Shorten name if too long
    final displayName = widget.name.length > 20
        ? '${widget.name.substring(0, 18)}…'
        : widget.name;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Tooltip(
          message: '${widget.name} (${widget.role})',
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.navy500,
              borderRadius: AppRadius.roundedFull,
              border: Border.all(color: Colors.white.withAlpha(30), width: 1.5),
            ),
            child: Center(
              child: Text(
                widget.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),

        if (!widget.compact) ...[
          const SizedBox(width: 10),

          // Name + role
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTypography.bodySm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                widget.role,
                style: AppTypography.overline.copyWith(
                  color: AppColors.orange500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(width: AppSpacing.sm),

        // Logout button
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_)  => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: 'Keluar dari sistem',
            child: GestureDetector(
              onTap: widget.onLogout,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hovered
                      ? AppColors.statusOccupied.withAlpha(30)
                      : Colors.transparent,
                  borderRadius: AppRadius.roundedMd,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 19,
                  color: _hovered ? AppColors.statusOccupied : Colors.white54,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────
/// Manager Sidebar Navigation
/// Sidebar for the Manager dashboard. Width: 240px expanded.
/// Per design.md §6.9 — active item: orange left indicator + navy700 bg.
/// ─────────────────────────────────────────────────────────────────
class ManagerSidebar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onNavChanged;
  final String managerName;
  final VoidCallback onLogout;

  const ManagerSidebar({
    super.key,
    required this.activeIndex,
    required this.onNavChanged,
    required this.managerName,
    required this.onLogout,
  });

  static const _navItems = [
    (Icons.dashboard_outlined,      Icons.dashboard_rounded,      'Ikhtisar'),
    (Icons.meeting_room_outlined,   Icons.meeting_room_rounded,   'Inventaris Kamar'),
    (Icons.bar_chart_outlined,      Icons.bar_chart_rounded,      'Laporan'),
    (Icons.history_rounded,         Icons.history_rounded,        'Audit Trail'),
  ];

  @override
  Widget build(BuildContext context) {
    final initials = _initials(managerName);

    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.navy900,
        border: Border(right: BorderSide(color: Color(0xFF0A2A6E), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.orange600,
                    borderRadius: AppRadius.roundedMd,
                  ),
                  child: const Center(
                    child: Text(
                      'SH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sinar Harapan',
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Manager Portal',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.navy100.withAlpha(140),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF0A2A6E), height: 1),

          const SizedBox(height: AppSpacing.sm),

          // ── Nav Items ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    'NAVIGASI',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.navy100.withAlpha(80),
                      fontSize: 11,
                    ),
                  ),
                ),
                ...List.generate(_navItems.length, (i) {
                  return _SidebarNavItem(
                    inactiveIcon: _navItems[i].$1,
                    activeIcon: _navItems[i].$2,
                    label: _navItems[i].$3,
                    isActive: activeIndex == i,
                    onTap: () => onNavChanged(i),
                  );
                }),
              ],
            ),
          ),

          const Spacer(),

          const Divider(color: Color(0xFF0A2A6E), height: 1),

          // ── User Section ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.navy500,
                    borderRadius: AppRadius.roundedFull,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        managerName.length > 16
                            ? '${managerName.substring(0, 14)}…'
                            : managerName,
                        style: AppTypography.bodySm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        'MANAGER',
                        style: AppTypography.overline.copyWith(
                          color: AppColors.orange500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      size: 19, color: Colors.white38),
                  tooltip: 'Keluar',
                  onPressed: onLogout,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'M';
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.inactiveIcon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_)  => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.navy700.withAlpha(180)
                : (_hovered ? AppColors.navy700.withAlpha(80) : Colors.transparent),
            borderRadius: AppRadius.roundedMd,
          ),
          child: Stack(
            children: [
              // Active indicator stripe (left 3px, per design.md)
              if (isActive)
                Positioned(
                  left: 0,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: AppColors.orange600,
                      borderRadius: AppRadius.roundedFull,
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isActive ? widget.activeIcon : widget.inactiveIcon,
                      size: 21,
                      color: isActive
                          ? Colors.white
                          : (_hovered ? Colors.white70 : Colors.white38),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.label,
                      style: AppTypography.body.copyWith(
                        color: isActive
                            ? Colors.white
                            : (_hovered ? Colors.white70 : Colors.white54),
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
