import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sinarharapan_app/features/room_management/data/room_seed_data.dart';

void main() {
  group('Real Hotel Sinar Harapan Room Data Tests', () {
    test('Total kamar harus tepat 16 kamar', () {
      expect(kRealHotelRooms.length, 16);
    });

    test('Lantai hanya boleh {1, 2} dengan pembagian 6 kamar di Lt 1 dan 10 kamar di Lt 2', () {
      final floors = kRealHotelRooms.map((r) => r.floor).toSet();
      expect(floors, {1, 2});

      final floor1Rooms = kRealHotelRooms.where((r) => r.floor == 1).toList();
      final floor2Rooms = kRealHotelRooms.where((r) => r.floor == 2).toList();

      expect(floor1Rooms.length, 6);
      expect(floor2Rooms.length, 10);
    });

    test('Data setiap kamar persis sesuai spesifikasi tabel nyata (+10.000 final, integer)', () {
      final expectedSpecs = <String, ({int floor, String type, int price})>{
        // Lantai 1
        '01': (floor: 1, type: 'AC', price: 170000),
        '02': (floor: 1, type: 'AC', price: 170000),
        '03': (floor: 1, type: 'AC', price: 170000),
        '04': (floor: 1, type: 'Kipas', price: 120000),
        '05': (floor: 1, type: 'AC', price: 170000),
        '5A': (floor: 1, type: 'AC', price: 200000),
        // Lantai 2
        '06': (floor: 2, type: 'AC', price: 170000),
        '07': (floor: 2, type: 'AC Twin', price: 200000),
        '08': (floor: 2, type: 'Kipas', price: 120000),
        '09': (floor: 2, type: 'AC Twin', price: 200000),
        '10': (floor: 2, type: 'AC', price: 170000),
        '11': (floor: 2, type: 'AC', price: 170000),
        '12': (floor: 2, type: 'AC', price: 170000),
        '13': (floor: 2, type: 'Kipas', price: 120000),
        '14': (floor: 2, type: 'Kipas', price: 120000),
        '15': (floor: 2, type: 'Kipas', price: 120000),
      };

      for (final room in kRealHotelRooms) {
        final spec = expectedSpecs[room.roomNumber];
        expect(spec, isNotNull, reason: 'Kamar ${room.roomNumber} tidak ada di spesifikasi');
        expect(room.floor, spec!.floor, reason: 'Lantai kamar ${room.roomNumber} salah');
        expect(room.roomType, spec.type, reason: 'Tipe kamar ${room.roomNumber} salah');
        expect(room.basePricePerNight, spec.price, reason: 'Harga kamar ${room.roomNumber} salah');
        expect(room.basePricePerNight, isA<int>(), reason: 'Harga kamar ${room.roomNumber} harus int');
      }
    });

    test('Pengurutan alami (natural sort): 5A tepat di antara 05 dan 06', () {
      final numbers = ['06', '15', '01', '5A', '05', '04', '10', '02'];
      numbers.sort(compareRoomNumbers);

      expect(numbers, ['01', '02', '04', '05', '5A', '06', '10', '15']);

      final allNumbers = kRealHotelRooms.map((r) => r.roomNumber).toList();
      final sortedNumbers = List<String>.from(allNumbers)..sort(compareRoomNumbers);
      expect(sortedNumbers, [
        '01', '02', '03', '04', '05', '5A',
        '06', '07', '08', '09', '10', '11', '12', '13', '14', '15'
      ]);

      // Verifikasi posisi 5A
      final idx05 = sortedNumbers.indexOf('05');
      final idx5A = sortedNumbers.indexOf('5A');
      final idx06 = sortedNumbers.indexOf('06');
      expect(idx5A, idx05 + 1);
      expect(idx06, idx5A + 1);
    });

    test('Seed idempotent: dipanggil berkali-kali tetap 16 kamar unik', () {
      final initial = seedRooms();
      expect(initial.length, 16);

      // Jalankan berulang kali dengan daftar yang sudah ada
      final seeded2 = seedRooms(existingRooms: initial);
      expect(seeded2.length, 16);

      final seeded5 = seedRooms(existingRooms: seeded2);
      expect(seeded5.length, 16);

      final uniqueNumbers = seeded5.map((r) => r.roomNumber).toSet();
      expect(uniqueNumbers.length, 16);
    });

    test('Format rupiah dengan titik pemisah ribuan dan format per malam', () {
      final currFmt = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

      final room01 = kRealHotelRooms.firstWhere((r) => r.roomNumber == '01');
      final room04 = kRealHotelRooms.firstWhere((r) => r.roomNumber == '04');
      final room5A = kRealHotelRooms.firstWhere((r) => r.roomNumber == '5A');

      expect('${currFmt.format(room01.basePricePerNight)} / malam', 'Rp 170.000 / malam');
      expect('${currFmt.format(room04.basePricePerNight)} / malam', 'Rp 120.000 / malam');
      expect('${currFmt.format(room5A.basePricePerNight)} / malam', 'Rp 200.000 / malam');
    });

    test('Tipe kamar hanya Kipas, AC, dan AC Twin', () {
      final types = kRealHotelRooms.map((r) => r.roomType).toSet();
      expect(types, {'Kipas', 'AC', 'AC Twin'});
      expect(kRealRoomTypes, ['Kipas', 'AC', 'AC Twin']);
    });
  });
}
