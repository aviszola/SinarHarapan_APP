enum UserRole { receptionist, manager }

class UserModel {
  final String id;
  final String username;
  final String fullName;
  final UserRole role;
  final String token;

  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.token,
  });

  bool get isReceptionist => role == UserRole.receptionist;
  bool get isManager => role == UserRole.manager;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Bentuk respons dari POST /auth/login (backend.md §2.1 & endpoint.md §2.1):
    // {
    //   "token": "...",
    //   "expiresIn": 43200,
    //   "user": { "id": "...", "fullName": "...", "role": "RECEPTIONIST" | "MANAGER" }
    // }
    final userMap = (json['user'] is Map<String, dynamic>)
        ? json['user'] as Map<String, dynamic>
        : json;

    final tokenVal = json['token']?.toString() ?? userMap['token']?.toString();
    if (tokenVal == null || tokenVal.isEmpty) {
      throw FormatException('Token tidak ditemukan pada respons login backend');
    }

    final roleStr = (userMap['role']?.toString() ?? '').toUpperCase();
    final role = roleStr == 'MANAGER' ? UserRole.manager : UserRole.receptionist;

    return UserModel(
      id: userMap['id']?.toString() ?? '',
      username: userMap['username']?.toString() ?? '',
      fullName: userMap['fullName']?.toString() ?? userMap['full_name']?.toString() ?? '',
      role: role,
      token: tokenVal,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'role': isManager ? 'MANAGER' : 'RECEPTIONIST',
    'token': token,
  };
}
