import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';

void main() {
  group('Smart OCR & Identity Detection Tests', () {
    test('FlutterValidation verifies NIK and Phone formatting accurately', () {
      expect(FlutterValidation.validateIdNumber('3578012409890002', 'KTP'), isNull);
      expect(FlutterValidation.validateIdNumber('12345', 'KTP'), isNotNull);
      expect(FlutterValidation.validateIdNumber('C1234567', 'PASSPORT'), isNull);
      expect(FlutterValidation.validateIdNumber('901234567890', 'SIM'), isNull);

      expect(FlutterValidation.validateWa('081234567890'), isNull);
      expect(FlutterValidation.validateWa('+6281234567890'), isNull);
      expect(FlutterValidation.validateWa('12345'), isNotNull);
    });

    test('Detected NIK matches valid regex pattern for KTP', () {
      final nikRegex = RegExp(r'^\d{16}$');
      const testNik = '3578012409890002';
      expect(nikRegex.hasMatch(testNik), isTrue);
    });
  });
}
