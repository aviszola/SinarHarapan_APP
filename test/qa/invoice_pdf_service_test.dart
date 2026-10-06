import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/features/checkout/domain/invoice_pdf_service.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('InvoicePdfService Tests', () {
    final sampleRoom = RoomModel(
      id: '101',
      roomNumber: '101',
      roomType: 'Deluxe Double',
      floor: 1,
      status: RoomStatusType.occupied,
      basePricePerNight: 350000,
      facilities: const ['AC', 'WiFi', 'Smart TV', 'Water Heater'],
      activeGuestName: 'Budi Darmawan',
      guestNik: '3515081234560001',
      activeGuestPhone: '081234567890',
      bookingSource: 'REDDOORZ',
      reddoorzBookingCode: 'RD-987654',
      checkInTime: DateTime(2026, 9, 30, 14, 0),
      expectedCheckOutTime: DateTime(2026, 10, 2, 12, 0),
      invoiceNumber: 'INV/SH/20260930/0001',
    );

    test('generateInvoicePdf generates valid PDF bytes with magic header', () async {
      final bytes = await InvoicePdfService.generateInvoicePdf(
        room: sampleRoom,
        roomTotal: 700000,
        lateFee: 0,
        minibarFee: 0,
        damageFee: 0,
        grandTotal: 700000,
        receptionistName: 'Siti Rahmawati',
        invoiceNumber: 'INV/SH/20260930/0001',
      );

      expect(bytes, isNotEmpty);
      // Valid PDF document starts with '%PDF'
      final magicHeader = String.fromCharCodes(bytes.take(4));
      expect(magicHeader, equals('%PDF'));
    });

    test('generateInvoicePdf supports additional charges properly', () async {
      final bytes = await InvoicePdfService.generateInvoicePdf(
        room: sampleRoom,
        roomTotal: 700000,
        lateFee: 50000,
        minibarFee: 35000,
        damageFee: 100000,
        grandTotal: 885000,
        receptionistName: 'Siti Rahmawati',
        invoiceNumber: 'INV/SH/20260930/0002',
      );

      expect(bytes, isNotEmpty);
      final magicHeader = String.fromCharCodes(bytes.take(4));
      expect(magicHeader, equals('%PDF'));
    });

    test('saveInvoicePdf executes cleanly and outputs valid PDF file', () async {
      final savedPath = await InvoicePdfService.saveInvoicePdf(
        room: sampleRoom,
        roomTotal: 700000,
        grandTotal: 700000,
        receptionistName: 'Siti Rahmawati',
        invoiceNumber: 'INV/SH/20260930/0003',
      );

      expect(savedPath, isNotNull);
      expect(savedPath!.endsWith('.pdf'), isTrue);
      final file = File(savedPath);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(100));

      // Clean up test file if needed
      try {
        file.deleteSync();
      } catch (_) {}
    });
  });
}
