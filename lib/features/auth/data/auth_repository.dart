import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _api.post('/auth/login', body: {
        'username': username.trim(),
        'password': password,
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
    final username = role == UserRole.receptionist ? 'resepsionis01' : 'manager01';
    final password = role == UserRole.receptionist ? 'Resepsionis123!' : 'Manager123!';
    return login(username: username, password: password);
  }

  /// Logout: hapus token lokal terlebih dahulu,
  /// kemudian panggil POST /auth/logout secara best-effort (abaikan jika gagal/404).
  Future<void> logout() async {
    await _api.setToken(null);
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Abaikan jika endpoint 404 atau server unreachable, token lokal sudah dihapus
    }
  }

  /// Cek apakah ada token tersimpan di secure storage saat inisialisasi aplikasi
  Future<String?> getSavedToken() async {
    await _api.init();
    return _api.token;
  }
}
