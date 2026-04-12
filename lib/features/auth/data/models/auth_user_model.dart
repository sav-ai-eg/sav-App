class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final int id;
  final String username;
  final String role;
  final String firstName;
  final String lastName;
  final String email;

  String get displayName {
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return username;
  }

  factory AuthUserModel.fromMap(Map<String, dynamic> map) {
    return AuthUserModel(
      id: _toInt(map['id']),
      username: (map['username'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      firstName: (map['first_name'] ?? '').toString(),
      lastName: (map['last_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
