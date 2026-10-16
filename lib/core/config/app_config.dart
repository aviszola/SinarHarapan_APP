import 'package:flutter/foundation.dart';

class AppConfig {
  // Base URL dari --dart-define=BASE_URL=...
  // Default langsung terhubung ke backend server produksi di Railway
  static const String _envBaseUrl = String.fromEnvironment('BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _cleanUrl(_envBaseUrl);
    }
    return 'https://sinar-harapan-backend-production.up.railway.app/api';
  }

  // Mock hanya dihormati jika BUKAN ReleaseMode (!kReleaseMode) dan diaktifkan via --dart-define=USE_MOCK=true
  static const bool _envUseMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static const String _envUseMockStr = String.fromEnvironment('USE_MOCK');
  static bool? _mockOverrideForTesting;

  @visibleForTesting
  static void setMockForTesting(bool? value) {
    _mockOverrideForTesting = value;
  }

  static bool get useMock =>
      !kReleaseMode &&
      (_mockOverrideForTesting ??
          (_envUseMock || _envUseMockStr.toLowerCase() == 'true' || _envUseMockStr == '1'));

  // Timeout terpisah untuk menangani cold start backend
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Helper agar tidak terjadi trailing slash atau double /api
  static String _cleanUrl(String url) {
    var cleaned = url.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}
