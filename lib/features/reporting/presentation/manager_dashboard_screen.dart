import 'dart:async';
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
import '../../shared_widgets/app_feedback.dart';
import '../../shared_widgets/app_header.dart';
import '../../shared_widgets/metric_card.dart';
import '../../shared_widgets/status_badge.dart';
import '../data/reporting_repository.dart';
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

  final ReportingRepository _reportingRepo = ReportingRepository();
  List<AuditLogModel> _auditLogs = [];
  bool _isLoadingAuditLogs = false;
  String _auditLogFilter = 'ALL';
  Map<String, dynamic>? _summaryData;
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadAuditLogs();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoadingSummary = true);
    try {
      final data = await _reportingRepo.getSummary();
      if (mounted) setState(() => _summaryData = data);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSummary = false);
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoadingAuditLogs = true);
    try {
      final logs = await _reportingRepo.getAuditLogs();
      if (mounted) setState(() => _auditLogs = logs);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingAuditLogs = false);
  }

  void _handleLogout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _handleToggleMaintenance(RoomModel room) async {
    try {
      await ref.read(roomListProvider.notifier).toggleMaintenance(room.id);
      if (mounted) {
        if (room.isMaintenance) {
          AppFeedback.showSuccess(
            context,
            title: 'Kamar Siap Dihuni',
            message: 'Kamar ${room.roomNumber} telah diaktifkan kembali ke status Tersedia.',
          );
        } else {
          AppFeedback.showInfo(
            context,
            title: 'Mode Pemeliharaan',
            message: 'Kamar ${room.roomNumber} dipindahkan ke mode Maintenance (Perbaikan).',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Gagal Mengubah Status',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  Future<void> _handleDeleteRoom(RoomModel room) async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Hapus Kamar ${room.roomNumber}?',
      message: 'Apakah Anda yakin ingin menghapus unit kamar ${room.roomNumber} (Tipe ${room.roomType}) dari inventaris hotel? Tindakan ini bersifat permanen.',
      confirmLabel: 'Hapus Unit Kamar',
      cancelLabel: 'Batal',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (!confirmed || !mounted) return;

    try {
      await ref.read(roomListProvider.notifier).deleteRoom(room.id);
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: 'Unit Dihapus',
          message: 'Kamar ${room.roomNumber} berhasil dihapus dari inventaris operasional.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Gagal Menghapus Kamar',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    }
  }

  bool _isExportingExcel = false;
  bool _isExportingPdf = false;

  Future<void> _handleExportExcel() async {
    if (_isExportingExcel) return;
    setState(() => _isExportingExcel = true);

    try {
      String? savedPath;
      try {
        // Coba unduh dari backend GET /reports/export-excel
        final bytes = await _reportingRepo.exportExcel();
        if (bytes.isNotEmpty) {
          savedPath = await ReportExportService.saveBytesToFile(
            bytes: bytes,
            fileName: 'laporan-bulanan-${DateTime.now().millisecondsSinceEpoch}.xlsx',
          );
        }
      } catch (_) {
        // Fallback ke generator lokal jika offline
        final rooms = ref.read(roomListProvider).valueOrNull ?? [];
        savedPath = await ReportExportService.exportToExcel(
          rooms: rooms,
          periodName: 'September 2026',
        );
      }

      if (!mounted) return;

      if (savedPath == null) {
        AppFeedback.showInfo(
          context,
          title: 'Unduhan Dibatalkan',
          message: 'Pengunduhan berkas Excel dibatalkan oleh pengguna.',
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

      AppFeedback.showSuccess(
        context,
        title: 'Unduhan Selesai',
        message: 'Laporan Excel tersimpan: $fileName',
        actionLabel: 'BUKA',
        onAction: () => ReportExportService.openFile(savedPath!),
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        title: 'Ekspor Gagal',
        message: 'Gagal mengekspor Excel: $e',
      );
    } finally {
      if (mounted) setState(() => _isExportingExcel = false);
    }
  }

  Future<void> _handleExportPdf() async {
    if (_isExportingPdf) return;
    setState(() => _isExportingPdf = true);

    try {
      String? savedPath;
      try {
        // Coba unduh dari backend GET /reports/export-pdf
        final bytes = await _reportingRepo.exportPdf();
        if (bytes.isNotEmpty) {
          savedPath = await ReportExportService.saveBytesToFile(
            bytes: bytes,
            fileName: 'laporan-resmi-${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
        }
      } catch (_) {
        // Fallback ke generator lokal jika offline
        final rooms = ref.read(roomListProvider).valueOrNull ?? [];
        final authState = ref.read(authStateProvider);
        final managerName = authState.user?.fullName ?? 'Hendra Wijaya';
        savedPath = await ReportExportService.exportToPdf(
          rooms: rooms,
          periodName: 'September 2026',
          managerName: managerName,
        );
      }

      if (!mounted) return;

      if (savedPath == null) {
        AppFeedback.showInfo(
          context,
          title: 'Unduhan Dibatalkan',
          message: 'Pengunduhan PDF dibatalkan oleh pengguna.',
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

      AppFeedback.showSuccess(
        context,
        title: 'Unduhan Selesai',
        message: 'Laporan PDF resmi tersimpan: $fileName',
        actionLabel: 'BUKA',
        onAction: () => ReportExportService.openFile(savedPath!),
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        title: 'Ekspor Gagal',
        message: 'Gagal mengekspor PDF: $e',
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
      builder: (ctx) {
        // Auto-dismiss alert dialog setelah 3 detik
        Timer? autoCloseTimer;
        autoCloseTimer = Timer(const Duration(seconds: 3), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });

        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            autoCloseTimer?.cancel();
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isExcel ? AppColors.availableBg : AppColors.errorBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExcel ? Icons.table_chart : Icons.picture_as_pdf,
                    color: isExcel ? AppColors.statusAvailable : AppColors.orange600,
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
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: AppColors.textDisabled),
                    SizedBox(width: 4),
                    Text(
                      'Pemberitahuan ini otomatis tertutup dalam 3 detik...',
                      style: TextStyle(fontSize: 11, color: AppColors.textDisabled, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  autoCloseTimer?.cancel();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Tutup'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Buka Folder'),
                onPressed: () {
                  autoCloseTimer?.cancel();
                  ReportExportService.openFolder(filePath);
                  Navigator.of(ctx).pop();
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExcel ? AppColors.statusAvailable : AppColors.orange600,
                  foregroundColor: AppColors.surface,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(isExcel ? 'Buka Excel Sekarang' : 'Buka PDF Sekarang'),
                onPressed: () {
                  autoCloseTimer?.cancel();
                  ReportExportService.openFile(filePath);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
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
    final rooms = roomsAsync.valueOrNull ?? [];

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
                SafeArea(
                  bottom: false,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.sm + 4 : AppSpacing.md, vertical: 10),
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
                              padding: const EdgeInsets.only(right: 6.0),
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: AppColors.navy900),
                                tooltip: 'Buka Menu Navigasi',
                                onPressed: () => Scaffold.of(bContext).openDrawer(),
                              ),
                            ),
                          ),

                        Expanded(
                          child: Text(
                            _getTabTitle(_activeNavIndex, isMobile: isMobile),
                            style: (isMobile ? AppTypography.bodyLg : AppTypography.h2).copyWith(
                              color: AppColors.navy900,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: AppSpacing.xs),

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

                        const SizedBox(width: 4),

                        // If in Reports tab or Overview: show export buttons
                        if (_activeNavIndex == 2 || _activeNavIndex == 0) ...[
                          if (isMobile) ...[
                            IconButton(
                              tooltip: 'Ekspor Excel (.xlsx)',
                              icon: const Icon(Icons.table_view_outlined, color: AppColors.statusAvailable),
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

  String _getTabTitle(int index, {bool isMobile = false}) {
    if (isMobile) {
      switch (index) {
        case 0:
          return 'Analytics';
        case 1:
          return 'Inventaris';
        case 2:
          return 'Laporan';
        case 3:
          return 'Audit Trail';
        default:
          return 'Dashboard';
      }
    }
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
        return _buildOverviewTab(currencyFormatter, totalRooms, occupiedRooms, occupancyRate, rooms);
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
    List<RoomModel> rooms,
  ) {
    final summary = _summaryData;
    final totalCheckIn = summary?['totalCheckIn']?.toString() ?? '0';
    final totalCheckOut = summary?['totalCheckOut']?.toString() ?? '0';
    final occRateVal = summary?['occupancyRate'] != null
        ? '${summary!['occupancyRate']}%'
        : (occupancyRate > 0 ? '${occupancyRate.toStringAsFixed(1)}%' : '0.0%');
    final rawRevenue = summary?['totalNetRevenue'];
    final num? parsedRevenue = rawRevenue == null
        ? null
        : (rawRevenue is num ? rawRevenue : num.tryParse(rawRevenue.toString()));
    final totalNetRevenue = parsedRevenue != null
        ? currencyFormatter.format(parsedRevenue)
        : 'Rp 0';

    // Channel composition dari summary (endpoint.md §8.1)
    final channels = summary?['channelComposition'] as Map<String, dynamic>?;
    final reddoorzCount = (channels?['reddoorz'] is num)
        ? (channels!['reddoorz'] as num).toInt()
        : int.tryParse(channels?['reddoorz']?.toString() ?? '0');
    final walkInCount = (channels?['walkIn'] is num)
        ? (channels!['walkIn'] as num).toInt()
        : int.tryParse(channels?['walkIn']?.toString() ?? '0');
    final totalChannels = (reddoorzCount ?? 0) + (walkInCount ?? 0);
    final reddoorzPct = totalChannels > 0 ? ((reddoorzCount ?? 0) / totalChannels * 100).round() : 50;
    final walkInPct = totalChannels > 0 ? (100 - reddoorzPct) : 50;

    final reddoorzNominal = totalChannels > 0 && parsedRevenue != null
        ? (parsedRevenue * (reddoorzCount ?? 0) / totalChannels)
        : 0;
    final walkInNominal = totalChannels > 0 && parsedRevenue != null
        ? (parsedRevenue * (walkInCount ?? 0) / totalChannels)
        : 0;

    // Kalkulasi okupansi riil per lantai dari list rooms
    final f1Rooms = rooms.where((r) => r.floor == 1).toList();
    final f1Occ = f1Rooms.where((r) => r.isOccupied).length;
    final f1Total = f1Rooms.isNotEmpty ? f1Rooms.length : 5;
    final f1Ratio = f1Rooms.isNotEmpty ? f1Occ / f1Rooms.length : 0.0;
    final f1Label = '${(f1Ratio * 100).toStringAsFixed(0)}% ($f1Occ/$f1Total Kamar)';

    final f2Rooms = rooms.where((r) => r.floor == 2).toList();
    final f2Occ = f2Rooms.where((r) => r.isOccupied).length;
    final f2Total = f2Rooms.isNotEmpty ? f2Rooms.length : 5;
    final f2Ratio = f2Rooms.isNotEmpty ? f2Occ / f2Rooms.length : 0.0;
    final f2Label = '${(f2Ratio * 100).toStringAsFixed(0)}% ($f2Occ/$f2Total Kamar)';

    final f3Rooms = rooms.where((r) => r.floor == 3).toList();
    final f3Occ = f3Rooms.where((r) => r.isOccupied).length;
    final f3Total = f3Rooms.isNotEmpty ? f3Rooms.length : 4;
    final f3Ratio = f3Rooms.isNotEmpty ? f3Occ / f3Rooms.length : 0.0;
    final f3Label = '${(f3Ratio * 100).toStringAsFixed(0)}% ($f3Occ/$f3Total Kamar)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingSummary)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        // KPI Cards Grid (design.md §6.7) - Responsive 4-card or 2x2 or 1-column layout
        LayoutBuilder(
          builder: (context, constraints) {
            final kpi1 = MetricCard(
              title: 'Total Check-In (Bulan Berjalan)',
              value: totalCheckIn,
              trendText: summary != null ? 'Tamu terdaftar bulan ini' : 'Memuat data...',
              isTrendPositive: true,
              trailing: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.orange100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.login_rounded, size: 18, color: AppColors.orange800),
              ),
            );
            final kpi2 = MetricCard(
              title: 'Total Check-Out',
              value: totalCheckOut,
              trendText: summary != null ? 'Selesai menginap' : 'Memuat data...',
              isTrendPositive: true,
              trailing: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.navy50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout_rounded, size: 18, color: AppColors.navy700),
              ),
            );
            final kpi3 = MetricCard(
              title: 'Rasio Okupansi Realtime',
              value: occRateVal,
              trendText: '$occupiedRooms terisi dari $totalRooms total kamar',
              isTrendPositive: true,
              trailing: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.availableBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.meeting_room_rounded, size: 18, color: AppColors.statusAvailable),
              ),
            );
            final kpi4 = MetricCard(
              title: 'Akumulasi Pendapatan Bersih',
              value: totalNetRevenue,
              trendText: summary != null ? 'Total pendapatan bersih bulan berjalan' : 'Memuat data...',
              isTrendPositive: true,
              trailing: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.navy50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppColors.navy900),
              ),
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
                            flex: totalChannels > 0 ? reddoorzPct : 50,
                            child: Container(
                              color: AppColors.orange600,
                              alignment: Alignment.center,
                              child: Text(
                                totalChannels > 0 ? 'RedDoorz $reddoorzPct%' : 'RedDoorz',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: totalChannels > 0 ? walkInPct : 50,
                            child: Container(
                              color: AppColors.navy700,
                              alignment: Alignment.center,
                              child: Text(
                                totalChannels > 0 ? 'Walk-in $walkInPct%' : 'Walk-in',
                                style: const TextStyle(
                                  color: AppColors.white,
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
                          Container(width: 12, height: 12, color: AppColors.orange600),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mitra RedDoorz', style: AppTypography.caption),
                                Text(
                                  reddoorzCount != null
                                      ? '$reddoorzCount Transaksi · ${currencyFormatter.format(reddoorzNominal)}'
                                      : '0 Transaksi',
                                  style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 12, height: 12, color: AppColors.navy700),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Walk-in Langsung', style: AppTypography.caption),
                                Text(
                                  walkInCount != null
                                      ? '$walkInCount Transaksi · ${currencyFormatter.format(walkInNominal)}'
                                      : '0 Transaksi',
                                  style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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

                  _buildFloorOccupancyRow('Lantai 1 (Kamar 101 - 105)', f1Ratio, f1Label),
                  const SizedBox(height: 10),
                  _buildFloorOccupancyRow('Lantai 2 (Kamar 201 - 205)', f2Ratio, f2Label),
                  const SizedBox(height: 10),
                  _buildFloorOccupancyRow('Lantai 3 (Kamar 301 - 304)', f3Ratio, f3Label),
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
            Expanded(
              child: Text(
                title,
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: ratio > 0 ? AppColors.orange800 : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: AppColors.navy50,
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio > 0 ? AppColors.orange600 : AppColors.border,
            ),
            minHeight: 6,
          ),
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                Column(
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
              final isMobile = constraints.maxWidth < 720;

              if (isMobile) {
                // Mobile Card View for Rooms
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tipe ${room.roomType}',
                                      style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      'Lantai ${room.floor} · ${currencyFormatter.format(room.basePricePerNight)}/mlm',
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: room.status),
                            ],
                          ),
                          if (room.facilities.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: room.facilities.map((f) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(f, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                              )).toList(),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.navy700),
                                label: const Text('Ubah', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => RoomCrudDialog(roomToEdit: room),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: Icon(
                                  Icons.build_circle_outlined,
                                  size: 15,
                                  color: room.isMaintenance ? AppColors.statusAvailable : AppColors.textSecondary,
                                ),
                                label: Text(
                                  room.isMaintenance ? 'Aktifkan' : 'Maintenance',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: room.isOccupied ? null : () => _handleToggleMaintenance(room),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Hapus Kamar',
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusOccupied),
                                onPressed: room.isOccupied ? null : () => _handleDeleteRoom(room),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              // Desktop Table View
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
                                        onPressed: room.isOccupied ? null : () => _handleToggleMaintenance(room),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Hapus Kamar',
                                        icon: const Icon(Icons.delete_outline, color: AppColors.statusOccupied),
                                        onPressed: room.isOccupied ? null : () => _handleDeleteRoom(room),
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
              final isMobile = constraints.maxWidth < 720;

              if (isMobile) {
                // Mobile Card View for Transactions
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final hasGuest = room.activeGuestName != null;
                    final invoice = room.invoiceNumber ?? 'INV/SH/20260924/${(index + 1).toString().padLeft(4, '0')}';
                    final guest = room.activeGuestName ?? 'Tamu Walk-in';
                    final phone = room.activeGuestPhone ?? '081234567890';
                    final source = room.bookingSource ?? (index % 2 == 0 ? 'REDDOORZ' : 'WALK_IN');
                    final total = room.basePricePerNight * (index % 3 + 1);

                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(invoice, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy900)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasGuest ? AppColors.statusErrorBg : AppColors.statusSuccessBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hasGuest ? 'Menginap' : 'Selesai',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: hasGuest ? AppColors.statusOccupied : AppColors.statusAvailable,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(guest, style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('Kamar ${room.roomNumber} (${room.roomType}) · WA: $phone', style: AppTypography.caption),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: source == 'REDDOORZ' ? AppColors.orange100 : AppColors.navy100,
                                      borderRadius: AppRadius.roundedSm,
                                    ),
                                    child: Text(
                                      source,
                                      style: AppTypography.overline.copyWith(
                                        color: source == 'REDDOORZ' ? AppColors.orange800 : AppColors.navy700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormatter.format(total),
                                    style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy900),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              // Desktop Table View
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
                            final invoice = room.invoiceNumber ?? 'INV/SH/20260924/${(index + 1).toString().padLeft(4, '0')}';
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
                                            color: source == 'REDDOORZ' ? AppColors.orange100 : AppColors.navy100,
                                            borderRadius: AppRadius.roundedSm,
                                          ),
                                          child: Text(
                                            source,
                                            style: AppTypography.overline.copyWith(
                                              color: source == 'REDDOORZ' ? AppColors.orange800 : AppColors.navy700,
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
                                        color: hasGuest ? AppColors.statusOccupied : AppColors.statusAvailable,
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

  // TAB 3: Audit Trail Log (Modern Human-Readable Feed)
  Widget _buildAuditTrailTab() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final filteredLogs = _auditLogs.where((log) {
      if (_auditLogFilter == 'ALL') return true;
      if (_auditLogFilter == 'CHECKIN_OUT') {
        return log.actionType == 'CHECK_IN' || log.actionType == 'CHECK_OUT';
      }
      if (_auditLogFilter == 'ROOM_MGMT') {
        return log.actionType.contains('ROOM') || log.actionType.contains('STATUS');
      }
      if (_auditLogFilter == 'SECURITY') {
        return log.actionType.contains('LOGIN') || log.actionType.contains('AUTH') || log.actionType.contains('SECURITY');
      }
      if (_auditLogFilter == 'REPORT') {
        return log.actionType.contains('REPORT') || log.actionType.contains('EXPORT');
      }
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Tab & Deskripsi
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_toggle_off_rounded, size: 22, color: AppColors.navy900),
                          const SizedBox(width: 8),
                          Text('Rekam Jejak Operasional & Audit Trail', style: AppTypography.h3),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Setiap aktivitas check-in, check-out, ubah status kamar, dan tindakan staf terekam real-time untuk akuntabilitas hotel.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Muat Ulang Log',
                  icon: const Icon(Icons.refresh, color: AppColors.navy700),
                  onPressed: _loadAuditLogs,
                ),
              ],
            ),
          ),

          // Filter Segment Chips (Gaya Linear / Modern SaaS)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildAuditFilterChip('ALL', 'Semua Aktivitas (${_auditLogs.length})'),
                  const SizedBox(width: 8),
                  _buildAuditFilterChip('CHECKIN_OUT', 'Check-In & Out'),
                  const SizedBox(width: 8),
                  _buildAuditFilterChip('ROOM_MGMT', 'Status Kamar & Fisik'),
                  const SizedBox(width: 8),
                  _buildAuditFilterChip('SECURITY', 'Keamanan & Autentikasi'),
                  const SizedBox(width: 8),
                  _buildAuditFilterChip('REPORT', 'Ekspor Laporan'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          if (_isLoadingAuditLogs)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredLogs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navy50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inbox_outlined, size: 36, color: AppColors.textDisabled),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada catatan aktivitas pada kategori ini',
                      style: AppTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih filter lain atau lakukan tindakan di sistem untuk melihat rekaman log.',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 760;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredLogs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final parsed = _parseAuditLog(log, currencyFormatter);
                    final (actorName, actorRole) = _parseActor(log.userName);
                    final cleanIp = _cleanIp(log.ipAddress);
                    final dateStr = DateFormat('dd MMM yyyy').format(log.timestamp);
                    final timeStr = DateFormat('HH:mm:ss').format(log.timestamp);

                    if (isMobile) {
                      // Modern Card View di Smartphone
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: parsed.iconBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(parsed.icon, size: 16, color: parsed.iconColor),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: parsed.badgeBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    parsed.actionLabel,
                                    style: AppTypography.overline.copyWith(
                                      color: parsed.badgeColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$dateStr · $timeStr',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              parsed.title,
                              style: AppTypography.bodySm.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy900,
                              ),
                            ),
                            if (parsed.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                parsed.subtitle,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_outline, size: 12, color: AppColors.navy700),
                                      const SizedBox(width: 4),
                                      Text(
                                        actorRole != null ? '$actorName ($actorRole)' : actorName,
                                        style: const TextStyle(fontSize: 11, color: AppColors.navy900, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    cleanIp,
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    // Modern SaaS Feed Row di Desktop & Laptop
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon Avatar Lingkaran
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: parsed.iconBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(parsed.icon, size: 19, color: parsed.iconColor),
                          ),
                          const SizedBox(width: 14),

                          // Konten Tengah: Action, Judul, Subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: parsed.badgeBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        parsed.actionLabel,
                                        style: AppTypography.overline.copyWith(
                                          color: parsed.badgeColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        parsed.title,
                                        style: AppTypography.bodySm.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy900,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                if (parsed.subtitle.isNotEmpty)
                                  Text(
                                    parsed.subtitle,
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.navy50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.person_outline, size: 12, color: AppColors.navy700),
                                          const SizedBox(width: 4),
                                          Text(
                                            actorName,
                                            style: const TextStyle(fontSize: 11, color: AppColors.navy900, fontWeight: FontWeight.w600),
                                          ),
                                          if (actorRole != null) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '• $actorRole',
                                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.navy50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.terminal_rounded, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            cleanIp,
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontFamily: 'monospace'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Waktu Sisi Kanan
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAuditFilterChip(String key, String label) {
    final isSelected = _auditLogFilter == key;
    return InkWell(
      onTap: () => setState(() => _auditLogFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy900 : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.navy900 : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.surface : AppColors.navy700,
          ),
        ),
      ),
    );
  }

  String _cleanIp(String ip) {
    if (ip.startsWith('::ffff:')) {
      return ip.substring(7);
    }
    return ip;
  }

  (String name, String? role) _parseActor(String actorStr) {
    final reg = RegExp(r'^(.*?)(?:\s*\((.*?)\))?$');
    final m = reg.firstMatch(actorStr);
    if (m != null) {
      final n = m.group(1)?.trim() ?? actorStr;
      final r = m.group(2)?.trim();
      return (n.isNotEmpty ? n : 'Staf', r);
    }
    return (actorStr, null);
  }

  _AuditLogParsed _parseAuditLog(AuditLogModel log, NumberFormat currencyFormatter) {
    final act = log.actionType.toUpperCase();
    final d = log.details;

    String? extract(String key) {
      final reg = RegExp('$key:\\s*([^,}]+)', caseSensitive: false);
      final match = reg.firstMatch(d);
      return match?.group(1)?.trim();
    }

    if (act == 'CHECK_IN') {
      final guest = extract('guestName') ?? 'Tamu';
      final room = extract('roomNumber') ?? '-';
      final inv = extract('invoiceNumber');
      return _AuditLogParsed(
        actionLabel: 'CHECK-IN',
        title: 'Check-in Tamu: $guest',
        subtitle: inv != null ? 'Kamar $room · No. Invoice: $inv' : 'Kamar $room · Reservasi berhasil diproses',
        icon: Icons.login_rounded,
        badgeBg: AppColors.availableBg,
        badgeColor: AppColors.availableText,
        iconBg: AppColors.availableBg,
        iconColor: AppColors.statusAvailable,
      );
    } else if (act == 'CHECK_OUT') {
      final room = extract('roomNumber') ?? '-';
      final totalRaw = extract('totalAmount');
      final inv = extract('invoiceNumber');
      final lateFeeRaw = extract('lateFee');
      String paymentStr = '';
      if (totalRaw != null) {
        final amount = num.tryParse(totalRaw);
        if (amount != null) paymentStr = 'Total Biaya: ${currencyFormatter.format(amount)}';
      }
      final lateFee = num.tryParse(lateFeeRaw ?? '0') ?? 0;
      final lateStr = lateFee > 0 ? ' (Denda: ${currencyFormatter.format(lateFee)})' : '';

      return _AuditLogParsed(
        actionLabel: 'CHECK-OUT',
        title: 'Check-out Selesai: Kamar $room',
        subtitle: [
          if (paymentStr.isNotEmpty) '$paymentStr$lateStr',
          if (inv != null) 'Invoice: $inv',
        ].join(' · '),
        icon: Icons.logout_rounded,
        badgeBg: AppColors.orange100,
        badgeColor: AppColors.orange800,
        iconBg: AppColors.orange100,
        iconColor: AppColors.orange600,
      );
    } else if (act.contains('STATUS') || act.contains('CLEAN')) {
      final reason = extract('reason');
      final newStatus = extract('newStatus') ?? '';
      final prevStatus = extract('previousStatus') ?? '';
      String title = 'Pembaruan Status Kamar';
      String subtitle = 'Status kamar diperbarui';

      if (reason == 'MARK_CLEAN' || newStatus == 'AVAILABLE') {
        title = 'Pembersihan Kamar Selesai (Siap Dijual)';
        subtitle = prevStatus.isNotEmpty ? 'Status diubah dari $prevStatus ke Siap Dihuni (Available)' : 'Kamar bersih dan siap ditempati tamu';
      } else if (newStatus == 'MAINTENANCE') {
        title = 'Kamar Masuk Perbaikan (Maintenance)';
        subtitle = 'Unit dinonaktifkan sementara untuk perbaikan teknis';
      } else if (newStatus == 'DIRTY') {
        title = 'Kamar Ditandai Perlu Dibersihkan (Dirty)';
        subtitle = 'Menunggu jadwal pembersihan tim housekeeping';
      } else if (newStatus.isNotEmpty) {
        title = 'Status Kamar Diubah: $newStatus';
        subtitle = prevStatus.isNotEmpty ? 'Sebelumnya berstatus: $prevStatus' : d;
      }

      return _AuditLogParsed(
        actionLabel: 'STATUS KAMAR',
        title: title,
        subtitle: subtitle,
        icon: Icons.cleaning_services_rounded,
        badgeBg: AppColors.navy50,
        badgeColor: AppColors.navy700,
        iconBg: AppColors.navy50,
        iconColor: AppColors.navy700,
      );
    } else if (act.contains('LOGIN') || act.contains('AUTH')) {
      final user = extract('username') ?? 'staf';
      final isFailed = act.contains('FAIL');
      return _AuditLogParsed(
        actionLabel: isFailed ? 'LOGIN GAGAL' : 'LOGIN BERHASIL',
        title: isFailed ? 'Percobaan Masuk Gagal (Security Alert)' : 'Autentikasi Pengguna Berhasil',
        subtitle: 'Upaya akses sistem untuk akun "$user"',
        icon: isFailed ? Icons.gpp_maybe_rounded : Icons.verified_user_rounded,
        badgeBg: isFailed ? AppColors.errorBg : AppColors.availableBg,
        badgeColor: isFailed ? AppColors.errorText : AppColors.availableText,
        iconBg: isFailed ? AppColors.errorBg : AppColors.availableBg,
        iconColor: isFailed ? AppColors.error : AppColors.statusAvailable,
      );
    } else if (act.contains('DELETE')) {
      final room = extract('roomNumber') ?? '';
      return _AuditLogParsed(
        actionLabel: 'HAPUS DATA',
        title: 'Penghapusan Inventaris Kamar $room',
        subtitle: 'Data unit kamar dihapus dari daftar operasional hotel',
        icon: Icons.delete_outline_rounded,
        badgeBg: AppColors.errorBg,
        badgeColor: AppColors.errorText,
        iconBg: AppColors.errorBg,
        iconColor: AppColors.error,
      );
    } else if (act.contains('EXPORT') || act.contains('REPORT')) {
      final format = extract('format')?.toUpperCase() ?? 'EXCEL';
      final total = extract('totalRecords') ?? 'beberapa';
      return _AuditLogParsed(
        actionLabel: 'UNDUH LAPORAN',
        title: 'Ekspor Rekapitulasi Laporan $format',
        subtitle: 'Mengunduh rekapitulasi data keuangan & operasional ($total data)',
        icon: Icons.file_download_outlined,
        badgeBg: AppColors.navy100,
        badgeColor: AppColors.navy900,
        iconBg: AppColors.navy50,
        iconColor: AppColors.navy700,
      );
    } else {
      return _AuditLogParsed(
        actionLabel: act.replaceAll('_', ' '),
        title: 'Aktivitas ${act.replaceAll('_', ' ')}',
        subtitle: d.isNotEmpty ? d : 'Tidak ada rincian tambahan',
        icon: Icons.history_rounded,
        badgeBg: AppColors.navy50,
        badgeColor: AppColors.navy700,
        iconBg: AppColors.navy50,
        iconColor: AppColors.navy700,
      );
    }
  }
}

class _AuditLogParsed {
  final String actionLabel;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color badgeBg;
  final Color badgeColor;
  final Color iconBg;
  final Color iconColor;

  const _AuditLogParsed({
    required this.actionLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeBg,
    required this.badgeColor,
    required this.iconBg,
    required this.iconColor,
  });
}
