import 'package:flutter_test/flutter_test.dart';
import 'package:sinarharapan_app/features/room_management/data/room_repository.dart';
import 'package:sinarharapan_app/features/room_management/domain/room_model.dart';
import 'package:sinarharapan_app/features/room_management/presentation/room_controller.dart';

class TestRoomRepository extends RoomRepository {
  final List<RoomModel> _rooms = [
    const RoomModel(
      id: 'rm-01',
      roomNumber: '01',
      roomType: 'AC',
      floor: 1,
      basePricePerNight: 170000,
      facilities: ['AC', 'WiFi', 'TV', 'Kamar Mandi Dalam'],
      status: RoomStatusType.available,
    ),
    const RoomModel(
      id: 'rm-02',
      roomNumber: '02',
      roomType: 'AC',
      floor: 1,
      basePricePerNight: 170000,
      facilities: ['AC', 'WiFi', 'TV', 'Kamar Mandi Dalam'],
      status: RoomStatusType.occupied,
      activeGuestName: 'Agus Santoso',
      activeGuestPhone: '081234567890',
    ),
  ];

  @override
  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    return List.from(_rooms);
  }

  @override
  Future<RoomModel> addRoom({
    required String roomNumber,
    required String roomType,
    required int floor,
    required int basePricePerNight,
    required List<String> facilities,
  }) async {
    if (_rooms.any((r) => r.roomNumber == roomNumber)) {
      throw Exception('Nomor kamar sudah terdaftar');
    }
    final newRoom = RoomModel(
      id: 'rm-$roomNumber',
      roomNumber: roomNumber,
      roomType: roomType,
      floor: floor,
      basePricePerNight: basePricePerNight,
      facilities: facilities,
      status: RoomStatusType.available,
    );
    _rooms.add(newRoom);
    return newRoom;
  }

  @override
  Future<RoomModel> updateRoom({
    required String id,
    String? roomNumber,
    String? roomType,
    int? floor,
    int? basePricePerNight,
    List<String>? facilities,
    String? status,
  }) async {
    final idx = _rooms.indexWhere((r) => r.id == id);
    if (idx == -1) throw Exception('Kamar tidak ditemukan');
    final cur = _rooms[idx];
    final updated = cur.copyWith(
      roomNumber: roomNumber ?? cur.roomNumber,
      roomType: roomType ?? cur.roomType,
      floor: floor ?? cur.floor,
      basePricePerNight: basePricePerNight ?? cur.basePricePerNight,
      facilities: facilities ?? cur.facilities,
      status: status != null ? RoomModel.parseStatus(status) : cur.status,
    );
    _rooms[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteRoom(String id) async {
    final room = _rooms.firstWhere((r) => r.id == id, orElse: () => throw Exception('Kamar tidak ditemukan'));
    if (room.isOccupied) throw Exception('Kamar sedang terisi');
    _rooms.removeWhere((r) => r.id == id);
  }
}

void main() {
  group('Room Inventory CRUD Tests', () {
    late TestRoomRepository repository;
    late RoomListNotifier notifier;

    setUp(() {
      repository = TestRoomRepository();
      notifier = RoomListNotifier(repository);
    });

    tearDown(() {
      notifier.dispose();
    });

    test('Loads initial rooms correctly', () async {
      await notifier.loadRooms();
      expect(notifier.state.hasValue, true);
      final rooms = notifier.state.value!;
      expect(rooms.isNotEmpty, true);
      expect(rooms.any((r) => r.roomNumber == '01'), true);
    });

    test('Add room successfully adds new room to inventory', () async {
      final uniqueRoomNumber = '99${DateTime.now().millisecondsSinceEpoch % 100}';

      await notifier.addRoom(
        roomNumber: uniqueRoomNumber,
        roomType: 'AC Twin',
        floor: 2,
        basePrice: 200000,
        facilities: ['AC', 'WiFi Cepat', 'Smart TV 50"'],
      );

      final rooms = notifier.state.value!;
      final addedRoom = rooms.firstWhere((r) => r.roomNumber == uniqueRoomNumber);
      expect(addedRoom.roomType, 'AC Twin');
      expect(addedRoom.floor, 2);
      expect(addedRoom.basePricePerNight, 200000);
      expect(addedRoom.status, RoomStatusType.available);
      expect(addedRoom.facilities, contains('Smart TV 50"'));
    });

    test('Add room with duplicate number throws Exception', () async {
      expect(
        () => notifier.addRoom(
          roomNumber: '01', // Already exists
          roomType: 'AC',
          floor: 1,
          basePrice: 170000,
          facilities: ['AC'],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Edit room successfully updates room details', () async {
      await notifier.loadRooms();
      final targetRoom = notifier.state.value!.firstWhere((r) => r.roomNumber == '01');

      await notifier.editRoom(
        roomId: targetRoom.id,
        roomNumber: '01',
        roomType: 'AC Twin',
        floor: 1,
        basePrice: 200000,
        facilities: ['AC', 'WiFi Cepat'],
      );

      final updatedRoom = notifier.state.value!.firstWhere((r) => r.id == targetRoom.id);
      expect(updatedRoom.roomType, 'AC Twin');
      expect(updatedRoom.basePricePerNight, 200000);
      expect(updatedRoom.facilities, contains('WiFi Cepat'));
    });

    test('Toggle maintenance sets available room to maintenance and back', () async {
      await notifier.loadRooms();
      final availableRoom = notifier.state.value!.firstWhere((r) => r.isAvailable);

      // 1. Toggle to maintenance
      await notifier.toggleMaintenance(availableRoom.id);
      var room = notifier.state.value!.firstWhere((r) => r.id == availableRoom.id);
      expect(room.isMaintenance, true);

      // 2. Toggle back to available
      await notifier.toggleMaintenance(availableRoom.id);
      room = notifier.state.value!.firstWhere((r) => r.id == availableRoom.id);
      expect(room.isAvailable, true);
    });

    test('Toggle maintenance on occupied room throws Exception', () async {
      await notifier.loadRooms();
      final occupiedRoom = notifier.state.value!.firstWhere((r) => r.isOccupied);

      expect(
        () => notifier.toggleMaintenance(occupiedRoom.id),
        throwsA(isA<Exception>()),
      );
    });

    test('Delete room removes it from inventory', () async {
      final deleteTestNumber = '88${DateTime.now().millisecondsSinceEpoch % 100}';
      await notifier.addRoom(
        roomNumber: deleteTestNumber,
        roomType: 'Standard',
        floor: 1,
        basePrice: 200000,
        facilities: ['AC'],
      );

      final addedRoom = notifier.state.value!.firstWhere((r) => r.roomNumber == deleteTestNumber);
      await notifier.deleteRoom(addedRoom.id);

      final rooms = notifier.state.value!;
      expect(rooms.any((r) => r.roomNumber == deleteTestNumber), false);
    });

    test('Delete occupied room throws Exception', () async {
      await notifier.loadRooms();
      final occupiedRoom = notifier.state.value!.firstWhere((r) => r.isOccupied);

      expect(
        () => notifier.deleteRoom(occupiedRoom.id),
        throwsA(isA<Exception>()),
      );
    });
  });
}
