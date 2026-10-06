import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// Error code standar dari backend (backend.md §5.4)
enum ApiErrorCode {
  unauthorized,    // 401 UNAUTHORIZED
  forbidden,       // 403 FORBIDDEN
  validationError, // 400 VALIDATION_ERROR
  notFound,        // 404 NOT_FOUND
  conflict,        // 409 CONFLICT
  rateLimited,     // 429 RATE_LIMITED
  externalServiceError, // 502 EXTERNAL_SERVICE_ERROR
  internalError,   // 500 INTERNAL_ERROR
  networkError,    // tidak ada koneksi
  timeout,
  unknown,
}

ApiErrorCode _parseErrorCode(String? code, int statusCode) {
  switch (code) {
    case 'UNAUTHORIZED': return ApiErrorCode.unauthorized;
    case 'FORBIDDEN': return ApiErrorCode.forbidden;
    case 'VALIDATION_ERROR': return ApiErrorCode.validationError;
    case 'NOT_FOUND': return ApiErrorCode.notFound;
    case 'CONFLICT': return ApiErrorCode.conflict;
    case 'RATE_LIMITED': return ApiErrorCode.rateLimited;
    case 'EXTERNAL_SERVICE_ERROR': return ApiErrorCode.externalServiceError;
    case 'INTERNAL_ERROR': return ApiErrorCode.internalError;
    default:
      if (statusCode == 401) return ApiErrorCode.unauthorized;
      if (statusCode == 403) return ApiErrorCode.forbidden;
      if (statusCode == 400) return ApiErrorCode.validationError;
      if (statusCode == 404) return ApiErrorCode.notFound;
      if (statusCode == 409) return ApiErrorCode.conflict;
      if (statusCode == 429) return ApiErrorCode.rateLimited;
      return ApiErrorCode.unknown;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorCode code;
  final dynamic fields;

  ApiException(this.message, {this.statusCode, this.code = ApiErrorCode.unknown, this.fields});

  bool get isUnauthorized => code == ApiErrorCode.unauthorized;
  bool get isForbidden => code == ApiErrorCode.forbidden;
  bool get isConflict => code == ApiErrorCode.conflict;
  bool get isRateLimited => code == ApiErrorCode.rateLimited;

  @override
  String toString() => message;
}

/// Singleton HTTP client yang mengelola token, envelope parsing,
/// interceptor 401 → refresh → retry, dan indikator cold start.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = SecureTokenStorage();
  final _httpClient = http.Client();

  String? _tokenCache;
  bool _isRefreshing = false;

  // Callback untuk memaksa logout dari UI (di-set oleh AuthNotifier)
  void Function()? _onForceLogout;
  void setForceLogoutCallback(void Function() cb) => _onForceLogout = cb;

  Future<void> init() async {
    _tokenCache = await _storage.getToken();
  }

  Future<void> setToken(String? token) async {
    _tokenCache = token;
    if (token != null) {
      await _storage.saveToken(token);
    } else {
      await _storage.deleteToken();
    }
  }

  String? get token => _tokenCache;

  Map<String, String> _headers({bool isMultipart = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (!isMultipart) h['Content-Type'] = 'application/json';
    final t = _tokenCache;
    if (t != null && t.isNotEmpty) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? q]) {
    // Pastikan tidak ada /api ganda dan tidak ada trailing slash
    var clean = path.startsWith('/') ? path.substring(1) : path;
    final base = Uri.parse('${AppConfig.baseUrl}/$clean');
    if (q != null && q.isNotEmpty) {
      final sp = q.map((k, v) => MapEntry(k, v?.toString() ?? ''))
        ..removeWhere((_, v) => v.isEmpty);
      return base.replace(queryParameters: sp);
    }
    return base;
  }

  /// Membuka envelope {success, data, meta} dari backend.
  /// Parse error {success:false, error:{code, message, fields}} ke ApiException.
  dynamic _unwrap(http.Response resp) {
    dynamic body;
    try {
      body = jsonDecode(resp.body);
    } catch (_) {
      body = resp.body;
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (body is Map<String, dynamic>) {
        // Buka envelope {success, data, meta}
        if (body['success'] == true && body.containsKey('data')) {
          return body['data'];
        }
        return body;
      }
      return body;
    }

    // Parse error dari backend
    String msg = 'Terjadi kesalahan (HTTP ${resp.statusCode})';
    String? code;
    dynamic fields;

    if (body is Map<String, dynamic> && body['error'] is Map) {
      final err = body['error'] as Map<String, dynamic>;
      msg = err['message']?.toString() ?? msg;
      code = err['code']?.toString();
      fields = err['fields'];
    } else if (body is Map<String, dynamic> && body['message'] != null) {
      msg = body['message'].toString();
    }

    throw ApiException(
      msg,
      statusCode: resp.statusCode,
      code: _parseErrorCode(code, resp.statusCode),
      fields: fields,
    );
  }

  /// Coba refresh token sekali, lalu retry request semula.
  /// Jika refresh gagal, paksa logout.
  Future<dynamic> _tryRefreshAndRetry(Future<http.Response> Function() retryFn) async {
    if (_isRefreshing) {
      _onForceLogout?.call();
      throw ApiException('Sesi berakhir. Silakan login kembali.',
          code: ApiErrorCode.unauthorized);
    }
    _isRefreshing = true;
    try {
      final refreshed = await _refreshToken();
      if (!refreshed) {
        _onForceLogout?.call();
        throw ApiException('Sesi berakhir. Silakan login kembali.',
            code: ApiErrorCode.unauthorized);
      }
      final resp = await retryFn().timeout(AppConfig.receiveTimeout);
      return _unwrap(resp);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final uri = _buildUri('/auth/refresh');
      final resp = await _httpClient
          .post(uri, headers: _headers())
          .timeout(AppConfig.connectTimeout);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final newToken = body['data']?['token']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await setToken(newToken);
          return true;
        }
      }
    } catch (_) {}
    await setToken(null);
    return false;
  }

  bool _isAuthPath(String path) {
    final clean = path.startsWith('/') ? path : '/$path';
    return clean.startsWith('/auth/');
  }

  Future<dynamic> _execute(
    Future<http.Response> Function() call, {
    bool isGet = false,
    bool allowRefresh = true,
  }) async {
    try {
      http.Response resp;
      try {
        resp = await call().timeout(AppConfig.connectTimeout);
      } on TimeoutException {
        throw ApiException('Koneksi ke server timeout. Server mungkin sedang dalam proses start-up, coba lagi sebentar.',
            code: ApiErrorCode.timeout);
      }

      // Interceptor 401: refresh sekali, retry (hanya untuk endpoint non-auth dengan token aktif)
      if (resp.statusCode == 401 &&
          allowRefresh &&
          _tokenCache != null &&
          _tokenCache!.isNotEmpty) {
        return _tryRefreshAndRetry(() => call());
      }

      return _unwrap(resp);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          code: ApiErrorCode.networkError);
    } on TimeoutException {
      throw ApiException('Koneksi ke server timeout. Server mungkin sedang dalam proses start-up, coba lagi sebentar.',
          code: ApiErrorCode.timeout);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Kesalahan tidak terduga: $e', code: ApiErrorCode.unknown);
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    if (kDebugMode) debugPrint('[API] GET $path $queryParams');
    return _execute(
      () => _httpClient.get(_buildUri(path, queryParams), headers: _headers()),
      isGet: true,
      allowRefresh: !_isAuthPath(path),
    );
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    if (kDebugMode) debugPrint('[API] POST $path');
    return _execute(
      () => _httpClient.post(
        _buildUri(path),
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
      allowRefresh: !_isAuthPath(path),
    );
  }

  Future<dynamic> patch(String path, {dynamic body}) async {
    if (kDebugMode) debugPrint('[API] PATCH $path');
    return _execute(
      () => _httpClient.patch(
        _buildUri(path),
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
      allowRefresh: !_isAuthPath(path),
    );
  }

  Future<dynamic> delete(String path) async {
    if (kDebugMode) debugPrint('[API] DELETE $path');
    return _execute(
      () => _httpClient.delete(_buildUri(path), headers: _headers()),
      allowRefresh: !_isAuthPath(path),
    );
  }

  @visibleForTesting
  MediaType resolveMediaTypeForTesting(String filename, List<int> bytes) => _resolveMediaType(filename, bytes);

  MediaType _resolveMediaType(String filename, List<int> bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return MediaType('image', 'jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return MediaType('image', 'png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return MediaType('image', 'webp');
    }
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  /// Upload multipart/form-data — untuk OCR extract-identity (endpoint.md §4.1: field 'image')
  Future<dynamic> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String filename,
    required Map<String, String> fields,
    String fileFieldName = 'image',
  }) async {
    if (kDebugMode) debugPrint('[API] POST multipart $path ($filename)');
    final uri = _buildUri(path);
    final mediaType = _resolveMediaType(filename, fileBytes);

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers(isMultipart: true))
      ..fields.addAll(fields)
      ..files.add(http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: filename,
        contentType: mediaType,
      ));
    try {
      final streamedResp = await request.send().timeout(AppConfig.connectTimeout);
      final resp = await http.Response.fromStream(streamedResp);
      if (resp.statusCode == 401) {
        return _tryRefreshAndRetry(() async {
          final r2 = http.MultipartRequest('POST', uri)
            ..headers.addAll(_headers(isMultipart: true))
            ..fields.addAll(fields)
            ..files.add(http.MultipartFile.fromBytes(
              fileFieldName,
              fileBytes,
              filename: filename,
              contentType: mediaType,
            ));
          final s = await r2.send().timeout(AppConfig.connectTimeout);
          return http.Response.fromStream(s);
        });
      }
      return _unwrap(resp);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server.', code: ApiErrorCode.networkError);
    } on TimeoutException {
      throw ApiException('Upload timeout.', code: ApiErrorCode.timeout);
    }
  }

  /// Unduh binary file (Excel/PDF) — tidak melewati ResponseInterceptor backend
  Future<List<int>> downloadBytes(String path, {Map<String, dynamic>? queryParams}) async {
    if (kDebugMode) debugPrint('[API] GET binary $path');
    try {
      final resp = await _httpClient
          .get(_buildUri(path, queryParams), headers: _headers())
          .timeout(AppConfig.receiveTimeout);
      if (resp.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (!refreshed) {
          _onForceLogout?.call();
          throw ApiException('Sesi berakhir.', code: ApiErrorCode.unauthorized);
        }
        final resp2 = await _httpClient
            .get(_buildUri(path, queryParams), headers: _headers())
            .timeout(AppConfig.receiveTimeout);
        if (resp2.statusCode != 200) _unwrap(resp2);
        return resp2.bodyBytes;
      }
      if (resp.statusCode != 200) _unwrap(resp);
      return resp.bodyBytes;
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server.', code: ApiErrorCode.networkError);
    } on TimeoutException {
      throw ApiException('Download timeout.', code: ApiErrorCode.timeout);
    }
  }
}
