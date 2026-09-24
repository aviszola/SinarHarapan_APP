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
  final String? activeGuestName;
  final String? guestNik;
  final String? activeGuestPhone;
  final String? bookingSource; // REDDOORZ | WALK_IN
  final String? reddoorzBookingCode;
  final DateTime? checkInTime;
  final DateTime? expectedCheckOutTime;
  final String? invoiceNumber;
  final String? waReminderStatus; // SENT, DELIVERED, READ, FAILED

  const RoomModel({
    required this.id,
    required this.roomNumber,
    required this.roomType,
    required this.floor,
    required this.basePricePerNight,
    required this.facilities,
    required this.status,
    this.activeGuestName,
    this.guestNik,
    this.activeGuestPhone,
    this.bookingSource,
    this.reddoorzBookingCode,
    this.checkInTime,
    this.expectedCheckOutTime,
    this.invoiceNumber,
    this.waReminderStatus,
  });

  bool get isAvailable => status == RoomStatusType.available;
  bool get isOccupied => status == RoomStatusType.occupied;
  bool get isDirty => status == RoomStatusType.dirty;
  bool get isMaintenance => status == RoomStatusType.maintenance;

  RoomModel copyWith({
    String? id,
    String? roomNumber,
    String? roomType,
    int? floor,
    double? basePricePerNight,
    List<String>? facilities,
    RoomStatusType? status,
    String? activeGuestName,
    String? guestNik,
    String? activeGuestPhone,
    String? bookingSource,
    String? reddoorzBookingCode,
    DateTime? checkInTime,
    DateTime? expectedCheckOutTime,
    String? invoiceNumber,
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
      activeGuestName: clearActiveReservation ? null : (activeGuestName ?? this.activeGuestName),
      guestNik: clearActiveReservation ? null : (guestNik ?? this.guestNik),
      activeGuestPhone: clearActiveReservation ? null : (activeGuestPhone ?? this.activeGuestPhone),
      bookingSource: clearActiveReservation ? null : (bookingSource ?? this.bookingSource),
      reddoorzBookingCode: clearActiveReservation ? null : (reddoorzBookingCode ?? this.reddoorzBookingCode),
      checkInTime: clearActiveReservation ? null : (checkInTime ?? this.checkInTime),
      expectedCheckOutTime: clearActiveReservation ? null : (expectedCheckOutTime ?? this.expectedCheckOutTime),
      invoiceNumber: clearActiveReservation ? null : (invoiceNumber ?? this.invoiceNumber),
      waReminderStatus: clearActiveReservation ? null : (waReminderStatus ?? this.waReminderStatus),
    );
  }
}
