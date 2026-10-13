import 'dart:io';
import 'dart:ui' as ui;
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
import 'package:sinarharapan_app/features/auth/presentation/widgets/split_door_transition.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_controller.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_grid_screen.dart';

class _MockAuthRepo extends AuthRepository {
  @override
  Future<UserModel> login({required String username, required String password}) async {
    return const UserModel(
      id: 'usr-r1',
      username: 'demo_receptionist',
      fullName: 'Siti Rahmawati',
      role: UserRole.receptionist,
      token: 'jwt-mock',
    );
  }
}

class _MockRoomRepo extends RoomRepository {
  final List<RoomModel> _rooms = [
    const RoomModel(
      id: 'rm-01',
      roomNumber: '01',
      roomType: 'AC',
      floor: 1,
      basePricePerNight: 170000,
      facilities: ['AC', 'WiFi', 'TV', 'Water Heater'],
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
  });

  final outputDir = Directory(r'c:\Sinar Harapan APP\sinarharapan_app\docs\screenshots\transition');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final artifactDir = Directory(r'C:\Users\LOQ 25\.gemini\antigravity-ide\brain\ac219e4c-c385-44cb-a95d-647beeab6547\transition');
  if (!artifactDir.existsSync()) {
    artifactDir.createSync(recursive: true);
  }

  testWidgets('Capture Sequential 30 FPS Frames of Split-Door Overlay Transition', (tester) async {
    const width = 1280.0;
    const height = 800.0;
    tester.view.physicalSize = const Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Langkah A: Ambil snapshot visual layar LoginScreen asli
    final loginBoundaryKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          roomRepositoryProvider.overrideWithValue(_MockRoomRepo()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: RepaintBoundary(
            key: loginBoundaryKey,
            child: const LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    late ui.Image loginSnapshot;
    await tester.runAsync(() async {
      final boundary = loginBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      expect(boundary, isNotNull);
      loginSnapshot = await boundary!.toImage(pixelRatio: 1.0);
    });

    // Langkah B: Setup SplitDoorOverlayWidget di atas Dashboard Resepsionis (RoomGridScreen)
    final rootBoundaryKey = GlobalKey();
    const splitWidth = width * (5 / 11); // 581.81 px

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
          roomRepositoryProvider.overrideWithValue(_MockRoomRepo()),
          authStateProvider.overrideWith(
            (ref) => AuthNotifier(_MockAuthRepo())
              ..state = const AuthState(
                user: UserModel(
                  id: 'usr-r1',
                  username: 'demo_receptionist',
                  fullName: 'Siti Rahmawati',
                  role: UserRole.receptionist,
                  token: 'jwt-mock',
                ),
              ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: RepaintBoundary(
            key: rootBoundaryKey,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Dashboard di bawah (tujuan login)
                  const RoomGridScreen(),
                  // Overlay transisi pintu split-door di root
                  SplitDoorOverlayWidget(
                    image: loginSnapshot,
                    splitWidth: splitWidth,
                    totalWidth: width,
                    totalHeight: height,
                    onComplete: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Frame 0ms (Pintu tertutup penuh)
    await tester.pump();

    // 30 FPS Sampling Timeline (Durasi Total 950ms, Waktu Buka Meluncur ~808ms)
    final sampleTimes = [
      0,    // Frame 01 (0ms): Pintu tertutup penuh, badge SH muncul di tengah
      100,  // Frame 02 (100ms): Pintu tertutup rapat, badge SH stabil
      180,  // Frame 03 (180ms): Ambang batas interval (t=0.15-0.18), pintu mulai membelah
      300,  // Frame 04 (300ms): Panel meluncur perlahan ke kiri dan kanan, celah ~20%
      450,  // Frame 05 (450ms): Pintu meluncur dengan mantap, celah ~45%, search bar tampak
      600,  // Frame 06 (600ms): Pintu terbuka ~70%, kartu kamar terlihat jelas di tengah
      750,  // Frame 07 (750ms): Pintu terbuka ~88%, celah pintu melebar luas
      870,  // Frame 08 (870ms): Pintu terbuka ~97%, panel hampir di luar viewport
      950,  // Frame 09 (950ms): Pintu terbuka 100%, transisi selesai sempurna
    ];

    int lastElapsed = 0;
    int frameIndex = 1;

    for (final elapsed in sampleTimes) {
      final delta = elapsed - lastElapsed;
      if (delta > 0) {
        await tester.pump(Duration(milliseconds: delta));
      }
      lastElapsed = elapsed;

      final frameNumberStr = frameIndex.toString().padLeft(3, '0');
      final fileName = 'f_${frameNumberStr}_${elapsed}ms.png';

      await tester.runAsync(() async {
        final boundary = rootBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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
  });
}
