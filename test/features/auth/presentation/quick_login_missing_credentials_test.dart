import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/app/theme.dart';
import 'package:sinarharapan_app/features/auth/data/auth_repository.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/auth/presentation/auth_controller.dart';
import 'package:sinarharapan_app/features/auth/presentation/login_screen.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_controller.dart';

class _MissingCredsAuthRepository extends AuthRepository {
  @override
  Future<UserModel> quickLogin(UserRole role) async {
    // Mensimulasikan ketiadaan kredensial dev
    throw UnsupportedError('Kredensial dev belum dikonfigurasi');
  }
}

class _EmptyRoomRepo extends RoomRepository {}

void main() {
  group('Quick Login Missing Credentials Handling', () {
    test('1. AuthController menangani error kredensial belum dikonfigurasi tanpa crash', () async {
      final repo = _MissingCredsAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      final result = await notifier.quickLogin(UserRole.receptionist);

      expect(result, isFalse, reason: 'Quick login harus mengembalikan false');
      final state = container.read(authStateProvider);
      expect(state.isLoading, isFalse);
      expect(
        state.errorMessage,
        equals('Kredensial dev belum dikonfigurasi'),
        reason: 'Pesan error harus jelas dan ramah pengembang tanpa prefix exception',
      );
    });

    testWidgets('2. UI LoginScreen menampilkan banner error jelas saat quick login tanpa kredensial', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _MissingCredsAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            roomRepositoryProvider.overrideWithValue(_EmptyRoomRepo()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cari tombol Resepsionis di panel Mode Pengembangan desktop
      final receptionistQuickBtn = find.text('Resepsionis');
      expect(receptionistQuickBtn, findsOneWidget);

      await tester.tap(receptionistQuickBtn);
      await tester.pumpAndSettle();

      // Verifikasi banner error muncul dengan pesan yang ditentukan
      expect(find.text('Kredensial dev belum dikonfigurasi'), findsOneWidget);
    });
  });
}
