import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/main.dart';

void main() {
  testWidgets('PMS App initializes on Login Screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SinarHarapanPmsApp(),
      ),
    );

    // Initial frame rendering
    await tester.pumpAndSettle();

    // Verify hotel branding and login components
    expect(find.text('Hotel Sinar Harapan'), findsOneWidget);
    expect(find.text('Masuk ke Sistem PMS'), findsOneWidget);
    expect(find.text('Masuk ke Sistem'), findsOneWidget);
    expect(find.text('Resepsionis'), findsOneWidget);
    expect(find.text('Manajer Hotel'), findsOneWidget);
  });
}
