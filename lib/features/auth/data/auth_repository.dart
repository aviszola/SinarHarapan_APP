import '../domain/user_model.dart';

class AuthRepository {
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 'usr-001',
      'username': 'receptionist',
      'password': 'password123',
      'full_name': 'Siti Rahmawati',
      'role': 'RECEPTIONIST',
    },
    {
      'id': 'usr-002',
      'username': 'manager',
      'password': 'password123',
      'full_name': 'Hendra Wijaya',
      'role': 'MANAGER',
    },
  ];

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    // Simulate slight network latency
    await Future.delayed(const Duration(milliseconds: 350));

    final cleanUser = username.trim().toLowerCase();
    final matched = _mockUsers.firstWhere(
      (u) =>
          (u['username'] as String).toLowerCase() == cleanUser &&
          u['password'] == password,
      orElse: () => {},
    );

    if (matched.isEmpty) {
      throw Exception('Kredensial tidak valid. Gunakan akun receptionist atau manager.');
    }

    return UserModel.fromJson({
      ...matched,
      'token': 'sh_jwt_${matched['id']}_${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  Future<UserModel> loginAsQuickRole(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final username = role == UserRole.receptionist ? 'receptionist' : 'manager';
    return login(username: username, password: 'password123');
  }
}
