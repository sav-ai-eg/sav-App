import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession({required AuthSessionEntity session});

  Future<String> getRefreshToken();

  Future<void> clearSession();
}
