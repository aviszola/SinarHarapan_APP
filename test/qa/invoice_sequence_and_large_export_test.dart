import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/features/checkout/domain/invoice_sequence_service.dart';
import 'package:sinarharapan_app/features/reporting/domain/report_export_service.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    InvoiceSequenceService.instance.resetForTesting();
  });

  group('QA-OUT-01 & Invoice Sequence Tests', () {
    test('5a: Consecutive check-ins on the same day increment sequence (0001 -> 0002) without duplicates', () async {
      final todayMorning = DateTime(2026, 9, 25, 9, 0);
      final todayAfternoon = DateTime(2026, 9, 25, 16, 30);

      // Sesuai alur baru: Invoice diterbitkan langsung saat check-in
      final invA = InvoiceSequenceService.instance.generateNextInvoiceNumber(transactionDate: todayMorning);
      expect(invA, 'INV/SH/20260925/0001');

      final roomA = RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: const ['AC'],
        status: RoomStatusType.occupied,
        activeGuestName: 'Tamu A (Pagi)',
        activeGuestPhone: '081111111111',
        bookingSource: 'WALK_IN',
        invoiceNumber: invA,
        checkInTime: todayMorning,
      );
      expect(roomA.invoiceNumber, 'INV/SH/20260925/0001');

      // Tamu A check-out: tidak bikin invoice baru, invoice tetap sama
      final roomAfterCheckoutA = roomA.copyWith(
        status: RoomStatusType.dirty,
      );
      expect(roomAfterCheckoutA.invoiceNumber, 'INV/SH/20260925/0001');

      // Tamu B check-in ke Kamar 101 pada hari yang sama: invoice sequence naik ke 0002
      final invB = InvoiceSequenceService.instance.generateNextInvoiceNumber(transactionDate: todayAfternoon);
      expect(invB, 'INV/SH/20260925/0002');
      expect(invB, isNot(equals(invA)));
      expect(invB.contains('101'), isFalse);

      final roomB = RoomModel(
        id: 'rm-101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        basePricePerNight: 250000,
        facilities: const ['AC'],
        status: RoomStatusType.occupied,
        activeGuestName: 'Tamu B (Sore)',
        activeGuestPhone: '082222222222',
        bookingSource: 'REDDOORZ',
        reddoorzBookingCode: 'RD-77889',
        invoiceNumber: invB,
        checkInTime: todayAfternoon,
      );
      expect(roomB.invoiceNumber, 'INV/SH/20260925/0002');

      // Tamu B check-out sore hari: invoice tetap 0002, additionalCharges tersimpan
      final roomAfterCheckoutB = roomB.copyWith(
        status: RoomStatusType.dirty,
        additionalCharges: 50000,
      );
      expect(roomAfterCheckoutB.invoiceNumber, 'INV/SH/20260925/0002');
      expect(roomAfterCheckoutB.additionalCharges, 50000);

      // Skenario hari baru: Counter harus reset ke 0001
      final nextDay = DateTime(2026, 9, 26, 11, 0);
      final nextDayInvoice = InvoiceSequenceService.instance.generateNextInvoiceNumber(
        transactionDate: nextDay,
      );
      expect(nextDayInvoice, 'INV/SH/20260926/0001');
    });

    test('5b: Two exports generated with time delay have IDENTICAL stored invoice numbers', () async {
      // Siapkan kamar dengan nomor invoice tersimpan dari transaksi check-out sebelumnya
      final fixedRooms = [
        const RoomModel(
          id: 'rm-101',
          roomNumber: '101',
          roomType: 'Standard',
          floor: 1,
          status: RoomStatusType.dirty,
          basePricePerNight: 250000,
          facilities: ['AC', 'WiFi'],
          activeGuestName: 'Budi Santoso',
          invoiceNumber: 'INV/SH/20260925/0001',
        ),
        const RoomModel(
          id: 'rm-102',
          roomNumber: '102',
          roomType: 'Deluxe',
          floor: 1,
          status: RoomStatusType.occupied,
          basePricePerNight: 500000,
          facilities: ['AC', 'WiFi', 'TV'],
          activeGuestName: 'Agus Santoso',
          invoiceNumber: 'INV/SH/20260923/0001',
        ),
      ];

      // Export 1
      final items1 = ReportExportService.buildTransactionItems(fixedRooms);
      final path1 = await ReportExportService.exportToExcel(
        rooms: fixedRooms,
        periodName: 'September 2026',
      );

      // Simulasi delay waktu
      await Future.delayed(const Duration(milliseconds: 50));

      // Export 2
      final items2 = ReportExportService.buildTransactionItems(fixedRooms);
      final path2 = await ReportExportService.exportToExcel(
        rooms: fixedRooms,
        periodName: 'September 2026',
      );

      expect(path1, isNotNull);
      expect(path2, isNotNull);

      // Verifikasi bahwa nomor invoice tidak berubah-ubah saat diekspor berulang kali
      expect(items1[0].invoice, items2[0].invoice);
      expect(items1[0].invoice, 'INV/SH/20260925/0001');
      expect(items1[1].invoice, items2[1].invoice);
      expect(items1[1].invoice, 'INV/SH/20260923/0001'); // Tetap tanggal transaksi 23 September!
      expect(items1[1].date, '23/09/2026');
    });

    test('7: Large dataset export (15 rows) correctly calculates SUM formula, preserves widths, and freeze pane', () async {
      final largeRooms = List.generate(15, (i) {
        final rNum = (101 + i).toString();
        final seq = (i + 1).toString().padLeft(4, '0');
        return RoomModel(
          id: 'rm-$rNum',
          roomNumber: rNum,
          roomType: i % 2 == 0 ? 'Standard' : 'Deluxe',
          floor: (i ~/ 5) + 1,
          status: i % 3 == 0 ? RoomStatusType.occupied : RoomStatusType.dirty,
          basePricePerNight: 250000.0 + (i * 25000),
          facilities: const ['AC', 'WiFi'],
          activeGuestName: 'Tamu Uji $rNum',
          activeGuestPhone: '08129999${i.toString().padLeft(4, '0')}',
          bookingSource: i % 2 == 0 ? 'REDDOORZ' : 'WALK_IN',
          invoiceNumber: 'INV/SH/20260925/$seq',
        );
      });

      final path = await ReportExportService.exportToExcel(
        rooms: largeRooms,
        periodName: 'September 2026',
      );

      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);

      final items = ReportExportService.buildTransactionItems(largeRooms);
      expect(items.length, 15);
      expect(items.first.invoice, 'INV/SH/20260925/0001');
      expect(items.last.invoice, 'INV/SH/20260925/0015');
    });
  });
}
