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

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    String userStr = 'Unknown';
    if (json['user'] is Map) {
      final u = json['user'] as Map<String, dynamic>;
      final fn = u['fullName']?.toString() ?? '';
      final role = u['role']?.toString() ?? '';
      userStr = role.isNotEmpty ? '$fn ($role)' : fn;
    } else if (json['userName'] != null) {
      userStr = json['userName'].toString();
    }

    String detailStr = '';
    if (json['details'] is Map) {
      final map = json['details'] as Map;
      detailStr = map.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } else if (json['details'] != null) {
      detailStr = json['details'].toString();
    }

    return AuditLogModel(
      id: json['id']?.toString() ?? '',
      userName: userStr,
      actionType: json['actionType']?.toString() ?? json['action_type']?.toString() ?? '',
      resourceType: json['resourceType']?.toString() ?? json['resource_type']?.toString() ?? '',
      details: detailStr,
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
              : DateTime.now()),
      ipAddress: json['ipAddress']?.toString() ?? json['ip_address']?.toString() ?? '127.0.0.1',
    );
  }
}
