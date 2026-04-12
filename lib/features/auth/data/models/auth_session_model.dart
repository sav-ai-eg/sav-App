import 'package:sav/features/auth/data/models/auth_user_model.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUserModel user;

  factory AuthSessionModel.fromMap(Map<String, dynamic> map) {
    return AuthSessionModel(
      accessToken: (map['access'] ?? '').toString(),
      refreshToken: (map['refresh'] ?? '').toString(),
      user: AuthUserModel.fromMap(
        (map['user'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}
