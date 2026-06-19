import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/auth_session_storage.dart';
import 'package:sav/core/services/backend_api_service.dart';
import 'package:sav/core/services/firestore_service.dart';
import 'package:sav/features/auth/data/models/driver_model.dart';
import 'package:sav/features/auth/domain/usecases/logout_use_case.dart';
import 'package:sav/features/settings/data/models/vehicle_info.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final FirestoreService _firestoreService;
  final BackendApiService _backendApiService;
  final SharedPreferences _prefs;
  final LogoutUseCase _logoutUseCase;
  final AuthSessionStorage _authSessionStorage;

  SettingsCubit(
    this._firestoreService,
    this._backendApiService,
    this._prefs,
    this._logoutUseCase,
    this._authSessionStorage,
  ) : super(const SettingsInitial());

  Future<void> loadDriverData() async {
    emit(const SettingsLoading());

    try {
      final driverId = _resolveDriverId();
      if (driverId == null) {
        emit(const SettingsError('No driver data found. Please login again.'));
        return;
      }

      final locationGranted = await _resolveLocationPermissionStatus();
      final driver = await _resolveDriver(driverId);
      final vehicle = await _resolveVehicleInfo();
      final resolvedDriver = _mergeVehicleIntoDriver(driver, vehicle);
      final hasValidSession = await _hasValidSession(driverId);
      final selectedAlertSound =
          _prefs.getString(AppConstants.prefSelectedAlertSound) ?? 'trucksound.wav';

      emit(
        SettingsLoaded(
            driver: resolvedDriver,
            vehicle: vehicle,
          alertSoundEnabled:
              _prefs.getBool(AppConstants.prefAlertSoundEnabled) ?? true,
          selectedAlertSound: selectedAlertSound,
          vibrationEnabled:
              _prefs.getBool(AppConstants.prefVibrationEnabled) ?? true,
          notificationsEnabled:
              _prefs.getBool(AppConstants.prefNotificationsEnabled) ?? true,
          detectionIntervalMs: _resolveDetectionIntervalMs(),
          locationPermissionGranted: locationGranted,
          username:
              _prefs.getString(AppConstants.prefDriverUsername)?.trim() ?? '',
          role: _prefs.getString(AppConstants.prefDriverRole)?.trim() ?? '',
          hasValidSession: hasValidSession,
        ),
      );
    } catch (_) {
      final driverId = _resolveDriverId() ?? '';
      final locationGranted = await _resolveLocationPermissionStatus();
      final vehicle = await _resolveVehicleInfo();
      final hasValidSession = await _hasValidSession(driverId);
      final fallbackDriver = _localFallbackDriver(driverId);
      final resolvedDriver = _mergeVehicleIntoDriver(fallbackDriver, vehicle);
      final selectedAlertSound =
          _prefs.getString(AppConstants.prefSelectedAlertSound) ?? 'trucksound.wav';

      emit(
        SettingsLoaded(
          driver: resolvedDriver,
          vehicle: vehicle,
          alertSoundEnabled:
              _prefs.getBool(AppConstants.prefAlertSoundEnabled) ?? true,
          selectedAlertSound: selectedAlertSound,
          vibrationEnabled:
              _prefs.getBool(AppConstants.prefVibrationEnabled) ?? true,
          notificationsEnabled:
              _prefs.getBool(AppConstants.prefNotificationsEnabled) ?? true,
          detectionIntervalMs: _resolveDetectionIntervalMs(),
          locationPermissionGranted: locationGranted,
          username:
              _prefs.getString(AppConstants.prefDriverUsername)?.trim() ?? '',
          role: _prefs.getString(AppConstants.prefDriverRole)?.trim() ?? '',
          hasValidSession: hasValidSession,
        ),
      );
    }
  }

  Future<void> setSelectedAlertSound(String sound) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) {
      return;
    }

    await _prefs.setString(AppConstants.prefSelectedAlertSound, sound);
    emit(currentState.copyWith(selectedAlertSound: sound));
  }

  Future<void> setAlertSoundEnabled(bool enabled) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) {
      return;
    }

    await _prefs.setBool(AppConstants.prefAlertSoundEnabled, enabled);
    emit(currentState.copyWith(alertSoundEnabled: enabled));
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) {
      return;
    }

    await _prefs.setBool(AppConstants.prefVibrationEnabled, enabled);
    emit(currentState.copyWith(vibrationEnabled: enabled));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) {
      return;
    }

    await _prefs.setBool(AppConstants.prefNotificationsEnabled, enabled);
    emit(currentState.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setDetectionIntervalMs(int intervalMs) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) {
      return;
    }

    final normalizedInterval = _normalizeDetectionIntervalMs(intervalMs);

    await _prefs.setInt(AppConstants.prefDetectionInterval, normalizedInterval);
    emit(currentState.copyWith(detectionIntervalMs: normalizedInterval));
  }

  Future<void> refreshPermissionStatus() async {
    final currentState = state;
    if (currentState is! SettingsLoaded) {
      return;
    }

    final locationGranted = await _resolveLocationPermissionStatus();
    emit(currentState.copyWith(locationPermissionGranted: locationGranted));
  }

  Future<String?> signOut() async {
    final currentState = state;
    if (currentState is SettingsLoaded && currentState.isSigningOut) {
      return null;
    }

    if (currentState is SettingsLoaded) {
      emit(currentState.copyWith(isSigningOut: true));
    }

    final result = await _logoutUseCase();

    if (currentState is SettingsLoaded) {
      emit(currentState.copyWith(isSigningOut: false, hasValidSession: false));
    }

    return result.fold((failure) => failure.message.trim(), (_) => null);
  }

  String? _resolveDriverId() {
    final driverId = _prefs.getString(AppConstants.prefDriverId)?.trim();
    if (driverId == null || driverId.isEmpty) {
      return null;
    }
    return driverId;
  }

  Future<bool> _hasValidSession(String driverId) {
    if (driverId.trim().isEmpty) {
      return Future<bool>.value(false);
    }

    return _authSessionStorage.hasValidSession();
  }

  Future<DriverModel> _resolveDriver(String driverId) async {
    try {
      final doc = await _firestoreService.getDriver(driverId);
      if (!doc.exists) {
        return _localFallbackDriver(driverId);
      }

      final driver = DriverModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

      final cachedAvatar =
          _prefs.getString(AppConstants.prefDriverAvatarUrl)?.trim() ?? '';
      final profileAvatar = driver.avatarUrl?.trim() ?? '';

      final mergedDriver = profileAvatar.isNotEmpty
          ? driver
          : driver.copyWith(
              avatarUrl: cachedAvatar.isEmpty ? null : cachedAvatar,
            );

      await _cacheDriverProfile(mergedDriver);
      return mergedDriver;
    } catch (_) {
      return _localFallbackDriver(driverId);
    }
  }

  Future<VehicleInfo?> _resolveVehicleInfo() async {
    try {
      final payload = await _backendApiService.fetchAssignedVehicle();
      if (payload == null || payload.isEmpty) {
        return null;
      }

      final vehicle = VehicleInfo.fromMap(payload);
      await _cacheVehicleInfo(vehicle);
      return vehicle;
    } catch (_) {
      return null;
    }
  }

  DriverModel _mergeVehicleIntoDriver(DriverModel driver, VehicleInfo? vehicle) {
    if (vehicle == null || vehicle.plateNumber.trim().isEmpty) {
      return driver;
    }

    if (driver.vehiclePlate.trim().toUpperCase() ==
        vehicle.plateNumber.trim().toUpperCase()) {
      return driver;
    }

    return driver.copyWith(vehiclePlate: vehicle.plateNumber);
  }

  Future<void> _cacheVehicleInfo(VehicleInfo vehicle) async {
    if (vehicle.plateNumber.trim().isEmpty) {
      return;
    }

    await _prefs.setString(
      AppConstants.prefDriverVehiclePlate,
      vehicle.plateNumber.trim().toUpperCase(),
    );
  }

  DriverModel _localFallbackDriver(String driverId) {
    return DriverModel(
      id: driverId,
      name: _prefs.getString(AppConstants.prefDriverName) ?? 'Driver',
      phone: _prefs.getString(AppConstants.prefDriverPhone) ?? '',
      licenseNumber:
          _prefs.getString(AppConstants.prefDriverLicenseNumber) ?? '',
      vehiclePlate: _prefs.getString(AppConstants.prefDriverVehiclePlate) ?? '',
      companyName:
          (_prefs.getString(AppConstants.prefDriverCompanyName) ?? '')
              .trim()
              .isEmpty
          ? null
          : _prefs.getString(AppConstants.prefDriverCompanyName),
      emergencyContact:
          (_prefs.getString(AppConstants.prefDriverEmergencyContact) ?? '')
              .trim()
              .isEmpty
          ? null
          : _prefs.getString(AppConstants.prefDriverEmergencyContact),
      avatarUrl:
          (_prefs.getString(AppConstants.prefDriverAvatarUrl) ?? '')
              .trim()
              .isEmpty
          ? null
          : _prefs.getString(AppConstants.prefDriverAvatarUrl),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _cacheDriverProfile(DriverModel driver) async {
    await _prefs.setString(AppConstants.prefDriverName, driver.name);
    await _prefs.setString(AppConstants.prefDriverPhone, driver.phone);
    await _prefs.setString(
      AppConstants.prefDriverLicenseNumber,
      driver.licenseNumber,
    );
    if (driver.vehiclePlate.trim().isNotEmpty) {
      await _prefs.setString(
        AppConstants.prefDriverVehiclePlate,
        driver.vehiclePlate,
      );
    }
    await _prefs.setString(
      AppConstants.prefDriverCompanyName,
      driver.companyName ?? '',
    );
    await _prefs.setString(
      AppConstants.prefDriverEmergencyContact,
      driver.emergencyContact ?? '',
    );
    await _prefs.setString(
      AppConstants.prefDriverAvatarUrl,
      driver.avatarUrl ?? '',
    );
  }

  bool _isLocationGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }

  Future<bool> _resolveLocationPermissionStatus() async {
    try {
      final locationStatus = await Permission.locationWhenInUse.status;
      return _isLocationGranted(locationStatus);
    } catch (_) {
      return false;
    }
  }

  int _resolveDetectionIntervalMs() {
    final saved = _prefs.getInt(AppConstants.prefDetectionInterval);
    return _normalizeDetectionIntervalMs(
      saved ?? AppConstants.detectionIntervalMs,
    );
  }

  int _normalizeDetectionIntervalMs(int value) {
    const allowed = <int>[500, 750, 1000, 1250, 1500, 2000];

    var closest = allowed.first;
    var smallestDiff = (value - closest).abs();

    for (final item in allowed.skip(1)) {
      final diff = (value - item).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        closest = item;
      }
    }

    return closest;
  }
}
