import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/theme/app_theme.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/auth/presentation/auth_controller.dart';
import 'package:sinarharapan_app/features/auth/data/auth_repository.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_controller.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_grid_screen.dart';

class _FakeAuthRepo extends AuthRepository {
  @override
  Future<UserModel> login({required String username, required String password}) async {
    return const UserModel(
      id: 'usr-rec',
      username: 'receptionist',
      fullName: 'Siti Rahma',
      role: UserRole.receptionist,
      token: 'jwt-mock',
    );
  }

  @override
  Future<UserModel> quickLogin(UserRole role) async {
    return login(username: 'receptionist', password: 'password123');
  }
}

class _FakeRoomRepo extends RoomRepository {
  final List<RoomModel> _rooms = [
    const RoomModel(
      id: 'rm-01',
      roomNumber: '01',
      roomType: 'AC',
      floor: 1,
      basePricePerNight: 170000,
      facilities: ['AC', 'WiFi', 'TV'],
      status: RoomStatusType.available,
    ),
    const RoomModel(
      id: 'rm-02',
      roomNumber: '02',
      roomType: 'AC',
      floor: 1,
      basePricePerNight: 170000,
      facilities: ['AC', 'WiFi'],
      status: RoomStatusType.occupied,
      activeGuestName: 'Budi Santoso',
      activeGuestPhone: '081234567890',
    ),
    const RoomModel(
      id: 'rm-06',
      roomNumber: '06',
      roomType: 'AC',
      floor: 2,
      basePricePerNight: 170000,
      facilities: ['AC', 'WiFi', 'TV'],
      status: RoomStatusType.dirty,
    ),
    const RoomModel(
      id: 'rm-07',
      roomNumber: '07',
      roomType: 'AC Twin',
      floor: 2,
      basePricePerNight: 200000,
      facilities: ['AC', 'WiFi', 'TV'],
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
      final fontLoader = FontLoader('LucideIcons')..addFont(Future.value(fontData));
      await fontLoader.load();
    }
  });

  final outputDir = Directory('docs/screenshots/toolbar');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  Future<void> captureScreen({
    required WidgetTester tester,
    required Widget child,
    required String fileName,
    required double width,
    required double height,
    ProviderContainer? container,
    Future<void> Function(WidgetTester)? beforeCapture,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;

    final boundaryKey = GlobalKey();
    final c = container ??
        ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
            authStateProvider.overrideWith((ref) => AuthNotifier(_FakeAuthRepo())
              ..state = const AuthState(
                user: UserModel(
                  id: 'usr-rec',
                  username: 'receptionist',
                  fullName: 'Siti Rahma',
                  role: UserRole.receptionist,
                  token: 'jwt-mock',
                ),
              )),
          ],
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          builder: (context, materialChild) => RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: width,
              height: height,
              child: materialChild,
            ),
          ),
          home: child,
        ),
      ),
    );

    await tester.pumpAndSettle();

    if (beforeCapture != null) {
      await beforeCapture(tester);
    }

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

    // Unmount and dispose container to ensure no timers linger
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    c.dispose();

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  testWidgets('Capture toolbar screenshots across 1920, 1280, 734, and 360', (tester) async {
    const widths = [1920.0, 1280.0, 734.0, 360.0];

    for (final width in widths) {
      final wInt = width.toInt();
      final height = width < 500 ? 760.0 : 850.0;

      // 1. Default RoomGridScreen
      await captureScreen(
        tester: tester,
        child: RoomGridScreen(fixedTime: DateTime(2026, 10, 12, 10, 0)),
        fileName: 'room_toolbar_${wInt}_default.png',
        width: width,
        height: height,
      );
    }

    // 2. Filter Aktif (1280px): Deluxe + Tersedia + query "10"
    {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
          authStateProvider.overrideWith((ref) => AuthNotifier(_FakeAuthRepo())
            ..state = const AuthState(
              user: UserModel(
                id: 'usr-rec',
                username: 'receptionist',
                fullName: 'Siti Rahma',
                role: UserRole.receptionist,
                token: 'jwt-mock',
              ),
            )),
        ],
      );
      container.read(roomFilterProvider.notifier).state = const RoomFilterState(
        roomType: 'AC',
        status: RoomStatusType.available,
        searchQuery: '0',
      );

      await captureScreen(
        tester: tester,
        container: container,
        child: RoomGridScreen(fixedTime: DateTime(2026, 10, 12, 10, 0)),
        fileName: 'room_toolbar_1280_filter_active.png',
        width: 1280,
        height: 850,
      );
    }

    // 3. Dropdown MenuAnchor terbuka (1280px)
    {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
          authStateProvider.overrideWith((ref) => AuthNotifier(_FakeAuthRepo())
            ..state = const AuthState(
              user: UserModel(
                id: 'usr-rec',
                username: 'receptionist',
                fullName: 'Siti Rahma',
                role: UserRole.receptionist,
                token: 'jwt-mock',
              ),
            )),
        ],
      );

      await captureScreen(
        tester: tester,
        container: container,
        child: RoomGridScreen(fixedTime: DateTime(2026, 10, 12, 10, 0)),
        fileName: 'room_toolbar_1280_menu_open.png',
        width: 1280,
        height: 850,
        beforeCapture: (t) async {
          await t.tap(find.text('Semua Tipe'));
          await t.pumpAndSettle();
        },
      );
    }

    // 4. Empty state (1280px): query "RoomTidakAda"
    {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
          authStateProvider.overrideWith((ref) => AuthNotifier(_FakeAuthRepo())
            ..state = const AuthState(
              user: UserModel(
                id: 'usr-rec',
                username: 'receptionist',
                fullName: 'Siti Rahma',
                role: UserRole.receptionist,
                token: 'jwt-mock',
              ),
            )),
        ],
      );
      container.read(roomFilterProvider.notifier).state = const RoomFilterState(
        searchQuery: 'RoomTidakAda',
      );

      await captureScreen(
        tester: tester,
        container: container,
        child: RoomGridScreen(fixedTime: DateTime(2026, 10, 12, 10, 0)),
        fileName: 'room_toolbar_1280_empty_state.png',
        width: 1280,
        height: 850,
      );
    }
  });
}
