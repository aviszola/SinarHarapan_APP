import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
import 'package:sinarharapan_app/features/shared_widgets/app_button.dart';
import 'package:sinarharapan_app/theme/app_icons.dart';

class _FakeAuthRepo extends AuthRepository {
  int loginCalls = 0;
  bool shouldSucceed = true;

  @override
  Future<UserModel> login({required String username, required String password}) async {
    loginCalls++;
    if (shouldSucceed && username == 'test_receptionist' && password == 'password123') {
      return const UserModel(
        id: 'usr-1',
        username: 'test_receptionist',
        fullName: 'Siti Rahmawati',
        role: UserRole.receptionist,
        token: 'token-mock',
      );
    }
    throw Exception('Nama pengguna atau kata sandi salah. Coba lagi.');
  }

  @override
  Future<UserModel> quickLogin(UserRole role) async {
    loginCalls++;
    if (shouldSucceed) {
      return UserModel(
        id: 'usr-1',
        username: role == UserRole.manager ? 'test_manager' : 'test_receptionist',
        fullName: role == UserRole.manager ? 'Budi Santoso' : 'Siti Rahmawati',
        role: role,
        token: 'token-mock',
      );
    }
    throw Exception('Login gagal');
  }
}

class _TestRoomRepository extends RoomRepository {
  @override
  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    return const [
      RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        floor: 1,
        roomType: 'STANDARD',
        basePricePerNight: 200000,
        facilities: ['AC', 'WiFi'],
        status: RoomStatusType.available,
      ),
    ];
  }

  @override
  Future<List<RoomStatusSnapshot>> getRoomStatusOnly() async {
    return const [
      RoomStatusSnapshot(
        id: 'rm-101',
        roomNumber: '101',
        status: RoomStatusType.available,
      ),
    ];
  }
}

Future<ui.Image> _createTestImage(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = const Color(0xFF001B4E);
  canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Split-Door Login Transition Verification Suite (Root Overlay & In-Tree)', () {
    testWidgets('1. SplitDoorOverlayWidget: Frame Tengah (250ms) Menunjukkan Posisi Translate != 0 dan != Final', (tester) async {
      final testImage = await _createTestImage(1280, 800);
      const splitWidth = 581.81; // 1280 * (5 / 11)
      const totalWidth = 1280.0;
      const totalHeight = 800.0;

      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SplitDoorOverlayWidget(
              image: testImage,
              splitWidth: splitWidth,
              totalWidth: totalWidth,
              totalHeight: totalHeight,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      // Frame awal (0ms)
      await tester.pump();
      expect(find.byType(SplitDoorOverlayWidget), findsOneWidget);
      expect(find.text('SH'), findsOneWidget);

      // Pada t=0ms, translation offset adalah 0
      final initialTransforms = tester.widgetList<Transform>(find.byType(Transform)).toList();
      expect(initialTransforms.length, greaterThanOrEqualTo(2));
      final initialLeftTransform = initialTransforms[0];
      final initialRightTransform = initialTransforms[1];
      expect(initialLeftTransform.transform.getTranslation().x, equals(0.0), reason: 'Di 0ms, panel kiri belum bergeser');
      expect(initialRightTransform.transform.getTranslation().x, equals(0.0), reason: 'Di 0ms, panel kanan belum bergeser');

      // Maju ke frame tengah (250ms)
      await tester.pump(const Duration(milliseconds: 250));

      final midTransforms = tester.widgetList<Transform>(find.byType(Transform)).toList();
      final midLeftTranslation = midTransforms[0].transform.getTranslation().x;
      final midRightTranslation = midTransforms[1].transform.getTranslation().x;

      // Verifikasi translasi != 0 dan != final
      expect(midLeftTranslation, isNegative, reason: 'Panel kiri harus bergerak ke arah kiri (< 0)');
      expect(midLeftTranslation, greaterThan(-splitWidth), reason: 'Panel kiri belum mencapai posisi akhir (-splitWidth)');
      expect(midLeftTranslation, isNot(equals(0.0)), reason: 'Panel kiri translasi != 0 pada 250ms');

      expect(midRightTranslation, isPositive, reason: 'Panel kanan harus bergerak ke arah kanan (> 0)');
      expect(midRightTranslation, lessThan(totalWidth - splitWidth), reason: 'Panel kanan belum mencapai posisi akhir');
      expect(midRightTranslation, isNot(equals(0.0)), reason: 'Panel kanan translasi != 0 pada 250ms');

      // Maju 700ms lagi (total 950ms) dan pump frame penyelesaian
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 50));
      expect(completed, isTrue, reason: 'Callback onComplete harus dipanggil saat durasi selesai');
    });

    testWidgets('2. Transisi TIDAK Berjalan Saat Login Gagal, Banner Error Inline Tetap Muncul', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAuthRepo()..shouldSucceed = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            roomRepositoryProvider.overrideWithValue(_TestRoomRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'wrong_user');
      await tester.enterText(textFields.last, 'wrong_pass');
      await tester.pump();

      final submitBtn = find.widgetWithText(AppButton, 'Masuk ke Sistem');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // TIDAK boleh ada SplitDoorOverlayWidget saat login gagal
      expect(find.byType(SplitDoorOverlayWidget), findsNothing);

      // Banner error inline muncul
      expect(find.text('Nama pengguna atau kata sandi salah. Coba lagi.'), findsOneWidget);
      expect(find.byIcon(AppIcons.error), findsOneWidget);
    });

    testWidgets('3. Reduced Motion: Duration.zero dan Langsung Berpindah Tanpa Overlay', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAuthRepo()..shouldSucceed = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            roomRepositoryProvider.overrideWithValue(_TestRoomRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: const MediaQueryData(
                disableAnimations: true, // Prefer-reduced-motion aktif
              ),
              child: const LoginScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'test_receptionist');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump();

      final submitBtn = find.widgetWithText(AppButton, 'Masuk ke Sistem');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      await tester.pump();

      // Karena disableAnimations == true, SplitDoorOverlayWidget dilewati langsung
      expect(find.byType(SplitDoorOverlayWidget), findsNothing);
    });

    testWidgets('4. Tombol Masuk Tetap Nonaktif Selama Transisi (Cegah Double Submit)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAuthRepo()..shouldSucceed = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            roomRepositoryProvider.overrideWithValue(_TestRoomRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'test_receptionist');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump();

      // Tap pertama
      final submitBtn = find.widgetWithText(AppButton, 'Masuk ke Sistem');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump(); // mulai login

      expect(fakeRepo.loginCalls, 1);

      // Selama login/transisi aktif, tombol harus nonaktif (onPressed: null) & loading
      final primaryButtons = tester.widgetList<AppButton>(find.byType(AppButton)).toList();
      final loginBtn = primaryButtons.firstWhere((b) => b.label == 'Masuk ke Sistem');
      expect(loginBtn.onPressed, isNull, reason: 'Tombol harus dinonaktifkan saat transisi/loading');
      expect(loginBtn.isLoading, isTrue, reason: 'Tombol harus berstatus loading');

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();

      // Panggilan login tetap hanya 1 kali (tidak ada double-submit)
      expect(fakeRepo.loginCalls, 1);
    });

    testWidgets('5. AnimationController Ter-dispose Bersih Tanpa Pending Timer saat Unmount', (tester) async {
      final testImage = await _createTestImage(800, 600);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: SplitDoorOverlayWidget(
            image: testImage,
            splitWidth: 400,
            totalWidth: 800,
            totalHeight: 600,
            onComplete: () {},
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Hapus widget dari tree sebelum durasi selesai
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Unmounted')),
        ),
      );

      // Tidak boleh ada pengecualian dari dispose controller
      expect(tester.takeException(), isNull);
    });

    // Uji responsivitas & pencegahan overflow pada resolusi wajib
    final viewports = [
      {'name': '360x640 (Mobile Kecil)', 'size': const Size(360, 640)},
      {'name': '390x844 (Mobile Standar)', 'size': const Size(390, 844)},
      {'name': '768x1024 (Tablet)', 'size': const Size(768, 1024)},
      {'name': '1280x800 (Laptop)', 'size': const Size(1280, 800)},
      {'name': '1920x1080 (FHD Desktop)', 'size': const Size(1920, 1080)},
    ];

    for (final vp in viewports) {
      testWidgets('6. Verifikasi Bebas Overflow SplitDoorOverlayWidget pada Resolusi ${vp['name']}', (tester) async {
        final size = vp['size'] as Size;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final split = size.width >= 900 ? size.width * (5 / 11) : size.width * 0.5;
        final testImage = await _createTestImage(size.width.toInt(), size.height.toInt());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: SplitDoorOverlayWidget(
              image: testImage,
              splitWidth: split,
              totalWidth: size.width,
              totalHeight: size.height,
              onComplete: () {},
            ),
          ),
        );

        // Uji di beberapa titik interpolasi transisi (0%, 25%, 50%, 75%, 100%)
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Tidak boleh overflow di awal pada ${size.width}px');

        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.takeException(), isNull, reason: 'Tidak boleh overflow di 150ms pada ${size.width}px');

        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'Tidak boleh overflow di 450ms pada ${size.width}px');

        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Tidak boleh overflow saat selesai pada ${size.width}px');
      });
    }
  });
}
