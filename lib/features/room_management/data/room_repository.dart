import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/room_model.dart';
import 'room_seed_data.dart';

/// Model untuk respons GET /rooms/status — hanya id, roomNumber, status, updatedAt
class RoomStatusSnapshot {
  final String id;
  final String roomNumber;
  final RoomStatusType status;
  final DateTime? updatedAt;

  const RoomStatusSnapshot({
    required this.id,
    required this.roomNumber,
    required this.status,
    this.updatedAt,
  });

  factory RoomStatusSnapshot.fromJson(Map<String, dynamic> json) => RoomStatusSnapshot(
        id: json['id']?.toString() ?? '',
        roomNumber: json['roomNumber']?.toString() ?? '',
        status: RoomModel.parseStatus(json['status']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
      );
}

/// Validasi sisi Flutter yang mirror DTO backend (backend.md §8.1)
class FlutterValidation {
  static final _waRegex = RegExp(r'^(\+62|08)\d{8,13}$');

  static String? validateWa(String? phone) {
    if (phone == null || phone.trim().isEmpty) return 'Nomor WhatsApp wajib diisi';
    if (!_waRegex.hasMatch(phone.trim())) {
      return 'Format tidak valid (gunakan +62 atau 08...)';
    }
    return null;
  }

  static String? validateIdNumber(String? idNumber, String idType) {
    if (idNumber == null || idNumber.trim().isEmpty) return 'Nomor identitas wajib diisi';
    final v = idNumber.trim();
    switch (idType) {
      case 'KTP':
        if (!RegExp(r'^\d{16}$').hasMatch(v)) return 'NIK KTP harus 16 digit angka';
        break;
      case 'SIM':
        if (!RegExp(r'^\d{12,16}$').hasMatch(v)) return 'Nomor SIM harus 12–16 digit angka';
        break;
      case 'PASSPORT':
        if (!RegExp(r'^[A-Za-z0-9]{6,9}$').hasMatch(v)) {
          return 'Nomor paspor harus 6–9 karakter alfanumerik';
        }
        break;
      case 'OTHER':
        if (v.length < 4 || v.length > 30) return 'Nomor identitas harus 4–30 karakter';
        break;
    }
    return null;
  }

  static String? validatePaymentMethod(String? method) {
    const valid = {'CASH', 'QRIS', 'TRANSFER', 'REDDOORZ_PREPAID'};
    if (method == null || !valid.contains(method)) {
      return 'Metode pembayaran tidak valid';
    }
    return null;
  }
}

class RoomRepository {
  final ApiClient _api = ApiClient();

  // ---------------------------------------------------------------------------
  // IN-MEMORY MOCK STORE (Digunakan jika AppConfig.useMock aktif)
  // ---------------------------------------------------------------------------
  static List<RoomModel>? _inMemoryMockRooms;

  static List<RoomModel> get _mockRooms {
    _inMemoryMockRooms ??= List<RoomModel>.from(kRealHotelRooms);
    return _inMemoryMockRooms!;
  }

  static void resetMockRooms() {
    _inMemoryMockRooms = List<RoomModel>.from(kRealHotelRooms);
  }

  static String _toBackendRoomType(String localType) {
    switch (localType.toUpperCase()) {
      case 'KIPAS':
        return 'Standard';
      case 'AC':
        return 'Superior';
      case 'AC TWIN':
      case 'TWIN':
        return 'Deluxe';
      default:
        return const ['Standard', 'Superior', 'Deluxe', 'Family'].contains(localType)
            ? localType
            : 'Superior';
    }
  }

  // ---------------------------------------------------------------------------
  // READ — fallback ke data seed riil jika AppConfig.useMock aktif atau API belum terhubung
  // ---------------------------------------------------------------------------

  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    if (AppConfig.useMock) {
      var list = List<RoomModel>.from(_mockRooms);
      if (roomType != null && roomType != 'ALL') {
        list = list.where((r) => r.roomType == roomType).toList();
      }
      if (floor != null && floor != 0) {
        list = list.where((r) => r.floor == floor).toList();
      }
      if (status != null) {
        list = list.where((r) => r.status.name.toUpperCase() == status.toUpperCase()).toList();
      }
      return list..sort(compareRooms);
    }

    final params = <String, dynamic>{};
    if (roomType != null && roomType != 'ALL') params['roomType'] = roomType;
    if (floor != null && floor != 0) params['floor'] = floor.toString();
    if (status != null) params['status'] = status;

    try {
      final res = await _api.get('/rooms', queryParams: params.isEmpty ? null : params);
      if (res is List && res.isNotEmpty) {
        var rooms = res
            .map((item) => RoomModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Jangan sertakan kamar contoh lama (002, 102, 103, 400)
        const legacyNumbers = {'002', '102', '103', '400'};
        final realRoomsOnly = rooms.where((r) => !legacyNumbers.contains(r.roomNumber)).toList();
        if (realRoomsOnly.isNotEmpty) {
          rooms = realRoomsOnly;
        }

        // Pastikan seluruh 16 kamar riil Sinar Harapan selalu lengkap
        final existingNumbers = rooms.map((r) => r.roomNumber).toSet();
        for (final seed in kRealHotelRooms) {
          if (!existingNumbers.contains(seed.roomNumber)) {
            rooms.add(seed);
          }
        }

        rooms.sort(compareRooms);

        // Backend GET /rooms tidak mengembalikan activeReservation (hanya di GET /rooms/:id).
        final occupiedIndices = <int>[];
        for (int i = 0; i < rooms.length; i++) {
          if (rooms[i].isOccupied && rooms[i].activeReservationId == null) {
            occupiedIndices.add(i);
          }
        }

        if (occupiedIndices.isNotEmpty) {
          await Future.wait(occupiedIndices.map((idx) async {
            try {
              final detail = await getRoomById(rooms[idx].id);
              if (detail != null) {
                rooms[idx] = detail;
              }
            } catch (_) {}
          }));
        }

        return rooms;
      }
    } catch (_) {}

    return [];
  }

  /// GET /rooms/status — polling ringan tiap 15 detik (endpoint.md §3.2, PRD FR-ROOM-07)
  Future<List<RoomStatusSnapshot>> getRoomStatusOnly() async {
    if (AppConfig.useMock) {
      return _mockRooms
          .map((r) => RoomStatusSnapshot(id: r.id, roomNumber: r.roomNumber, status: r.status))
          .toList();
    }

    try {
      final res = await _api.get('/rooms/status');
      if (res is List && res.isNotEmpty) {
        return res
            .map((item) => RoomStatusSnapshot.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  Future<RoomModel?> getRoomById(String id) async {
    if (AppConfig.useMock) {
      return _mockRooms.cast<RoomModel?>().firstWhere(
        (r) => r?.id == id || r?.roomNumber == id,
        orElse: () => null,
      );
    }

    try {
      final res = await _api.get('/rooms/$id');
      if (res is Map<String, dynamic>) return RoomModel.fromJson(res);
    } catch (_) {}

    return null;
  }

  // ---------------------------------------------------------------------------
  // WRITE
  // ---------------------------------------------------------------------------

  /// POST /rooms — Manager only, hanya field whitelist DTO
  Future<RoomModel> addRoom({
    required String roomNumber,
    required String roomType,
    required int floor,
    required int basePricePerNight,
    required List<String> facilities,
  }) async {
    if (AppConfig.useMock) {
      final exists = _mockRooms.any((r) => r.roomNumber == roomNumber && r.floor == floor);
      if (exists) {
        throw ApiException('Kamar dengan nomor $roomNumber di lantai $floor sudah ada',
            code: ApiErrorCode.conflict);
      }
      final newRoom = RoomModel(
        id: 'rm-mock-${roomNumber.toLowerCase()}',
        roomNumber: roomNumber,
        roomType: roomType,
        floor: floor,
        basePricePerNight: basePricePerNight,
        facilities: facilities,
        status: RoomStatusType.available,
      );
      _mockRooms.add(newRoom);
      _mockRooms.sort(compareRooms);
      return newRoom;
    }

    final res = await _api.post('/rooms', body: {
      'roomNumber': roomNumber,
      'roomType': _toBackendRoomType(roomType),
      'floor': floor,
      'basePricePerNight': basePricePerNight,
      if (facilities.isNotEmpty) 'facilities': facilities,
    });
    if (res is Map<String, dynamic>) return RoomModel.fromJson(res);
    throw ApiException('Respons tambah kamar tidak valid');
  }

  /// PATCH /rooms/:id — Manager only, hanya field yang diubah (whitelist DTO)
  Future<RoomModel> updateRoom({
    required String id,
    String? roomNumber,
    String? roomType,
    int? floor,
    int? basePricePerNight,
    List<String>? facilities,
    String? status,
  }) async {
    if (AppConfig.useMock) {
      final idx = _mockRooms.indexWhere((r) => r.id == id || r.roomNumber == id);
      if (idx == -1) throw ApiException('Kamar tidak ditemukan', code: ApiErrorCode.notFound);
      final c = _mockRooms[idx];
      RoomStatusType newStatus = c.status;
      if (status != null) {
        switch (status.toUpperCase()) {
          case 'AVAILABLE':
            newStatus = RoomStatusType.available;
            break;
          case 'OCCUPIED':
            newStatus = RoomStatusType.occupied;
            break;
          case 'DIRTY':
            newStatus = RoomStatusType.dirty;
            break;
          case 'MAINTENANCE':
            newStatus = RoomStatusType.maintenance;
            break;
        }
      }
      final updated = RoomModel(
        id: c.id,
        roomNumber: roomNumber ?? c.roomNumber,
        roomType: roomType ?? c.roomType,
        floor: floor ?? c.floor,
        basePricePerNight: basePricePerNight ?? c.basePricePerNight,
        facilities: facilities ?? c.facilities,
        status: newStatus,
        activeReservationId: c.activeReservationId,
        activeGuestName: c.activeGuestName,
        guestNik: c.guestNik,
        activeGuestPhone: c.activeGuestPhone,
        bookingSource: c.bookingSource,
        reddoorzBookingCode: c.reddoorzBookingCode,
        checkInTime: c.checkInTime,
        expectedCheckOutTime: c.expectedCheckOutTime,
        invoiceNumber: c.invoiceNumber,
        additionalCharges: c.additionalCharges,
        waReminderStatus: c.waReminderStatus,
      );
      _mockRooms[idx] = updated;
      return updated;
    }

    final body = <String, dynamic>{};
    if (roomNumber != null) body['roomNumber'] = roomNumber;
    if (roomType != null) body['roomType'] = _toBackendRoomType(roomType);
    if (floor != null) body['floor'] = floor;
    if (basePricePerNight != null) body['basePricePerNight'] = basePricePerNight;
    if (facilities != null) body['facilities'] = facilities;
    if (status != null) body['status'] = status;
    final res = await _api.patch('/rooms/$id', body: body);
    if (res is Map<String, dynamic>) return RoomModel.fromJson(res);
    throw ApiException('Respons update kamar tidak valid');
  }

  /// DELETE /rooms/:id — Manager only
  Future<void> deleteRoom(String id) async {
    if (AppConfig.useMock) {
      _mockRooms.removeWhere((r) => r.id == id || r.roomNumber == id);
      return;
    }
    await _api.delete('/rooms/$id');
  }

  /// PATCH /rooms/:id/mark-clean — Receptionist (FR-OUT-04)
  Future<void> markRoomClean(String id) async {
    if (AppConfig.useMock) {
      final idx = _mockRooms.indexWhere((r) => r.id == id || r.roomNumber == id);
      if (idx != -1) {
        final c = _mockRooms[idx];
        _mockRooms[idx] = RoomModel(
          id: c.id,
          roomNumber: c.roomNumber,
          roomType: c.roomType,
          floor: c.floor,
          basePricePerNight: c.basePricePerNight,
          facilities: c.facilities,
          status: RoomStatusType.available,
        );
      }
      return;
    }
    await _api.patch('/rooms/$id/mark-clean');
  }

  // ---------------------------------------------------------------------------
  // POST /reservations — check-in
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> createReservation({
    required String roomId,
    required String bookingSource,     // 'REDDOORZ' | 'WALK_IN'
    String? reddoorzBookingCode,       // wajib jika bookingSource == 'REDDOORZ'
    required String idType,            // 'KTP' | 'PASSPORT' | 'SIM' | 'OTHER'
    required String idNumber,
    required String guestFullName,
    String? guestAddress,
    String? guestNationality,
    required String guestPhone,        // format: ^(\+62|08)\d{8,13}$
    String? idImageUrl,
    required String checkInTime,       // ISO8601
    required String expectedCheckOutTime, // ISO8601
    required int totalNights,
    required double roomRate,
    required String paymentMethod,     // 'CASH' | 'QRIS' | 'TRANSFER' | 'REDDOORZ_PREPAID'
  }) async {
    // Validasi sisi Flutter sebelum kirim ke backend
    final waErr = FlutterValidation.validateWa(guestPhone);
    if (waErr != null) throw ApiException(waErr, code: ApiErrorCode.validationError);
    final idErr = FlutterValidation.validateIdNumber(idNumber, idType);
    if (idErr != null) throw ApiException(idErr, code: ApiErrorCode.validationError);
    final pmErr = FlutterValidation.validatePaymentMethod(paymentMethod);
    if (pmErr != null) throw ApiException(pmErr, code: ApiErrorCode.validationError);
    if (bookingSource == 'REDDOORZ' &&
        (reddoorzBookingCode == null || reddoorzBookingCode.trim().isEmpty)) {
      throw ApiException('Booking code RedDoorz wajib diisi',
          code: ApiErrorCode.validationError);
    }

    if (AppConfig.useMock) {
      final idx = _mockRooms.indexWhere((r) => r.id == roomId || r.roomNumber == roomId);
      if (idx == -1) throw ApiException('Kamar tidak ditemukan', code: ApiErrorCode.notFound);
      final c = _mockRooms[idx];
      if (c.isOccupied) {
        throw ApiException('Kamar ${c.roomNumber} sudah ditempati', code: ApiErrorCode.conflict);
      }
      final invNumber =
          'INV-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${c.roomNumber}';
      final resId = 'res-mock-${DateTime.now().millisecondsSinceEpoch}';
      final updated = RoomModel(
        id: c.id,
        roomNumber: c.roomNumber,
        roomType: c.roomType,
        floor: c.floor,
        basePricePerNight: roomRate.toInt(),
        facilities: c.facilities,
        status: RoomStatusType.occupied,
        activeReservationId: resId,
        activeGuestName: guestFullName,
        guestNik: idNumber,
        activeGuestPhone: guestPhone,
        bookingSource: bookingSource,
        reddoorzBookingCode: reddoorzBookingCode,
        checkInTime: checkInTime.isNotEmpty ? DateTime.tryParse(checkInTime) ?? DateTime.now() : DateTime.now(),
        expectedCheckOutTime: expectedCheckOutTime.isNotEmpty ? DateTime.tryParse(expectedCheckOutTime) : null,
        invoiceNumber: invNumber,
      );
      _mockRooms[idx] = updated;
      return {
        'id': resId,
        'invoiceNumber': invNumber,
        'status': 'ACTIVE',
        'roomId': c.id,
      };
    }

    // Bangun payload — hanya field dari DTO, tidak ada yang ekstra
    final guest = <String, dynamic>{
      'idType': idType,
      'idNumber': idNumber,
      'fullName': guestFullName,
      'phoneWhatsapp': guestPhone,
    };
    if (guestAddress != null && guestAddress.isNotEmpty) guest['address'] = guestAddress;
    if (guestNationality != null && guestNationality.isNotEmpty) {
      guest['nationality'] = guestNationality;
    }
    if (idImageUrl != null && idImageUrl.isNotEmpty) guest['idImageUrl'] = idImageUrl;

    final body = <String, dynamic>{
      'roomId': roomId,
      'bookingSource': bookingSource,
      'guest': guest,
      'checkInTime': checkInTime,
      'expectedCheckOutTime': expectedCheckOutTime,
      'totalNights': totalNights,
      'roomRate': roomRate,
      'paymentMethod': paymentMethod,
    };
    if (reddoorzBookingCode != null && reddoorzBookingCode.isNotEmpty) {
      body['reddoorzBookingCode'] = reddoorzBookingCode;
    }

    final res = await _api.post('/reservations', body: body);
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Respons check-in tidak valid');
  }

  // ---------------------------------------------------------------------------
  // POST /reservations/:id/checkout
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> processCheckout({
    required String reservationId,
    required String actualCheckOutTime, // ISO8601
    required List<Map<String, dynamic>> additionalCharges, // [{label, amount}]
  }) async {
    if (AppConfig.useMock) {
      final idx = _mockRooms.indexWhere((r) =>
          r.activeReservationId == reservationId ||
          r.id == reservationId ||
          r.roomNumber == reservationId);
      if (idx != -1) {
        final c = _mockRooms[idx];
        _mockRooms[idx] = RoomModel(
          id: c.id,
          roomNumber: c.roomNumber,
          roomType: c.roomType,
          floor: c.floor,
          basePricePerNight: c.basePricePerNight,
          facilities: c.facilities,
          status: RoomStatusType.dirty, // Aturan domain: kamar beralih ke DIRTY
        );
      }
      return {
        'success': true,
        'message': 'Checkout berhasil (mock in-memory)',
        'reservationId': reservationId,
      };
    }

    final res = await _api.post(
      '/reservations/$reservationId/checkout',
      body: {
        'actualCheckOutTime': actualCheckOutTime,
        'additionalCharges': additionalCharges,
      },
    );
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Respons checkout tidak valid');
  }

  // ---------------------------------------------------------------------------
  // Reservations read endpoints
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getReservations({
    int page = 1,
    int limit = 20,
  }) async {
    if (AppConfig.useMock) {
      return _mockRooms.where((r) => r.isOccupied).map((r) => {
            'id': r.activeReservationId ?? 'res-mock-${r.id}',
            'roomNumber': r.roomNumber,
            'guestName': r.activeGuestName ?? 'Tamu Demo',
            'status': 'ACTIVE',
            'checkInTime': r.checkInTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
          }).toList();
    }

    final res = await _api.get('/reservations',
        queryParams: {'page': page.toString(), 'limit': limit.toString()});
    if (res is List) return List<Map<String, dynamic>>.from(res);
    if (res is Map && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data'] as List);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getReservationById(String id) async {
    if (AppConfig.useMock) {
      final room = _mockRooms.firstWhere(
        (r) => r.activeReservationId == id || r.id == id,
        orElse: () => _mockRooms.first,
      );
      return {
        'id': room.activeReservationId ?? 'res-mock-${room.id}',
        'roomNumber': room.roomNumber,
        'guestName': room.activeGuestName ?? 'Tamu Demo',
        'status': 'ACTIVE',
      };
    }

    final res = await _api.get('/reservations/$id');
    if (res is Map<String, dynamic>) return res;
    return null;
  }

  Future<String?> getInvoiceUrl(String reservationId) async {
    if (AppConfig.useMock) return null;
    final res = await _api.get('/reservations/$reservationId/invoice');
    if (res is Map<String, dynamic>) {
      return res['invoicePdfUrl']?.toString() ??
          res['invoiceUrl']?.toString() ??
          res['url']?.toString();
    }
    return null;
  }
}
