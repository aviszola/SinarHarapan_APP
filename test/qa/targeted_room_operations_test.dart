import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/app/theme.dart';
import 'package:sinarharapan_app/core/network/api_client.dart';
import 'package:sinarharapan_app/features/auth/data/auth_repository.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/auth/presentation/auth_controller.dart';
import 'package:sinarharapan_app/features/checkout/presentation/check_out_dialog.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_controller.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_grid_screen.dart';

class _FakeAuthRepo extends AuthRepository {
  @override
  Future<UserModel> login({required String username, required String password}) async {
    return const UserModel(
      id: 'usr-1',
      username: 'receptionist',
      fullName: 'Siti Rahmawati',
      role: UserRole.receptionist,
      token: 'jwt-mock-receptionist',
    );
  }

  @override
  Future<UserModel> quickLogin(UserRole role) async {
    return login(username: 'receptionist', password: 'password123');
  }
}

class _TargetedFakeRoomRepo extends RoomRepository {
  List<RoomModel> rooms;
  bool shouldFailCheckout = false;
  String? checkoutFailureMessage;
  bool checkoutCalled = false;
  bool cleanCalled = false;

  _TargetedFakeRoomRepo({required this.rooms});

  @override
  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    return List.from(rooms);
  }

  @override
  Future<RoomModel?> getRoomById(String id) async {
    try {
      return rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<RoomStatusSnapshot>> getRoomStatusOnly() async {
    return rooms
        .map((r) => RoomStatusSnapshot(id: r.id, roomNumber: r.roomNumber, status: r.status))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> processCheckout({
    required String reservationId,
    required String actualCheckOutTime,
    required List<Map<String, dynamic>> additionalCharges,
  }) async {
    checkoutCalled = true;
    if (shouldFailCheckout) {
      throw ApiException(checkoutFailureMessage ?? 'Kamar memiliki tagihan tertunda yang belum dibayar');
    }

    final idx = rooms.indexWhere((r) => r.activeReservationId == reservationId);
    if (idx != -1) {
      rooms[idx] = rooms[idx].copyWith(
        status: RoomStatusType.dirty,
        activeGuestName: null,
        activeGuestPhone: null,
      );
    }
    return {'success': true, 'message': 'Checkout berhasil diproses'};
  }

  @override
  Future<void> markRoomClean(String roomId) async {
    cleanCalled = true;
    final idx = rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      rooms[idx] = rooms[idx].copyWith(status: RoomStatusType.available);
    }
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  Widget buildTestApp({
    required _TargetedFakeRoomRepo roomRepo,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
        roomRepositoryProvider.overrideWithValue(roomRepo),
        authStateProvider.overrideWith(
          (ref) => AuthNotifier(_FakeAuthRepo())
            ..state = const AuthState(
              user: UserModel(
                id: 'usr-1',
                username: 'receptionist',
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
        home: const RoomGridScreen(),
      ),
    );
  }

  group('Target A: Room Checkout Behavioral Tests', () {
    testWidgets('Occupied room tap opens CheckOutDialog and successfully checks out', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _TargetedFakeRoomRepo(
        rooms: [
          RoomModel(
            id: 'rm-102',
            roomNumber: '102',
            roomType: 'Standard',
            floor: 1,
            basePricePerNight: 250000,
            facilities: const ['AC', 'WiFi'],
            status: RoomStatusType.occupied,
            activeReservationId: 'res-102',
            activeGuestName: 'Budi Santoso',
            activeGuestPhone: '081234567890',
            checkInTime: DateTime.now().subtract(const Duration(hours: 18)),
            expectedCheckOutTime: DateTime.now().add(const Duration(hours: 4)),
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(roomRepo: repo));
      await tester.pumpAndSettle();

      // Pastikan kartu kamar 102 dengan nama tamu Budi Santoso muncul
      expect(find.text('Kamar 102'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);

      // Ketuk kamar 102
      await tester.tap(find.text('Kamar 102'));
      await tester.pumpAndSettle();

      // Verifikasi CheckOutDialog terbuka
      expect(find.byType(CheckOutDialog), findsOneWidget);
      expect(find.text('Proses Check-Out Tamu'), findsOneWidget);

      // Cari tombol 'Selesaikan Check-Out (Tanpa Biaya)'
      final confirmBtn = find.text('Selesaikan Check-Out (Tanpa Biaya)');
      expect(confirmBtn, findsOneWidget);

      // Ketuk tombol konfirmasi checkout
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verifikasi repo.processCheckout terpanggil
      expect(repo.checkoutCalled, isTrue);

      // Dialog harus tertutup
      expect(find.byType(CheckOutDialog), findsNothing);

      // Status kamar pada repo dan UI beralih ke Dirty (Kotor)
      expect(repo.rooms.first.status, RoomStatusType.dirty);
      expect(find.text('Kamar 102'), findsOneWidget);
      expect(find.text('Kotor'), findsWidgets);
    });

    testWidgets('Occupied room checkout failure displays error feedback and preserves occupied state', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _TargetedFakeRoomRepo(
        rooms: [
          RoomModel(
            id: 'rm-102',
            roomNumber: '102',
            roomType: 'Standard',
            floor: 1,
            basePricePerNight: 250000,
            facilities: const ['AC', 'WiFi'],
            status: RoomStatusType.occupied,
            activeReservationId: 'res-102',
            activeGuestName: 'Budi Santoso',
            checkInTime: DateTime.now().subtract(const Duration(hours: 18)),
            expectedCheckOutTime: DateTime.now().add(const Duration(hours: 4)),
          ),
        ],
      );
      repo.shouldFailCheckout = true;
      repo.checkoutFailureMessage = 'Kamar memiliki tagihan tertunda yang belum dibayar';

      await tester.pumpWidget(buildTestApp(roomRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kamar 102'));
      await tester.pumpAndSettle();

      expect(find.byType(CheckOutDialog), findsOneWidget);

      // Ketuk konfirmasi checkout
      await tester.tap(find.text('Selesaikan Check-Out (Tanpa Biaya)'));
      await tester.pumpAndSettle();

      // Verifikasi proses checkout dipanggil tetapi gagal
      expect(repo.checkoutCalled, isTrue);

      // Pesan error harus ditampilkan
      expect(find.text('Gagal Check-Out'), findsOneWidget);
      expect(find.text('Kamar memiliki tagihan tertunda yang belum dibayar'), findsOneWidget);

      // State kamar TIDAK boleh beralih palsu ke Dirty; tetap Occupied
      expect(repo.rooms.first.status, RoomStatusType.occupied);
    });
  });

  group('Target B: Dirty Cleaning & Maintenance Dialog Tests', () {
    testWidgets('Dirty room tap displays cleaning confirmation, and confirm marks room available', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _TargetedFakeRoomRepo(
        rooms: [
          const RoomModel(
            id: 'rm-103',
            roomNumber: '103',
            roomType: 'Standard',
            floor: 1,
            basePricePerNight: 250000,
            facilities: ['AC', 'WiFi'],
            status: RoomStatusType.dirty,
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(roomRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Kamar 103'), findsOneWidget);
      expect(find.text('Kotor'), findsWidgets);

      // Ketuk kamar kotor
      await tester.tap(find.text('Kamar 103'));
      await tester.pumpAndSettle();

      // Dialog konfirmasi pembersihan harus muncul
      expect(find.text('Pembersihan Kamar 103'), findsOneWidget);
      expect(find.text('Tandai Siap Huni'), findsOneWidget);
      expect(find.text('Nanti Dulu'), findsOneWidget);

      // Ketuk 'Tandai Siap Huni'
      await tester.tap(find.text('Tandai Siap Huni'));
      await tester.pumpAndSettle();

      // Verifikasi repo.markRoomClean terpanggil
      expect(repo.cleanCalled, isTrue);

      // Dialog tertutup, status kamar berubah ke Tersedia (available)
      expect(find.text('Pembersihan Kamar 103'), findsNothing);
      expect(repo.rooms.first.status, RoomStatusType.available);
      expect(find.text('Tersedia'), findsWidgets);
    });

    testWidgets('Dirty room tap cancelation leaves room in dirty state', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _TargetedFakeRoomRepo(
        rooms: [
          const RoomModel(
            id: 'rm-103',
            roomNumber: '103',
            roomType: 'Standard',
            floor: 1,
            basePricePerNight: 250000,
            facilities: ['AC', 'WiFi'],
            status: RoomStatusType.dirty,
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(roomRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kamar 103'));
      await tester.pumpAndSettle();

      expect(find.text('Pembersihan Kamar 103'), findsOneWidget);

      // Ketuk tombol batal 'Nanti Dulu'
      await tester.tap(find.text('Nanti Dulu'));
      await tester.pumpAndSettle();

      // Dialog tertutup, markRoomClean TIDAK terpanggil, status tetap Dirty
      expect(find.text('Pembersihan Kamar 103'), findsNothing);
      expect(repo.cleanCalled, isFalse);
      expect(repo.rooms.first.status, RoomStatusType.dirty);
    });

    testWidgets('Maintenance room tap displays informational dialog and closes cleanly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _TargetedFakeRoomRepo(
        rooms: [
          const RoomModel(
            id: 'rm-104',
            roomNumber: '104',
            roomType: 'Suite',
            floor: 2,
            basePricePerNight: 500000,
            facilities: ['AC', 'WiFi', 'TV'],
            status: RoomStatusType.maintenance,
          ),
        ],
      );

      await tester.pumpWidget(buildTestApp(roomRepo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Kamar 104'), findsOneWidget);

      // Ketuk kamar perawatan
      await tester.tap(find.text('Kamar 104'));
      await tester.pumpAndSettle();

      // Dialog perawatan harus muncul
      expect(find.text('Kamar 104 Dalam Perawatan'), findsOneWidget);
      expect(
        find.textContaining('Kamar ini sedang dalam proses pemeliharaan fasilitas'),
        findsOneWidget,
      );

      // Ketuk 'Tutup'
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      expect(find.text('Kamar 104 Dalam Perawatan'), findsNothing);
      expect(repo.rooms.first.status, RoomStatusType.maintenance);
    });
  });
}
