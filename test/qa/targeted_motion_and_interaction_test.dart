import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/app/theme.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_card.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_controller.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_filter_bar.dart';
import 'package:sinarharapan_app/features/shared_widgets/status_badge.dart';

class _FakeRoomRepo extends RoomRepository {
  @override
  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    return const [
      RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: ['AC', 'WiFi'],
        status: RoomStatusType.available,
      ),
    ];
  }

  @override
  Future<List<RoomStatusSnapshot>> getRoomStatusOnly() async {
    return const [
      RoomStatusSnapshot(id: 'rm-101', roomNumber: '101', status: RoomStatusType.available),
    ];
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Target C: Search Debounce & Clear Button Behavioral Tests', () {
    testWidgets('Rapid typing in RoomFilterBar debounces query for 150ms before updating provider', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RoomFilterBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField);
      expect(searchFieldFinder, findsOneWidget);

      // 1. Ketik '1'
      await tester.enterText(searchFieldFinder, '1');
      await tester.pump(const Duration(milliseconds: 50));
      // Query belum boleh masuk ke provider sebelum 150ms
      expect(container.read(roomFilterProvider).searchQuery, isEmpty);

      // 2. Ketik '10' cepat (< 150ms berikutnya)
      await tester.enterText(searchFieldFinder, '10');
      await tester.pump(const Duration(milliseconds: 50));
      // Query masih kosong karena timer debounce di-reset
      expect(container.read(roomFilterProvider).searchQuery, isEmpty);

      // 3. Ketik '101'
      await tester.enterText(searchFieldFinder, '101');
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(roomFilterProvider).searchQuery, isEmpty);

      // 4. Tunggu sisa durasi hingga melewati 150ms
      await tester.pump(const Duration(milliseconds: 60)); // total > 150ms sejak ketikan terakhir
      expect(container.read(roomFilterProvider).searchQuery, '101');

      // Unmount & dispose container bersih
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump();
    });

    testWidgets('Tapping search clear button immediately resets query and cancels debounce timer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RoomFilterBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField);
      await tester.enterText(searchFieldFinder, 'Deluxe');
      await tester.pump(const Duration(milliseconds: 200));
      expect(container.read(roomFilterProvider).searchQuery, 'Deluxe');

      // Tombol clear ('x') muncul saat query terisi
      final clearIconBtnFinder = find.byTooltip('Hapus pencarian');
      expect(clearIconBtnFinder, findsOneWidget);

      await tester.tap(clearIconBtnFinder);
      await tester.pump();

      // Query langsung kosong seketika tanpa jeda debounce
      expect(container.read(roomFilterProvider).searchQuery, isEmpty);
      final textField = tester.widget<TextField>(searchFieldFinder);
      expect(textField.controller?.text, isEmpty);

      // Bersihkan
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump();
    });

    testWidgets('Tapping Reset button clears search and restores initial filter state', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RoomFilterBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField);
      await tester.enterText(searchFieldFinder, 'Suite');
      await tester.pump(const Duration(milliseconds: 200));

      final resetBtnFinder = find.widgetWithText(OutlinedButton, 'Reset');
      expect(resetBtnFinder, findsOneWidget);

      await tester.tap(resetBtnFinder);
      await tester.pump();

      expect(container.read(roomFilterProvider).searchQuery, isEmpty);
      expect(container.read(roomFilterProvider).roomType, 'ALL');
      expect(container.read(roomFilterProvider).floor, 0);

      // Bersihkan
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump();
    });
  });

  group('Target D: Refresh Button & Rotation Interaction Tests', () {
    testWidgets('Refresh button invokes onRefresh and is disabled while isRefreshing is true', (tester) async {
      int refreshCallCount = 0;
      bool isRefreshing = false;

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      Widget buildFilterBar(StateSetter setState) {
        return UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: RoomFilterBar(
                isRefreshing: isRefreshing,
                onRefresh: () {
                  refreshCallCount++;
                  setState(() => isRefreshing = true);
                },
              ),
            ),
          ),
        );
      }

      late StateSetter stateSetter;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            stateSetter = setState;
            return buildFilterBar(setState);
          },
        ),
      );
      await tester.pumpAndSettle();

      final segarkanBtnFinder = find.widgetWithText(OutlinedButton, 'Segarkan');
      expect(segarkanBtnFinder, findsOneWidget);

      // Saat normal, tombol aktif
      OutlinedButton btnWidget = tester.widget<OutlinedButton>(segarkanBtnFinder);
      expect(btnWidget.onPressed, isNotNull);

      // Ketuk tombol segarkan
      await tester.tap(segarkanBtnFinder);
      await tester.pump();

      expect(refreshCallCount, 1);

      // Ketika isRefreshing == true, tombol harus dinonaktifkan (onPressed: null)
      btnWidget = tester.widget<OutlinedButton>(segarkanBtnFinder);
      expect(btnWidget.onPressed, isNull);

      // Reset isRefreshing kembali ke false
      stateSetter(() => isRefreshing = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250)); // Biarkan rotasi controller animateTo(1.0) selesai

      // Tombol aktif kembali
      btnWidget = tester.widget<OutlinedButton>(segarkanBtnFinder);
      expect(btnWidget.onPressed, isNotNull);

      // Bersihkan
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump();
    });
  });

  group('Target E: Reduced Motion Accessibility Tests', () {
    testWidgets('StatusBadge uses Duration.zero when disableAnimations is true vs 180ms normally', (tester) async {
      // 1. Kondisi normal (disableAnimations = false)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(disableAnimations: false),
              child: StatusBadge(status: RoomStatusType.available),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      AnimatedContainer normalAnimatedContainer =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
      expect(normalAnimatedContainer.duration, const Duration(milliseconds: 180));

      // 2. Kondisi reduced motion (disableAnimations = true)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: StatusBadge(status: RoomStatusType.available),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      AnimatedContainer reducedAnimatedContainer =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
      expect(reducedAnimatedContainer.duration, Duration.zero);
    });

    testWidgets('RoomCard preserves scale 1.0 even when pressed if disableAnimations is true', (tester) async {
      const room = RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: ['AC', 'WiFi'],
        status: RoomStatusType.available,
      );

      // Render dengan reduced motion aktif
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: RoomCard(
                room: room,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byType(RoomCard);
      final gesture = await tester.startGesture(tester.getCenter(cardFinder));
      await tester.pump();

      // Pada reduced motion, AnimatedScale harus tetap 1.0 (tidak mengecil ke 0.99)
      final scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, 1.0);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('Target F: Animation Lifecycle & Pointer Cleanup Tests', () {
    testWidgets('RoomCard pointer down sets scale 0.99 and pointer cancel restores scale 1.0', (tester) async {
      const room = RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: ['AC', 'WiFi'],
        status: RoomStatusType.available,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(disableAnimations: false),
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: RoomCard(
                    room: room,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      AnimatedScale scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, 1.0);

      // 1. Pointer Down
      final gesture = await tester.startGesture(tester.getCenter(find.byType(RoomCard)));
      await tester.pump();

      scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, 0.99, reason: 'Tekan kartu memicu scale 0.99');

      // 2. Pointer Cancel (gesture dibatalkan / drag keluar)
      await gesture.cancel();
      await tester.pump();

      scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, 1.0, reason: 'Membatalkan gesture mengembalikan scale ke 1.0');

      await tester.pumpAndSettle();
    });

    testWidgets('Unmounting RoomFilterBar with active in-flight debounce timer disposes cleanly without timer leaks', (tester) async {
      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RoomFilterBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mulai mengetik untuk mengaktifkan debounce timer 150ms
      await tester.enterText(find.byType(TextField), 'Testing In Flight');
      await tester.pump(const Duration(milliseconds: 30)); // timer aktif di latar belakang

      // Unmount widget secara tiba-tiba saat timer debounce masih aktif
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump();

      // Jika _debounceTimer tidak dibatalkan di dispose(), Flutter test runner akan melempar:
      // "A Timer is still pending even after the widget tree was disposed."
      expect(tester.takeException(), isNull, reason: 'Tidak ada timer yang tertinggal setelah unmount');
    });

    testWidgets('Unmounting RoomFilterBar with active repeating refresh animation disposes cleanly without ticker leaks', (tester) async {
      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RoomFilterBar(
                isRefreshing: true, // _refreshController.repeat() aktif
              ),
            ),
          ),
        ),
      );
      // Animasi sedang berputar
      await tester.pump(const Duration(milliseconds: 100));

      // Unmount saat animasi sedang berputar
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pump();

      // Harus bersih tanpa TickerException
      expect(tester.takeException(), isNull, reason: 'AnimationController ter-dispose tanpa ticker leak');
    });
  });
}
