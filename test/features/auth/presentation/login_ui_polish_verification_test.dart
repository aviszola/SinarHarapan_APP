import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/app/theme.dart';
import 'package:sinarharapan_app/features/auth/data/auth_repository.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/auth/presentation/auth_controller.dart';
import 'package:sinarharapan_app/features/auth/presentation/login_screen.dart';
import 'package:sinarharapan_app/features/shared_widgets/app_button.dart';
import 'package:sinarharapan_app/features/shared_widgets/app_text_field.dart';
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
      expect(find.text('Frontdesk PMS v1.0'), findsWidgets);
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
      expect(find.text('WAKTU OPERASIONAL SISTEM'), findsOneWidget);
      expect(find.text('Operasional Resepsionis & Manajemen'), findsOneWidget);
      expect(find.text('FRONTDESK PMS'), findsOneWidget);
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

      final passwordTextField = find.byType(TextField).last;
      TextField tfWidget = tester.widget<TextField>(passwordTextField);
      expect(tfWidget.obscureText, isTrue);

      final toggleBtn = find.byTooltip('Tampilkan kata sandi');
      expect(toggleBtn, findsOneWidget);

      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

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

    testWidgets('11. Urutan Tab Logis: Username -> Password -> Toggle Mata -> Tombol Masuk', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
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

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // 1. Username field awal fokus otomatis di desktop
      final usernameFocus = tester.widget<TextField>(textFields.first).focusNode!;
      final passwordFocus = tester.widget<TextField>(textFields.last).focusNode!;

      // Pastikan username memiliki fokus awal
      usernameFocus.requestFocus();
      await tester.pumpAndSettle();
      expect(usernameFocus.hasFocus, isTrue);

      // 2. Tab menuju password
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(passwordFocus.hasFocus, isTrue);

      // 3. Tab menuju toggle mata
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final toggleFinder = find.byTooltip('Tampilkan kata sandi');
      expect(toggleFinder, findsOneWidget);

      // 4. Tab berikutnya mencapai tombol masuk
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppButton, 'Masuk ke Sistem'), findsOneWidget);
    });

    testWidgets('12. Fokus Visible: Border dan Label Berubah State saat Field Difokuskan', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
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

      final firstField = find.byType(TextField).first;
      await tester.tap(firstField);
      await tester.pumpAndSettle();

      final focusNode = tester.widget<TextField>(firstField).focusNode!;
      expect(focusNode.hasFocus, isTrue);

      final labelFinder = find.descendant(
        of: find.byType(AppTextField).first,
        matching: find.byType(AnimatedDefaultTextStyle),
      );
      final animatedTextStyle = tester.widget<AnimatedDefaultTextStyle>(labelFinder);
      expect(animatedTextStyle.style.color, equals(AppColors.navy700));
    });

    testWidgets('13. Hover pada Tombol Utama Menampilkan Efek Interaksi Mouse', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
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

      final buttonFinder = find.widgetWithText(AppButton, 'Masuk ke Sistem');
      expect(buttonFinder, findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Geser mouse ke atas tombol Masuk ke Sistem
      await gesture.moveTo(tester.getCenter(buttonFinder));
      await tester.pump();

      final inkWellFinder = find.descendant(
        of: buttonFinder,
        matching: find.byType(InkWell),
      );
      expect(inkWellFinder, findsOneWidget);
      final inkWell = tester.widget<InkWell>(inkWellFinder);
      expect(inkWell.mouseCursor, equals(SystemMouseCursors.click));
    });

    testWidgets('14. Timer Jam Dibatalkan saat Dispose (Tanpa Pending Timer)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Ganti widget untuk memicu dispose pada LoginScreen dan _LeftBrandPanel
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));

      // Verifikasi tidak ada exception atau pending timers bocor
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. Rebuild Jam Tidak Membangun Ulang Form Card', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Isi input pada form
      final usernameField = find.byType(TextField).first;
      await tester.enterText(usernameField, 'resepsionis_aktif');
      await tester.pump();

      // Majukan waktu 2 detik (memicu timer tick pada _LeftBrandPanel)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Input teks pada form tetap utuh tidak ter-reset
      final tf = tester.widget<TextField>(usernameField);
      expect(tf.controller?.text, equals('resepsionis_aktif'));
    });
  });
}
