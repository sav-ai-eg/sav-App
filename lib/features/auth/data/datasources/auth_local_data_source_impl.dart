import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/services/auth_session_storage.dart';
import 'package:sav/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(
    SharedPreferences preferences, {
    AuthSessionStorage? sessionStorage,
  }) : _prefs = preferences,
       _sessionStorage =
           sessionStorage ?? AuthSessionStorage(preferences: preferences);

  final SharedPreferences _prefs;
  final AuthSessionStorage _sessionStorage;

  @override
  Future<void> saveSession({required AuthSessionEntity session}) async {
    await _sessionStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    final operations = <Future<bool>>[
      _prefs.setString(AppConstants.prefDriverId, session.user.id.toString()),
      _prefs.setString(AppConstants.prefDriverName, session.user.displayName),
      _prefs.setString(AppConstants.prefDriverPhone, session.user.phoneNumber),
      _prefs.setString(
        AppConstants.prefDriverLicenseNumber,
        session.user.licenseNumber,
      ),
      _prefs.setString(
        AppConstants.prefDriverEmergencyContact,
        session.user.emergencyContactPhone,
      ),
      _prefs.setString(
        AppConstants.prefDriverAvatarUrl,
        session.user.avatarUrl,
      ),
      _prefs.setString(AppConstants.prefDriverUsername, session.user.username),
      _prefs.setString(AppConstants.prefDriverRole, session.user.role),
    ];

    final result = await Future.wait<bool>(operations);
    if (result.any((bool success) => !success)) {
      throw const CacheException('Unable to save auth session locally.');
    }
  }

  @override
  Future<String> getRefreshToken() {
    return _sessionStorage.getRefreshToken();
  }

  @override
  Future<void> clearSession() async {
    try {
      await _sessionStorage.clearSession();
    } catch (_) {
      throw const CacheException('Unable to clear auth session locally.');
    }
  }
}
