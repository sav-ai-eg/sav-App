class AppConstants {
  AppConstants._();

  static const String appName = 'SAV';
  static const String fontFamily = 'Inter';

  /// Keys
  static const String googleMapsApiKey =
      'AIzaSyAYV6yWdmcUkqgb33sEXKkZMNthrHuXoUg';
  static bool get hasGoogleMapsApiKey => googleMapsApiKey.trim().isNotEmpty;
  static bool get shouldAllowMissingMapsKeyInCurrentBuild => false;
  static bool get shouldDisableLiveMapsFeatures => false;

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
  static const String prefDriverPhone = 'driverPhone';
  static const String prefDriverLicenseNumber = 'driverLicenseNumber';
  static const String prefDriverVehiclePlate = 'driverVehiclePlate';
  static const String prefDriverCompanyName = 'driverCompanyName';
  static const String prefDriverEmergencyContact = 'driverEmergencyContact';
  static const String prefDriverAvatarUrl = 'driverAvatarUrl';
  static const String prefDriverUsername = 'driverUsername';
  static const String prefDriverRole = 'driverRole';
  static const String prefNotificationsEnabled = 'notificationsEnabled';
  static const String prefAccessToken = 'accessToken';
  static const String prefRefreshToken = 'refreshToken';
  static const String prefHomeDashboardCache = 'homeDashboardCache';
  static const String prefHomeDashboardCacheAt = 'homeDashboardCacheAt';

  static const String _apiBaseUrlFromDefine = String.fromEnvironment(
    'SAV_API_BASE_URL',
  );
  static const String _defaultApiBaseUrl = 'https://sav.up.railway.app';

  static String get apiBaseUrl {
    if (_apiBaseUrlFromDefine.isEmpty) {
      return _defaultApiBaseUrl;
    }

    return _normalizeApiBaseUrl(_apiBaseUrlFromDefine);
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

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' || _isBlockedHost(uri.host)) {
      return _defaultApiBaseUrl;
    }

    final portSegment = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$portSegment';
  }

  static bool _isBlockedHost(String host) {
    final normalizedHost = host.toLowerCase().trim();

    if (normalizedHost == 'localhost' || normalizedHost == '10.0.2.2') {
      return true;
    }

    if (normalizedHost == '127.0.0.1' || normalizedHost.startsWith('127.')) {
      return true;
    }

    final octets = normalizedHost.split('.');
    if (octets.length != 4) {
      return false;
    }

    final parts = octets.map(int.tryParse).toList(growable: false);
    if (parts.any((value) => value == null || value < 0 || value > 255)) {
      return false;
    }

    final first = parts[0]!;
    final second = parts[1]!;

    if (first == 10) {
      return true;
    }

    if (first == 172 && second >= 16 && second <= 31) {
      return true;
    }

    if (first == 192 && second == 168) {
      return true;
    }

    return false;
  }

  // ─── Emergency Numbers ────────────────────────────────────
  static const String emergencyAmbulance = '123';
  static const String emergencyPolice = '122';
  static const String emergencyFire = '180';
}
