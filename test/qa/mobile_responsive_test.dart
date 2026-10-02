import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/app/theme.dart';
import 'package:sinarharapan_app/features/auth/presentation/login_screen.dart';
import 'package:sinarharapan_app/features/reporting/presentation/manager_dashboard_screen.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_card.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_filter_bar.dart';
import 'package:sinarharapan_app/features/shared_widgets/app_header.dart';
import 'package:sinarharapan_app/features/shared_widgets/metric_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Mobile Responsive Layout Verification', () {
    testWidgets('LoginScreen renders cleanly on 360x640 mobile screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Sistem'), findsWidgets);
      expect(find.text('Resepsionis'), findsOneWidget);
      expect(find.text('Manajer Hotel'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Tidak boleh ada overflow pada layar mobile');
    });

    testWidgets('ReceptionistTopBar renders cleanly without overflow on 360px mobile', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ReceptionistTopBar(
              userName: 'Siti Rahmawati',
              userRole: 'RECEPTIONIST',
              activeWaCount: 3,
              onLogout: () {},
              onOpenActiveGuests: () {},
              onOpenManagerPortal: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SH'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'ReceptionistTopBar mobile tidak boleh overflow');
    });

    testWidgets('RoomFilterBar displays full width search and scrollable chips on mobile', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ProviderScope(
              child: RoomFilterBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Semua Tipe'), findsOneWidget);
      expect(find.text('Semua Lantai'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'RoomFilterBar mobile tidak boleh overflow');
    });

    testWidgets('RoomCard renders without overflow on 160px narrow mobile card', (WidgetTester tester) async {
      final room = RoomModel(
        id: '101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: ['AC', 'WiFi'],
        status: RoomStatusType.available,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 130,
                child: RoomCard(
                  room: room,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('101'), findsOneWidget);
      expect(find.text('Check-in'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'RoomCard compact mobile tidak boleh overflow');
    });

    testWidgets('MetricCard scales value on mobile viewport without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: MetricCard(
                title: 'Akumulasi Pendapatan Bersih',
                value: 'Rp 48.750.000',
                trendText: '▲ 18.2% di atas target bulanan',
                isTrendPositive: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AKUMULASI PENDAPATAN BERSIH'), findsOneWidget);
      expect(find.text('Rp 48.750.000'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'MetricCard mobile tidak boleh overflow');
    });

    testWidgets('ManagerDashboardScreen provides drawer navigation on mobile', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(
            child: ManagerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drawer hamburger button must be visible on mobile
      expect(find.byIcon(Icons.menu), findsOneWidget);
      // Compact tab title 'Analytics' on mobile
      expect(find.text('Analytics'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'ManagerDashboardScreen mobile tidak boleh overflow');
    });
  });
}
