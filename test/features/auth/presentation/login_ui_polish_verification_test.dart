import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/app/theme.dart';
import 'package:sinarharapan_app/features/auth/data/auth_repository.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/auth/presentation/auth_controller.dart';
import 'package:sinarharapan_app/features/auth/presentation/login_screen.dart';
import 'package:sinarharapan_app/features/shared_widgets/app_button.dart';
import 'package:sinarharapan_app/theme/app_icons.dart';

class _FakeAuthRepo extends AuthRepository {
  bool loginCalled = false;
  String? lastUsername;
  String? lastPassword;

  @override
  Future<UserModel> login({required String username, required String password}) async {
    loginCalled = true;
    lastUsername = username;
    lastPassword = password;
    if (username == 'resepsionis01' && password == 'password123') {
      return const UserModel(
        id: 'usr-1',
        username: 'resepsionis01',
        fullName: 'Siti Rahmawati',
        role: UserRole.receptionist,
        token: 'token-mock',
      );
    }
    throw Exception('Nama pengguna atau kata sandi salah. Coba lagi.');
  }

  @override
  Future<UserModel> quickLogin(UserRole role) async {
    return login(username: 'resepsionis01', password: 'password123');
  }
}

double _getLuminance(Color color) {
  final r = color.r;
  final g = color.g;
  final b = color.b;
  final rLinear = r <= 0.04045 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
  final gLinear = g <= 0.04045 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
  final bLinear = b <= 0.04045 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);
  return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
}

double _getContrastRatio(Color foreground, Color background) {
  final l1 = _getLuminance(foreground);
  final l2 = _getLuminance(background);
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Login Screen UI Polish Verification Suite', () {
    testWidgets('1. Render LoginScreen pada lebar Mobile 390x844 tanpa overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Sistem'), findsWidgets);
      expect(find.text('Hotel Sinar Harapan'), findsOneWidget);
      expect(find.text('Frontdesk PMS · Terminal Resepsionis'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Tidak boleh ada overflow pada 390px');
    });

    testWidgets('2. Render LoginScreen pada lebar Desktop 1920x1080 dengan panel operasional tanpa overflow', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Sistem'), findsWidgets);
      expect(find.text('WAKTU OPERASIONAL FRONTDESK'), findsOneWidget);
      expect(find.text('Terminal Resepsionis Utama · Lobby 1'), findsOneWidget);
      expect(find.text('Sistem Lokal Aktif · Terhubung ke Server'), findsOneWidget);
      expect(find.text('TERMINAL FRONTDESK'), findsOneWidget);
      expect(find.text('SH'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'Tidak boleh ada overflow pada 1920px');
    });

    testWidgets('3. Uji Bebas Overflow pada Semua Viewport: 360, 390, 768, 1280, 1920', (tester) async {
      final viewports = [
        const Size(360, 640),
        const Size(390, 844),
        const Size(768, 1024),
        const Size(1280, 800),
        const Size(1920, 1080),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Layar tidak boleh overflow pada viewport ${size.width}x${size.height}',
        );
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('4. Uji Bebas Overflow saat Teks Diperbesar 1.3x (Text Scale 1.3x)', (tester) async {
      for (final size in [const Size(390, 844), const Size(1280, 800)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.3),
                  ),
                  child: child!,
                );
              },
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Tidak boleh overflow dengan text scale 1.3x pada lebar ${size.width}',
        );
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('5. Validasi Field Kosong Menampilkan Pesan Error Inline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tekan tombol Masuk ke Sistem tanpa mengisi form
      final submitBtn = find.widgetWithText(AppButton, 'Masuk ke Sistem');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Nama pengguna wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('6. Toggle Password Mengubah Visibilitas dan Tooltip Semantics', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Password field awalnya obscure
      final passwordTextField = find.byType(TextField).last;
      TextField tfWidget = tester.widget<TextField>(passwordTextField);
      expect(tfWidget.obscureText, isTrue);

      // Cari tombol toggle visibilitas password
      final toggleBtn = find.byTooltip('Tampilkan kata sandi');
      expect(toggleBtn, findsOneWidget);

      // Klik toggle
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      // Sekarang password terlihat
      tfWidget = tester.widget<TextField>(passwordTextField);
      expect(tfWidget.obscureText, isFalse);
      expect(find.byTooltip('Sembunyikan kata sandi'), findsOneWidget);
    });

    testWidgets('7. Submit Form via Enter pada Field Password', (tester) async {
      final fakeRepo = _FakeAuthRepo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'resepsionis01');
      await tester.enterText(textFields.last, 'password123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(fakeRepo.loginCalled, isTrue);
      expect(fakeRepo.lastUsername, 'resepsionis01');
      expect(fakeRepo.lastPassword, 'password123');
    });

    testWidgets('8. State Loading Menonaktifkan Tombol Masuk untuk Mencegah Double Submit', (tester) async {
      final fakeRepo = _FakeAuthRepo();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Set state auth menjadi loading
      container.read(authStateProvider.notifier).state = const AuthState(isLoading: true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      final submitBtn = tester.widget<AppButton>(find.byType(AppButton).first);
      expect(submitBtn.isLoading, isTrue);
      expect(submitBtn.onPressed, isNull, reason: 'Tombol harus dinonaktifkan saat isLoading true');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('9. Verifikasi Kontras Warna Tombol Utama WCAG AA (>= 4.5:1)', (tester) async {
      // Warna latar: orange600 (#FF6600), warna teks/ikon: navy900 (#001B4E)
      final ratio = _getContrastRatio(AppColors.navy900, AppColors.orange600);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Rasio kontras harus memenuhi WCAG AA >= 4.5:1');
      expect(ratio, closeTo(5.65, 0.1));
    });

    testWidgets('10. Banner Error Autentikasi Ditampilkan saat Login Gagal', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeRepo = _FakeAuthRepo();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'invalid_user');
      await tester.enterText(textFields.last, 'wrong_pass');
      final submitBtn = find.widgetWithText(AppButton, 'Masuk ke Sistem');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Nama pengguna atau kata sandi salah. Coba lagi.'), findsOneWidget);
      expect(find.byIcon(AppIcons.error), findsOneWidget);
    });
  });
}
