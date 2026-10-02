export '../../shared_widgets/status_badge.dart' show RoomStatusType;
import '../../shared_widgets/status_badge.dart';

class RoomModel {
  final String id;
  final String roomNumber;
  final String roomType; // Standard, Superior, Deluxe, Family
  final int floor;
  final double basePricePerNight;
  final List<String> facilities;
  final RoomStatusType status;
  // Metadata for active occupancy (if any)
  final String? activeReservationId;
  final String? activeGuestName;
  final String? guestNik;
  final String? activeGuestPhone;
  final String? bookingSource; // REDDOORZ | WALK_IN
  final String? reddoorzBookingCode;
  final DateTime? checkInTime;
  final DateTime? expectedCheckOutTime;
  final String? invoiceNumber;
  final double? additionalCharges;
  final String? waReminderStatus; // SENT, DELIVERED, READ, FAILED

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.floor,
    required this.basePricePerNight,
    required this.facilities,
    required this.status,
    this.activeReservationId,
    this.activeGuestName,
    this.guestNik,
    this.activeGuestPhone,
    this.bookingSource,
    this.reddoorzBookingCode,
    this.checkInTime,
    this.expectedCheckOutTime,
    this.invoiceNumber,
    this.additionalCharges,
    this.waReminderStatus,
  });

  bool get isAvailable => status == RoomStatusType.available;
  bool get isOccupied => status == RoomStatusType.occupied;
  bool get isDirty => status == RoomStatusType.dirty;
  bool get isMaintenance => status == RoomStatusType.maintenance;

  static RoomStatusType parseStatus(dynamic status) {
    if (status == null) return RoomStatusType.available;
    final s = status.toString().toUpperCase();
    switch (s) {
      case 'OCCUPIED':
        return RoomStatusType.occupied;
      case 'DIRTY':
      case 'CLEANING':
        return RoomStatusType.dirty;
      case 'MAINTENANCE':
        return RoomStatusType.maintenance;
      case 'AVAILABLE':
      default:
        return RoomStatusType.available;
    }
  }

  static String statusToString(RoomStatusType status) {
    switch (status) {
      case RoomStatusType.occupied:
        return 'OCCUPIED';
      case RoomStatusType.dirty:
        return 'DIRTY';
      case RoomStatusType.maintenance:
        return 'MAINTENANCE';
      case RoomStatusType.available:
        return 'AVAILABLE';
    }
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final activeRes = json['activeReservation'] as Map<String, dynamic>?;
    final guestObj = activeRes?['guest'] as Map<String, dynamic>?;

    return RoomModel(
      id: json['id']?.toString() ?? '',
      roomNumber: json['roomNumber']?.toString() ?? json['room_number']?.toString() ?? '',
      roomType: json['roomType']?.toString() ?? json['room_type']?.toString() ?? 'Standard',
      floor: json['floor'] is int ? json['floor'] : int.tryParse(json['floor']?.toString() ?? '1') ?? 1,
      basePricePerNight: (json['basePricePerNight'] ?? json['base_price_per_night'] ?? 0).toDouble(),
      facilities: json['facilities'] is List
          ? (json['facilities'] as List).map((e) => e.toString()).toList()
          : [],
      status: parseStatus(json['status']),
      activeReservationId: activeRes?['id']?.toString() ?? json['activeReservationId']?.toString(),
      activeGuestName: json['activeGuestName'] ?? activeRes?['guestName'] ?? guestObj?['fullName'] ?? json['guest_name'],
      guestNik: json['guestNik'] ?? guestObj?['idNumber'] ?? json['guest_nik'],
      activeGuestPhone: json['activeGuestPhone'] ?? guestObj?['phoneWhatsapp'] ?? json['guest_phone'],
      bookingSource: json['bookingSource'] ?? activeRes?['bookingSource'] ?? json['booking_source'],
      reddoorzBookingCode: json['reddoorzBookingCode'] ?? activeRes?['reddoorzBookingCode'] ?? json['reddoorz_code'],
      checkInTime: json['checkInTime'] != null
          ? DateTime.tryParse(json['checkInTime'].toString())
          : (activeRes?['checkInTime'] != null ? DateTime.tryParse(activeRes!['checkInTime'].toString()) : null),
      expectedCheckOutTime: json['expectedCheckOutTime'] != null
          ? DateTime.tryParse(json['expectedCheckOutTime'].toString())
          : (activeRes?['expectedCheckOutTime'] != null ? DateTime.tryParse(activeRes!['expectedCheckOutTime'].toString()) : null),
      invoiceNumber: json['invoiceNumber'] ?? activeRes?['invoiceNumber'] ?? json['invoice_number'],
      additionalCharges: (json['additionalCharges'] ?? activeRes?['additionalCharges'])?.toDouble(),
      waReminderStatus: json['waReminderStatus'] ?? json['wa_reminder_status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomNumber': roomNumber,
    'roomType': roomType,
    'floor': floor,
    'basePricePerNight': basePricePerNight,
    'facilities': facilities,
    'status': statusToString(status),
    if (activeReservationId != null) 'activeReservationId': activeReservationId,
    if (activeGuestName != null) 'activeGuestName': activeGuestName,
    if (guestNik != null) 'guestNik': guestNik,
    if (activeGuestPhone != null) 'activeGuestPhone': activeGuestPhone,
    if (bookingSource != null) 'bookingSource': bookingSource,
    if (reddoorzBookingCode != null) 'reddoorzBookingCode': reddoorzBookingCode,
    if (checkInTime != null) 'checkInTime': checkInTime?.toIso8601String(),
    if (expectedCheckOutTime != null) 'expectedCheckOutTime': expectedCheckOutTime?.toIso8601String(),
    if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
    if (additionalCharges != null) 'additionalCharges': additionalCharges,
    if (waReminderStatus != null) 'waReminderStatus': waReminderStatus,
  };

  RoomModel copyWith({
    String? id,
    String? roomNumber,
    String? roomType,
    int? floor,
    double? basePricePerNight,
    List<String>? facilities,
    RoomStatusType? status,
    String? activeReservationId,
    String? activeGuestName,
    String? guestNik,
    String? activeGuestPhone,
    String? bookingSource,
    String? reddoorzBookingCode,
    DateTime? checkInTime,
    DateTime? expectedCheckOutTime,
    String? invoiceNumber,
    double? additionalCharges,
    String? waReminderStatus,
    bool clearActiveReservation = false,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      floor: floor ?? this.floor,
      basePricePerNight: basePricePerNight ?? this.basePricePerNight,
      facilities: facilities ?? this.facilities,
      status: status ?? this.status,
      activeReservationId: clearActiveReservation ? null : (activeReservationId ?? this.activeReservationId),
      activeGuestName: clearActiveReservation ? null : (activeGuestName ?? this.activeGuestName),
      guestNik: clearActiveReservation ? null : (guestNik ?? this.guestNik),
      activeGuestPhone: clearActiveReservation ? null : (activeGuestPhone ?? this.activeGuestPhone),
      bookingSource: clearActiveReservation ? null : (bookingSource ?? this.bookingSource),
      reddoorzBookingCode: clearActiveReservation ? null : (reddoorzBookingCode ?? this.reddoorzBookingCode),
      checkInTime: clearActiveReservation ? null : (checkInTime ?? this.checkInTime),
      expectedCheckOutTime: clearActiveReservation ? null : (expectedCheckOutTime ?? this.expectedCheckOutTime),
      invoiceNumber: clearActiveReservation ? null : (invoiceNumber ?? this.invoiceNumber),
      additionalCharges: clearActiveReservation ? null : (additionalCharges ?? this.additionalCharges),
      waReminderStatus: clearActiveReservation ? null : (waReminderStatus ?? this.waReminderStatus),
    );
  }
}
