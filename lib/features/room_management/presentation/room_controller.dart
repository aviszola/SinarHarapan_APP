import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../checkout/domain/invoice_sequence_service.dart';
import '../../shared_widgets/status_badge.dart';
import '../data/room_repository.dart';
import '../domain/room_model.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

class RoomFilterState {
  final String roomType; // 'ALL' or specific
  final int floor; // 0 for ALL, or 1, 2, 3
  final RoomStatusType? status; // null for ALL
  final String searchQuery;

  const RoomFilterState({
    this.roomType = 'ALL',
    this.floor = 0,
    this.status,
    this.searchQuery = '',
  });

  RoomFilterState copyWith({
    String? roomType,
    int? floor,
    RoomStatusType? status,
    bool clearStatus = false,
    String? searchQuery,
  }) {
    return RoomFilterState(
      roomType: roomType ?? this.roomType,
      floor: floor ?? this.floor,
      status: clearStatus ? null : (status ?? this.status),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class RoomListNotifier extends StateNotifier<AsyncValue<List<RoomModel>>> {
  final RoomRepository _repository;

  RoomListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRooms();
  }

  Future<void> loadRooms() async {
    try {
      final rooms = await _repository.getRooms();
      InvoiceSequenceService.instance.seedFromInvoices(
        rooms.map((r) => r.invoiceNumber),
      );
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRoomCleaned(String roomId) async {
    final currentList = state.value;
    if (currentList == null) return;

    final room = currentList.firstWhere((r) => r.id == roomId);
    final updated = room.copyWith(
      status: RoomStatusType.available,
      clearActiveReservation: true,
    );

    await _repository.updateRoom(updated);
    await loadRooms();
  }

  Future<void> toggleMaintenance(String roomId) async {
    final currentList = state.value;
    if (currentList == null) return;

    final room = currentList.firstWhere((r) => r.id == roomId);
    if (room.isOccupied) {
      throw Exception('Kamar sedang ditempati, tidak bisa diubah ke mode maintenance');
    }

    final newStatus = room.isMaintenance
        ? RoomStatusType.available
        : RoomStatusType.maintenance;

    final updated = room.copyWith(status: newStatus);
    await _repository.updateRoom(updated);
    await loadRooms();
  }

  Future<RoomModel?> checkIn({
    required String roomId,
    required String guestName,
    String? guestNik,
    required String guestPhone,
    required String bookingSource,
    required String? reddoorzBookingCode,
    required int totalNights,
    required double basePrice,
    required String paymentMethod,
    String? invoiceNumber,
  }) async {
    final currentList = state.value;
    if (currentList == null) return null;

    final room = currentList.firstWhere((r) => r.id == roomId);
    final now = DateTime.now();
    final expectedCheckout = DateTime(
      now.year,
      now.month,
      now.day + totalNights,
      12, // Standar check-out jam 12:00 WIB
      0,
    );

    // Sesuai alur baru: Invoice diterbitkan langsung di awal saat check-in
    final generatedInvoice = invoiceNumber ??
        InvoiceSequenceService.instance.generateNextInvoiceNumber(
          transactionDate: now,
        );

    final updated = room.copyWith(
      status: RoomStatusType.occupied,
      activeGuestName: guestName,
      guestNik: guestNik,
      activeGuestPhone: guestPhone,
      bookingSource: bookingSource,
      reddoorzBookingCode: reddoorzBookingCode,
      checkInTime: now,
      expectedCheckOutTime: expectedCheckout,
      invoiceNumber: generatedInvoice,
      waReminderStatus: 'SENT',
    );

    await _repository.updateRoom(updated);
    await loadRooms();
    return updated;
  }

  Future<RoomModel?> checkOut({
    required String roomId,
    required double additionalCharges,
    DateTime? checkOutTime,
  }) async {
    final currentList = state.value;
    if (currentList == null) return null;

    final room = currentList.firstWhere((r) => r.id == roomId);

    // Sesuai alur baru:
    // Invoice utama sudah diterbitkan saat check-in.
    // Saat check-out, TIDAK ada nomor invoice baru yang dibuat.
    // Jika ada biaya tambahan, cukup dicatat di additionalCharges pada data reservasi yang sama.
    final updated = room.copyWith(
      status: RoomStatusType.dirty, // Setelah checkout menjadi dirty untuk dibersihkan
      additionalCharges: additionalCharges > 0 ? additionalCharges : null,
    );

    await _repository.updateRoom(updated);
    await loadRooms();
    return updated;
  }

  Future<void> addRoom({
    required String roomNumber,
    required String roomType,
    required int floor,
    required double basePrice,
    required List<String> facilities,
  }) async {
    final newRoom = RoomModel(
      id: 'rm-${DateTime.now().millisecondsSinceEpoch}',
      roomNumber: roomNumber,
      roomType: roomType,
      floor: floor,
      basePricePerNight: basePrice,
      facilities: facilities,
      status: RoomStatusType.available,
    );

    await _repository.addRoom(newRoom);
    await loadRooms();
  }

  Future<void> editRoom({
    required String roomId,
    required String roomNumber,
    required String roomType,
    required int floor,
    required double basePrice,
    required List<String> facilities,
  }) async {
    final currentList = state.value;
    if (currentList == null) return;

    final room = currentList.firstWhere((r) => r.id == roomId);
    final updated = room.copyWith(
      roomNumber: roomNumber,
      roomType: roomType,
      floor: floor,
      basePricePerNight: basePrice,
      facilities: facilities,
    );

    await _repository.updateRoom(updated);
    await loadRooms();
  }

  Future<void> deleteRoom(String roomId) async {
    await _repository.deleteRoom(roomId);
    await loadRooms();
  }
}

final roomListProvider = StateNotifierProvider<RoomListNotifier, AsyncValue<List<RoomModel>>>((ref) {
  final repo = ref.watch(roomRepositoryProvider);
  return RoomListNotifier(repo);
});

final roomFilterProvider = StateProvider<RoomFilterState>((ref) {
  return const RoomFilterState();
});

final filteredRoomsProvider = Provider<List<RoomModel>>((ref) {
  final roomsAsync = ref.watch(roomListProvider);
  final filter = ref.watch(roomFilterProvider);

  return roomsAsync.when(
    data: (rooms) {
      return rooms.where((room) {
        if (filter.searchQuery.trim().isNotEmpty) {
          final query = filter.searchQuery.trim().toLowerCase();
          final matchesNumber = room.roomNumber.toLowerCase().contains(query);
          final matchesGuest = (room.activeGuestName ?? '').toLowerCase().contains(query);
          final matchesPhone = (room.activeGuestPhone ?? '').toLowerCase().contains(query);
          final matchesInvoice = (room.invoiceNumber ?? '').toLowerCase().contains(query);
          if (!matchesNumber && !matchesGuest && !matchesPhone && !matchesInvoice) {
            return false;
          }
        }
        if (filter.roomType != 'ALL' && room.roomType != filter.roomType) {
          return false;
        }
        if (filter.floor != 0 && room.floor != filter.floor) {
          return false;
        }
        if (filter.status != null && room.status != filter.status) {
          return false;
        }
        return true;
      }).toList();
    },
    loading: () => [],
    error: (err, stack) => [],
  );
});

final roomStatsProvider = Provider<Map<RoomStatusType, int>>((ref) {
  final roomsAsync = ref.watch(roomListProvider);
  final map = {
    RoomStatusType.available: 0,
    RoomStatusType.occupied: 0,
    RoomStatusType.dirty: 0,
    RoomStatusType.maintenance: 0,
  };

  roomsAsync.whenData((rooms) {
    for (final r in rooms) {
      map[r.status] = (map[r.status] ?? 0) + 1;
    }
  });

  return map;
});
