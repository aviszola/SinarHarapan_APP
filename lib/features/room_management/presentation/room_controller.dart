import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../data/room_repository.dart';
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
  Timer? _pollingTimer;

  RoomListNotifier(this._repository) : super(const AsyncValue.loading()) {
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

  Future<void> loadRooms() async {
    state = const AsyncValue.loading();
    try {
      final rooms = await _repository.getRooms();
      state = AsyncValue.data(rooms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRoomCleaned(String roomId) async {
    // Operasi tulis: tidak ada fallback lokal; lempar error jika gagal
    await _repository.markRoomClean(roomId);
    await loadRooms();
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
    await loadRooms();
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

    // Reload dari server agar state sinkron dengan backend
    await loadRooms();
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

    await loadRooms();
    return result;
  }

  Future<void> addRoom({
    required String roomNumber,
    required String roomType,
    required int floor,
    required double basePrice,
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
    required double basePrice,
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
  return RoomListNotifier(repo);
});

final roomFilterProvider = StateProvider<RoomFilterState>((ref) => const RoomFilterState());

final filteredRoomsProvider = Provider<List<RoomModel>>((ref) {
  final roomsAsync = ref.watch(roomListProvider);
  final filter = ref.watch(roomFilterProvider);

  return roomsAsync.when(
    data: (rooms) => rooms.where((room) {
      if (filter.searchQuery.trim().isNotEmpty) {
        final q = filter.searchQuery.trim().toLowerCase();
        final match = room.roomNumber.toLowerCase().contains(q) ||
            (room.activeGuestName ?? '').toLowerCase().contains(q) ||
            (room.activeGuestPhone ?? '').toLowerCase().contains(q) ||
            (room.invoiceNumber ?? '').toLowerCase().contains(q);
        if (!match) return false;
      }
      if (filter.roomType != 'ALL' && room.roomType != filter.roomType) return false;
      if (filter.floor != 0 && room.floor != filter.floor) return false;
      if (filter.status != null && room.status != filter.status) return false;
      return true;
    }).toList(),
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

/// Banner "DATA CONTOH" — hanya tampil di debug build dengan USE_MOCK=true
bool get showMockBanner => AppConfig.useMock && kDebugMode;
