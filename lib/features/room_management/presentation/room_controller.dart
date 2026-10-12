import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../data/room_repository.dart';
import '../data/room_seed_data.dart';
import '../domain/room_model.dart';

/// Polling interval GET /rooms/status — endpoint.md §3.2 & PRD FR-ROOM-07: tiap 15 detik
const _kStatusPollingInterval = Duration(seconds: 15);

final roomRepositoryProvider = Provider<RoomRepository>((ref) => RoomRepository());

class RoomFilterState {
  final String roomType;
  final int floor;
  final RoomStatusType? status;
  final String searchQuery;

  const RoomFilterState({
    this.roomType = 'ALL',
    this.floor = 0,
    this.status,
    this.searchQuery = '',
  });

  int get activeFilterCount {
    int count = 0;
    if (roomType != 'ALL') count++;
    if (floor != 0) count++;
    if (status != null) count++;
    if (searchQuery.trim().isNotEmpty) count++;
    return count;
  }

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

final highlightedRoomIdProvider = StateProvider<String?>((ref) => null);

class RoomListNotifier extends StateNotifier<AsyncValue<List<RoomModel>>> {
  final RoomRepository _repository;
  final Ref? _ref;
  Timer? _pollingTimer;

  RoomListNotifier(this._repository, [this._ref]) : super(const AsyncValue.loading()) {
    loadRooms();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_kStatusPollingInterval, (_) => _pollStatus());
  }

  /// Polling ringan GET /rooms/status untuk update status grid tanpa full reload
  Future<void> _pollStatus() async {
    try {
      final snapshots = await _repository.getRoomStatusOnly();
      if (!mounted) return;
      state.whenData((rooms) {
        final statusMap = {for (final s in snapshots) s.id: s.status};
        final updated = rooms.map((r) {
          final newStatus = statusMap[r.id];
          return newStatus != null && newStatus != r.status
              ? r.copyWith(status: newStatus)
              : r;
        }).toList();
        state = AsyncValue.data(updated);
      });
    } catch (_) {
      // Polling gagal — abaikan, tidak mengganggu state
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> loadRooms({bool silent = false}) async {
    if (!silent || state.value == null) {
      state = const AsyncValue.loading();
    }
    try {
      final rooms = await _repository.getRooms();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> markRoomCleaned(String roomId) async {
    // Operasi tulis: tidak ada fallback lokal; lempar error jika gagal
    await _repository.markRoomClean(roomId);
    _ref?.read(highlightedRoomIdProvider.notifier).state = roomId;
    await loadRooms(silent: true);
  }

  Future<void> toggleMaintenance(String roomId) async {
    final currentList = state.value;
    if (currentList == null) throw StateError('Data kamar belum dimuat');

    final room = currentList.firstWhere((r) => r.id == roomId);
    if (room.isOccupied) {
      throw ApiException('Kamar sedang ditempati, tidak bisa diubah ke mode maintenance');
    }

    final newStatus = room.isMaintenance ? 'AVAILABLE' : 'MAINTENANCE';
    await _repository.updateRoom(id: roomId, status: newStatus);
    _ref?.read(highlightedRoomIdProvider.notifier).state = roomId;
    await loadRooms(silent: true);
  }

  /// Check-in: kirim ke backend DULU, baru reload state dari server
  Future<Map<String, dynamic>> checkIn({
    required String roomId,
    required String guestFullName,
    required String idType,
    required String idNumber,
    String? guestAddress,
    String? guestNationality,
    required String guestPhone,
    String? idImageUrl,
    required String bookingSource,
    String? reddoorzBookingCode,
    required int totalNights,
    required double roomRate,
    required String paymentMethod,
  }) async {
    final now = DateTime.now();
    final expectedCheckout = DateTime(
      now.year,
      now.month,
      now.day + totalNights,
      12, // standar checkout 12:00 WIB
    );

    // Kirim ke backend — jika gagal (409, 400, dll), exception dilempar ke UI
    final result = await _repository.createReservation(
      roomId: roomId,
      bookingSource: bookingSource,
      reddoorzBookingCode: reddoorzBookingCode,
      idType: idType,
      idNumber: idNumber,
      guestFullName: guestFullName,
      guestAddress: guestAddress,
      guestNationality: guestNationality,
      guestPhone: guestPhone,
      idImageUrl: idImageUrl,
      checkInTime: now.toIso8601String(),
      expectedCheckOutTime: expectedCheckout.toIso8601String(),
      totalNights: totalNights,
      roomRate: roomRate,
      paymentMethod: paymentMethod,
    );

    // Reload tanpa flicker skeleton
    await loadRooms(silent: true);
    return result;
  }

  /// Check-out: kirim ke backend DULU, baru reload state dari server
  Future<Map<String, dynamic>> checkOut({
    required String reservationId,
    required List<Map<String, dynamic>> additionalCharges,
    DateTime? checkOutTime,
  }) async {
    final actualTime = (checkOutTime ?? DateTime.now()).toIso8601String();

    // Kirim ke backend — path sudah benar: POST /reservations/:id/checkout
    final result = await _repository.processCheckout(
      reservationId: reservationId,
      actualCheckOutTime: actualTime,
      additionalCharges: additionalCharges,
    );

    await loadRooms(silent: true);
    return result;
  }

  Future<void> addRoom({
    required String roomNumber,
    required String roomType,
    required int floor,
    required int basePrice,
    required List<String> facilities,
  }) async {
    await _repository.addRoom(
      roomNumber: roomNumber,
      roomType: roomType,
      floor: floor,
      basePricePerNight: basePrice,
      facilities: facilities,
    );
    await loadRooms();
  }

  Future<void> editRoom({
    required String roomId,
    required String roomNumber,
    required String roomType,
    required int floor,
    required int basePrice,
    required List<String> facilities,
  }) async {
    await _repository.updateRoom(
      id: roomId,
      roomNumber: roomNumber,
      roomType: roomType,
      floor: floor,
      basePricePerNight: basePrice,
      facilities: facilities,
    );
    await loadRooms();
  }

  Future<void> deleteRoom(String roomId) async {
    await _repository.deleteRoom(roomId);
    await loadRooms();
  }
}

final roomListProvider =
    StateNotifierProvider<RoomListNotifier, AsyncValue<List<RoomModel>>>((ref) {
  final repo = ref.watch(roomRepositoryProvider);
  return RoomListNotifier(repo, ref);
});

final roomFilterProvider = StateProvider<RoomFilterState>((ref) => const RoomFilterState());

bool matchesRoomSearch(RoomModel room, String query) {
  if (query.trim().isEmpty) return true;
  final q = query.trim().toLowerCase();
  return room.roomNumber.toLowerCase().contains(q) ||
      (room.activeGuestName ?? '').toLowerCase().contains(q) ||
      (room.activeGuestPhone ?? '').toLowerCase().contains(q) ||
      (room.invoiceNumber ?? '').toLowerCase().contains(q);
}

final filteredRoomsProvider = Provider<List<RoomModel>>((ref) {
  final roomsAsync = ref.watch(roomListProvider);
  final filter = ref.watch(roomFilterProvider);

  return roomsAsync.when(
    data: (rooms) => rooms.where((room) {
      if (!matchesRoomSearch(room, filter.searchQuery)) return false;
      if (filter.roomType != 'ALL' && room.roomType != filter.roomType) return false;
      if (filter.floor != 0 && room.floor != filter.floor) return false;
      if (filter.status != null && room.status != filter.status) return false;
      return true;
    }).toList()..sort(compareRooms),
    loading: () => [],
    error: (_, _) => [],
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

/// Jumlah kamar per tipe dengan filter lain (floor, status, search) yang sedang aktif
final roomTypeCountsProvider = Provider<Map<String, int>>((ref) {
  final rooms = ref.watch(roomListProvider).asData?.value ?? [];
  final filter = ref.watch(roomFilterProvider);

  final types = kRealRoomFilterTypes;
  final result = <String, int>{for (final t in types) t: 0};

  for (final room in rooms) {
    if (!matchesRoomSearch(room, filter.searchQuery)) continue;
    if (filter.floor != 0 && room.floor != filter.floor) continue;
    if (filter.status != null && room.status != filter.status) continue;

    result['ALL'] = (result['ALL'] ?? 0) + 1;
    if (result.containsKey(room.roomType)) {
      result[room.roomType] = (result[room.roomType] ?? 0) + 1;
    } else {
      result[room.roomType] = 1;
    }
  }

  return result;
});

/// Jumlah kamar per lantai dengan filter lain (type, status, search) yang sedang aktif
final floorCountsProvider = Provider<Map<int, int>>((ref) {
  final rooms = ref.watch(roomListProvider).asData?.value ?? [];
  final filter = ref.watch(roomFilterProvider);

  final floors = kRealRoomFloors;
  final result = <int, int>{for (final f in floors) f: 0};

  for (final room in rooms) {
    if (!matchesRoomSearch(room, filter.searchQuery)) continue;
    if (filter.roomType != 'ALL' && room.roomType != filter.roomType) continue;
    if (filter.status != null && room.status != filter.status) continue;

    result[0] = (result[0] ?? 0) + 1;
    if (result.containsKey(room.floor)) {
      result[room.floor] = (result[room.floor] ?? 0) + 1;
    } else {
      result[room.floor] = 1;
    }
  }

  return result;
});

/// Jumlah kamar per status untuk chip status dengan filter lain (type, floor, search) yang sedang aktif
final statusCountsProvider = Provider<Map<RoomStatusType?, int>>((ref) {
  final rooms = ref.watch(roomListProvider).asData?.value ?? [];
  final filter = ref.watch(roomFilterProvider);

  final result = <RoomStatusType?, int>{
    null: 0,
    RoomStatusType.available: 0,
    RoomStatusType.occupied: 0,
    RoomStatusType.dirty: 0,
    RoomStatusType.maintenance: 0,
  };

  for (final room in rooms) {
    if (!matchesRoomSearch(room, filter.searchQuery)) continue;
    if (filter.roomType != 'ALL' && room.roomType != filter.roomType) continue;
    if (filter.floor != 0 && room.floor != filter.floor) continue;

    result[null] = (result[null] ?? 0) + 1;
    result[room.status] = (result[room.status] ?? 0) + 1;
  }

  return result;
});

/// Banner "DATA CONTOH" — hanya tampil di debug build dengan USE_MOCK=true
bool get showMockBanner => AppConfig.useMock && kDebugMode;
