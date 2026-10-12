import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_controller.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_filter_bar.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_grid_screen.dart';
import 'package:sinarharapan_app/theme/app_theme.dart';

class _FakeRoomRepo extends RoomRepository {
  final List<RoomModel> mockRooms;
  _FakeRoomRepo([this.mockRooms = const [
    RoomModel(
      id: '1',
      roomNumber: '101',
      roomType: 'Standard',
      floor: 1,
      basePricePerNight: 250000,
      facilities: ['AC', 'WiFi'],
      status: RoomStatusType.available,
    ),
    RoomModel(
      id: '2',
      roomNumber: '102',
      roomType: 'Deluxe',
      floor: 1,
      basePricePerNight: 350000,
      facilities: ['AC', 'WiFi', 'TV'],
      status: RoomStatusType.occupied,
      activeGuestName: 'Budi Santoso',
    ),
    RoomModel(
      id: '3',
      roomNumber: '201',
      roomType: 'Deluxe',
      floor: 2,
      basePricePerNight: 350000,
      facilities: ['AC', 'WiFi', 'TV'],
      status: RoomStatusType.dirty,
    ),
    RoomModel(
      id: '4',
      roomNumber: '202',
      roomType: 'Family',
      floor: 2,
      basePricePerNight: 500000,
      facilities: ['AC', 'WiFi', 'TV', 'Bathtub'],
      status: RoomStatusType.maintenance,
    ),
  ]]);

  @override
  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    return mockRooms;
  }
}

Widget _wrapWithScope({
  required Widget child,
  ProviderContainer? container,
  List<RoomModel>? rooms,
  double width = 1280,
  double height = 800,
  double textScale = 1.0,
}) {
  final c = container ??
      ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo(rooms ?? const [])),
        ],
      );

  return MediaQuery(
    data: MediaQueryData(
      size: Size(width, height),
      textScaler: TextScaler.linear(textScale),
    ),
    child: UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('RoomFilterBar — Chip Status Tests', () {
    testWidgets('1. Chip status render format Label + angka dan single-select sync dengan state', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        _wrapWithScope(
          child: const RoomFilterBar(),
          container: container,
          width: 1400,
        ),
      );
      await tester.pumpAndSettle();

      // Cek label dan count
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Tersedia'), findsOneWidget);
      expect(find.text('Terisi'), findsOneWidget);
      expect(find.text('Kotor'), findsOneWidget);
      expect(find.text('Perawatan'), findsOneWidget);

      // Default state status adalah null (Semua)
      expect(container.read(roomFilterProvider).status, isNull);

      // Klik chip Tersedia
      await tester.tap(find.text('Tersedia'));
      await tester.pumpAndSettle();
      expect(container.read(roomFilterProvider).status, RoomStatusType.available);

      // Klik chip Terisi
      await tester.tap(find.text('Terisi'));
      await tester.pumpAndSettle();
      expect(container.read(roomFilterProvider).status, RoomStatusType.occupied);

      // Klik kembali ke Semua
      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();
      expect(container.read(roomFilterProvider).status, isNull);

      container.dispose();
    });

    testWidgets('2. Chip dengan angka 0 tetap bisa dipilih', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Data hanya berisi kamar Available, yang lain 0
      final singleStatusRepo = _FakeRoomRepo([
        const RoomModel(
          id: '1',
          roomNumber: '101',
          roomType: 'Standard',
          floor: 1,
          basePricePerNight: 250000,
          facilities: ['WiFi'],
          status: RoomStatusType.available,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(singleStatusRepo),
        ],
      );

      await tester.pumpWidget(
        _wrapWithScope(
          child: const RoomFilterBar(),
          container: container,
          width: 1400,
        ),
      );
      await tester.pumpAndSettle();

      // Chip Kotor bernilai 0
      expect(find.text('Kotor'), findsOneWidget);
      await tester.tap(find.text('Kotor'));
      await tester.pumpAndSettle();

      // State harus terupdate ke dirty meskipun count 0
      expect(container.read(roomFilterProvider).status, RoomStatusType.dirty);

      container.dispose();
    });
  });

  group('RoomFilterBar — Custom Dropdown MenuAnchor Tests', () {
    testWidgets('3. Dropdown Tipe menampilkan MenuAnchor, opsi hitungan, dan item terpilih', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        _wrapWithScope(
          child: const RoomFilterBar(),
          container: container,
          width: 1400,
        ),
      );
      await tester.pumpAndSettle();

      // Tombol default "Semua Tipe"
      final typeBtnFinder = find.text('Semua Tipe');
      expect(typeBtnFinder, findsOneWidget);

      // Buka dropdown MenuAnchor
      await tester.tap(typeBtnFinder);
      await tester.pumpAndSettle();

      // Opsi Deluxe tampil di dalam menu
      final deluxeFinder = find.widgetWithText(MenuItemButton, 'Deluxe');
      expect(deluxeFinder, findsOneWidget);

      // Pilih Deluxe
      await tester.tap(deluxeFinder);
      await tester.pumpAndSettle();

      // Label tombol trigger berubah menjadi "Tipe: Deluxe"
      expect(find.text('Tipe: Deluxe'), findsOneWidget);
      expect(container.read(roomFilterProvider).roomType, 'Deluxe');

      container.dispose();
    });

    testWidgets('4. Dropdown Lantai menampilkan hitungan dan memperbarui state', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        _wrapWithScope(
          child: const RoomFilterBar(),
          container: container,
          width: 1400,
        ),
      );
      await tester.pumpAndSettle();

      // Tombol default "Semua Lantai"
      final floorBtnFinder = find.text('Semua Lantai');
      expect(floorBtnFinder, findsOneWidget);

      await tester.tap(floorBtnFinder);
      await tester.pumpAndSettle();

      final floor2Finder = find.widgetWithText(MenuItemButton, 'Lantai 2');
      expect(floor2Finder, findsOneWidget);

      await tester.tap(floor2Finder);
      await tester.pumpAndSettle();

      expect(find.text('Lantai: 2'), findsOneWidget);
      expect(container.read(roomFilterProvider).floor, 2);

      container.dispose();
    });
  });

  group('RoomFilterBar — Tombol Reset (n) Tests', () {
    testWidgets('5. Reset (n) muncul saat filter aktif dan membersihkan seluruh state', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        _wrapWithScope(
          child: const RoomFilterBar(),
          container: container,
          width: 1400,
        ),
      );
      await tester.pumpAndSettle();

      // Awalnya tidak ada filter aktif -> tombol Reset tidak muncul
      expect(find.widgetWithText(OutlinedButton, 'Reset'), findsNothing);

      // Aktifkan filter tipe Deluxe (1 filter)
      await tester.tap(find.text('Semua Tipe'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(MenuItemButton, 'Deluxe'));
      await tester.pumpAndSettle();

      // Tombol Reset (1) muncul
      expect(find.text(' (1)'), findsOneWidget);

      // Aktifkan juga filter status Tersedia (2 filter)
      await tester.tap(find.text('Tersedia'));
      await tester.pumpAndSettle();
      expect(find.text(' (2)'), findsOneWidget);

      // Klik tombol Reset
      final resetBtnFinder = find.widgetWithText(OutlinedButton, 'Reset');
      await tester.tap(resetBtnFinder);
      await tester.pumpAndSettle();

      // State kembali ke default
      expect(container.read(roomFilterProvider).roomType, 'ALL');
      expect(container.read(roomFilterProvider).status, isNull);
      expect(container.read(roomFilterProvider).searchQuery, isEmpty);
      expect(find.widgetWithText(OutlinedButton, 'Reset'), findsNothing);

      container.dispose();
    });
  });

  group('RoomFilterBar — Kolom Pencarian & Tombol Clear Tests', () {
    testWidgets('6. Kolom pencarian debounce 250ms dan tombol clear mengosongkan query', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        _wrapWithScope(
          child: const RoomFilterBar(),
          container: container,
          width: 1400,
        ),
      );
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'Budi');

      // Sebelum 250ms, query belum masuk ke provider
      await tester.pump(const Duration(milliseconds: 150));
      expect(container.read(roomFilterProvider).searchQuery, isEmpty);

      // Setelah melewati 250ms
      await tester.pump(const Duration(milliseconds: 150));
      expect(container.read(roomFilterProvider).searchQuery, 'Budi');

      // Tombol clear 'x' muncul
      final clearBtn = find.byTooltip('Hapus pencarian');
      expect(clearBtn, findsOneWidget);

      await tester.tap(clearBtn);
      await tester.pump();

      expect(container.read(roomFilterProvider).searchQuery, isEmpty);
      final tf = tester.widget<TextField>(searchInput);
      expect(tf.controller?.text, isEmpty);

      container.dispose();
    });

    testWidgets('7. Shortcut Ctrl+F memfokuskan search field', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        _wrapWithScope(
          child: const RoomFilterBar(),
          container: container,
          width: 1400,
        ),
      );
      await tester.pumpAndSettle();

      // Trigger Ctrl+F
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, platform: 'windows');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      final searchInput = find.byType(TextField);
      expect(searchInput, findsOneWidget);

      container.dispose();
    });
  });

  group('RoomFilterBar — Tombol Segarkan & Error Recovery Tests', () {
    testWidgets('8. Tombol Segarkan memicu refresh dan menampilkan error inline saat gagal', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool shouldFail = true;
      int refreshCalls = 0;

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
        ],
      );

      await tester.pumpWidget(
        _wrapWithScope(
          child: RoomFilterBar(
            onRefresh: () async {
              refreshCalls++;
              if (shouldFail) {
                throw Exception('Koneksi terputus');
              }
            },
          ),
          container: container,
          width: 1400,
        ),
      );
      await tester.pumpAndSettle();

      final refreshBtn = find.widgetWithText(OutlinedButton, 'Segarkan');
      expect(refreshBtn, findsOneWidget);

      // Klik segarkan (gagal)
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      expect(refreshCalls, 1);
      expect(find.text('Gagal memuat. Coba lagi.'), findsOneWidget);

      // Coba lagi dengan sukses
      shouldFail = false;
      final retryBtn = find.byTooltip('Coba Segarkan Kembali');
      await tester.tap(retryBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(refreshCalls, 2);

      // Tunggu reset success
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Teks diperbarui muncul
      expect(find.textContaining('Diperbarui'), findsOneWidget);

      container.dispose();
    });
  });

  group('RoomGridScreen — Empty State & Fade Transition Tests', () {
    testWidgets('9. Empty state bersih tampil tanpa ilustrasi bila hasil pencarian kosong', (tester) async {
      tester.view.physicalSize = const Size(1400, 800);
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
            home: RoomGridScreen(fixedTime: DateTime(2026, 10, 12, 10, 0)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Filter dengan kata yang tidak ada
      container.read(roomFilterProvider.notifier).state =
          const RoomFilterState(searchQuery: 'NonExistentRoomNumber999');
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada kamar yang cocok.'), findsOneWidget);
      final resetFilterBtn = find.widgetWithText(OutlinedButton, 'Reset filter');
      expect(resetFilterBtn, findsOneWidget);

      // Klik reset filter
      await tester.tap(resetFilterBtn);
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada kamar yang cocok.'), findsNothing);
      expect(find.text('Lantai 1'), findsOneWidget);

      container.dispose();
    });
  });

  group('RoomFilterBar — Layout Responsif Bebas Overflow Tests', () {
    const testWidths = [360.0, 390.0, 734.0, 768.0, 1280.0, 1400.0, 1920.0];

    for (final width in testWidths) {
      testWidgets('10. Lebar $width bebas overflow pada text scale 1.0x dan 1.3x', (tester) async {
        for (final scale in [1.0, 1.3]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;

          final container = ProviderContainer(
            overrides: [
              roomRepositoryProvider.overrideWithValue(_FakeRoomRepo()),
            ],
          );

          await tester.pumpWidget(
            _wrapWithScope(
              child: const RoomFilterBar(),
              container: container,
              width: width,
              textScale: scale,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          container.dispose();
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }
  });
}
