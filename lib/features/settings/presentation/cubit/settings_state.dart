import 'package:sav/features/auth/data/models/driver_model.dart';
import 'package:sav/features/settings/data/models/vehicle_info.dart';

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
  final VehicleInfo? vehicle;
  final bool alertSoundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final int detectionIntervalMs;
  final bool locationPermissionGranted;
  final String username;
  final String role;
  final bool hasValidSession;
  final bool isSigningOut;

  const SettingsLoaded({
    required this.driver,
    this.vehicle,
    required this.alertSoundEnabled,
    required this.vibrationEnabled,
    required this.notificationsEnabled,
    required this.detectionIntervalMs,
    required this.locationPermissionGranted,
    required this.username,
    required this.role,
    required this.hasValidSession,
    this.isSigningOut = false,
  });

  SettingsLoaded copyWith({
    DriverModel? driver,
    VehicleInfo? vehicle,
    bool? alertSoundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    int? detectionIntervalMs,
    bool? locationPermissionGranted,
    String? username,
    String? role,
    bool? hasValidSession,
    bool? isSigningOut,
  }) {
    return SettingsLoaded(
      driver: driver ?? this.driver,
      vehicle: vehicle ?? this.vehicle,
      alertSoundEnabled: alertSoundEnabled ?? this.alertSoundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      detectionIntervalMs: detectionIntervalMs ?? this.detectionIntervalMs,
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
