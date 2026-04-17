import 'package:sav/features/auth/data/models/auth_user_model.dart';
import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';

class AuthSessionModel extends AuthSessionEntity {
  const AuthSessionModel({
    required super.accessToken,
    required super.refreshToken,
    required super.user,
  });

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
