import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sinarharapan_app/features/reporting/domain/report_export_service.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/shared_widgets/status_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ReportExportService Tests', () {
    final sampleRooms = [
      const RoomModel(
        id: '101',
        roomNumber: '101',
        roomType: 'Standard',
        floor: 1,
        status: RoomStatusType.available,
        basePricePerNight: 250000,
        facilities: ['AC', 'WiFi'],
      ),
      const RoomModel(
        id: '102',
        roomNumber: '102',
        roomType: 'Deluxe',
        floor: 1,
        status: RoomStatusType.occupied,
        basePricePerNight: 500000,
        facilities: ['AC', 'WiFi', 'TV'],
        activeGuestName: 'Agus Santoso',
        activeGuestPhone: '081234567890',
        bookingSource: 'REDDOORZ',
        invoiceNumber: 'INV/SH/20260923/0001',
      ),
    ];

    test('buildTransactionItems maps rooms properly', () {
      final items = ReportExportService.buildTransactionItems(sampleRooms);
      expect(items.length, 2);
      expect(items[0].roomNumber, '101');
      expect(items[0].status, 'Selesai');
      expect(items[1].roomNumber, '102');
      expect(items[1].guestName, 'Agus Santoso');
      expect(items[1].status, 'Menginap');
    });

    test('exportToExcel executes without exceptions and creates valid file', () async {
      final path = await ReportExportService.exportToExcel(
        rooms: sampleRooms,
        periodName: 'September 2026',
      );
      expect(path, isNotNull);
      expect(path!.endsWith('.xlsx'), isTrue);
    });

    test('exportToPdf executes without exceptions and creates valid file', () async {
      final path = await ReportExportService.exportToPdf(
        rooms: sampleRooms,
        periodName: 'September 2026',
        managerName: 'Hendra Wijaya',
      );
      expect(path, isNotNull);
      expect(path!.endsWith('.pdf'), isTrue);
    });
  });
}
