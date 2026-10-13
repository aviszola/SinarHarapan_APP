// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/features/shared_widgets/app_button.dart';

void main() {
  group('AppButton Semantics & Accessibility Tests', () {
    testWidgets('1. Normal State: label tunggal tanpa duplikasi, enabled: true, button: true, onTap terpanggil', (tester) async {
      final handle = tester.ensureSemantics();
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Masuk ke Sistem',
              semanticIdentifier: 'login_submit_button',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      // Verifikasi Semantics node
      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(semantics.label, 'Masuk ke Sistem', reason: 'Label harus tunggal tanpa newline duplikasi');
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue, reason: 'Harus memiliki flag button');
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue, reason: 'Harus enabled');
      expect(semantics.identifier, 'login_submit_button', reason: 'Identifier harus sesuai');

      // Verifikasi aksi tap
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);

      handle.dispose();
    });

    testWidgets('2. Disabled State: enabled: false, onTap tidak terpanggil, label tunggal', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Masuk ke Sistem',
              semanticIdentifier: 'login_submit_button',
              onPressed: null, // disabled
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(semantics.label, 'Masuk ke Sistem');
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse, reason: 'Harus disabled saat onPressed null');

      handle.dispose();
    });

    testWidgets('3. Loading State: enabled: false, label dinamis mengikuti loadingLabel, button: true', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Masuk ke Sistem',
              isLoading: true,
              loadingLabel: 'Memproses...',
              onPressed: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(semantics.label, 'Memproses...', reason: 'Label harus dinamis mengikuti loadingLabel');
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse, reason: 'Harus disabled saat loading');

      handle.dispose();
    });

    testWidgets('4. Success State: enabled: false, label dinamis mengikuti successLabel', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Konfirmasi',
              isSuccess: true,
              successLabel: 'Berhasil Disimpan',
              onPressed: () {},
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(semantics.label, 'Berhasil Disimpan', reason: 'Label harus dinamis mengikuti successLabel');
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse, reason: 'Harus disabled saat sukses');

      handle.dispose();
    });
  });
}
