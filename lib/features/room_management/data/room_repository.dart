import '../../../core/network/api_client.dart';
import '../domain/room_model.dart';

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
  // READ — fallback ke list kosong, bukan data mock, jika API gagal
  // ---------------------------------------------------------------------------

  Future<List<RoomModel>> getRooms({String? roomType, int? floor, String? status}) async {
    final params = <String, dynamic>{};
    if (roomType != null && roomType != 'ALL') params['roomType'] = roomType;
    if (floor != null && floor != 0) params['floor'] = floor.toString();
    if (status != null) params['status'] = status;

    final res = await _api.get('/rooms', queryParams: params.isEmpty ? null : params);
    if (res is List) {
      return res
          .map((item) => RoomModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /rooms/status — polling ringan tiap 15 detik (endpoint.md §3.2, PRD FR-ROOM-07)
  Future<List<RoomStatusSnapshot>> getRoomStatusOnly() async {
    final res = await _api.get('/rooms/status');
    if (res is List) {
      return res
          .map((item) => RoomStatusSnapshot.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<RoomModel?> getRoomById(String id) async {
    final res = await _api.get('/rooms/$id');
    if (res is Map<String, dynamic>) return RoomModel.fromJson(res);
    return null;
  }

  // ---------------------------------------------------------------------------
  // WRITE — tidak ada fallback lokal; gagal = lempar exception ke UI
  // (Tahap 5: operasi tulis tidak boleh ada fallback)
  // ---------------------------------------------------------------------------

  /// POST /rooms — Manager only, hanya field whitelist DTO
  Future<RoomModel> addRoom({
    required String roomNumber,
    required String roomType,
    required int floor,
    required double basePricePerNight,
    required List<String> facilities,
  }) async {
    final res = await _api.post('/rooms', body: {
      'roomNumber': roomNumber,
      'roomType': roomType,
      'floor': floor,
      'basePricePerNight': basePricePerNight,
      // 'facilities' optional sesuai DTO; kirim hanya jika tidak kosong
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
    double? basePricePerNight,
    List<String>? facilities,
    String? status, // 'AVAILABLE' | 'MAINTENANCE' | dll
  }) async {
    final body = <String, dynamic>{};
    if (roomNumber != null) body['roomNumber'] = roomNumber;
    if (roomType != null) body['roomType'] = roomType;
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
    await _api.delete('/rooms/$id');
  }

  /// PATCH /rooms/:id/mark-clean — Receptionist (FR-OUT-04)
  Future<void> markRoomClean(String id) async {
    await _api.patch('/rooms/$id/mark-clean');
  }

  // ---------------------------------------------------------------------------
  // POST /reservations — check-in
  // Field disesuaikan PERSIS dengan CreateReservationDto (backend.md §8.1)
  // forbidNonWhitelisted=true: tidak ada field ekstra yang dikirim
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
    // reddoorzBookingCode — omit key jika null (bukan kirim null)
    if (reddoorzBookingCode != null && reddoorzBookingCode.isNotEmpty) {
      body['reddoorzBookingCode'] = reddoorzBookingCode;
    }
    // invoiceNumber TIDAK dikirim — backend yang generate (InvoiceService §8.4)

    final res = await _api.post('/reservations', body: body);
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Respons check-in tidak valid');
  }

  // ---------------------------------------------------------------------------
  // POST /reservations/:id/checkout — path diperbaiki dari /checkout
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> processCheckout({
    required String reservationId,
    required String actualCheckOutTime, // ISO8601
    required List<Map<String, dynamic>> additionalCharges, // [{label, amount}]
  }) async {
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
    final res = await _api.get('/reservations',
        queryParams: {'page': page.toString(), 'limit': limit.toString()});
    if (res is List) return List<Map<String, dynamic>>.from(res);
    if (res is Map && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data'] as List);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getReservationById(String id) async {
    final res = await _api.get('/reservations/$id');
    if (res is Map<String, dynamic>) return res;
    return null;
  }

  Future<String?> getInvoiceUrl(String reservationId) async {
    final res = await _api.get('/reservations/$reservationId/invoice');
    if (res is Map<String, dynamic>) {
      return res['url']?.toString() ?? res['invoiceUrl']?.toString();
    }
    return null;
  }
}
