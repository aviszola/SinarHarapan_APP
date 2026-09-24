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
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      role: (json['role'] as String).toUpperCase() == 'MANAGER'
          ? UserRole.manager
          : UserRole.receptionist,
      token: json['token'] as String? ?? 'mock-jwt-token',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'full_name': fullName,
    'role': isManager ? 'MANAGER' : 'RECEPTIONIST',
    'token': token,
  };
}
