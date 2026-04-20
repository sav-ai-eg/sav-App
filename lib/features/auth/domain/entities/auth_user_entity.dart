import 'package:equatable/equatable.dart';

class AuthUserEntity extends Equatable {
  const AuthUserEntity({
    required this.id,
    required this.username,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber = '',
    this.licenseNumber = '',
    this.emergencyContactPhone = '',
    this.avatarUrl = '',
  });

  final int id;
  final String username;
  final String role;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String licenseNumber;
  final String emergencyContactPhone;
  final String avatarUrl;

  String get displayName {
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return username;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        username,
        role,
        firstName,
        lastName,
        email,
        phoneNumber,
        licenseNumber,
        emergencyContactPhone,
        avatarUrl,
      ];
}
