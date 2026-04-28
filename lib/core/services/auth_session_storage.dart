import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';

class AuthSessionStorage {
  AuthSessionStorage({
    required SharedPreferences preferences,
    FlutterSecureStorage? secureStorage,
  }) : _prefs = preferences,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  static const List<String> _cachedSessionPreferenceKeys = <String>[
    AppConstants.prefDriverId,
    AppConstants.prefDriverName,
    AppConstants.prefDriverPhone,
    AppConstants.prefDriverLicenseNumber,
    AppConstants.prefDriverVehiclePlate,
    AppConstants.prefDriverCompanyName,
    AppConstants.prefDriverEmergencyContact,
    AppConstants.prefDriverAvatarUrl,
    AppConstants.prefDriverUsername,
    AppConstants.prefDriverRole,
    AppConstants.prefAlertSoundEnabled,
    AppConstants.prefVibrationEnabled,
    AppConstants.prefDetectionInterval,
    AppConstants.prefNotificationsEnabled,
  ];

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final normalizedAccessToken = accessToken.trim();
    final normalizedRefreshToken = refreshToken.trim();

    var wroteToSecureStorage = false;
    try {
      await Future.wait<void>(<Future<void>>[
        _secureStorage.write(
          key: AppConstants.secureAccessToken,
          value: normalizedAccessToken,
        ),
        _secureStorage.write(
          key: AppConstants.secureRefreshToken,
          value: normalizedRefreshToken,
        ),
      ]);
      wroteToSecureStorage = true;
    } catch (_) {
      wroteToSecureStorage = false;
    }

    if (wroteToSecureStorage) {
      await _clearLegacyTokenPreferences();
      return;
    }

    await Future.wait<bool>(<Future<bool>>[
      _prefs.setString(AppConstants.prefAccessToken, normalizedAccessToken),
      _prefs.setString(AppConstants.prefRefreshToken, normalizedRefreshToken),
    ]);
  }

  Future<void> saveRefreshedTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final normalizedAccessToken = accessToken.trim();
    final normalizedRefreshToken = refreshToken?.trim() ?? '';

    var wroteToSecureStorage = false;
    try {
      await _secureStorage.write(
        key: AppConstants.secureAccessToken,
        value: normalizedAccessToken,
      );

      if (normalizedRefreshToken.isNotEmpty) {
        await _secureStorage.write(
          key: AppConstants.secureRefreshToken,
          value: normalizedRefreshToken,
        );
      }

      wroteToSecureStorage = true;
    } catch (_) {
      wroteToSecureStorage = false;
    }

    if (wroteToSecureStorage) {
      await _clearLegacyTokenPreferences();
      return;
    }

    await _prefs.setString(AppConstants.prefAccessToken, normalizedAccessToken);
    if (normalizedRefreshToken.isNotEmpty) {
      await _prefs.setString(AppConstants.prefRefreshToken, normalizedRefreshToken);
    }
  }

  Future<String> getAccessToken() {
    return _readSecureOrMigrateToken(
      secureKey: AppConstants.secureAccessToken,
      legacyPreferenceKey: AppConstants.prefAccessToken,
    );
  }

  Future<String> getRefreshToken() {
    return _readSecureOrMigrateToken(
      secureKey: AppConstants.secureRefreshToken,
      legacyPreferenceKey: AppConstants.prefRefreshToken,
    );
  }

  Future<bool> hasValidSession() async {
    try {
      final driverId =
          _prefs.getString(AppConstants.prefDriverId)?.trim() ?? '';
      if (driverId.isEmpty) {
        return false;
      }

      final accessToken = await getAccessToken();
      if (_isJwtNotExpired(accessToken)) {
        return true;
      }

      final refreshToken = await getRefreshToken();
      return _isJwtNotExpired(refreshToken);
    } catch (_) {
      return false;
    }
  }

  Future<void> clearTokens() async {
    try {
      await Future.wait<void>(<Future<void>>[
        _secureStorage.delete(key: AppConstants.secureAccessToken),
        _secureStorage.delete(key: AppConstants.secureRefreshToken),
      ]);
    } catch (_) {
      // Legacy preferences are still cleared below so sign-out can complete.
    }

    await _clearLegacyTokenPreferences();
  }

  Future<void> clearSession() async {
    await clearTokens();
    await Future.wait<bool>(_cachedSessionPreferenceKeys.map(_prefs.remove));
  }

  Future<String> _readSecureOrMigrateToken({
    required String secureKey,
    required String legacyPreferenceKey,
  }) async {
    try {
      final secureValue = await _secureStorage.read(key: secureKey);
      final normalizedSecureValue = secureValue?.trim() ?? '';
      if (normalizedSecureValue.isNotEmpty) {
        return normalizedSecureValue;
      }
    } catch (_) {
      // Fall back to the legacy cache if the platform secure store is not ready.
    }

    final legacyValue = _prefs.getString(legacyPreferenceKey)?.trim() ?? '';
    if (legacyValue.isEmpty) {
      return '';
    }

    try {
      await _secureStorage.write(key: secureKey, value: legacyValue);
      await _prefs.remove(legacyPreferenceKey);
    } catch (_) {
      // Keep the legacy token usable for this run if migration fails.
    }

    return legacyValue;
  }

  Future<void> _clearLegacyTokenPreferences() async {
    await Future.wait<bool>(<Future<bool>>[
      _prefs.remove(AppConstants.prefAccessToken),
      _prefs.remove(AppConstants.prefRefreshToken),
    ]);
  }

  bool _isJwtNotExpired(String token) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return false;
    }

    try {
      final parts = normalizedToken.split('.');
      if (parts.length != 3) {
        return false;
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      if (payload is! Map<String, dynamic>) {
        return false;
      }

      final exp = payload['exp'];
      final expSeconds = exp is num ? exp.toInt() : int.tryParse('$exp');
      if (expSeconds == null) {
        return true;
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000);
      return expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 1)));
    } catch (_) {
      return false;
    }
  }
}
