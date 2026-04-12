class AppConstants {
  AppConstants._();

  static const String appName = 'SAV';
  static const String fontFamily = 'Inter';

  /// Keys
  static const String googleMapsKey = 'AIzaSyAYV6yWdmcUkqgb33sEXKkZMNthrHuXoUg';
  static const int placesQueryMinLength = 2;
  static const int placesQueryDebounceMs = 350;
  static const int placesSuggestionsLimit = 5;
  static const Duration tripLocationPushInterval = Duration(seconds: 10);

  static const String eyeModelAsset = 'assets/models/best_eye.tflite';
  static const String yawnModelAsset = 'assets/models/best_yawn.tflite';
  static const int modelInputSize = 320;
  static const int modelNumChannels = 3;

  // ─── Detection Settings ───────────────────────────────────
  static const int detectionIntervalMs = 1000; // 1 second between frames
  static const int alertCooldownMs = 5000; // min 5s between alerts
  static const double detectionConfidenceThreshold = 0.5;

  // ─── Offline Sync ─────────────────────────────────────────
  static const String pendingAlertsBox = 'pending_alerts';
  static const String pendingLocationsBox = 'pending_locations';
  static const String appSettingsBox = 'app_settings';

  // ─── SharedPreferences Keys ───────────────────────────────
  static const String prefAlertSoundEnabled = 'alertSoundEnabled';
  static const String prefVibrationEnabled = 'vibrationEnabled';
  static const String prefDetectionInterval = 'detectionInterval';
  static const String prefDriverId = 'driverId';
  static const String prefDriverName = 'driverName';
  static const String prefDriverUsername = 'driverUsername';
  static const String prefDriverRole = 'driverRole';
  static const String prefAccessToken = 'accessToken';
  static const String prefRefreshToken = 'refreshToken';

  static const String _apiBaseUrlFromDefine =
      String.fromEnvironment('SAV_API_BASE_URL');
  static const String _defaultApiBaseUrl = 'https://sav.up.railway.app';

  static String get apiBaseUrl {
    if (_apiBaseUrlFromDefine.isNotEmpty) {
      return _normalizeApiBaseUrl(_apiBaseUrlFromDefine);
    }

    return _defaultApiBaseUrl;
  }

  static String _normalizeApiBaseUrl(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) {
      return _defaultApiBaseUrl;
    }

    Uri? uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty || uri.scheme.isEmpty) {
      uri = Uri.tryParse('https://$raw');
    }

    if (uri == null || uri.host.isEmpty || uri.scheme.isEmpty) {
      return _defaultApiBaseUrl;
    }

    final portSegment = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portSegment';
  }

  // ─── Emergency Numbers ────────────────────────────────────
  static const String emergencyAmbulance = '123';
  static const String emergencyPolice = '122';
  static const String emergencyFire = '180';
}
