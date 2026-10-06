import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/features/auth/data/auth_repository.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/auth/presentation/auth_controller.dart';
import 'package:sinarharapan_app/features/auth/presentation/login_screen.dart';

class FakeAuthRepository extends AuthRepository {
  UserModel? currentUser;
  bool logoutCalled = false;
  String? lastUsername;
  String? lastPassword;

  @override
  Future<UserModel> login({required String username, required String password}) async {
    lastUsername = username;
    lastPassword = password;

    var cleanUsername = username.trim();
    var cleanPassword = password;

    final lowerUser = cleanUsername.toLowerCase();
    if (lowerUser == 'manager' || lowerUser == 'admin') {
      cleanUsername = 'manager01';
      if (cleanPassword == 'password123' ||
          cleanPassword == 'manager' ||
          cleanPassword == 'admin' ||
          cleanPassword == 'manager123') {
        cleanPassword = 'Manager123!';
      }
    } else if (lowerUser == 'resepsionis' || lowerUser == 'receptionist') {
      cleanUsername = 'resepsionis01';
      if (cleanPassword == 'password123' ||
          cleanPassword == 'resepsionis' ||
          cleanPassword == 'resepsionis123') {
        cleanPassword = 'Resepsionis123!';
      }
    }

    if (cleanUsername == 'resepsionis01' && cleanPassword == 'Resepsionis123!') {
      final user = const UserModel(
        id: 'user-rec-1',
        username: 'resepsionis01',
        fullName: 'Resepsionis Satu',
        role: UserRole.receptionist,
        token: 'token-rec-123',
      );
      currentUser = user;
      return user;
    }

    if (cleanUsername == 'manager01' && cleanPassword == 'Manager123!') {
      final user = const UserModel(
        id: 'user-mgr-1',
        username: 'manager01',
        fullName: 'Manager Utama',
        role: UserRole.manager,
        token: 'token-mgr-123',
      );
      currentUser = user;
      return user;
    }

    throw Exception('Kredensial tidak valid');
  }

  @override
  Future<UserModel> quickLogin(UserRole role) async {
    final username = role == UserRole.receptionist ? 'resepsionis01' : 'manager01';
    final password = role == UserRole.receptionist ? 'Resepsionis123!' : 'Manager123!';
    return login(username: username, password: password);
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    currentUser = null;
  }
}

void main() {
  testWidgets('LoginScreen starts with empty username and password fields', (tester) async {
    final fakeRepo = FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify fields are empty
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(2));

    final usernameField = tester.widget<TextField>(textFields.first);
    final passwordField = tester.widget<TextField>(textFields.last);

    expect(usernameField.controller?.text, isEmpty, reason: 'Username must be blank initially');
    expect(passwordField.controller?.text, isEmpty, reason: 'Password must be blank initially');
  });

  testWidgets('Auth Flow: Receptionist login -> logout -> Manager login succeeds cleanly', (tester) async {
    final fakeRepo = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    // 1. Receptionist quick login
    var success = await container.read(authStateProvider.notifier).quickLogin(UserRole.receptionist);
    expect(success, isTrue);
    expect(container.read(authStateProvider).user?.isReceptionist, isTrue);
    expect(container.read(authStateProvider).user?.role, equals(UserRole.receptionist));

    // 2. Logout
    await container.read(authStateProvider.notifier).logout();
    expect(container.read(authStateProvider).isAuthenticated, isFalse);
    expect(container.read(authStateProvider).user, isNull);
    expect(container.read(authStateProvider).errorMessage, isNull);
    expect(fakeRepo.logoutCalled, isTrue);

    // 3. Manager login with tolerance alias 'manager' & 'Manager123!'
    success = await container.read(authStateProvider.notifier).login('manager', 'Manager123!');
    expect(success, isTrue);
    expect(container.read(authStateProvider).user?.isManager, isTrue);
    expect(container.read(authStateProvider).user?.role, equals(UserRole.manager));
    expect(container.read(authStateProvider).errorMessage, isNull);

    // 4. Logout from Manager
    await container.read(authStateProvider.notifier).logout();
    expect(container.read(authStateProvider).isAuthenticated, isFalse);
    expect(container.read(authStateProvider).user, isNull);

    // 5. Manager login with tolerance alias 'manager' & 'password123'
    success = await container.read(authStateProvider.notifier).login('manager', 'password123');
    expect(success, isTrue);
    expect(container.read(authStateProvider).user?.isManager, isTrue);
  });
}
