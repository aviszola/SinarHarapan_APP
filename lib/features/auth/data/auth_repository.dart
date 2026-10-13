import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  // Kredensial pengembangan disuplai via --dart-define atau file lokal dev_credentials.json (gitignored).
  // Di mode rilis (kReleaseMode), seluruh jalur kredensial dev dinonaktifkan secara total.
  static const String _envRecUser = String.fromEnvironment('DEV_RECEPTIONIST_USER');
  static const String _envRecPass = String.fromEnvironment('DEV_RECEPTIONIST_PASS');
  static const String _envMgrUser = String.fromEnvironment('DEV_MANAGER_USER');
  static const String _envMgrPass = String.fromEnvironment('DEV_MANAGER_PASS');

  static Map<String, String>? _cachedLocalDevCreds;

  static String _getDevCred(String key, String envValue) {
    if (kReleaseMode) return '';
    if (envValue.isNotEmpty) return envValue;
    if (_cachedLocalDevCreds == null) {
      try {
        final f = File('dev_credentials.json');
        if (f.existsSync()) {
          final data = jsonDecode(f.readAsStringSync());
          if (data is Map) {
            _cachedLocalDevCreds = data.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        }
      } catch (_) {
        _cachedLocalDevCreds = {};
      }
      _cachedLocalDevCreds ??= {};
    }
    return _cachedLocalDevCreds![key] ?? '';
  }

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    if (AppConfig.useMock) {
      throw ApiException('Mode mock: gunakan tombol Mode Pengembangan');
    }

    var cleanUsername = username.trim();
    var cleanPassword = password;

    if (!kReleaseMode) {
      final devRecUser = _getDevCred('DEV_RECEPTIONIST_USER', _envRecUser);
      final devRecPass = _getDevCred('DEV_RECEPTIONIST_PASS', _envRecPass);
      final devMgrUser = _getDevCred('DEV_MANAGER_USER', _envMgrUser);
      final devMgrPass = _getDevCred('DEV_MANAGER_PASS', _envMgrPass);

      final lowerUser = cleanUsername.toLowerCase();
      if ((lowerUser == 'manager' || lowerUser == 'admin') && devMgrUser.isNotEmpty) {
        cleanUsername = devMgrUser;
        if ((cleanPassword == 'password123' ||
                cleanPassword == 'manager' ||
                cleanPassword == 'admin') &&
            devMgrPass.isNotEmpty) {
          cleanPassword = devMgrPass;
        }
      } else if ((lowerUser == 'resepsionis' || lowerUser == 'receptionist') &&
          devRecUser.isNotEmpty) {
        cleanUsername = devRecUser;
        if ((cleanPassword == 'password123' ||
                cleanPassword == 'resepsionis') &&
            devRecPass.isNotEmpty) {
          cleanPassword = devRecPass;
        }
      }
    }

    try {
      final res = await _api.post('/auth/login', body: {
        'username': cleanUsername,
        'password': cleanPassword,
      });

      if (res is Map<String, dynamic>) {
        final user = UserModel.fromJson(res);
        await _api.setToken(user.token);
        return user;
      }
      throw ApiException('Format respons backend tidak sesuai');
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.rateLimited || e.statusCode == 429) {
        throw ApiException('Terlalu banyak percobaan login. Silakan tunggu beberapa saat.',
            code: ApiErrorCode.rateLimited);
      }
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<UserModel> quickLogin(UserRole role) async {
    if (kReleaseMode) {
      throw UnsupportedError('Quick login tidak diizinkan pada build release');
    }

    if (AppConfig.useMock) {
      final isRec = role == UserRole.receptionist;
      final user = UserModel(
        id: isRec ? 'mock-rec-01' : 'mock-mgr-01',
        username: isRec ? 'resepsionis' : 'manager',
        fullName: isRec ? 'Resepsionis (Mode Mock)' : 'Manajer (Mode Mock)',
        role: role,
        token: 'mock-jwt-token-no-network',
      );
      await _api.setToken(user.token);
      return user;
    }

    final isRec = role == UserRole.receptionist;
    final username = isRec
        ? _getDevCred('DEV_RECEPTIONIST_USER', _envRecUser)
        : _getDevCred('DEV_MANAGER_USER', _envMgrUser);
    final password = isRec
        ? _getDevCred('DEV_RECEPTIONIST_PASS', _envRecPass)
        : _getDevCred('DEV_MANAGER_PASS', _envMgrPass);

    if (username.isEmpty || password.isEmpty) {
      throw UnsupportedError('Kredensial dev belum dikonfigurasi');
    }
    return login(username: username, password: password);
  }

  /// Logout (endpoint.md §2.3):
  /// Mengirim POST /auth/logout dengan token aktif ke server,
  /// lalu selalu menghapus token lokal di blok finally.
  Future<void> logout() async {
    if (AppConfig.useMock) {
      await _api.setToken(null);
      return;
    }
    try {
      if (_api.token != null && _api.token!.isNotEmpty) {
        await _api.post('/auth/logout');
      }
    } catch (_) {
      // Abaikan jika network error atau server 404/500, token lokal tetap dihapus
    } finally {
      await _api.setToken(null);
    }
  }
}
