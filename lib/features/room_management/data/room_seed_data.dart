import '../domain/room_model.dart';

/// Single Source of Truth untuk Data 16 Kamar Nyata Hotel Sinar Harapan.
///
/// Harga disimpan dalam bilangan bulat (int) Rupiah, tanpa double.
/// Catatan: Harga di bawah merupakan harga FINAL yang sudah termasuk +Rp 10.000 dari tarif dasar.
///
/// Struktur Lantai & Tipe:
/// - Lantai 1 (6 kamar):
///   - "01" (AC, Rp 170.000)
///   - "02" (AC, Rp 170.000)
///   - "03" (AC, Rp 170.000)
///   - "04" (Kipas, Rp 120.000)
///   - "05" (AC, Rp 170.000)
///   - "5A" (AC, Rp 200.000)
/// - Lantai 2 (10 kamar):
///   - "06" (AC, Rp 170.000)
///   - "07" (AC Twin, Rp 200.000)
///   - "08" (Kipas, Rp 120.000)
///   - "09" (AC Twin, Rp 200.000)
///   - "10" (AC, Rp 170.000)
///   - "11" (AC, Rp 170.000)
///   - "12" (AC, Rp 170.000)
///   - "13" (Kipas, Rp 120.000)
///   - "14" (Kipas, Rp 120.000)
///   - "15" (Kipas, Rp 120.000)
///
/// Total: Tepat 16 kamar (Hanya Lantai 1 dan 2).
/// Tipe Kamar: Kipas, AC, AC Twin.

const List<String> kRealRoomTypes = ['Kipas', 'AC', 'AC Twin'];
const List<String> kRealRoomFilterTypes = ['ALL', 'Kipas', 'AC', 'AC Twin'];
const List<int> kRealRoomFloors = [0, 1, 2];

final List<RoomModel> kRealHotelRooms = [
  // ── LANTAI 1 (6 Kamar) ─────────────────────────────────────────────────────
  // Harga final sudah termasuk +Rp 10.000 dari tarif dasar
  const RoomModel(
    id: 'rm-01',
    roomNumber: '01',
    roomType: 'AC',
    floor: 1,
    basePricePerNight: 170000,
    facilities: ['AC'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-02',
    roomNumber: '02',
    roomType: 'AC',
    floor: 1,
    basePricePerNight: 170000,
    facilities: ['AC'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-03',
    roomNumber: '03',
    roomType: 'AC',
    floor: 1,
    basePricePerNight: 170000,
    facilities: ['AC'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-04',
    roomNumber: '04',
    roomType: 'Kipas',
    floor: 1,
    basePricePerNight: 120000,
    facilities: ['Kipas'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-05',
    roomNumber: '05',
    roomType: 'AC',
    floor: 1,
    basePricePerNight: 170000,
    facilities: ['AC'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-5a',
    roomNumber: '5A',
    roomType: 'AC',
    floor: 1,
    basePricePerNight: 200000,
    facilities: ['AC'],
    status: RoomStatusType.available,
  ),

  // ── LANTAI 2 (10 Kamar) ────────────────────────────────────────────────────
  // Harga final sudah termasuk +Rp 10.000 dari tarif dasar
  const RoomModel(
    id: 'rm-06',
    roomNumber: '06',
    roomType: 'AC',
    floor: 2,
    basePricePerNight: 170000,
    facilities: ['AC'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-07',
    roomNumber: '07',
    roomType: 'AC Twin',
    floor: 2,
    basePricePerNight: 200000,
    facilities: ['AC', 'Twin'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-08',
    roomNumber: '08',
    roomType: 'Kipas',
    floor: 2,
    basePricePerNight: 120000,
    facilities: ['Kipas'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-09',
    roomNumber: '09',
    roomType: 'AC Twin',
    floor: 2,
    basePricePerNight: 200000,
    facilities: ['AC', 'Twin'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-10',
    roomNumber: '10',
    roomType: 'AC',
    floor: 2,
    basePricePerNight: 170000,
    facilities: ['AC'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-11',
    roomNumber: '11',
    roomType: 'AC',
    floor: 2,
    basePricePerNight: 170000,
    facilities: ['AC'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-12',
    roomNumber: '12',
    roomType: 'AC',
    floor: 2,
    basePricePerNight: 170000,
    facilities: ['AC'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-13',
    roomNumber: '13',
    roomType: 'Kipas',
    floor: 2,
    basePricePerNight: 120000,
    facilities: ['Kipas'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-14',
    roomNumber: '14',
    roomType: 'Kipas',
    floor: 2,
    basePricePerNight: 120000,
    facilities: ['Kipas'],
    status: RoomStatusType.available,
  ),
  const RoomModel(
    id: 'rm-15',
    roomNumber: '15',
    roomType: 'Kipas',
    floor: 2,
    basePricePerNight: 120000,
    facilities: ['Kipas'],
    status: RoomStatusType.available,
  ),
];

/// Membandingkan nomor kamar dengan aturan pengurutan alami (natural sort).
/// Memastikan urutan: "01" ... "05", "5A", "06" ... "15".
int compareRoomNumbers(String a, String b) {
  final regExp = RegExp(r'^(\d+)(.*)$');
  final matchA = regExp.firstMatch(a.trim());
  final matchB = regExp.firstMatch(b.trim());

  if (matchA != null && matchB != null) {
    final numA = int.parse(matchA.group(1)!);
    final numB = int.parse(matchB.group(1)!);
    if (numA != numB) {
      return numA.compareTo(numB);
    }
    final suffixA = matchA.group(2)!.toUpperCase();
    final suffixB = matchB.group(2)!.toUpperCase();
    return suffixA.compareTo(suffixB);
  }
  return a.compareTo(b);
}

/// Membandingkan dua RoomModel berdasarkan lantai, lalu nomor kamar alami.
int compareRooms(RoomModel a, RoomModel b) {
  if (a.floor != b.floor) {
    return a.floor.compareTo(b.floor);
  }
  return compareRoomNumbers(a.roomNumber, b.roomNumber);
}

/// Seed idempotent data kamar Hotel Sinar Harapan.
///
/// Dijalankan berkali-kali tidak akan menggandakan kamar.
/// Menambah 16 kamar nyata Hotel Sinar Harapan tanpa menghapus atau
/// mengubah kamar contoh lama (mis. 002, 400, 102, 103) maupun data reservasi/transaksi yang ada.
List<RoomModel> seedRooms({List<RoomModel>? existingRooms}) {
  final Map<String, RoomModel> roomMap = {};

  // 1. Pertahankan semua kamar lama/existing yang sudah ada (beserta status & reservasinya)
  if (existingRooms != null) {
    for (final room in existingRooms) {
      final key = '${room.floor}_${room.roomNumber}';
      roomMap[key] = room;
    }
  }

  // 2. Tambahkan 16 kamar nyata yang belum ada berdasarkan nomor kamar + lantai (idempotent)
  for (final seed in kRealHotelRooms) {
    final key = '${seed.floor}_${seed.roomNumber}';
    if (!roomMap.containsKey(key)) {
      roomMap[key] = seed;
    }
  }

  final result = roomMap.values.toList()..sort(compareRooms);
  return result;
}
