import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/features/auth/domain/user_model.dart';
import 'package:sinarharapan_app/features/shared_widgets/app_feedback.dart';
import 'package:sinarharapan_app/features/shared_widgets/app_logout_dialog.dart';
import 'package:sinarharapan_app/theme/app_icons.dart';

void main() {
  group('AppLogoutDialog Anti-Slop Verification Tests', () {
    testWidgets('Renders properly with Receptionist user details', (tester) async {
      const user = UserModel(
        id: 'rec-1',
        username: 'receptionist',
        fullName: 'Siti Rahmawati',
        role: UserRole.receptionist,
        token: 'mock-jwt-token',
      );

      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppLogoutDialog.show(context, user: user);
                },
                child: const Text('Open Logout Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Logout Dialog'));
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Keluar dari Sistem?'), findsOneWidget);
      expect(find.text('Konfirmasi pengakhiran sesi kerja aktif'), findsOneWidget);
      expect(find.byIcon(AppIcons.logout), findsNWidgets(2)); // Header icon + button icon

      // Verify User Details Card
      expect(find.text('Siti Rahmawati'), findsOneWidget);
      expect(find.text('SR'), findsOneWidget); // Initials
      expect(find.text('RESEPSIONIS'), findsOneWidget);
      expect(find.text('Sesi aktif Frontdesk PMS'), findsOneWidget);

      // Verify Advisory message
      expect(
        find.textContaining('Pastikan seluruh transaksi check-in, check-out'),
        findsOneWidget,
      );

      // Verify Touch Targets
      final cancelBtnFinder = find.widgetWithText(OutlinedButton, 'Batal');
      final confirmBtnFinder = find.widgetWithText(ElevatedButton, 'Keluar Akun');
      expect(cancelBtnFinder, findsOneWidget);
      expect(confirmBtnFinder, findsOneWidget);

      final cancelSize = tester.getSize(cancelBtnFinder);
      final confirmSize = tester.getSize(confirmBtnFinder);
      expect(cancelSize.height, greaterThanOrEqualTo(48.0));
      expect(confirmSize.height, greaterThanOrEqualTo(48.0));

      // Test Cancel Button returns false
      await tester.tap(cancelBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppLogoutDialog), findsNothing);
      expect(result, isFalse);
    });

    testWidgets('Renders properly with Manager role and confirms with true', (tester) async {
      const user = UserModel(
        id: 'mgr-1',
        username: 'manager',
        fullName: 'Budi Santoso',
        role: UserRole.manager,
        token: 'mock-jwt-token',
      );

      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppFeedback.showLogout(context, user: user);
                },
                child: const Text('Open Logout'),
              ),
            ),
          ),
        ),
      );

      // Open dialog via AppFeedback.showLogout helper
      await tester.tap(find.text('Open Logout'));
      await tester.pumpAndSettle();

      // Verify Manager Role Pill
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('BS'), findsOneWidget);
      expect(find.text('MANAJER'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Keluar Akun'));
      await tester.pumpAndSettle();

      expect(find.byType(AppLogoutDialog), findsNothing);
      expect(result, isTrue);
    });

    testWidgets('Tapping close button (X) dismisses dialog with false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppLogoutDialog.show(context);
                },
                child: const Text('Trigger Logout'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Logout'));
      await tester.pumpAndSettle();

      expect(find.byType(AppLogoutDialog), findsOneWidget);

      // Tap close icon button
      await tester.tap(find.byIcon(AppIcons.close));
      await tester.pumpAndSettle();

      expect(find.byType(AppLogoutDialog), findsNothing);
      expect(result, isFalse);
    });
  });
}
