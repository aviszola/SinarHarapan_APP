import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/features/shared_widgets/app_text_field.dart';

void main() {
  group('Smooth Keyboard Input & Scroll Padding Tests', () {
    testWidgets('AppTextField renders with generous scrollPadding for keyboard clearance', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppTextField(
                label: 'Nama Lengkap',
                hint: 'Masukkan nama',
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.scrollPadding.bottom, greaterThanOrEqualTo(100.0));
      expect(textField.scrollPhysics, isA<ClampingScrollPhysics>());

      // Test focus gain trigger
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('AppTextField supports custom scrollPadding when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Field Khusus',
              scrollPadding: EdgeInsets.only(bottom: 150, top: 30),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.scrollPadding.bottom, equals(150.0));
      expect(textField.scrollPadding.top, equals(30.0));
    });
  });
}
