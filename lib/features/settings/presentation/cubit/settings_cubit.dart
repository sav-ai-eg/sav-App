import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/firestore_service.dart';
import 'package:sav/features/auth/data/models/driver_model.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;

  SettingsCubit(this._firestoreService, this._prefs)
      : super(const SettingsInitial());

  Future<void> loadDriverData() async {
    emit(const SettingsLoading());

    try {
      final driverId = _prefs.getString(AppConstants.prefDriverId);
      if (driverId == null) {
        emit(const SettingsError('No driver data found'));
        return;
      }

      final doc = await _firestoreService.getDriver(driverId);
      if (!doc.exists) {
        // Fallback to local data
        emit(SettingsLoaded(driver: _localFallbackDriver(driverId)));
        return;
      }

      final driver = DriverModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      emit(SettingsLoaded(driver: driver));
    } catch (_) {
      final driverId = _prefs.getString(AppConstants.prefDriverId) ?? '';
      emit(SettingsLoaded(driver: _localFallbackDriver(driverId)));
    }
  }

  DriverModel _localFallbackDriver(String driverId) {
    return DriverModel(
      id: driverId,
      name: _prefs.getString(AppConstants.prefDriverName) ?? 'Driver',
      phone: '',
      licenseNumber: '',
      vehiclePlate: '',
      createdAt: DateTime.now(),
    );
  }

  Future<void> signOut() async {
    await _prefs.clear();
  }
}
