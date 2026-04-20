import 'package:sav/features/auth/domain/entities/auth_user_entity.dart';

class AuthUserModel extends AuthUserEntity {
  const AuthUserModel({
    required super.id,
    required super.username,
    required super.role,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.phoneNumber,
    super.licenseNumber,
    super.emergencyContactPhone,
    super.avatarUrl,
  });

  factory AuthUserModel.fromMap(Map<String, dynamic> map) {
    return AuthUserModel(
      id: _toInt(map['id']),
      username: (map['username'] ?? '').toString(),
      role: (map['role'] ?? '').toString(),
      firstName: (map['first_name'] ?? '').toString(),
      lastName: (map['last_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phoneNumber: (map['phone_number'] ?? '').toString(),
      licenseNumber: (map['license_number'] ?? '').toString(),
      emergencyContactPhone: (map['emergency_contact_phone'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] ?? map['avatarUrl'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
