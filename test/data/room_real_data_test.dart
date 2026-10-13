import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sinarharapan_app/features/room_management/data/room_seed_data.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';

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

    test('Data setiap kamar persis sesuai spesifikasi tabel nyata (+10.000 final, integer, assert per baris)', () {
      RoomModel getRoom(String num) => kRealHotelRooms.firstWhere((r) => r.roomNumber == num);

      // Lantai 1 (6 kamar)
      final r01 = getRoom('01');
      expect(r01.floor, 1); expect(r01.roomType, 'AC'); expect(r01.basePricePerNight, 170000); expect(r01.status, RoomStatusType.available);
      final r02 = getRoom('02');
      expect(r02.floor, 1); expect(r02.roomType, 'AC'); expect(r02.basePricePerNight, 170000); expect(r02.status, RoomStatusType.available);
      final r03 = getRoom('03');
      expect(r03.floor, 1); expect(r03.roomType, 'AC'); expect(r03.basePricePerNight, 170000); expect(r03.status, RoomStatusType.available);
      final r04 = getRoom('04');
      expect(r04.floor, 1); expect(r04.roomType, 'Kipas'); expect(r04.basePricePerNight, 120000); expect(r04.status, RoomStatusType.available);
      final r05 = getRoom('05');
      expect(r05.floor, 1); expect(r05.roomType, 'AC'); expect(r05.basePricePerNight, 170000); expect(r05.status, RoomStatusType.available);
      final r5A = getRoom('5A');
      expect(r5A.floor, 1); expect(r5A.roomType, 'AC'); expect(r5A.basePricePerNight, 200000); expect(r5A.status, RoomStatusType.available);

      // Lantai 2 (10 kamar)
      final r06 = getRoom('06');
      expect(r06.floor, 2); expect(r06.roomType, 'AC'); expect(r06.basePricePerNight, 170000); expect(r06.status, RoomStatusType.available);
      final r07 = getRoom('07');
      expect(r07.floor, 2); expect(r07.roomType, 'AC Twin'); expect(r07.basePricePerNight, 200000); expect(r07.status, RoomStatusType.available);
      final r08 = getRoom('08');
      expect(r08.floor, 2); expect(r08.roomType, 'Kipas'); expect(r08.basePricePerNight, 120000); expect(r08.status, RoomStatusType.available);
      final r09 = getRoom('09');
      expect(r09.floor, 2); expect(r09.roomType, 'AC Twin'); expect(r09.basePricePerNight, 200000); expect(r09.status, RoomStatusType.available);
      final r10 = getRoom('10');
      expect(r10.floor, 2); expect(r10.roomType, 'AC'); expect(r10.basePricePerNight, 170000); expect(r10.status, RoomStatusType.available);
      final r11 = getRoom('11');
      expect(r11.floor, 2); expect(r11.roomType, 'AC'); expect(r11.basePricePerNight, 170000); expect(r11.status, RoomStatusType.available);
      final r12 = getRoom('12');
      expect(r12.floor, 2); expect(r12.roomType, 'AC'); expect(r12.basePricePerNight, 170000); expect(r12.status, RoomStatusType.available);
      final r13 = getRoom('13');
      expect(r13.floor, 2); expect(r13.roomType, 'Kipas'); expect(r13.basePricePerNight, 120000); expect(r13.status, RoomStatusType.available);
      final r14 = getRoom('14');
      expect(r14.floor, 2); expect(r14.roomType, 'Kipas'); expect(r14.basePricePerNight, 120000); expect(r14.status, RoomStatusType.available);
      final r15 = getRoom('15');
      expect(r15.floor, 2); expect(r15.roomType, 'Kipas'); expect(r15.basePricePerNight, 120000); expect(r15.status, RoomStatusType.available);
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

    test('Seed mempertahankan kamar contoh lama tanpa perubahan data atau penghapusan', () {
      const legacyRoom002 = RoomModel(
        id: 'legacy-002',
        roomNumber: '002',
        roomType: 'AC',
        floor: 1,
        basePricePerNight: 250000,
        facilities: ['AC', 'WiFi Cepat', 'TV'],
        status: RoomStatusType.occupied,
        activeGuestName: 'Budi Santoso',
        activeReservationId: 'res-002',
      );
      const legacyRoom400 = RoomModel(
        id: 'legacy-400',
        roomNumber: '400',
        roomType: 'AC',
        floor: 1,
        basePricePerNight: 220000,
        facilities: ['AC', 'Shower Air Hangat'],
        status: RoomStatusType.dirty,
      );
      const legacyRoom102 = RoomModel(
        id: 'legacy-102',
        roomNumber: '102',
        roomType: 'AC',
        floor: 2,
        basePricePerNight: 350000,
        facilities: ['AC', 'Sofa', 'TV'],
        status: RoomStatusType.available,
      );

      final existingLegacyRooms = [legacyRoom002, legacyRoom400, legacyRoom102];

      // Jalankan seedRooms dengan existing legacy rooms
      final combined = seedRooms(existingRooms: existingLegacyRooms);

      // Harus berisi 3 kamar lama + 16 kamar nyata baru = 19 kamar
      expect(combined.length, 19);

      // Verifikasi kamar lama tetap utuh persis
      final retrieved002 = combined.firstWhere((r) => r.roomNumber == '002');
      expect(retrieved002.status, RoomStatusType.occupied);
      expect(retrieved002.activeGuestName, 'Budi Santoso');
      expect(retrieved002.activeReservationId, 'res-002');
      expect(retrieved002.basePricePerNight, 250000);

      final retrieved400 = combined.firstWhere((r) => r.roomNumber == '400');
      expect(retrieved400.status, RoomStatusType.dirty);

      final retrieved102 = combined.firstWhere((r) => r.roomNumber == '102');
      expect(retrieved102.status, RoomStatusType.available);
      expect(retrieved102.basePricePerNight, 350000);

      // Verifikasi 16 kamar nyata baru juga ada
      for (final seed in kRealHotelRooms) {
        final found = combined.any((r) => r.roomNumber == seed.roomNumber && r.floor == seed.floor);
        expect(found, isTrue, reason: 'Kamar nyata ${seed.roomNumber} harus ada di hasil gabungan');
      }

      // Verifikasi idempotensi: dijalankan ulang 2 kali tidak menggandakan kamar
      final secondRun = seedRooms(existingRooms: combined);
      expect(secondRun.length, 19);
      final thirdRun = seedRooms(existingRooms: secondRun);
      expect(thirdRun.length, 19);
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
