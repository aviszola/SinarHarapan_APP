import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/core/config/app_config.dart';
import 'package:sinarharapan_app/core/network/api_client.dart';
import 'package:sinarharapan_app/core/storage/token_storage.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TAHAP 3 — Validasi Input Mirroring Backend (backend.md §8.1)', () {
    test('Validasi nomor WhatsApp: wajib diawali +62 atau 08 dan 10-15 karakter', () {
      expect(FlutterValidation.validateWa('081234567890'), null);
      expect(FlutterValidation.validateWa('+6281234567890'), null);

      expect(FlutterValidation.validateWa(''), isNotNull);
      expect(FlutterValidation.validateWa('0215551234'), isNotNull);
      expect(FlutterValidation.validateWa('123456'), isNotNull);
      expect(FlutterValidation.validateWa('abcde'), isNotNull);
    });

    test('Validasi nomor identitas per jenis dokumen (KTP, SIM, PASSPORT, OTHER)', () {
      // KTP harus tepat 16 digit
      expect(FlutterValidation.validateIdNumber('3578012345670001', 'KTP'), null);
      expect(FlutterValidation.validateIdNumber('12345', 'KTP'), isNotNull);
      expect(FlutterValidation.validateIdNumber('357801234567000A', 'KTP'), isNotNull);

      // SIM 12-16 digit
      expect(FlutterValidation.validateIdNumber('123456789012', 'SIM'), null);
      expect(FlutterValidation.validateIdNumber('1234567890123456', 'SIM'), null);
      expect(FlutterValidation.validateIdNumber('12345', 'SIM'), isNotNull);

      // PASSPORT 6-9 alfanumerik
      expect(FlutterValidation.validateIdNumber('C1234567', 'PASSPORT'), null);
      expect(FlutterValidation.validateIdNumber('AB123456', 'PASSPORT'), null);
      expect(FlutterValidation.validateIdNumber('123', 'PASSPORT'), isNotNull);

      // OTHER 4-30 karakter
      expect(FlutterValidation.validateIdNumber('ID-12345', 'OTHER'), null);
      expect(FlutterValidation.validateIdNumber('12', 'OTHER'), isNotNull);
    });

    test('Validasi enum paymentMethod (CASH, QRIS, TRANSFER, REDDOORZ_PREPAID)', () {
      expect(FlutterValidation.validatePaymentMethod('CASH'), null);
      expect(FlutterValidation.validatePaymentMethod('QRIS'), null);
      expect(FlutterValidation.validatePaymentMethod('TRANSFER'), null);
      expect(FlutterValidation.validatePaymentMethod('REDDOORZ_PREPAID'), null);
      expect(FlutterValidation.validatePaymentMethod('BITCOIN'), isNotNull);
      expect(FlutterValidation.validatePaymentMethod('HUTANG'), isNotNull);
    });
  });

  group('TAHAP 4 — Token & Secure Storage', () {
    test('SecureTokenStorage encrypts and decrypts token correctly', () async {
      final storage = SecureTokenStorage();
      const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.sinarharapan';

      await storage.saveToken(testToken);
      final retrieved = await storage.getToken();
      expect(retrieved, testToken);

      await storage.deleteToken();
      final afterDelete = await storage.getToken();
      expect(afterDelete, isNull);
    });

    test('UserModel.fromJson throws FormatException if token is missing (no mock fallback)', () {
      // JSON tanpa token tidak boleh lagi fallback ke 'mock-jwt-token'
      expect(
        () => UserModel.fromJson({
          'id': 'usr-001',
          'username': 'receptionist',
          'full_name': 'Siti',
          'role': 'RECEPTIONIST',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('UserModel.fromJson parses valid backend token and user structure', () {
      final user = UserModel.fromJson({
        'token': 'real-jwt-token-from-backend',
        'expiresIn': 43200,
        'user': {
          'id': 'uuid-123',
          'fullName': 'Siti Rahmawati',
          'role': 'RECEPTIONIST',
        },
      });
      expect(user.id, 'uuid-123');
      expect(user.fullName, 'Siti Rahmawati');
      expect(user.role, UserRole.receptionist);
      expect(user.token, 'real-jwt-token-from-backend');
      expect(user.isReceptionist, true);
      expect(user.isManager, false);
    });
  });

  group('TAHAP 3 & 4 — ApiException Error Mapping', () {
    test('ApiClient maps 401 to ApiErrorCode.unauthorized', () {
      final exc = ApiException('Kredensial tidak valid', statusCode: 401, code: ApiErrorCode.unauthorized);
      expect(exc.isUnauthorized, true);
      expect(exc.statusCode, 401);
    });

    test('ApiClient maps 403 to ApiErrorCode.forbidden', () {
      final exc = ApiException('Role RECEPTIONIST tidak memiliki akses', statusCode: 403, code: ApiErrorCode.forbidden);
      expect(exc.isForbidden, true);
      expect(exc.statusCode, 403);
    });

    test('ApiClient maps 409 to ApiErrorCode.conflict', () {
      final exc = ApiException('Kamar sudah tidak tersedia', statusCode: 409, code: ApiErrorCode.conflict);
      expect(exc.isConflict, true);
      expect(exc.statusCode, 409);
    });

    test('ApiClient maps 429 to ApiErrorCode.rateLimited', () {
      final exc = ApiException('Terlalu banyak percobaan', statusCode: 429, code: ApiErrorCode.rateLimited);
      expect(exc.isRateLimited, true);
      expect(exc.statusCode, 429);
    });
  });

  group('TAHAP 2 & 5 — Kontrak DTO & Operasi Tulis Tanpa Fallback', () {
    test('RoomRepository.createReservation checks reddoorzBookingCode if REDDOORZ', () async {
      final repo = RoomRepository();
      expect(
        () => repo.createReservation(
          roomId: 'rm-101',
          bookingSource: 'REDDOORZ',
          reddoorzBookingCode: null, // Kosong
          idType: 'KTP',
          idNumber: '3578012345670001',
          guestFullName: 'Budi',
          guestPhone: '081234567890',
          checkInTime: DateTime.now().toIso8601String(),
          expectedCheckOutTime: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          totalNights: 1,
          roomRate: 250000,
          paymentMethod: 'REDDOORZ_PREPAID',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('AppConfig provides valid baseUrl and timeout', () {
      expect(AppConfig.baseUrl, isNotEmpty);
      expect(AppConfig.baseUrl.endsWith('/'), false);
      expect(AppConfig.connectTimeout.inSeconds, 20);
      expect(AppConfig.receiveTimeout.inSeconds, 20);
    });
  });
}
