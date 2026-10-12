import 'dart:io';
import 'dart:ui' as ui;
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
      id: 'rm-101',
      roomNumber: '101',
      roomType: 'Deluxe',
      floor: 1,
      basePricePerNight: 350000,
      facilities: ['AC', 'WiFi', 'TV'],
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
  ];

  @override
  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    return _rooms;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  final outputDir = Directory('docs/screenshots/toolbar/motion');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final artifactDir = Directory(r'C:\Users\LOQ 25\.gemini\antigravity-ide\brain\ac219e4c-c385-44cb-a95d-647beeab6547\toolbar\motion');
  if (!artifactDir.existsSync()) {
    artifactDir.createSync(recursive: true);
  }

  testWidgets('Sample motion frames for AnimatedSwitcher fade (150ms)', (tester) async {
    const width = 1280.0;
    const height = 850.0;
    tester.view.physicalSize = const Size(width, height);
    tester.view.devicePixelRatio = 1.0;

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

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          builder: (context, child) => RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: width,
              height: height,
              child: child,
            ),
          ),
          home: RoomGridScreen(fixedTime: DateTime(2026, 10, 12, 10, 0)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger filter change to cause AnimatedSwitcher fade transition (duration 150ms)
    container.read(roomFilterProvider.notifier).state = const RoomFilterState(
      searchQuery: 'NonExistentRoom',
    );
    // Initial pump after state change
    await tester.pump();

    // Sample timestamps at ~30 FPS: 0ms, 33ms, 66ms, 100ms, 150ms
    final sampleTimes = [0, 33, 66, 100, 150];
    int lastElapsed = 0;
    int frameIndex = 1;

    for (final elapsed in sampleTimes) {
      final delta = elapsed - lastElapsed;
      if (delta > 0) {
        await tester.pump(Duration(milliseconds: delta));
      }
      lastElapsed = elapsed;

      final frameNumberStr = frameIndex.toString().padLeft(3, '0');
      final fileName = 'fade_f_${frameNumberStr}_${elapsed}ms.png';

      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) return;

        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          await File('${outputDir.path}/$fileName').writeAsBytes(bytes);
          await File('${artifactDir.path}/$fileName').writeAsBytes(bytes);
        }
      });

      frameIndex++;
    }

    // Clean up
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    container.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
