import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../theme/app_icons.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../room_management/domain/room_model.dart';
import '../../room_management/presentation/room_controller.dart';
import '../../room_management/presentation/room_crud_dialog.dart';
import '../../shared_widgets/app_button.dart';
import '../../shared_widgets/app_feedback.dart';
import '../../shared_widgets/app_header.dart';
import '../../shared_widgets/empty_state.dart';
import '../../shared_widgets/kpi_tile.dart';
import '../../shared_widgets/status_badge.dart';
import '../data/reporting_repository.dart';
import '../domain/audit_log_model.dart';
import '../domain/report_export_service.dart';
import 'executive_trend_chart.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final Map<String, dynamic>? initialSummaryData;
  final List<AuditLogModel>? initialAuditLogs;
  final List<Map<String, dynamic>>? initialTransactions;

  const ManagerDashboardScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialSummaryData,
    this.initialAuditLogs,
    this.initialTransactions,
  });

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  late int _activeNavIndex; // 0: Ringkasan, 1: Inventaris, 2: Laporan, 3: Audit Trail

  final ReportingRepository _reportingRepo = ReportingRepository();
  List<AuditLogModel> _auditLogs = [];
  bool _isLoadingAuditLogs = false;
  String _auditLogFilter = 'ALL';
  Map<String, dynamic>? _summaryData;
  bool _isLoadingSummary = false;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = false;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _activeNavIndex = widget.initialTabIndex;
    if (widget.initialSummaryData != null) {
      _summaryData = widget.initialSummaryData;
    }
    if (widget.initialAuditLogs != null) {
      _auditLogs = widget.initialAuditLogs!;
    }
    if (widget.initialTransactions != null) {
      _transactions = widget.initialTransactions!;
    }
    _loadAllDashboardData();
  }

  Future<void> _loadAllDashboardData() async {
    _lastUpdated = DateTime.now();
    if (widget.initialSummaryData == null && widget.initialAuditLogs == null && widget.initialTransactions == null) {
      await Future.wait([
        _loadSummary(),
        _loadAuditLogs(),
        _loadTransactions(),
      ]);
    }
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

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      final txs = await _reportingRepo.getTransactions();
      if (mounted) setState(() => _transactions = txs);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingTransactions = false);
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
      icon: AppIcons.delete,
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
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.rounded),
            title: Row(
              children: [
                AppIcon.large(
                  isExcel ? AppIcons.excel : AppIcons.pdf,
                  color: isExcel ? AppColors.statusAvailable : AppColors.orange600,
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
                    borderRadius: AppRadius.rounded,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppIcon.small(
                            isExcel ? AppIcons.excel : AppIcons.pdf,
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
                    AppIcon.small(AppIcons.clock, color: AppColors.textDisabled),
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
                icon: const AppIcon.medium(AppIcons.folder),
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
                icon: const AppIcon.medium(AppIcons.openInNew),
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
                                icon: const AppIcon.medium(AppIcons.menu, color: AppColors.navy900),
                                tooltip: 'Buka Menu Navigasi',
                                onPressed: () => Scaffold.of(bContext).openDrawer(),
                              ),
                            ),
                          ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getTabTitle(_activeNavIndex, isMobile: isMobile),
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.brandNavyDark,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Diperbarui ${DateFormat('HH.mm').format(_lastUpdated)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Segarkan Data',
                          icon: const AppIcon.medium(AppIcons.refresh, color: AppColors.brandNavy),
                          onPressed: _loadAllDashboardData,
                        ),
                        const SizedBox(width: AppSpacing.xs),

                        // Quick Jump to Receptionist View
                        if (isMobile)
                          IconButton(
                            tooltip: 'Mode Resepsionis (Frontdesk)',
                            icon: const AppIcon.medium(AppIcons.reception, color: AppColors.navy700),
                            onPressed: () => context.go('/receptionist/rooms'),
                          )
                        else
                          AppButton(
                            label: 'Mode Resepsionis',
                            variant: AppButtonVariant.outline,
                            icon: AppIcons.reception,
                            onPressed: () => context.go('/receptionist/rooms'),
                          ),

                        const SizedBox(width: 4),

                        // If in Reports tab or Overview: show export buttons
                        if (_activeNavIndex == 2 || _activeNavIndex == 0) ...[
                          if (isMobile) ...[
                            IconButton(
                              tooltip: 'Ekspor Excel (.xlsx)',
                              icon: const AppIcon.medium(AppIcons.excel, color: AppColors.statusAvailable),
                              onPressed: _handleExportExcel,
                            ),
                            IconButton(
                              tooltip: 'Ekspor PDF Resmi',
                              icon: const AppIcon.medium(AppIcons.pdf, color: AppColors.orange600),
                              onPressed: _handleExportPdf,
                            ),
                          ] else ...[
                            AppButton(
                              label: 'Ekspor Excel',
                              variant: AppButtonVariant.secondary,
                              icon: AppIcons.excel,
                              isLoading: _isExportingExcel,
                              onPressed: _handleExportExcel,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppButton(
                              label: 'Ekspor PDF',
                              variant: AppButtonVariant.outline,
                              icon: AppIcons.pdf,
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
                              icon: const AppIcon.medium(AppIcons.add, color: AppColors.orange600),
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
                              icon: AppIcons.add,
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
    switch (index) {
      case 0:
        return 'Ringkasan';
      case 1:
        return 'Inventaris Kamar';
      case 2:
        return 'Laporan Keuangan';
      case 3:
        return 'Catatan Aktivitas';
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
    final occMonthlyRate = summary?['occupancyRate'] != null
        ? '${summary!['occupancyRate']}%'
        : '0%';
    final operationalRooms = rooms.where((r) => !r.isMaintenance).length;
    final todayOccPercent = operationalRooms > 0 ? (occupiedRooms / operationalRooms * 100).round() : 0;

    final rawRevenue = summary?['totalNetRevenue'];
    final num? parsedRevenue = rawRevenue == null
        ? null
        : (rawRevenue is num ? rawRevenue : num.tryParse(rawRevenue.toString()));
    final totalNetRevenue = parsedRevenue != null
        ? currencyFormatter.format(parsedRevenue)
        : 'Rp 0';

    // Saluran Pemesanan dari backend summary
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

    // Distribusi Lantai Berdasarkan Data Kamar Riil (Bukan Asumsi Hardcoded)
    final Map<int, List<RoomModel>> roomsByFloor = {};
    for (final r in rooms) {
      roomsByFloor.putIfAbsent(r.floor, () => []).add(r);
    }
    final sortedFloors = roomsByFloor.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingSummary)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: LinearProgressIndicator(minHeight: 2),
          ),

        // 4 Kartu KPI Ringkas & Berjarak Rapi
        LayoutBuilder(
          builder: (context, constraints) {
            final kpi1 = KpiTile(
              label: 'Pendapatan Bersih Bulan Ini',
              value: totalNetRevenue,
              subtitle: 'Berdasarkan transaksi selesai',
            );
            final kpi2 = KpiTile(
              label: 'Okupansi Hari Ini',
              value: '$todayOccPercent%',
              subtitle: '$occupiedRooms dari $operationalRooms kamar operasional aktif',
            );
            final kpi3 = KpiTile(
              label: 'Okupansi Bulan Ini',
              value: occMonthlyRate,
              subtitle: 'Penyebut: $operationalRooms kamar aktif × hari periode',
            );
            final kpi4 = KpiTile(
              label: 'Kedatangan Tamu (Check-In)',
              value: '$totalCheckIn Tamu',
              subtitle: 'Total check-in bulan ini',
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

        // Grafik Tren Bersih
        ExecutiveTrendChart(
          currencyFormatter: currencyFormatter,
          realTimeseriesData: _transactions,
        ),

        const SizedBox(height: AppSpacing.lg),

        // Komposisi Saluran Pemesanan & Okupansi Riil Per Lantai
        LayoutBuilder(
          builder: (context, constraints) {
            final isStacked = constraints.maxWidth < 820;

            final channelCard = Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saluran Pemesanan Tamu',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Perbandingan pemesanan Mitra RedDoorz vs Langsung',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Dua Tile Statistik Saluran yang Terang & Jelas
                  Row(
                    children: [
                      // RedDoorz
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEA580C),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'RedDoorz',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF9A3412),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$reddoorzPct%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF7C2D12),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${reddoorzCount ?? 0} Transaksi · ${currencyFormatter.format(reddoorzNominal)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF9A3412),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Langsung
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E3A8A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Langsung (Walk-In)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$walkInPct%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${walkInCount ?? 0} Transaksi · ${currencyFormatter.format(walkInNominal)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1E40AF),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Batang Proporsi Rapi Bersih Tanpa Teks Terjepit
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 10,
                      color: const Color(0xFFF1F5F9),
                      child: Row(
                        children: [
                          if (reddoorzPct > 0)
                            Expanded(
                              flex: reddoorzPct,
                              child: Container(color: const Color(0xFFEA580C)),
                            ),
                          if (walkInPct > 0)
                            Expanded(
                              flex: walkInPct,
                              child: Container(color: const Color(0xFF1E3A8A)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            final floorCard = Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hunian Berdasarkan Lantai',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Distribusi keterisian kamar aktif saat ini',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (sortedFloors.isEmpty)
                    const Text('Belum ada data kamar terdaftar', style: TextStyle(fontSize: 12))
                  else
                    for (final fl in sortedFloors) ...[
                      Builder(
                        builder: (context) {
                          final fRooms = roomsByFloor[fl]!;
                          final fOcc = fRooms.where((r) => r.isOccupied).length;
                          final fRatio = fRooms.isNotEmpty ? fOcc / fRooms.length : 0.0;
                          final fLabel = '${(fRatio * 100).toStringAsFixed(0)}% ($fOcc/${fRooms.length} Kamar)';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildFloorOccupancyRow('Lantai $fl', fRatio, fLabel),
                          );
                        },
                      ),
                    ],
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
                Expanded(child: channelCard),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: floorCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFloorOccupancyRow(String title, double ratio, String label) {
    final isOccupied = ratio > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isOccupied ? const Color(0xFFFEF3C7) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isOccupied
                      ? Border.all(color: const Color(0xFFFCD34D), width: 0.8)
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isOccupied
                        ? const Color(0xFF92400E)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOccupied ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
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
                  icon: AppIcons.add,
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
                                icon: const AppIcon.small(AppIcons.edit, color: AppColors.navy700),
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
                                icon: AppIcon.small(
                                  AppIcons.maintenance,
                                  color: room.isMaintenance ? AppColors.statusAvailable : AppColors.textSecondary,
                                ),
                                label: Text(
                                  room.isMaintenance ? 'Aktifkan' : 'Perawatan',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: room.isOccupied ? null : () => _handleToggleMaintenance(room),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Hapus Kamar',
                                icon: const AppIcon.medium(AppIcons.delete, color: AppColors.statusOccupied),
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
                                        icon: const AppIcon.medium(AppIcons.edit, color: AppColors.navy700),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => RoomCrudDialog(roomToEdit: room),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      AppButton(
                                        label: room.isMaintenance ? 'Aktifkan' : 'Perawatan',
                                        variant: AppButtonVariant.outline,
                                        icon: AppIcons.maintenance,
                                        onPressed: room.isOccupied ? null : () => _handleToggleMaintenance(room),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Hapus Kamar',
                                        icon: const AppIcon.medium(AppIcons.delete, color: AppColors.statusOccupied),
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
        borderRadius: AppRadius.rounded,
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
                    Text(
                      'Rekapitulasi Transaksi Pembayaran',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.brandNavyDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Data transaksi resmi untuk pembukuan dan audit hotel.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
                      icon: AppIcons.excel,
                      isLoading: _isExportingExcel,
                      onPressed: _handleExportExcel,
                    ),
                    AppButton(
                      label: 'Unduh PDF Resmi',
                      variant: AppButtonVariant.primary,
                      icon: AppIcons.pdf,
                      isLoading: _isExportingPdf,
                      onPressed: _handleExportPdf,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (_isLoadingTransactions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.brandNavy),
              ),
            )
          else if (_transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: EmptyStateWidget(
                icon: AppIcons.receipt,
                title: 'Belum Ada Transaksi Tercatat',
                message:
                    'Belum ada transaksi pembayaran atau reservasi yang tersimpan di server untuk periode ini. Riwayat transaksi akan tercatat otomatis saat tamu melakukan pembayaran.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = math.max(880.0, constraints.maxWidth);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      children: [
                        // Header Tabel
                        Container(
                          color: AppColors.bgSubtle,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text('NO. INVOICE', style: AppTextStyles.badge)),
                              Expanded(flex: 1, child: Text('KAMAR', style: AppTextStyles.badge)),
                              Expanded(flex: 2, child: Text('NAMA TAMU', style: AppTextStyles.badge)),
                              Expanded(flex: 2, child: Text('KANAL', style: AppTextStyles.badge)),
                              Expanded(flex: 2, child: Text('TOTAL BIAYA', style: AppTextStyles.badge)),
                              Expanded(flex: 2, child: Text('STATUS', style: AppTextStyles.badge)),
                            ],
                          ),
                        ),

                        // Baris Transaksi Riil
                        for (int i = 0; i < _transactions.length; i++) ...[
                          const Divider(height: 1),
                          Builder(
                            builder: (context) {
                              final tx = _transactions[i];
                              final invoice = tx['invoiceNumber']?.toString() ?? '-';
                              final roomNum = tx['roomNumber']?.toString() ?? '-';
                              final guest = tx['guestName'] != null && tx['guestName'].toString().trim().isNotEmpty
                                  ? tx['guestName'].toString()
                                  : '-';
                              final channel = tx['bookingSource'] != null && tx['bookingSource'].toString().trim().isNotEmpty
                                  ? tx['bookingSource'].toString()
                                  : '-';
                              final rawAmt = tx['totalAmount'] ?? tx['amount'] ?? 0;
                              final amt = rawAmt is num ? rawAmt : num.tryParse(rawAmt.toString()) ?? 0;
                              final status = tx['paymentStatus'] != null && tx['paymentStatus'].toString().trim().isNotEmpty
                                  ? tx['paymentStatus'].toString().toUpperCase()
                                  : '-';

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        invoice,
                                        style: AppTextStyles.numberMedium.copyWith(fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text('Kamar $roomNum', style: AppTextStyles.bodyMedium),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(guest, style: AppTextStyles.bodyMediumMedium),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(channel, style: AppTextStyles.caption),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        currencyFormatter.format(amt),
                                        style: AppTextStyles.numberMedium,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        status,
                                        style: AppTextStyles.badge.copyWith(
                                          color: status == 'LUNAS' || status == 'PAID'
                                              ? AppColors.statusAvailableText
                                              : AppColors.statusDirtyText,
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
                      Text(
                        'Rekam Jejak Operasional & Audit Trail',
                        style: AppTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  icon: const AppIcon.medium(AppIcons.refresh, color: AppColors.navy700),
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
                    const AppIcon.large(AppIcons.emptyState, color: AppColors.textDisabled),
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
                                AppIcon.small(parsed.icon, color: parsed.iconColor),
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
                                  child: Text(
                                    actorRole != null ? '$actorName ($actorRole)' : actorName,
                                    style: const TextStyle(fontSize: 11, color: AppColors.navy900, fontWeight: FontWeight.w500),
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
                          AppIcon.medium(parsed.icon, color: parsed.iconColor),
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
                                      child: Text(
                                        cleanIp,
                                        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontFamily: 'monospace'),
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
        icon: AppIcons.checkIn,
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
        icon: AppIcons.checkOut,
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
        icon: AppIcons.cleaning,
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
        icon: isFailed ? AppIcons.warning : AppIcons.shield,
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
        icon: AppIcons.delete,
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
        icon: AppIcons.download,
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
        icon: AppIcons.audit,
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
