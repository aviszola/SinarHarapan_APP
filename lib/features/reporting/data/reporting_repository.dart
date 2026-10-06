import '../../../core/network/api_client.dart';
import '../domain/audit_log_model.dart';

class ReportingRepository {
  final ApiClient _api = ApiClient();

  /// GET /audit-logs (Manager only, RBAC)
  /// Path diperbaiki dari /activity-logs -> /audit-logs
  Future<List<AuditLogModel>> getAuditLogs({
    int page = 1,
    int limit = 50,
    String? actionType,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (actionType != null && actionType.isNotEmpty) params['actionType'] = actionType;
    if (userId != null && userId.isNotEmpty) params['userId'] = userId;
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    final res = await _api.get('/audit-logs', queryParams: params);
    if (res is List) {
      return res
          .map((item) => AuditLogModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (res is Map && res['data'] is List) {
      return (res['data'] as List)
          .map((item) => AuditLogModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /reports/summary (Manager only, endpoint.md §8.1)
  /// Respons resmi:
  /// {
  ///   "totalCheckIn": 128,
  ///   "totalCheckOut": 120,
  ///   "occupancyRate": 78.5,
  ///   "channelComposition": { "reddoorz": 74, "walkIn": 54 },
  ///   "totalNetRevenue": 45200000
  /// }
  Future<Map<String, dynamic>?> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String().substring(0, 10);
    if (endDate != null) params['endDate'] = endDate.toIso8601String().substring(0, 10);

    final res = await _api.get('/reports/summary',
        queryParams: params.isEmpty ? null : params);
    if (res is Map<String, dynamic>) return res;
    return null;
  }

  /// GET /reports/transactions (Manager only, endpoint.md §8.2)
  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (startDate != null) params['startDate'] = startDate.toIso8601String().substring(0, 10);
    if (endDate != null) params['endDate'] = endDate.toIso8601String().substring(0, 10);

    final res = await _api.get('/reports/transactions', queryParams: params);
    if (res is List) return List<Map<String, dynamic>>.from(res);
    if (res is Map && res['data'] is List) {
      return List<Map<String, dynamic>>.from(res['data'] as List);
    }
    return [];
  }

  /// GET /reports/export-excel (Manager only, endpoint.md §8.3)
  /// Mengunduh file binary .xlsx langsung dari backend
  Future<List<int>> exportExcel({DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String().substring(0, 10);
    if (endDate != null) params['endDate'] = endDate.toIso8601String().substring(0, 10);
    return _api.downloadBytes('/reports/export-excel',
        queryParams: params.isEmpty ? null : params);
  }

  /// GET /reports/export-pdf (Manager only, endpoint.md §8.4)
  /// Mengunduh file binary .pdf resmi langsung dari backend
  Future<List<int>> exportPdf({DateTime? startDate, DateTime? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String().substring(0, 10);
    if (endDate != null) params['endDate'] = endDate.toIso8601String().substring(0, 10);
    return _api.downloadBytes('/reports/export-pdf',
        queryParams: params.isEmpty ? null : params);
  }

  /// POST /notifications/send-reminder (Receptionist, endpoint.md §7.1)
  /// Path diperbaiki dari /whatsapp/reminder -> /notifications/send-reminder
  Future<void> sendReminder({required String reservationId}) async {
    await _api.post('/notifications/send-reminder', body: {
      'reservationId': reservationId,
    });
  }

  /// POST /ocr/extract-identity (Receptionist, endpoint.md §4.1)
  /// Multipart upload: file + documentType (KTP | PASSPORT | SIM)
  Future<Map<String, dynamic>> extractIdentity({
    required List<int> imageBytes,
    required String filename,
    required String documentType, // 'KTP' | 'PASSPORT' | 'SIM'
  }) async {
    final res = await _api.postMultipart(
      '/ocr/extract-identity',
      fileBytes: imageBytes,
      filename: filename,
      fields: {'documentType': documentType},
      fileFieldName: 'image',
    );
    if (res is Map<String, dynamic>) return res;
    throw ApiException('Respons OCR tidak valid');
  }
}
