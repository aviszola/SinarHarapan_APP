import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/domain/user_model.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/reporting/presentation/manager_dashboard_screen.dart';
import '../features/room_management/presentation/room_grid_screen.dart';

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (previous, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthChangeNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/receptionist/rooms',
        builder: (context, state) {
          final authState = ref.read(authStateProvider);
          // Guard di sisi Flutter: Resepsionis tidak boleh akses manager route.
          // Backend adalah penentu akhir via 403.
          if (!authState.isAuthenticated) return const LoginScreen();
          return const RoomGridScreen();
        },
      ),
      GoRoute(
        path: '/manager/dashboard',
        builder: (context, state) {
          final authState = ref.read(authStateProvider);
          if (!authState.isAuthenticated) return const LoginScreen();
          // Jika Resepsionis mencoba akses route Manager, arahkan ke halaman mereka
          if (authState.user?.role == UserRole.receptionist) {
            return const RoomGridScreen();
          }
          return const ManagerDashboardScreen();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final isLoggingIn = state.matchedLocation == '/login';
      final isLoggedIn = authState.isAuthenticated;
      final user = authState.user;

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return user!.isManager ? '/manager/dashboard' : '/receptionist/rooms';
      }

      // Resepsionis tidak boleh mengakses path Manager
      if (isLoggedIn && user?.role == UserRole.receptionist &&
          state.matchedLocation.startsWith('/manager')) {
        return '/receptionist/rooms';
      }

      return null;
    },
  );
});
