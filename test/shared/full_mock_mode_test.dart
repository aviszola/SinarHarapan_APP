import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sinarharapan_app/core/config/app_config.dart';
import 'package:sinarharapan_app/core/network/api_client.dart';
import 'package:sinarharapan_app/features/auth/data/auth_repository.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/reporting/data/reporting_repository.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';

/// HTTP Client tiruan yang melempar error keras jika terjadi permintaan jaringan apa pun.
class ThrowingHttpClient extends http.BaseClient {
  int callCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    callCount++;
    throw StateError(
      'PELANGGARAN JARINGAN: Permintaan jaringan ke ${request.url} terdeteksi dalam mode mock!',
    );
  }
}

void main() {
  group('Full Mock Mode & Zero-Network Verification Tests', () {
    late ThrowingHttpClient throwingClient;
    late AuthRepository authRepo;
    late RoomRepository roomRepo;
    late ReportingRepository reportingRepo;

    setUp(() {
      AppConfig.setMockForTesting(true);
      throwingClient = ThrowingHttpClient();
      ApiClient().setClientForTesting(throwingClient);
      RoomRepository.resetMockRooms();
      authRepo = AuthRepository();
      roomRepo = RoomRepository();
      reportingRepo = ReportingRepository();
    });

    tearDown(() {
      AppConfig.setMockForTesting(null);
      ApiClient().resetClientForTesting();
    });

    test('Gerbang keamanan: USE_MOCK dihormati hanya jika !kReleaseMode', () {
      // Pada lingkungan test/debug (non-release), useMock mengikuti konfigurasi
      expect(AppConfig.useMock, isTrue, reason: 'Dalam test, USE_MOCK=true harus aktif');
    });

    test('Mock login: ketikan manual menolak dengan pesan terarah tanpa request jaringan', () async {
      expect(
        () => authRepo.login(username: 'resepsionis', password: 'password123'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Mode mock: gunakan tombol Mode Pengembangan'),
          ),
        ),
      );

      expect(throwingClient.callCount, 0, reason: 'Tidak boleh ada request HTTP ke backend');
    });

    test('Mock login: quickLogin (Resepsionis & Manajer) membuat sesi lokal palsu tanpa password dan 0 network call', () async {
      // 1. Login Resepsionis
      final receptionistUser = await authRepo.quickLogin(UserRole.receptionist);
      expect(receptionistUser, isNotNull);
      expect(receptionistUser.role, UserRole.receptionist);
      expect(receptionistUser.fullName, contains('Mock'));

      // 2. Login Manajer
      final managerUser = await authRepo.quickLogin(UserRole.manager);
      expect(managerUser, isNotNull);
      expect(managerUser.role, UserRole.manager);
      expect(managerUser.fullName, contains('Mock'));

      // 3. Logout
      await authRepo.logout();

      expect(throwingClient.callCount, 0, reason: 'Seluruh alur auth mock tidak menyentuh jaringan');
    });

    test('Cakupan Kamar: 16 kamar riil muncul dan urutan 5A tepat di antara 05 dan 06', () async {
      final rooms = await roomRepo.getRooms();
      expect(rooms.length, 16, reason: 'Total kamar di mock harus tepat 16 kamar kRealHotelRooms');

      // Verifikasi seluruh kamar awal berstatus Tersedia (available)
      for (final room in rooms) {
        expect(room.status, RoomStatusType.available);
        expect(room.activeGuestName, isNull);
      }

      // Verifikasi urutan alami: 5A di antara 05 dan 06
      final roomNumbers = rooms.map((r) => r.roomNumber).toList();
      final idx05 = roomNumbers.indexOf('05');
      final idx5A = roomNumbers.indexOf('5A');
      final idx06 = roomNumbers.indexOf('06');

      expect(idx05, isNot(-1));
      expect(idx5A, idx05 + 1, reason: '5A harus berada tepat setelah 05');
      expect(idx06, idx5A + 1, reason: '06 harus berada tepat setelah 5A');

      expect(throwingClient.callCount, 0);
    });

    test('Alur Check-in: validasi form & invoice tetap, mengubah kamar menjadi Terisi di memori dan menyimpan tamu (0 network)', () async {
      final rooms = await roomRepo.getRooms();
      final room01 = rooms.firstWhere((r) => r.roomNumber == '01');

      final reservation = await roomRepo.createReservation(
        roomId: room01.id,
        bookingSource: 'WALK_IN',
        idType: 'KTP',
        idNumber: '3201234567890001',
        guestFullName: 'Bambang Sudiro',
        guestPhone: '081234567890',
        checkInTime: DateTime.now().toIso8601String(),
        expectedCheckOutTime: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        totalNights: 1,
        roomRate: 170000,
        paymentMethod: 'CASH',
      );

      expect(reservation, isNotNull);
      expect(reservation['status'], 'ACTIVE');
      expect(reservation['invoiceNumber'], contains('01'));

      // Ambil kamar 01 dan pastikan statusnya berubah menjadi OCCUPIED
      final updatedRoom = await roomRepo.getRoomById(room01.id);
      expect(updatedRoom, isNotNull);
      expect(updatedRoom!.status, RoomStatusType.occupied);
      expect(updatedRoom.activeGuestName, 'Bambang Sudiro');

      expect(throwingClient.callCount, 0);
    });

    test('Anti double-tap: transaksi ganda pada kamar terisi ditolak (hanya 1 transaksi berhasil)', () async {
      final rooms = await roomRepo.getRooms();
      final room01 = rooms.firstWhere((r) => r.roomNumber == '01');

      // Check-in pertama
      await roomRepo.createReservation(
        roomId: room01.id,
        bookingSource: 'WALK_IN',
        idType: 'KTP',
        idNumber: '3201234567890001',
        guestFullName: 'Tamu Pertama',
        guestPhone: '081234567890',
        checkInTime: DateTime.now().toIso8601String(),
        expectedCheckOutTime: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        totalNights: 1,
        roomRate: 170000,
        paymentMethod: 'CASH',
      );

      // Tap kedua secara bersamaan / duplikat pada kamar yang sama
      expect(
        () => roomRepo.createReservation(
          roomId: room01.id,
          bookingSource: 'WALK_IN',
          idType: 'KTP',
          idNumber: '3201234567890002',
          guestFullName: 'Tamu Kedua',
          guestPhone: '081299998888',
          checkInTime: DateTime.now().toIso8601String(),
          expectedCheckOutTime: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          totalNights: 1,
          roomRate: 170000,
          paymentMethod: 'CASH',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('sudah ditempati'),
          ),
        ),
      );

      expect(throwingClient.callCount, 0);
    });

    test('Alur Check-out: kamar beralih ke status Kotor (DIRTY) sesuai aturan domain backend (0 network)', () async {
      final rooms = await roomRepo.getRooms();
      final room01 = rooms.firstWhere((r) => r.roomNumber == '01');

      // Check-in dulu
      final res = await roomRepo.createReservation(
        roomId: room01.id,
        bookingSource: 'WALK_IN',
        idType: 'KTP',
        idNumber: '3201234567890001',
        guestFullName: 'Bambang Sudiro',
        guestPhone: '081234567890',
        checkInTime: DateTime.now().toIso8601String(),
        expectedCheckOutTime: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        totalNights: 1,
        roomRate: 170000,
        paymentMethod: 'CASH',
      );

      // Check-out dengan biaya tambahan
      final checkoutResult = await roomRepo.processCheckout(
        reservationId: res['id'] as String,
        actualCheckOutTime: DateTime.now().toIso8601String(),
        additionalCharges: [
          {'label': 'Denda Kunci', 'amount': 50000},
        ],
      );
      expect(checkoutResult, isNotNull);
      expect(checkoutResult['success'], true);

      // Verifikasi status kamar berubah menjadi DIRTY dan tamu di-clear
      final dirtyRoom = await roomRepo.getRoomById(room01.id);
      expect(dirtyRoom, isNotNull);
      expect(dirtyRoom!.status, RoomStatusType.dirty);
      expect(dirtyRoom.activeGuestName, isNull);

      expect(throwingClient.callCount, 0);
    });

    test('Pembersihan kamar: markRoomClean mengubah status kamar dari DIRTY ke AVAILABLE di memori (0 network)', () async {
      final rooms = await roomRepo.getRooms();
      final room01 = rooms.firstWhere((r) => r.roomNumber == '01');

      // Set ke dirty terlebih dahulu lewat updateRoom
      await roomRepo.updateRoom(id: room01.id, status: 'DIRTY');
      final dirtyRoom = await roomRepo.getRoomById(room01.id);
      expect(dirtyRoom!.status, RoomStatusType.dirty);

      // Jalankan pembersihan
      await roomRepo.markRoomClean(room01.id);

      final cleanRoom = await roomRepo.getRoomById(room01.id);
      expect(cleanRoom, isNotNull);
      expect(cleanRoom!.status, RoomStatusType.available);

      expect(throwingClient.callCount, 0);
    });

    test('Perawatan kamar: toggle maintenance mengubah status kamar di memori (0 network)', () async {
      final rooms = await roomRepo.getRooms();
      final room02 = rooms.firstWhere((r) => r.roomNumber == '02');

      // Kamar 02 (available) diubah jadi maintenance
      final updatedMaint = await roomRepo.updateRoom(
        id: room02.id,
        status: RoomStatusType.maintenance.name,
      );
      expect(updatedMaint.status, RoomStatusType.maintenance);

      // Kembalikan ke available
      final restored02 = await roomRepo.updateRoom(
        id: room02.id,
        status: RoomStatusType.available.name,
      );
      expect(restored02.status, RoomStatusType.available);

      expect(throwingClient.callCount, 0);
    });

    test('Layar Manajer & Inventaris: data mock bertanda jelas dan CRUD kamar di memori (0 network)', () async {
      // 1. Summary
      final summary = await reportingRepo.getSummary();
      expect(summary, isNotNull);
      expect(summary?['note'], contains('Data contoh (mock)'));

      // 2. Audit logs
      final auditLogs = await reportingRepo.getAuditLogs();
      expect(auditLogs, isNotEmpty);
      expect(auditLogs.first.details, contains('Data contoh (mock)'));

      // 3. Transactions
      final txs = await reportingRepo.getTransactions();
      expect(txs, isNotEmpty);
      expect(txs.first['description'], contains('Data contoh (mock)'));

      // 4. Inventaris: Tambah kamar baru di memori
      final newRoom = await roomRepo.addRoom(
        roomNumber: '99',
        roomType: 'AC',
        floor: 2,
        basePricePerNight: 180000,
        facilities: ['AC'],
      );
      expect(newRoom.roomNumber, '99');

      final allRoomsWithNew = await roomRepo.getRooms();
      expect(allRoomsWithNew.any((r) => r.roomNumber == '99'), isTrue);

      // 5. Inventaris: Hapus kamar dari memori
      await roomRepo.deleteRoom(newRoom.id);
      final allRoomsAfterDel = await roomRepo.getRooms();
      expect(allRoomsAfterDel.any((r) => r.roomNumber == '99'), isFalse);

      expect(throwingClient.callCount, 0);
    });
  });
}
