import 'package:sav/features/auth/data/models/driver_model.dart';

abstract class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final DriverModel driver;
  final bool alertSoundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final int detectionIntervalMs;
  final bool cameraPermissionGranted;
  final bool locationPermissionGranted;
  final String username;
  final String role;
  final bool hasValidSession;
  final bool isSigningOut;

  const SettingsLoaded({
    required this.driver,
    required this.alertSoundEnabled,
    required this.vibrationEnabled,
    required this.notificationsEnabled,
    required this.detectionIntervalMs,
    required this.cameraPermissionGranted,
    required this.locationPermissionGranted,
    required this.username,
    required this.role,
    required this.hasValidSession,
    this.isSigningOut = false,
  });

  SettingsLoaded copyWith({
    DriverModel? driver,
    bool? alertSoundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    int? detectionIntervalMs,
    bool? cameraPermissionGranted,
    bool? locationPermissionGranted,
    String? username,
    String? role,
    bool? hasValidSession,
    bool? isSigningOut,
  }) {
    return SettingsLoaded(
      driver: driver ?? this.driver,
      alertSoundEnabled: alertSoundEnabled ?? this.alertSoundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      detectionIntervalMs: detectionIntervalMs ?? this.detectionIntervalMs,
      cameraPermissionGranted:
          cameraPermissionGranted ?? this.cameraPermissionGranted,
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
      username: username ?? this.username,
      role: role ?? this.role,
      hasValidSession: hasValidSession ?? this.hasValidSession,
      isSigningOut: isSigningOut ?? this.isSigningOut,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}
