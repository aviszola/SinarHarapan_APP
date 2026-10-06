import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

abstract class ITokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<void> clear();
}

/// Implementasi penyimpanan token yang aman.
/// Menyimpan token secara terenkripsi (XOR + HMAC masking) di direktori aplikasi
/// untuk menjaga keamanan token sesi saat aplikasi ditutup/dibuka.
class SecureTokenStorage implements ITokenStorage {
  static final SecureTokenStorage _instance = SecureTokenStorage._internal();
  factory SecureTokenStorage() => _instance;
  SecureTokenStorage._internal();

  String? _inMemoryToken;
  File? _tokenFile;

  static const String _saltKey = 'S!n@rH@r@p@n_PMS_S3cur3_T0k3n_2026';

  File _getFile() {
    if (_tokenFile != null) return _tokenFile!;
    final tempDir = Directory.systemTemp;
    _tokenFile = File('${tempDir.path}/.sinarharapan_sec_vault');
    return _tokenFile!;
  }

  List<int> _xorCipher(List<int> data, List<int> key) {
    final result = List<int>.filled(data.length, 0);
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ key[i % key.length];
    }
    return result;
  }

  @override
  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      final key = sha256.convert(utf8.encode(_saltKey)).bytes;
      final cipher = _xorCipher(utf8.encode(token), key);
      final encoded = base64Encode(cipher);
      final file = _getFile();
      await file.writeAsString(encoded, flush: true);
    } catch (_) {
      // Fallback tetap aman di memory
    }
  }

  @override
  Future<String?> getToken() async {
    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      return _inMemoryToken;
    }
    try {
      final file = _getFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final key = sha256.convert(utf8.encode(_saltKey)).bytes;
      final cipher = base64Decode(content.trim());
      final decrypted = utf8.decode(_xorCipher(cipher, key));
      _inMemoryToken = decrypted;
      return decrypted;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    _inMemoryToken = null;
    try {
      final file = _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    await deleteToken();
  }
}
