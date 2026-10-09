import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/app/theme.dart';
import 'package:sinarharapan_app/features/auth/data/auth_repository.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/auth/presentation/auth_controller.dart';
import 'package:sinarharapan_app/features/auth/presentation/login_screen.dart';
import 'package:sinarharapan_app/features/reporting/domain/audit_log_model.dart';
import 'package:sinarharapan_app/features/reporting/presentation/manager_dashboard_screen.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_controller.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_grid_screen.dart';

class _FakeAuthRepo extends AuthRepository {
  @override
  Future<UserModel> login({required String username, required String password}) async {
    return const UserModel(
      id: 'usr-1',
      username: 'manager',
      fullName: 'Hendra Wijaya',
      role: UserRole.manager,
      token: 'jwt-mock',
    );
  }

  @override
  Future<UserModel> quickLogin(UserRole role) async {
    return login(username: 'manager', password: 'password123');
  }
}

class _FakeRoomRepo extends RoomRepository {
  final List<RoomModel> _rooms = [
    const RoomModel(
      id: 'rm-101',
      roomNumber: '101',
      roomType: 'Deluxe',
      floor: 1,
      basePricePerNight: 350000,
      facilities: ['AC', 'WiFi', 'TV', 'Water Heater'],
      status: RoomStatusType.available,
    ),
    const RoomModel(
      id: 'rm-102',
      roomNumber: '102',
      roomType: 'Standard',
      floor: 1,
      basePricePerNight: 250000,
      facilities: ['AC', 'WiFi'],
      status: RoomStatusType.occupied,
      activeGuestName: 'Budi Santoso',
      activeGuestPhone: '081234567890',
    ),
    const RoomModel(
      id: 'rm-103',
      roomNumber: '103',
      roomType: 'Standard',
      floor: 1,
      basePricePerNight: 250000,
      facilities: ['AC', 'WiFi'],
      status: RoomStatusType.dirty,
    ),
    const RoomModel(
      id: 'rm-104',
      roomNumber: '104',
      roomType: 'Family Suite',
      floor: 2,
      basePricePerNight: 500000,
      facilities: ['AC', 'WiFi', 'TV', 'Kulkas'],
      status: RoomStatusType.maintenance,
    ),
  ];

  @override
  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    return _rooms;
  }

  @override
  Future<List<RoomStatusSnapshot>> getRoomStatusOnly() async {
    return _rooms
        .map((r) => RoomStatusSnapshot(id: r.id, roomNumber: r.roomNumber, status: r.status))
        .toList();
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    final fontFile = File('build/unit_test_assets/packages/lucide_icons_flutter/assets/lucide.ttf');
    if (fontFile.existsSync()) {
      final bytes = fontFile.readAsBytesSync();
      final fontData = ByteData.view(bytes.buffer);
      for (final family in ['packages/lucide_icons_flutter/Lucide', 'Lucide']) {
        final loader = FontLoader(family);
        loader.addFont(Future.value(fontData));
        await loader.load();
      }
    }
  });

  final outputDir = Directory(r'c:\Sinar Harapan APP\sinarharapan_app\docs\screenshots\icons');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  const managerUser = UserModel(
    id: 'usr-m1',
    username: 'manager',
    fullName: 'Hendra Wijaya',
    role: UserRole.manager,
    token: 'jwt-manager',
  );

  const receptionistUser = UserModel(
    id: 'usr-r1',
    username: 'receptionist',
    fullName: 'Siti Rahmawati',
    role: UserRole.receptionist,
    token: 'jwt-receptionist',
  );

  final fakeSummary = {
    'totalRevenue': 15250000,
    'netRevenue': 14800000,
    'todayOccupancyPercent': 75.0,
    'monthOccupancyPercent': 68.5,
    'totalCheckIn': 42,
    'totalRooms': 20,
    'occupiedRooms': 15,
    'timeseries': [
      {'date': '2026-10-01', 'revenue': 1200000, 'occupancy': 60.0},
      {'date': '2026-10-02', 'revenue': 1800000, 'occupancy': 75.0},
      {'date': '2026-10-03', 'revenue': 2100000, 'occupancy': 85.0},
      {'date': '2026-10-04', 'revenue': 1600000, 'occupancy': 70.0},
      {'date': '2026-10-05', 'revenue': 2400000, 'occupancy': 90.0},
      {'date': '2026-10-06', 'revenue': 1900000, 'occupancy': 75.0},
      {'date': '2026-10-07', 'revenue': 2200000, 'occupancy': 80.0},
    ],
    'channelDistribution': {
      'reddoorzNominal': 8500000,
      'reddoorzCount': 22,
      'walkInNominal': 6750000,
      'walkInCount': 20,
    },
  };

  final fakeAuditLogs = [
    AuditLogModel(
      id: 'aud-1',
      actionType: 'CHECK_IN',
      userName: 'Siti Rahmawati (RECEPTIONIST)',
      resourceType: 'reservation',
      details: 'guestName: Budi Santoso, roomNumber: 102, invoiceNumber: INV-20261009-001',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ipAddress: '192.168.1.10',
    ),
    AuditLogModel(
      id: 'aud-2',
      actionType: 'STATUS_CLEAN',
      userName: 'Agus (STAFF)',
      resourceType: 'room',
      details: 'roomNumber: 101, reason: MARK_CLEAN, previousStatus: DIRTY, newStatus: AVAILABLE',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ipAddress: '192.168.1.15',
    ),
    AuditLogModel(
      id: 'aud-3',
      actionType: 'EXPORT_REPORT',
      userName: 'Hendra Wijaya (MANAGER)',
      resourceType: 'report',
      details: 'format: EXCEL, totalRecords: 42',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ipAddress: '192.168.1.5',
    ),
  ];

  final fakeTransactions = [
    {
      'id': 'tx-1',
      'invoiceNumber': 'INV-20261009-001',
      'roomNumber': '102',
      'guestName': 'Budi Santoso',
      'amount': 350000,
      'paymentMethod': 'CASH',
      'status': 'PAID',
      'createdAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
    },
    {
      'id': 'tx-2',
      'invoiceNumber': 'INV-20261008-004',
      'roomNumber': '104',
      'guestName': 'Dewi Lestari',
      'amount': 500000,
      'paymentMethod': 'TRANSFER',
      'status': 'PAID',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];

  Future<void> captureScreen({
    required WidgetTester tester,
    required Widget child,
    required String fileName,
    required double width,
    required double height,
    UserModel? mockUser,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
          authStateProvider.overrideWith((ref) => AuthNotifier(_FakeAuthRepo())..state = AuthState(user: mockUser ?? managerUser)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: width,
              height: height,
              child: child,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(buffer);
    });

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  testWidgets('Capture visual screenshots for widths 360, 1280, and 1920', (tester) async {
    for (final width in [360.0, 1280.0, 1920.0]) {
      final wInt = width.toInt();
      final height = width < 500 ? 800.0 : 900.0;

      // 1. Login Screen
      await captureScreen(
        tester: tester,
        child: const LoginScreen(),
        fileName: 'login_$wInt.png',
        width: width,
        height: height,
      );

      // 2. Receptionist Room Grid
      await captureScreen(
        tester: tester,
        child: const RoomGridScreen(),
        fileName: 'receptionist_grid_$wInt.png',
        width: width,
        height: height,
        mockUser: receptionistUser,
      );

      // 3. Manager Tab 0 (Ringkasan / Overview)
      await captureScreen(
        tester: tester,
        child: ManagerDashboardScreen(
          initialTabIndex: 0,
          initialSummaryData: fakeSummary,
          initialAuditLogs: fakeAuditLogs,
          initialTransactions: fakeTransactions,
        ),
        fileName: 'manager_dashboard_ringkasan_$wInt.png',
        width: width,
        height: height,
        mockUser: managerUser,
      );

      // 4. Manager Tab 1 (Inventaris Kamar)
      await captureScreen(
        tester: tester,
        child: ManagerDashboardScreen(
          initialTabIndex: 1,
          initialSummaryData: fakeSummary,
          initialAuditLogs: fakeAuditLogs,
          initialTransactions: fakeTransactions,
        ),
        fileName: 'manager_dashboard_inventaris_$wInt.png',
        width: width,
        height: height,
        mockUser: managerUser,
      );

      // 5. Manager Tab 2 (Laporan Transaksi)
      await captureScreen(
        tester: tester,
        child: ManagerDashboardScreen(
          initialTabIndex: 2,
          initialSummaryData: fakeSummary,
          initialAuditLogs: fakeAuditLogs,
          initialTransactions: fakeTransactions,
        ),
        fileName: 'manager_dashboard_laporan_$wInt.png',
        width: width,
        height: height,
        mockUser: managerUser,
      );

      // 6. Manager Tab 3 (Audit Trail)
      await captureScreen(
        tester: tester,
        child: ManagerDashboardScreen(
          initialTabIndex: 3,
          initialSummaryData: fakeSummary,
          initialAuditLogs: fakeAuditLogs,
          initialTransactions: fakeTransactions,
        ),
        fileName: 'manager_dashboard_audit_$wInt.png',
        width: width,
        height: height,
        mockUser: managerUser,
      );
    }
  });
}
