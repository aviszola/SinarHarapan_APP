import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/reporting/presentation/manager_dashboard_screen.dart';
import '../features/room_management/presentation/room_grid_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/receptionist/rooms',
        builder: (context, state) => const RoomGridScreen(),
      ),
      GoRoute(
        path: '/manager/dashboard',
        builder: (context, state) => const ManagerDashboardScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isLoggedIn = authState.isAuthenticated;

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return authState.user!.isManager
            ? '/manager/dashboard'
            : '/receptionist/rooms';
      }

      return null;
    },
  );
});
