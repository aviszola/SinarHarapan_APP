import '../../shared_widgets/status_badge.dart';
import '../domain/room_model.dart';

class RoomRepository {
  static final List<RoomModel> _rooms = [
    // Floor 1
    RoomModel(
      id: 'rm-101',
      roomNumber: '101',
      roomType: 'Standard',
      floor: 1,
      basePricePerNight: 250000,
      facilities: ['AC', 'TV', 'WiFi', 'Shower Air Hangat'],
      status: RoomStatusType.available,
    ),
    RoomModel(
      id: 'rm-102',
      roomNumber: '102',
      roomType: 'Standard',
      floor: 1,
      basePricePerNight: 250000,
      facilities: ['AC', 'TV', 'WiFi', 'Shower Air Hangat'],
      status: RoomStatusType.occupied,
      activeGuestName: 'Agus Santoso',
      activeGuestPhone: '081234567890',
      bookingSource: 'REDDOORZ',
      reddoorzBookingCode: 'RD-89421',
      checkInTime: DateTime.now().subtract(const Duration(hours: 20)),
      expectedCheckOutTime: DateTime.now().add(const Duration(minutes: 45)), // H-1 jam!
      invoiceNumber: 'INV/SH/20260923/0001',
      waReminderStatus: 'DELIVERED',
    ),
    RoomModel(
      id: 'rm-103',
      roomNumber: '103',
      roomType: 'Superior',
      floor: 1,
      basePricePerNight: 320000,
      facilities: ['AC', 'Smart TV 43"', 'WiFi Cepat', 'Shower Air Hangat', 'Kulkas Mini'],
      status: RoomStatusType.available,
    ),
    RoomModel(
      id: 'rm-104',
      roomNumber: '104',
      roomType: 'Superior',
      floor: 1,
      basePricePerNight: 320000,
      facilities: ['AC', 'Smart TV 43"', 'WiFi Cepat', 'Shower Air Hangat'],
      status: RoomStatusType.dirty,
      invoiceNumber: 'INV/SH/20260924/0002',
    ),
    RoomModel(
      id: 'rm-105',
      roomNumber: '105',
      roomType: 'Deluxe',
      floor: 1,
      basePricePerNight: 450000,
      facilities: ['AC', 'Smart TV 50"', 'WiFi 50Mbps', 'Bathtub', 'Kulkas Mini', 'King Bed'],
      status: RoomStatusType.maintenance,
    ),

    // Floor 2
    RoomModel(
      id: 'rm-201',
      roomNumber: '201',
      roomType: 'Standard',
      floor: 2,
      basePricePerNight: 250000,
      facilities: ['AC', 'TV', 'WiFi', 'Shower Air Hangat'],
      status: RoomStatusType.available,
    ),
    RoomModel(
      id: 'rm-202',
      roomNumber: '202',
      roomType: 'Standard',
      floor: 2,
      basePricePerNight: 250000,
      facilities: ['AC', 'TV', 'WiFi', 'Shower Air Hangat'],
      status: RoomStatusType.occupied,
      activeGuestName: 'Dian Permata',
      activeGuestPhone: '081398765432',
      bookingSource: 'WALK_IN',
      checkInTime: DateTime.now().subtract(const Duration(hours: 14)),
      expectedCheckOutTime: DateTime.now().add(const Duration(hours: 6)),
      invoiceNumber: 'INV/SH/20260923/0003',
      waReminderStatus: 'SENT',
    ),
    RoomModel(
      id: 'rm-203',
      roomNumber: '203',
      roomType: 'Superior',
      floor: 2,
      basePricePerNight: 320000,
      facilities: ['AC', 'Smart TV 43"', 'WiFi Cepat', 'Shower Air Hangat', 'Balkon'],
      status: RoomStatusType.available,
    ),
    RoomModel(
      id: 'rm-204',
      roomNumber: '204',
      roomType: 'Deluxe',
      floor: 2,
      basePricePerNight: 450000,
      facilities: ['AC', 'Smart TV 50"', 'WiFi 50Mbps', 'Bathtub', 'Balkon View'],
      status: RoomStatusType.occupied,
      activeGuestName: 'Michael Tan',
      activeGuestPhone: '081901234567',
      bookingSource: 'REDDOORZ',
      reddoorzBookingCode: 'RD-90214',
      checkInTime: DateTime.now().subtract(const Duration(hours: 22)),
      expectedCheckOutTime: DateTime.now().add(const Duration(minutes: 30)),
      invoiceNumber: 'INV/SH/20260923/0004',
      waReminderStatus: 'READ',
    ),
    RoomModel(
      id: 'rm-205',
      roomNumber: '205',
      roomType: 'Family',
      floor: 2,
      basePricePerNight: 600000,
      facilities: ['AC 2 Unit', 'Smart TV 55"', 'WiFi', '2 Queen Beds', 'Ruang Tamu'],
      status: RoomStatusType.available,
    ),

    // Floor 3
    RoomModel(
      id: 'rm-301',
      roomNumber: '301',
      roomType: 'Standard',
      floor: 3,
      basePricePerNight: 250000,
      facilities: ['AC', 'TV', 'WiFi', 'Shower Air Hangat'],
      status: RoomStatusType.available,
    ),
    RoomModel(
      id: 'rm-302',
      roomNumber: '302',
      roomType: 'Superior',
      floor: 3,
      basePricePerNight: 320000,
      facilities: ['AC', 'Smart TV 43"', 'WiFi Cepat', 'Shower Air Hangat'],
      status: RoomStatusType.occupied,
      activeGuestName: 'Nurul Hidayah',
      activeGuestPhone: '085712345678',
      bookingSource: 'WALK_IN',
      checkInTime: DateTime.now().subtract(const Duration(hours: 5)),
      expectedCheckOutTime: DateTime.now().add(const Duration(hours: 19)),
      invoiceNumber: 'INV/SH/20260924/0005',
      waReminderStatus: 'SENT',
    ),
    RoomModel(
      id: 'rm-303',
      roomNumber: '303',
      roomType: 'Deluxe',
      floor: 3,
      basePricePerNight: 450000,
      facilities: ['AC', 'Smart TV 50"', 'WiFi 50Mbps', 'Bathtub'],
      status: RoomStatusType.dirty,
    ),
    RoomModel(
      id: 'rm-304',
      roomNumber: '304',
      roomType: 'Family',
      floor: 3,
      basePricePerNight: 600000,
      facilities: ['AC 2 Unit', 'Smart TV 55"', 'WiFi', '2 Queen Beds', 'Pemandangan Kota'],
      status: RoomStatusType.available,
    ),
  ];

  Future<List<RoomModel>> getRooms() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_rooms);
  }

  Future<void> updateRoom(RoomModel updatedRoom) async {
    final index = _rooms.indexWhere((r) => r.id == updatedRoom.id);
    if (index != -1) {
      _rooms[index] = updatedRoom;
    }
  }

  Future<void> addRoom(RoomModel newRoom) async {
    if (_rooms.any((r) => r.roomNumber == newRoom.roomNumber)) {
      throw Exception('Nomor kamar ${newRoom.roomNumber} sudah digunakan!');
    }
    _rooms.add(newRoom);
  }

  Future<void> deleteRoom(String roomId) async {
    final room = _rooms.firstWhere((r) => r.id == roomId, orElse: () => throw Exception('Kamar tidak ditemukan'));
    if (room.isOccupied) {
      throw Exception('Kamar sedang ditempati tamu. Tidak dapat dihapus!');
    }
    _rooms.removeWhere((r) => r.id == roomId);
  }
}
