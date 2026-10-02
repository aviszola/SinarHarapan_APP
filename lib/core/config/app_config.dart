import 'package:flutter/foundation.dart';

class AppConfig {
  // Base URL dari --dart-define=BASE_URL=...
  // Jika tidak disetel:
  // - Pada Debug mode: default ke http://localhost:3000/api (BUKAN URL produksi!)
  // - Pada Release mode: default ke backend produksi
  static const String _envBaseUrl = String.fromEnvironment('BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _cleanUrl(_envBaseUrl);
    }
    if (kDebugMode) {
      return 'http://localhost:3000/api';
    }
    return 'https://sinar-harapan-backend-production.up.railway.app/api';
  }

  // Mock hanya boleh aktif jika kDebugMode DAN diaktifkan via --dart-define=USE_MOCK=true
  static const bool _envUseMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
  static bool get useMock => kDebugMode && _envUseMock;

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
