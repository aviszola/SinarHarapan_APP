import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../room_management/domain/room_model.dart';
import '../../room_management/presentation/room_controller.dart';
import '../../room_management/presentation/room_crud_dialog.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_header.dart';
import '../../shared_widgets/metric_card.dart';
import '../../shared_widgets/status_badge.dart';
import '../domain/audit_log_model.dart';
import '../domain/report_export_service.dart';
import 'executive_trend_chart.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  int _activeNavIndex = 0; // 0: Overview, 1: Inventory, 2: Reports, 3: Audit Trail

  final List<AuditLogModel> _sampleAuditLogs = [
    AuditLogModel(
      id: 'log-101',
      userName: 'Siti Rahmawati (Resepsionis)',
      actionType: 'CHECK_IN',
      resourceType: 'reservation',
      details: 'Check-in Kamar 102 - Agus Santoso (RedDoorz RD-89421)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ipAddress: '192.168.1.104',
    ),
    AuditLogModel(
      id: 'log-102',
      userName: 'Siti Rahmawati (Resepsionis)',
      actionType: 'CHECK_OUT',
      resourceType: 'reservation',
      details: 'Check-out & Pelunasan Faktur INV/SH/20260924/0002 Kamar 104',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      ipAddress: '192.168.1.104',
    ),
    AuditLogModel(
      id: 'log-103',
      userName: 'Hendra Wijaya (Manager)',
      actionType: 'CREATE_ROOM',
      resourceType: 'room',
      details: 'Penambahan inventaris unit kamar 304 (Tipe Family - Lt. 3)',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ipAddress: '192.168.1.101',
    ),
    AuditLogModel(
      id: 'log-104',
      userName: 'Siti Rahmawati (Resepsionis)',
      actionType: 'WA_REMINDER_RESEND',
      resourceType: 'notification',
      details: 'Kirim ulang pengingat WA manual Kamar 204 (Michael Tan)',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      ipAddress: '192.168.1.104',
    ),
    AuditLogModel(
      id: 'log-105',
      userName: 'Hendra Wijaya (Manager)',
      actionType: 'EXPORT_REPORT',
      resourceType: 'report',
      details: 'Ekspor laporan bulanan September 2026 format Excel (.xlsx)',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ipAddress: '192.168.1.101',
    ),
  ];

  void _handleLogout() {
    ref.read(authStateProvider.notifier).logout();
    context.go('/login');
  }

  bool _isExportingExcel = false;
  bool _isExportingPdf = false;

  Future<void> _handleExportExcel() async {
    if (_isExportingExcel) return;
    setState(() => _isExportingExcel = true);

    try {
      final rooms = ref.read(roomListProvider).value ?? [];
      final savedPath = await ReportExportService.exportToExcel(
        rooms: rooms,
        periodName: 'September 2026',
      );

      if (!mounted) return;

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengunduhan Excel dibatalkan.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final fileName = savedPath.split(RegExp(r'[\\/]')).last;

      _showDownloadSuccessDialog(
        title: 'Unduhan Excel Berhasil!',
        fileName: fileName,
        filePath: savedPath,
        isExcel: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Laporan Excel tersimpan: $fileName',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'BUKA',
            textColor: Colors.white,
            onPressed: () => ReportExportService.openFile(savedPath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Gagal mengekspor Excel: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  Future<void> _handleExportPdf() async {
    if (_isExportingPdf) return;
    setState(() => _isExportingPdf = true);

    try {
      final rooms = ref.read(roomListProvider).value ?? [];
      final authState = ref.read(authStateProvider);
      final managerName = authState.user?.fullName ?? 'Hendra Wijaya';

      final savedPath = await ReportExportService.exportToPdf(
        rooms: rooms,
        periodName: 'September 2026',
        managerName: managerName,
      );

      if (!mounted) return;

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengunduhan PDF dibatalkan.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final fileName = savedPath.split(RegExp(r'[\\/]')).last;

      _showDownloadSuccessDialog(
        title: 'Unduhan PDF Resmi Berhasil!',
        fileName: fileName,
        filePath: savedPath,
        isExcel: false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.navy700,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Laporan PDF resmi tersimpan: $fileName',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'BUKA',
            textColor: AppColors.orange500,
            onPressed: () => ReportExportService.openFile(savedPath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Gagal mengekspor PDF: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  void _showDownloadSuccessDialog({
    required String title,
    required String fileName,
    required String filePath,
    required bool isExcel,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isExcel ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExcel ? Icons.table_chart : Icons.picture_as_pdf,
                color: isExcel ? const Color(0xFF16A34A) : AppColors.orange600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Berkas laporan telah berhasil diunduh dan tersimpan ke perangkat Anda:',
              style: TextStyle(fontSize: 13, color: AppColors.navy500),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navy50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isExcel ? Icons.file_present_outlined : Icons.description_outlined,
                        size: 16,
                        color: AppColors.navy700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    filePath,
                    style: const TextStyle(fontSize: 11, color: AppColors.navy500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Buka Folder'),
            onPressed: () {
              ReportExportService.openFolder(filePath);
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isExcel ? const Color(0xFF16A34A) : AppColors.orange600,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(isExcel ? 'Buka Excel Sekarang' : 'Buka PDF Sekarang'),
            onPressed: () {
              ReportExportService.openFile(filePath);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final roomsAsync = ref.watch(roomListProvider);
    final rooms = roomsAsync.value ?? [];

    final totalRooms = rooms.length;
    final occupiedRooms = rooms.where((r) => r.isOccupied).length;
    final occupancyRate = totalRooms > 0 ? (occupiedRooms / totalRooms * 100) : 0.0;

    final authState = ref.watch(authStateProvider);
    final managerName = authState.user?.fullName ?? 'Manajer';

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 960;
    final isMobile = screenWidth < 600;

    final sidebar = ManagerSidebar(
      activeIndex: _activeNavIndex,
      onNavChanged: (i) {
        setState(() => _activeNavIndex = i);
        if (isCompact && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      managerName: managerName,
      onLogout: _handleLogout,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: isCompact ? Drawer(child: sidebar) : null,
      body: Row(
        children: [
          // 1. Manager Sidebar (only visible side-by-side on wide desktop screens)
          if (!isCompact) sidebar,

          // 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      // Hamburger button on compact / tablet / mobile
                      if (isCompact)
                        Builder(
                          builder: (bContext) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.menu, color: AppColors.navy900),
                              tooltip: 'Buka Menu Navigasi',
                              onPressed: () => Scaffold.of(bContext).openDrawer(),
                            ),
                          ),
                        ),

                      Expanded(
                        child: Text(
                          _getTabTitle(_activeNavIndex),
                          style: (isMobile ? AppTypography.bodyLg : AppTypography.h2).copyWith(
                            color: AppColors.navy900,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      // Quick Jump to Receptionist View
                      if (isMobile)
                        IconButton(
                          tooltip: 'Mode Resepsionis (Frontdesk)',
                          icon: const Icon(Icons.storefront_outlined, color: AppColors.navy700),
                          onPressed: () => context.go('/receptionist/rooms'),
                        )
                      else
                        AppButton(
                          label: 'Mode Resepsionis',
                          variant: AppButtonVariant.outline,
                          icon: Icons.storefront_outlined,
                          onPressed: () => context.go('/receptionist/rooms'),
                        ),

                      const SizedBox(width: 6),

                      // If in Reports tab or Overview: show export buttons
                      if (_activeNavIndex == 2 || _activeNavIndex == 0) ...[
                        if (isMobile) ...[
                          IconButton(
                            tooltip: 'Ekspor Excel (.xlsx)',
                            icon: const Icon(Icons.table_view_outlined, color: Color(0xFF16A34A)),
                            onPressed: _handleExportExcel,
                          ),
                          IconButton(
                            tooltip: 'Ekspor PDF Resmi',
                            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.orange600),
                            onPressed: _handleExportPdf,
                          ),
                        ] else ...[
                          AppButton(
                            label: 'Ekspor Excel',
                            variant: AppButtonVariant.secondary,
                            icon: Icons.table_view_outlined,
                            isLoading: _isExportingExcel,
                            onPressed: _handleExportExcel,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppButton(
                            label: 'Ekspor PDF',
                            variant: AppButtonVariant.outline,
                            icon: Icons.picture_as_pdf_outlined,
                            isLoading: _isExportingPdf,
                            onPressed: _handleExportPdf,
                          ),
                        ],
                      ],

                      // If in Inventory tab: show add room button
                      if (_activeNavIndex == 1)
                        if (isMobile)
                          IconButton(
                            tooltip: 'Tambah Unit Kamar',
                            icon: const Icon(Icons.add_circle, color: AppColors.orange600),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const RoomCrudDialog(),
                              );
                            },
                          )
                        else
                          AppButton(
                            label: 'Tambah Kamar',
                            variant: AppButtonVariant.primary,
                            icon: Icons.add,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const RoomCrudDialog(),
                              );
                            },
                          ),
                    ],
                  ),
                ),

                // Tab Content Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
                    child: _buildTabBody(currencyFormatter, totalRooms, occupiedRooms, occupancyRate, rooms),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Executive Analytics & Performance';
      case 1:
        return 'Manajemen Inventaris Kamar & Tarif';
      case 2:
        return 'Rekapitulasi Transaksi & Ekspor Laporan';
      case 3:
        return 'Audit Trail & Rekam Aktivitas Staf';
      default:
        return 'Dashboard Manajer';
    }
  }


  Widget _buildTabBody(
    NumberFormat currencyFormatter,
    int totalRooms,
    int occupiedRooms,
    double occupancyRate,
    List<RoomModel> rooms,
  ) {
    switch (_activeNavIndex) {
      case 0:
        return _buildOverviewTab(currencyFormatter, totalRooms, occupiedRooms, occupancyRate);
      case 1:
        return _buildInventoryTab(currencyFormatter, rooms);
      case 2:
        return _buildReportsTab(currencyFormatter, rooms);
      case 3:
        return _buildAuditTrailTab();
      default:
        return const SizedBox();
    }
  }

  // TAB 0: Executive Overview
  Widget _buildOverviewTab(
    NumberFormat currencyFormatter,
    int totalRooms,
    int occupiedRooms,
    double occupancyRate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Cards Grid (design.md §6.7) - Responsive 4-card or 2x2 or 1-column layout
        LayoutBuilder(
          builder: (context, constraints) {
            final kpi1 = MetricCard(
              title: 'Total Check-In (Bulan Berjalan)',
              value: '142',
              trendText: '▲ 14% vs bulan lalu',
              isTrendPositive: true,
            );
            final kpi2 = MetricCard(
              title: 'Total Check-Out',
              value: '138',
              trendText: '97% tepat waktu (12:00 WIB)',
              isTrendPositive: true,
            );
            final kpi3 = MetricCard(
              title: 'Rasio Okupansi Realtime',
              value: '${occupancyRate.toStringAsFixed(1)}%',
              trendText: '$occupiedRooms terisi dari $totalRooms total kamar',
              isTrendPositive: true,
            );
            final kpi4 = MetricCard(
              title: 'Akumulasi Pendapatan Bersih',
              value: currencyFormatter.format(48750000),
              trendText: '▲ 18.2% di atas target bulanan',
              isTrendPositive: true,
            );

            if (constraints.maxWidth >= 980) {
              return Row(
                children: [
                  Expanded(child: kpi1),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: kpi2),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: kpi3),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: kpi4),
                ],
              );
            } else if (constraints.maxWidth >= 540) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: kpi1),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: kpi2),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: kpi3),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: kpi4),
                    ],
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  kpi1,
                  const SizedBox(height: AppSpacing.sm),
                  kpi2,
                  const SizedBox(height: AppSpacing.sm),
                  kpi3,
                  const SizedBox(height: AppSpacing.sm),
                  kpi4,
                ],
              );
            }
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        // Complex Multi-metric Line Chart: Past vs Present (Bulan Berjalan vs Bulan Lalu)
        ExecutiveTrendChart(currencyFormatter: currencyFormatter),

        const SizedBox(height: AppSpacing.lg),

        // Channel Composition & Floor Occupancy
        LayoutBuilder(
          builder: (context, constraints) {
            final isStacked = constraints.maxWidth < 820;

            final channelCard = Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.roundedLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KOMPOSISI SALURAN PEMESANAN',
                    style: AppTypography.overline,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rasio Penjualan Kamar: RedDoorz vs Walk-in Offline',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Clean Flat Bar Representation
                  ClipRRect(
                    borderRadius: AppRadius.roundedFull,
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 65,
                            child: Container(
                              color: Colors.red.shade700,
                              alignment: Alignment.center,
                              child: const Text(
                                'RedDoorz 65%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 35,
                            child: Container(
                              color: AppColors.navy700,
                              alignment: Alignment.center,
                              child: const Text(
                                'Walk-in 35%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mitra RedDoorz', style: AppTypography.caption),
                              Text(
                                '92 Transaksi (Rp 31.687.500)',
                                style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, color: AppColors.navy700),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Walk-in Langsung', style: AppTypography.caption),
                              Text(
                                '50 Transaksi (Rp 17.062.500)',
                                style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );

            final floorCard = Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.roundedLg,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TINGKAT OKUPANSI PER LANTAI', style: AppTypography.overline),
                  const SizedBox(height: 4),
                  Text(
                    'Distribusi Kepadatan Tamu Hotel Sinar Harapan',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _buildFloorOccupancyRow('Lantai 1 (Kamar 101 - 105)', 0.8, '80% Terisi'),
                  const SizedBox(height: 10),
                  _buildFloorOccupancyRow('Lantai 2 (Kamar 201 - 205)', 0.6, '60% Terisi'),
                  const SizedBox(height: 10),
                  _buildFloorOccupancyRow('Lantai 3 (Kamar 301 - 304)', 0.75, '75% Terisi'),
                ],
              ),
            );

            if (isStacked) {
              return Column(
                children: [
                  channelCard,
                  const SizedBox(height: AppSpacing.md),
                  floorCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: channelCard),
                const SizedBox(width: AppSpacing.md),
                Expanded(flex: 5, child: floorCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFloorOccupancyRow(String title, double ratio, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.navy700, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: AppColors.bg,
          color: AppColors.navy700,
          minHeight: 8,
          borderRadius: AppRadius.roundedSm,
        ),
      ],
    );
  }

  // TAB 1: Inventory Management
  Widget _buildInventoryTab(NumberFormat currencyFormatter, List<RoomModel> rooms) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar Seluruh Unit Kamar (${rooms.length} Kamar Terdaftar)',
                        style: AppTypography.h3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manajer berwenang mengubah tarif, mengatur mode perbaikan, atau menambah unit.',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppButton(
                  label: 'Tambah Kamar Baru',
                  variant: AppButtonVariant.primary,
                  icon: Icons.add,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const RoomCrudDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.max(880.0, constraints.maxWidth);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      for (int index = 0; index < rooms.length; index++) ...[
                        if (index > 0) const Divider(height: 1),
                        Builder(
                          builder: (context) {
                            final room = rooms[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.navy100,
                                      borderRadius: AppRadius.roundedSm,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      room.roomNumber,
                                      style: AppTypography.h3.copyWith(
                                        color: AppColors.navy900,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),

                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Tipe ${room.roomType}', style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700)),
                                        Text('Lantai ${room.floor}', style: AppTypography.caption),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currencyFormatter.format(room.basePricePerNight),
                                          style: AppTypography.bodySm.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.navy900,
                                          ),
                                        ),
                                        Text('per malam', style: AppTypography.caption),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    flex: 2,
                                    child: StatusBadge(status: room.status),
                                  ),

                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      room.facilities.join(', '),
                                      style: AppTypography.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Ubah Data Kamar',
                                        icon: const Icon(Icons.edit_outlined, color: AppColors.navy700),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => RoomCrudDialog(roomToEdit: room),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      AppButton(
                                        label: room.isMaintenance ? 'Aktifkan' : 'Maintenance',
                                        variant: AppButtonVariant.outline,
                                        icon: Icons.build_circle_outlined,
                                        onPressed: room.isOccupied
                                            ? null
                                            : () async {
                                                try {
                                                  await ref.read(roomListProvider.notifier).toggleMaintenance(room.id);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        backgroundColor: room.isMaintenance ? AppColors.statusAvailable : AppColors.statusMaintenance,
                                                        content: Text(room.isMaintenance
                                                            ? 'Kamar ${room.roomNumber} diaktifkan kembali ke status Tersedia.'
                                                            : 'Kamar ${room.roomNumber} diubah ke mode Perbaikan / Maintenance.'),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        backgroundColor: AppColors.statusOccupied,
                                                        content: Text(e.toString().replaceAll('Exception: ', '')),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Hapus Kamar',
                                        icon: const Icon(Icons.delete_outline, color: AppColors.statusOccupied),
                                        onPressed: room.isOccupied
                                            ? null
                                            : () {
                                                showDialog(
                                                  context: context,
                                                  builder: (dialogCtx) => AlertDialog(
                                                    title: Text('Hapus Kamar ${room.roomNumber}?'),
                                                    content: Text('Apakah Anda yakin ingin menghapus unit kamar ${room.roomNumber} (Tipe ${room.roomType}) dari inventaris hotel?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(dialogCtx).pop(),
                                                        child: const Text('Batal'),
                                                      ),
                                                      FilledButton(
                                                        style: FilledButton.styleFrom(
                                                          backgroundColor: AppColors.statusOccupied,
                                                        ),
                                                        onPressed: () async {
                                                          Navigator.of(dialogCtx).pop();
                                                          try {
                                                            await ref.read(roomListProvider.notifier).deleteRoom(room.id);
                                                            if (context.mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  backgroundColor: AppColors.statusOccupied,
                                                                  content: Text('Kamar ${room.roomNumber} berhasil dihapus dari inventaris.'),
                                                                ),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            if (context.mounted) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  backgroundColor: AppColors.statusOccupied,
                                                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                                                ),
                                                              );
                                                            }
                                                          }
                                                        },
                                                        child: const Text('Hapus Unit'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // TAB 2: Reports & Transaction Table
  Widget _buildReportsTab(NumberFormat currencyFormatter, List<RoomModel> rooms) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rekapitulasi Transaksi Periode September 2026', style: AppTypography.h3),
                    Text(
                      'Data sensitif NIK & kontak tamu hanya dapat diakses & diunduh oleh peran Manajer (UU PDP).',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton(
                      label: 'Unduh Excel (.xlsx)',
                      variant: AppButtonVariant.secondary,
                      icon: Icons.file_download_outlined,
                      isLoading: _isExportingExcel,
                      onPressed: _handleExportExcel,
                    ),
                    AppButton(
                      label: 'Unduh PDF Resmi',
                      variant: AppButtonVariant.primary,
                      icon: Icons.picture_as_pdf_outlined,
                      isLoading: _isExportingPdf,
                      onPressed: _handleExportPdf,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.max(920.0, constraints.maxWidth);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        color: AppColors.navy100,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text('NO. INVOICE', style: AppTypography.overline)),
                            Expanded(flex: 1, child: Text('KAMAR', style: AppTypography.overline)),
                            Expanded(flex: 2, child: Text('NAMA TAMU', style: AppTypography.overline)),
                            Expanded(flex: 2, child: Text('WHATSAPP', style: AppTypography.overline)),
                            Expanded(flex: 2, child: Text('KANAL', style: AppTypography.overline)),
                            Expanded(flex: 2, child: Text('TOTAL BIAYA', style: AppTypography.overline)),
                            Expanded(flex: 2, child: Text('STATUS', style: AppTypography.overline)),
                          ],
                        ),
                      ),

                      for (int index = 0; index < rooms.length; index++) ...[
                        const Divider(height: 1),
                        Builder(
                          builder: (context) {
                            final room = rooms[index];
                            final hasGuest = room.activeGuestName != null;
                            final invoice = room.invoiceNumber ?? 'INV/SH/20260924/00${index + 1}';
                            final guest = room.activeGuestName ?? 'Tamu Walk-in';
                            final phone = room.activeGuestPhone ?? '081234567890';
                            final source = room.bookingSource ?? (index % 2 == 0 ? 'REDDOORZ' : 'WALK_IN');
                            final total = room.basePricePerNight * (index % 3 + 1);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      invoice,
                                      style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text('Kamar ${room.roomNumber}', style: AppTypography.bodySm),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      guest,
                                      style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(phone, style: AppTypography.caption),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: source == 'REDDOORZ' ? Colors.red.shade50 : AppColors.navy100,
                                            borderRadius: AppRadius.roundedSm,
                                          ),
                                          child: Text(
                                            source,
                                            style: AppTypography.overline.copyWith(
                                              color: source == 'REDDOORZ' ? Colors.red.shade700 : AppColors.navy700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      currencyFormatter.format(total),
                                      style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      hasGuest ? 'Menginap' : 'Selesai',
                                      style: AppTypography.caption.copyWith(
                                        color: hasGuest ? AppColors.statusOccupied : const Color(0xFF16A34A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // TAB 3: Audit Trail Log
  Widget _buildAuditTrailTab() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: 4,
              children: [
                Text('Log Aktivitas Staf & Audit Trail Transaksi', style: AppTypography.h3),
                Text(
                  'Setiap tindakan check-in, check-out, ubah inventaris, dan unduh laporan tercatat permanen.',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.max(760.0, constraints.maxWidth);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      for (int index = 0; index < _sampleAuditLogs.length; index++) ...[
                        if (index > 0) const Divider(height: 1),
                        Builder(
                          builder: (context) {
                            final log = _sampleAuditLogs[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.navy100,
                                      borderRadius: AppRadius.roundedSm,
                                    ),
                                    child: Text(
                                      log.actionType,
                                      style: AppTypography.overline.copyWith(
                                        color: AppColors.navy700,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),

                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(log.details, style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600)),
                                        Text('Oleh: ${log.userName} • IP: ${log.ipAddress}', style: AppTypography.caption),
                                      ],
                                    ),
                                  ),

                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm:ss').format(log.timestamp),
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
