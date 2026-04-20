import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> saveSession({required AuthSessionEntity session}) async {
    final operations = <Future<bool>>[
      _prefs.setString(AppConstants.prefAccessToken, session.accessToken),
      _prefs.setString(AppConstants.prefRefreshToken, session.refreshToken),
      _prefs.setString(AppConstants.prefDriverId, session.user.id.toString()),
      _prefs.setString(AppConstants.prefDriverName, session.user.displayName),
      _prefs.setString(AppConstants.prefDriverUsername, session.user.username),
      _prefs.setString(AppConstants.prefDriverRole, session.user.role),
    ];

    final result = await Future.wait<bool>(operations);
    if (result.any((bool success) => !success)) {
      throw const CacheException('Unable to save auth session locally.');
    }
  }

  @override
  String getRefreshToken() {
    return _prefs.getString(AppConstants.prefRefreshToken)?.trim() ?? '';
  }

  @override
  Future<void> clearSession() async {
    final operations = <Future<bool>>[
      _prefs.remove(AppConstants.prefAccessToken),
      _prefs.remove(AppConstants.prefRefreshToken),
      _prefs.remove(AppConstants.prefDriverId),
      _prefs.remove(AppConstants.prefDriverName),
      _prefs.remove(AppConstants.prefDriverPhone),
      _prefs.remove(AppConstants.prefDriverLicenseNumber),
      _prefs.remove(AppConstants.prefDriverVehiclePlate),
      _prefs.remove(AppConstants.prefDriverCompanyName),
      _prefs.remove(AppConstants.prefDriverEmergencyContact),
      _prefs.remove(AppConstants.prefDriverUsername),
      _prefs.remove(AppConstants.prefDriverRole),
      _prefs.remove(AppConstants.prefAlertSoundEnabled),
      _prefs.remove(AppConstants.prefVibrationEnabled),
      _prefs.remove(AppConstants.prefDetectionInterval),
      _prefs.remove(AppConstants.prefNotificationsEnabled),
    ];

    final result = await Future.wait<bool>(operations);
    if (result.any((bool success) => !success)) {
      throw const CacheException('Unable to clear auth session locally.');
    }
  }
}
