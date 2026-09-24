class AuditLogModel {
  final String id;
  final String userName;
  final String actionType; // CHECK_IN, CHECK_OUT, CREATE_ROOM, EDIT_PRICE, EXPORT_REPORT, WA_REMINDER_RESEND
  final String resourceType; // reservation, room, report
  final String details;
  final DateTime timestamp;
  final String ipAddress;

  const AuditLogModel({
    required this.id,
    required this.userName,
    required this.actionType,
    required this.resourceType,
    required this.details,
    required this.timestamp,
    required this.ipAddress,
  });
}
