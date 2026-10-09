import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../theme/app_icons.dart';

/// Top navigation bar for the Receptionist view.
/// Height: 64px, background: navy900. Per design.md §6.9.
class ReceptionistTopBar extends StatefulWidget {
  final String userName;
  final String userRole;
  final VoidCallback onLogout;
  final VoidCallback? onOpenActiveGuests;
  final VoidCallback? onOpenManagerPortal;
  final int activeWaCount;
  final DateTime? fixedTime;

  const ReceptionistTopBar({
    super.key,
    required this.userName,
    required this.onLogout,
    this.userRole = 'RECEPTIONIST',
    this.onOpenActiveGuests,
    this.onOpenManagerPortal,
    this.activeWaCount = 0,
    this.fixedTime,
  });

  @override
  State<ReceptionistTopBar> createState() => _ReceptionistTopBarState();
}

class _ReceptionistTopBarState extends State<ReceptionistTopBar> {
  Timer? _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = widget.fixedTime ?? DateTime.now();
    // Tick every second for live clock only if not fixed
    if (widget.fixedTime == null) {
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;

    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEE, d MMM yyyy', 'id').format(_now);
    final initials = _initials(widget.userName);

    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.navy900,
          border: Border(
            bottom: BorderSide(color: AppColors.navy700, width: 1),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.sm + 4 : AppSpacing.lg,
        ),
        child: Row(
          children: [
            // ── Brand ──────────────────────────────────────────────
            _BrandMark(compact: isMobile),

            if (!isMobile) ...[
              SizedBox(width: isTablet ? AppSpacing.md : AppSpacing.lg),
              _VDivider(),
              SizedBox(width: isTablet ? AppSpacing.md : AppSpacing.lg),

              // ── Tanggal & Waktu Terbaca Rapi ──────────────────────
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStr,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (!isTablet)
                    Text(
                      dateStr,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandNavyTint.withAlpha(180),
                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),
            ] else ...[
              const SizedBox(width: AppSpacing.xs),
              // Compact mobile clock
              Text(
                DateFormat('HH:mm').format(_now),
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.white.withAlpha(180),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
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
                  icon: const AppIcon(
                    AppIcons.reception,
                    color: AppColors.white,
                    size: AppIconSize.medium,
                    tooltip: 'Portal Manajer & Inventaris Kamar',
                  ),
                  onPressed: widget.onOpenManagerPortal,
                )
              else
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.navy700,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.roundedMd,
                    ),
                  ),
                  icon: const AppIcon.small(
                    AppIcons.reception,
                    color: AppColors.orange500,
                  ),
                  label: Text(
                    'Portal Manajer (Inventaris)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
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
          decoration: const BoxDecoration(
            color: AppColors.brandOrange,
            borderRadius: AppRadius.roundedSm,
          ),
          child: const Center(
            child: Text(
              'SH',
              style: TextStyle(
                color: AppColors.white,
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
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                'PMS Frontdesk',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandNavyTint.withAlpha(180),
                  fontSize: 11,
                ),
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
    return Container(height: 28, width: 1, color: AppColors.white.withAlpha(20));
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

    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final Color textColor;
    final Color badgeBgColor;
    final Color badgeTextColor;
    final List<BoxShadow>? shadows;

    if (hasGuests) {
      if (_hovered) {
        bgColor = AppColors.orange600;
        borderColor = AppColors.orange500;
        iconColor = AppColors.navy900;
        textColor = AppColors.navy900;
        badgeBgColor = AppColors.navy900;
        badgeTextColor = AppColors.orange600;
        shadows = [
          BoxShadow(
            color: AppColors.orange600.withAlpha(115),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      } else {
        bgColor = AppColors.orange600.withAlpha(46);
        borderColor = AppColors.orange500.withAlpha(153);
        iconColor = AppColors.orange500;
        textColor = AppColors.white;
        badgeBgColor = AppColors.orange600;
        badgeTextColor = AppColors.navy900;
        shadows = [
          BoxShadow(
            color: AppColors.navy900.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
      }
    } else {
      bgColor = _hovered
          ? AppColors.navy700
          : AppColors.navy700.withAlpha(128);
      borderColor = AppColors.white.withAlpha(40);
      iconColor = AppColors.white.withAlpha(180);
      textColor = AppColors.white.withAlpha(180);
      badgeBgColor = Colors.transparent;
      badgeTextColor = Colors.transparent;
      shadows = null;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.roundedMd,
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.small(AppIcons.guest, color: iconColor),
              if (!widget.compact) ...[
                const SizedBox(width: 7),
                Text(
                  'Tamu Aktif',
                  style: AppTypography.caption.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
              if (hasGuests) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: AppRadius.roundedFull,
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: AppColors.navy900.withAlpha(40),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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
              border: Border.all(color: AppColors.white.withAlpha(30), width: 1.5),
            ),
            child: Center(
              child: Text(
                widget.initials,
                style: const TextStyle(
                  color: AppColors.white,
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
                  color: AppColors.white,
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
          onExit: (_) => setState(() => _hovered = false),
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
                      ? AppColors.error.withAlpha(30)
                      : Colors.transparent,
                  borderRadius: AppRadius.roundedMd,
                ),
                child: AppIcon(
                  AppIcons.logout,
                  size: AppIconSize.medium,
                  color: _hovered ? AppColors.error : AppColors.white.withAlpha(140),
                  tooltip: 'Keluar dari sistem',
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
    (AppIcons.dashboard, 'Ikhtisar'),
    (AppIcons.room, 'Inventaris Kamar'),
    (AppIcons.report, 'Laporan'),
    (AppIcons.audit, 'Audit Trail'),
  ];

  @override
  Widget build(BuildContext context) {
    final initials = _initials(managerName);

    return SafeArea(
      right: false,
      child: Container(
        width: 240,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.navy900,
          border: Border(right: BorderSide(color: AppColors.navy700, width: 1)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                                    color: AppColors.navy900,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sinar Harapan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.h3.copyWith(
                                      color: AppColors.white,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Manager Portal',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.navy100.withAlpha(140),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(color: AppColors.navy700, height: 1),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Nav Items ────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
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
                                icon: _navItems[i].$1,
                                label: _navItems[i].$2,
                                isActive: activeIndex == i,
                                onTap: () => onNavChanged(i),
                              );
                            }),
                          ],
                        ),
                      ),

                      const Spacer(),

                      const Divider(color: AppColors.navy700, height: 1),

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
                                    color: AppColors.white,
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
                                      color: AppColors.white,
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
                              icon: AppIcon(
                                AppIcons.logout,
                                size: AppIconSize.medium,
                                color: AppColors.white.withAlpha(100),
                                tooltip: 'Keluar',
                              ),
                              tooltip: 'Keluar',
                              onPressed: onLogout,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
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
          },
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isNotEmpty ? name[0].toUpperCase() : 'M';
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
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
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.brandNavy
                : (_hovered
                    ? AppColors.brandNavy.withAlpha(100)
                    : Colors.transparent),
            borderRadius: AppRadius.rounded,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: Row(
              children: [
                AppIcon(
                  widget.icon,
                  size: AppIconSize.medium,
                  color: isActive
                      ? AppColors.white
                      : (_hovered ? AppColors.white.withAlpha(200) : AppColors.brandNavyTint.withAlpha(160)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isActive
                          ? AppColors.white
                          : (_hovered ? AppColors.white.withAlpha(200) : AppColors.brandNavyTint.withAlpha(180)),
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
