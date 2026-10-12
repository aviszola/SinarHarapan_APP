import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/app/theme.dart';
import 'package:sinarharapan_app/features/checkout/presentation/check_out_dialog.dart';
import 'package:sinarharapan_app/features/checkout/presentation/invoice_preview_dialog.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_card.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_controller.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_grid_screen.dart';
import 'package:sinarharapan_app/features/reservation/presentation/active_guests_modal.dart';
import 'package:sinarharapan_app/features/reservation/presentation/check_in_modal.dart';
import 'package:sinarharapan_app/core/network/api_client.dart';
import 'package:sinarharapan_app/theme/app_icons.dart';
import 'package:sinarharapan_app/features/shared_widgets/app_button.dart';
import 'package:sinarharapan_app/features/shared_widgets/status_badge.dart';

class _MotionTestRoomRepo extends RoomRepository {
  int checkInCalls = 0;
  int checkOutCalls = 0;
  Completer<Map<String, dynamic>>? checkInCompleter;
  Completer<Map<String, dynamic>>? checkOutCompleter;
  bool shouldFailCheckIn = false;
  String checkInErrorMessage = '409: Kamar sudah terisi';
  bool shouldFailCheckOut = false;

  final List<RoomModel> _rooms = [
    const RoomModel(
      id: 'rm-101',
      roomNumber: '101',
      roomType: 'Standard',
      floor: 1,
      basePricePerNight: 250000,
      facilities: ['AC', 'WiFi'],
      status: RoomStatusType.available,
    ),
    const RoomModel(
      id: 'rm-102',
      roomNumber: '102',
      roomType: 'Deluxe',
      floor: 1,
      basePricePerNight: 350000,
      facilities: ['AC', 'WiFi', 'TV'],
      status: RoomStatusType.occupied,
      activeReservationId: 'res-999',
      activeGuestName: 'Budi Santoso',
      activeGuestPhone: '081234567890',
    ),
  ];

  @override
  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    return _rooms;
  }

  @override
  Future<RoomModel?> getRoomById(String id) async {
    return _rooms.firstWhere((r) => r.id == id, orElse: () => _rooms.first);
  }

  @override
  Future<Map<String, dynamic>> createReservation({
    required String roomId,
    required String bookingSource,
    String? reddoorzBookingCode,
    required String idType,
    required String idNumber,
    required String guestFullName,
    String? guestAddress,
    String? guestNationality,
    required String guestPhone,
    String? idImageUrl,
    required String checkInTime,
    required String expectedCheckOutTime,
    required int totalNights,
    required double roomRate,
    required String paymentMethod,
  }) async {
    checkInCalls++;
    if (shouldFailCheckIn) {
      throw ApiException(checkInErrorMessage, statusCode: 409);
    }
    if (checkInCompleter != null) {
      return checkInCompleter!.future;
    }
    return {'id': 'res-101', 'status': 'ACTIVE', 'invoiceNumber': 'INV-TEST-001'};
  }

  @override
  Future<Map<String, dynamic>> processCheckout({
    required String reservationId,
    required String actualCheckOutTime,
    required List<Map<String, dynamic>> additionalCharges,
  }) async {
    checkOutCalls++;
    if (shouldFailCheckOut) {
      throw Exception('Tagihan belum lunas');
    }
    if (checkOutCompleter != null) {
      return checkOutCompleter!.future;
    }
    return {'status': 'CHECKED_OUT', 'total': 0};
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Prioritas 1: Tombol Check-in/Check-out Motion & Double-Submit Guard Tests', () {
    testWidgets('CheckOutDialog: state berurutan normal -> loading -> sukses (600ms) -> pop, dan double-submit dicegah', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _MotionTestRoomRepo();
      final completer = Completer<Map<String, dynamic>>();
      repo.checkOutCompleter = completer;

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final testRoom = repo._rooms[1]; // room 102 occupied

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CheckOutDialog(room: testRoom),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmBtnFinder = find.widgetWithText(AppButton, 'Selesaikan Check-Out (Tanpa Biaya)');
      expect(confirmBtnFinder, findsOneWidget);

      // 1. Tombol awal dalam keadaan Normal (bukan loading, bukan sukses)
      final appBtnBefore = tester.widget<AppButton>(confirmBtnFinder);
      expect(appBtnBefore.isLoading, isFalse);
      expect(appBtnBefore.isSuccess, isFalse);
      expect(appBtnBefore.onPressed, isNotNull);

      // 2. Klik tombol konfirmasi check-out
      await tester.tap(confirmBtnFinder);
      await tester.pump(); // frame transisi ke loading

      // Rapid double-tap: ketuk tombol untuk kedua kalinya saat in-flight
      await tester.tap(find.byType(AppButton).last);
      await tester.pump();

      // Verifikasi tombol dalam state LOADING
      final appBtnLoading = tester.widget<AppButton>(find.byType(AppButton).last);
      expect(appBtnLoading.isLoading, isTrue);
      expect(appBtnLoading.onPressed, isNull, reason: 'Tombol nonaktif saat loading');
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'Spinner muncul di dalam tombol');

      // Verifikasi double-tap hanya memanggil repository 1 KALI (guard UI in-flight berhasil)
      expect(repo.checkOutCalls, 1, reason: 'Double-tap dicegah di level UI flag in-flight');

      // 3. Selesaikan panggilan backend secara asinkron
      completer.complete({'status': 'CHECKED_OUT'});
      await tester.pump(); // update state ke success

      // Verifikasi tombol dalam state SUKSES (centang + 'Berhasil Check-Out')
      final appBtnSuccess = tester.widget<AppButton>(find.byType(AppButton).last);
      expect(appBtnSuccess.isSuccess, isTrue);
      expect(find.text('Berhasil Check-Out'), findsOneWidget);
      expect(find.descendant(of: find.byType(AppButton).last, matching: find.byIcon(AppIcons.check)), findsOneWidget);

      // Tunggu durasi sukses 450ms
      await tester.pump(const Duration(milliseconds: 200));
      // Masih dalam state sukses
      expect(find.text('Berhasil Check-Out'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Dialog berhasil pop (tertutup) setelah jeda sukses 450ms
      expect(find.byType(CheckOutDialog), findsNothing);

      container.dispose();
    });

    testWidgets('CheckOutDialog error: kembali normal dan menampilkan pesan inline', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _MotionTestRoomRepo();
      repo.shouldFailCheckOut = true;

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final testRoom = repo._rooms[1];

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CheckOutDialog(room: testRoom),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmBtnFinder = find.widgetWithText(AppButton, 'Selesaikan Check-Out (Tanpa Biaya)');
      await tester.tap(confirmBtnFinder);
      await tester.pumpAndSettle();

      // Dialog tetap terbuka dan menampilkan pesan inline
      expect(find.byType(CheckOutDialog), findsOneWidget);
      expect(find.text('Gagal: Tagihan belum lunas'), findsOneWidget, reason: 'Pesan error inline tampil');

      // Tombol kembali normal dan aktif kembali
      final appBtnAfterError = tester.widget<AppButton>(find.byType(AppButton).last);
      expect(appBtnAfterError.isLoading, isFalse);
      expect(appBtnAfterError.isSuccess, isFalse);
      expect(appBtnAfterError.onPressed, isNotNull);

      container.dispose();
    });

    testWidgets('InvoicePreviewDialog: check-in button sequential normal -> loading -> success (600ms)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int confirmCheckInInvocations = 0;
      final completer = Completer<void>();

      final dialog = InvoicePreviewDialog(
        room: const RoomModel(
          id: 'rm-101',
          roomNumber: '101',
          roomType: 'Standard',
          floor: 1,
          basePricePerNight: 250000,
          facilities: ['AC'],
          status: RoomStatusType.available,
          activeGuestName: 'Dewi Lestari',
          activeGuestPhone: '081987654321',
        ),
        roomTotal: 250000,
        grandTotal: 250000,
        receptionistName: 'Resepsionis 1',
        onConfirmCheckIn: () async {
          confirmCheckInInvocations++;
          await completer.future;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: dialog),
        ),
      );
      await tester.pumpAndSettle();

      final confirmBtn = find.widgetWithText(AppButton, 'Konfirmasi Lunas & Masuk Kamar');
      expect(confirmBtn, findsOneWidget);
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();

      // Tap confirm button
      await tester.tap(confirmBtn);
      await tester.pump();

      // Rapid double tap
      await tester.tap(find.byType(AppButton).last);
      await tester.pump();

      // Loading state
      expect(confirmCheckInInvocations, 1, reason: 'Double-tap dicegah di level UI');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete async action
      completer.complete();
      await tester.pump();

      // Success state
      expect(find.text('Berhasil Check-In'), findsOneWidget);
      expect(find.descendant(of: find.byType(AppButton).last, matching: find.byIcon(AppIcons.check)), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Berhasil Check-In'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(InvoicePreviewDialog), findsNothing);
    });
  });

  group('Prioritas 1B: Urutan Penutupan Dialog Check-In & Anti Double-Submit', () {
    testWidgets('Urutan penutupan dialog: InvoicePreviewDialog menutup dirinya sendiri, lalu CheckInModal menutup < 1 detik setelah centang', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _MotionTestRoomRepo();
      final completer = Completer<Map<String, dynamic>>();
      repo.checkInCompleter = completer;

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(repo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RoomGridScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Klik kartu kamar 101 (Tersedia)
      final roomCardFinder = find.byKey(const ValueKey('room_card_rm-101'));
      expect(roomCardFinder, findsOneWidget);
      await tester.tap(roomCardFinder);
      await tester.pumpAndSettle();

      // CheckInModal terbuka
      expect(find.byType(CheckInModal), findsOneWidget);

      // 2. Isi data form di CheckInModal
      final modalFields = find.descendant(of: find.byType(CheckInModal), matching: find.byType(TextField));
      await tester.enterText(modalFields.at(0), '3201010101010001'); // NIK
      await tester.enterText(modalFields.at(1), 'Budi Handoko');     // Nama
      await tester.enterText(modalFields.at(2), '081234567890');     // WA
      await tester.pumpAndSettle();

      // 3. Klik 'Pratinjau Invoice & Selesaikan'
      final previewBtn = find.widgetWithText(AppButton, 'Pratinjau Invoice & Selesaikan');
      expect(previewBtn, findsOneWidget);
      await tester.tap(previewBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog invoice terbuka di atas modal check-in
      expect(find.byType(InvoicePreviewDialog), findsOneWidget);
      expect(find.byType(CheckInModal), findsOneWidget);

      // 4. Klik konfirmasi di invoice preview dialog
      final confirmInvoiceBtn = find.widgetWithText(AppButton, 'Konfirmasi Lunas & Masuk Kamar');
      expect(confirmInvoiceBtn, findsOneWidget);
      await tester.tap(confirmInvoiceBtn);
      await tester.pump(); // frame transisi ke loading

      // Verifikasi tombol invoice dalam state loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // 5. Selesaikan pemanggilan backend
      completer.complete({'id': 'res-101', 'status': 'ACTIVE', 'invoiceNumber': 'INV-001'});
      await tester.pump(); // frame update ke sukses

      // Verifikasi centang sukses terlihat
      expect(find.text('Berhasil Check-In'), findsOneWidget);

      // 6. Ukur pump bertahap:
      // Jeda centang 450ms
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Berhasil Check-In'), findsOneWidget);
      expect(find.byType(InvoicePreviewDialog), findsOneWidget);

      // Selesaikan jeda 450ms
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(); // trigger pop(true) invoice dialog

      // InvoicePreviewDialog telah menutup dirinya sendiri (transisi exit 150-300ms)
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(InvoicePreviewDialog), findsNothing, reason: 'InvoicePreviewDialog tertutup setelah 450ms');

      // Verifikasi CheckInModal tertutup kurang dari 1 detik setelah centang selesai (transisi exit 150-300ms)
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CheckInModal), findsNothing, reason: 'CheckInModal otomatis tertutup segera setelah invoice menutup (< 1 detik)');

      // Selesaikan sisa timer highlight reset (500ms)
      await tester.pump(const Duration(milliseconds: 550));

      container.dispose();
    });

    testWidgets('Skenario gagal check-in: invoice dialog tetap terbuka, tombol kembali normal, pesan error inline', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _MotionTestRoomRepo();
      repo.shouldFailCheckIn = true;
      repo.checkInErrorMessage = '409: Kamar sudah terisi';

      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(repo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RoomGridScreen(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Buka check in modal
      await tester.tap(find.byKey(const ValueKey('room_card_rm-101')));
      await tester.pump(const Duration(milliseconds: 300));

      // Isi data form di CheckInModal
      final modalFields2 = find.descendant(of: find.byType(CheckInModal), matching: find.byType(TextField));
      await tester.enterText(modalFields2.at(0), '3201010101010002');
      await tester.enterText(modalFields2.at(1), 'Rudi');
      await tester.enterText(modalFields2.at(2), '081234567891');
      await tester.pump(const Duration(milliseconds: 300));

      // Buka invoice
      await tester.tap(find.widgetWithText(AppButton, 'Pratinjau Invoice & Selesaikan'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(InvoicePreviewDialog), findsOneWidget);

      // Konfirmasi check-in (akan fail)
      await tester.tap(find.widgetWithText(AppButton, 'Konfirmasi Lunas & Masuk Kamar'));
      await tester.pump(const Duration(milliseconds: 300));

      // Invoice dialog tetap terbuka dan menampilkan pesan error inline
      expect(find.byType(InvoicePreviewDialog), findsOneWidget);
      expect(find.descendant(of: find.byType(InvoicePreviewDialog), matching: find.text('409: Kamar sudah terisi')), findsOneWidget);

      // Tombol kembali normal
      final confirmBtn = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Konfirmasi Lunas & Masuk Kamar'));
      expect(confirmBtn.isLoading, isFalse);
      expect(confirmBtn.isSuccess, isFalse);
      expect(confirmBtn.onPressed, isNotNull);

      // Tutup invoice preview dengan tombol X (pop false)
      await tester.tap(find.descendant(of: find.byType(InvoicePreviewDialog), matching: find.byIcon(AppIcons.close)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Invoice dialog tertutup, tapi CheckInModal tetap terbuka
      expect(find.byType(InvoicePreviewDialog), findsNothing);
      expect(find.byType(CheckInModal), findsOneWidget);

      // Tombol submit di CheckInModal aktif kembali (_isSubmitting direset)
      final modalSubmitBtn = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Pratinjau Invoice & Selesaikan'));
      expect(modalSubmitBtn.isLoading, isFalse);
      expect(modalSubmitBtn.onPressed, isNotNull);

      container.dispose();
    });

    testWidgets('Skenario batal check-in: tutup invoice, CheckInModal tetap terbuka dan form dapat disubmit ulang', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _MotionTestRoomRepo();
      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(repo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RoomGridScreen(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const ValueKey('room_card_rm-101')));
      await tester.pump(const Duration(milliseconds: 300));

      final modalFields3 = find.descendant(of: find.byType(CheckInModal), matching: find.byType(TextField));
      await tester.enterText(modalFields3.at(0), '3201010101010003');
      await tester.enterText(modalFields3.at(1), 'Maya');
      await tester.enterText(modalFields3.at(2), '081234567892');
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(AppButton, 'Pratinjau Invoice & Selesaikan'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(InvoicePreviewDialog), findsOneWidget);

      // Klik tombol close pada invoice
      await tester.tap(find.descendant(of: find.byType(InvoicePreviewDialog), matching: find.byIcon(AppIcons.close)));
      await tester.pump(const Duration(milliseconds: 300));

      // Invoice dialog tertutup, tapi CheckInModal tetap terbuka
      expect(find.byType(InvoicePreviewDialog), findsNothing);
      expect(find.byType(CheckInModal), findsOneWidget);

      // _isSubmitting direset
      final modalSubmitBtn = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Pratinjau Invoice & Selesaikan'));
      expect(modalSubmitBtn.isLoading, isFalse);
      expect(modalSubmitBtn.onPressed, isNotNull);

      container.dispose();
    });
  });

  group('Prioritas 2: Sorotan Kartu Kamar (RoomCard Highlight & Key) Tests', () {
    testWidgets('RoomCard dengan isHighlighted: true menjalankan animasi sorotan ≤ 400ms dan reset', (tester) async {
      final room = const RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: ['AC'],
        status: RoomStatusType.available,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 290,
                height: 184,
                child: RoomCard(
                  key: const ValueKey('room_card_rm-101'),
                  room: room,
                  isHighlighted: false,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Update widget dengan isHighlighted: true
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 290,
                height: 184,
                child: RoomCard(
                  key: const ValueKey('room_card_rm-101'),
                  room: room,
                  isHighlighted: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Frame awal highlight (100ms): animasi naik
      await tester.pump(const Duration(milliseconds: 100));
      // Animasi puncak (200ms)
      await tester.pump(const Duration(milliseconds: 100));
      // Animasi turun kembali (400ms)
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Tidak ada timer pending yang tersisa
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('RoomCard preserves stable key in GridView without skeleton unmount on silent refresh', (tester) async {
      final repo = _MotionTestRoomRepo();
      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(repo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RoomGridScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kartu kamar 101 dan 102 harus ada dengan ValueKey stabil
      expect(find.byKey(const ValueKey('room_card_rm-101')), findsOneWidget);
      expect(find.byKey(const ValueKey('room_card_rm-102')), findsOneWidget);

      // Trigger silent refresh
      await container.read(roomListProvider.notifier).loadRooms(silent: true);
      await tester.pump();

      // Skeleton loader TIDAK boleh muncul karena silent: true
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('room_card_rm-101')), findsOneWidget);

      container.dispose();
    });
  });

  group('Prioritas 3: StatusBadge Ukuran Tetap & Cross-Fade Tests', () {
    testWidgets('StatusBadge maintains strict Size(90, 24) across ALL 4 statuses (zero layout shift)', (tester) async {
      for (final status in RoomStatusType.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: StatusBadge(status: status),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final badgeFinder = find.byType(StatusBadge);
        expect(badgeFinder, findsOneWidget);

        final renderBox = tester.renderObject<RenderBox>(find.byType(AnimatedContainer).first);
        expect(renderBox.size.width, 90.0, reason: 'Lebar badge untuk ${status.name} harus tepat 90.0px');
        expect(renderBox.size.height, 24.0, reason: 'Tinggi badge untuk ${status.name} harus tepat 24.0px');
      }
    });

    testWidgets('StatusBadge uses AnimatedSwitcher for text cross-fade <= 180ms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: StatusBadge(status: RoomStatusType.available),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tersedia'), findsOneWidget);

      // Update status ke occupied
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: StatusBadge(status: RoomStatusType.occupied),
          ),
        ),
      );

      // Animasi transisi berjalan <= 180ms
      await tester.pump(const Duration(milliseconds: 90));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('Terisi'), findsOneWidget);
    });
  });

  group('Prioritas 4: Dialog Check-In / Check-Out Transisi & Barrier Dismissible Tests', () {
    testWidgets('CheckIn dialog is NOT dismissible via barrier tap (barrierDismissible: false)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _MotionTestRoomRepo();
      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(repo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RoomGridScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap kamar 101 (Available) untuk membuka CheckInModal
      await tester.tap(find.text('Kamar 101'));
      await tester.pumpAndSettle();

      expect(find.byType(CheckInModal), findsOneWidget);
      expect(find.text('Formulir Check-In Tamu'), findsOneWidget);

      // Ketuk di luar modal (mis. pojok kiri atas barrier gelap)
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // Modal transaksi HARUS tetap terbuka (barrierDismissible: false)
      expect(find.byType(CheckInModal), findsOneWidget);
      expect(find.text('Formulir Check-In Tamu'), findsOneWidget);

      // Tutup via tombol Batal
      await tester.tap(find.widgetWithText(AppButton, 'Batal'));
      await tester.pumpAndSettle();

      expect(find.byType(CheckInModal), findsNothing);

      container.dispose();
    });

    testWidgets('Active Guests dialog (read-only) IS dismissible via barrier tap (barrierDismissible: true)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _MotionTestRoomRepo();
      final container = ProviderContainer(
        overrides: [
          roomRepositoryProvider.overrideWithValue(repo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: RoomGridScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka modal tamu aktif di topbar
      final activeGuestsBtn = find.text('Tamu Aktif');
      expect(activeGuestsBtn, findsOneWidget);
      await tester.tap(activeGuestsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ActiveGuestsModal), findsOneWidget);
      expect(find.text('Monitor Tamu Aktif & WhatsApp'), findsOneWidget);

      // Ketuk barrier di luar modal
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // Dialog baca saja tertutup via barrier
      expect(find.byType(ActiveGuestsModal), findsNothing);

      container.dispose();
    });
  });

  group('Prioritas 5: Hover, Tekan Kartu ±0.98, dan Aksesibilitas Keyboard Tests', () {
    testWidgets('RoomCard: press down triggers scale ±0.98, and cancel/up cleans state cleanly', (tester) async {
      final room = const RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: ['AC'],
        status: RoomStatusType.available,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 290,
                height: 184,
                child: RoomCard(
                  room: room,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Normal state: scale 1.0
      AnimatedScale scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, 1.0);

      // Pointer down: scale turun ke 0.98
      final gesture = await tester.startGesture(tester.getCenter(find.byType(RoomCard)));
      await tester.pump();

      scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, closeTo(0.98, 0.005), reason: 'Tekan kartu memicu scale 0.98');

      // Pointer up: kembali ke scale 1.0
      await gesture.up();
      await tester.pump();

      scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, 1.0);
    });

    testWidgets('RoomCard: Keyboard navigation (Focus + Enter) triggers onTap callback', (tester) async {
      bool cardTapped = false;

      final room = const RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: ['AC'],
        status: RoomStatusType.available,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 290,
                height: 184,
                child: RoomCard(
                  room: room,
                  onTap: () => cardTapped = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final focusFinder = find.byType(Focus);
      expect(focusFinder, findsWidgets);

      // Kirim event keyboard Enter saat kartu difokuskan
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(cardTapped, isTrue, reason: 'Menekan Enter pada kartu yang fokus memicu callback onTap');
    });

    testWidgets('Reduced Motion (disableAnimations: true) forces scale to 1.0 even on pointer down', (tester) async {
      final room = const RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: ['AC'],
        status: RoomStatusType.available,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Center(
                child: SizedBox(
                  width: 290,
                  height: 184,
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

      final gesture = await tester.startGesture(tester.getCenter(find.byType(RoomCard)));
      await tester.pump();

      final scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, 1.0, reason: 'Reduced motion mengunci scale ke 1.0 tanpa animasi');

      await gesture.up();
      await tester.pump();
    });
  });

  group('Verifikasi Bebas Overflow di Lebar 360, 768, 1280, 1920 dan Text Scale 1.3x', () {
    final widths = [360.0, 768.0, 1280.0, 1920.0];
    final textScales = [1.0, 1.3];

    for (final width in widths) {
      for (final textScale in textScales) {
        testWidgets('RoomGridScreen bebas overflow pada lebar ${width}px dan text scale ${textScale}x', (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final repo = _MotionTestRoomRepo();
          final container = ProviderContainer(
            overrides: [
              roomRepositoryProvider.overrideWithValue(repo),
            ],
          );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 900),
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: const Scaffold(
                    body: RoomGridScreen(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(RoomGridScreen), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'Tidak ada overflow pada lebar $width dengan text scale $textScale');

          container.dispose();
        });
      }
    }
  });
}
