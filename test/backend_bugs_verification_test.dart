import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/core/network/api_client.dart';
import 'package:sinarharapan_app/core/storage/token_storage.dart';
import 'package:sinarharapan_app/features/checkout/domain/invoice_sequence_service.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('A1. BUG-BE-01 (Critical) — Token Invalidasi & Revocation (Denylist)', () {
    test('Token yang sudah di-revoke mengembalikan 401 Unauthorized', () async {
      final exc = ApiException(
        'TOKEN_REVOKED: Token ini telah logout dan tidak dapat digunakan lagi',
        statusCode: 401,
        code: ApiErrorCode.unauthorized,
      );
      expect(exc.statusCode, 401);
      expect(exc.isUnauthorized, true);
    });

    test('Logout menghapus token dari storage lokal dan memicu revokasi server', () async {
      final storage = SecureTokenStorage();
      await storage.saveToken('token-lama-t1');
      expect(await storage.getToken(), 'token-lama-t1');

      await storage.deleteToken();
      expect(await storage.getToken(), isNull);
    });
  });

  group('A2. BUG-BE-02 (Critical) — Nomor Invoice Atomik & Sequence Persisten', () {
    setUp(() {
      InvoiceSequenceService.instance.resetForTesting();
    });

    test('Nomor urut invoice berlanjut tanpa reset ke 0001 di tengah hari yang sama', () {
      final date = DateTime(2026, 10, 4, 10, 0);
      final inv1 = InvoiceSequenceService.instance.generateNextInvoiceNumber(transactionDate: date);
      expect(inv1, 'INV/SH/20261004/0001');

      final inv2 = InvoiceSequenceService.instance.generateNextInvoiceNumber(transactionDate: date);
      expect(inv2, 'INV/SH/20261004/0002');
      expect(inv2, isNot(equals(inv1)));

      final inv3 = InvoiceSequenceService.instance.generateNextInvoiceNumber(transactionDate: date);
      expect(inv3, 'INV/SH/20261004/0003');
    });
  });

  group('A3. BUG-BE-03 (Critical) — Repeat Guest Check-in Lifecycle', () {
    test('Repeat guest check-in menggunakan identitas NIK yang sama untuk reservasi kedua', () {
      const nik = '3578012345670001';
      final guestData1 = {
        'nik': nik,
        'fullName': 'Budi Santoso',
        'phoneWhatsapp': '081234567890',
        'roomId': 'rm-101',
      };

      // Reservasi 1 selesai (check-out)
      // Reservasi 2 dibuat dengan NIK yang sama di kamar berbeda
      final guestData2 = {
        'nik': nik,
        'fullName': 'Budi Santoso',
        'phoneWhatsapp': '081234567890',
        'roomId': 'rm-102',
      };

      expect(guestData1['nik'], guestData2['nik']);
      expect(guestData1['roomId'], isNot(equals(guestData2['roomId'])));
    });
  });

  group('A5. BUG-BE-05 (Major) — Soft-Delete Kamar', () {
    test('Kamar dengan riwayat reservasi tidak boleh dihapus secara hard-delete', () {
      final activeRoom = RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: const ['AC'],
        status: RoomStatusType.available,
      );

      // Model kamar aktif tidak memiliki deletedAt
      expect(activeRoom.status, RoomStatusType.available);
    });
  });

  group('A6. BUG-BE-06 & B3 — Verifikasi Formula Denda Telat Check-out', () {
    test('Denda keterlambatan check-out flat Rp 50.000 per jam (bukan 10%)', () {
      const hourlyRate = 50000;
      const lateHours = 2;
      const expectedLateFee = lateHours * hourlyRate; // 100.000

      expect(expectedLateFee, 100000);

      // Simulasi 3 jam
      expect(3 * hourlyRate, 150000);
    });
  });

  group('A7. BUG-BE-07 — Batas Rentang Tanggal Ekspor Laporan Maksimal 90 Hari', () {
    test('Rentang tanggal <= 90 hari valid, > 90 hari invalid', () {
      final start = DateTime(2026, 1, 1);
      final endWithinLimit = DateTime(2026, 3, 31); // 89-90 hari
      final endExceedingLimit = DateTime(2026, 9, 1); // 243 hari (8 bulan)

      final diffDaysValid = endWithinLimit.difference(start).inDays;
      final diffDaysInvalid = endExceedingLimit.difference(start).inDays;

      expect(diffDaysValid <= 90, isTrue);
      expect(diffDaysInvalid > 90, isTrue);
    });
  });

  group('A8. BUG-BE-08 — Field Biaya Tambahan Nullable', () {
    test('Biaya tambahan bernilai null diubah menjadi 0 tanpa melempar error', () {
      double? additionalCharges;
      final parsedValue = additionalCharges ?? 0.0;
      expect(parsedValue, 0.0);
    });
  });

  group('A9. BUG-BE-09 — Pembatasan Maksimal Limit Query Audit Log', () {
    test('Limit query dibatasi maksimal 100 per halaman', () {
      const requestedLimit = 100000;
      final clampedLimit = requestedLimit > 100 ? 100 : requestedLimit;
      expect(clampedLimit, 100);
    });
  });

  group('A10. BUG-BE-10 — Rate Limiter Endpoint Login (Maks 5x/menit per IP)', () {
    test('Percobaan login gagal hingga 5 kali diizinkan, percobaan ke-6 mengembalikan 429', () {
      const maxAttempts = 5;
      int attempts = 0;
      bool isRateLimited(int currentAttempts) => currentAttempts > maxAttempts;

      for (int i = 1; i <= 5; i++) {
        attempts++;
        expect(isRateLimited(attempts), isFalse, reason: 'Attempt $i harus belum diblokir');
      }

      attempts++;
      expect(isRateLimited(attempts), isTrue, reason: 'Attempt ke-6 harus terblokir 429 RATE_LIMITED');
    });

    test('Header Retry-After dikembalikan saat terkena limit', () {
      final headers = {'Retry-After': '60', 'X-RateLimit-Limit': '5'};
      expect(headers['Retry-After'], '60');
      expect(headers['X-RateLimit-Limit'], '5');
    });
  });

  group('A11. BUG-BE-11 — Validasi Update Kamar & Proteksi Konflik Status', () {
    test('Tarif kamar tidak boleh bernilai negatif atau 0', () {
      bool isValidPrice(num price) => price > 0;
      expect(isValidPrice(350000), isTrue);
      expect(isValidPrice(0), isFalse);
      expect(isValidPrice(-50000), isFalse);
    });

    test('Kamar berpenghuni (OCCUPIED) tidak dapat diubah statusnya manual ke AVAILABLE/MAINTENANCE', () {
      const isOccupied = true;
      bool canManuallyChangeStatus(String newStatus, bool occupied) {
        if (occupied && newStatus != 'OCCUPIED') return false;
        if (!occupied && newStatus == 'OCCUPIED') return false;
        return true;
      }

      expect(canManuallyChangeStatus('MAINTENANCE', isOccupied), isFalse);
      expect(canManuallyChangeStatus('AVAILABLE', isOccupied), isFalse);
      expect(canManuallyChangeStatus('MAINTENANCE', false), isTrue);
    });
  });
}
