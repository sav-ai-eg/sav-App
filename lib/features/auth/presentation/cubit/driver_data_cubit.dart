import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/firestore_service.dart';
import 'package:sav/features/auth/data/models/driver_model.dart';
import 'package:uuid/uuid.dart';

part 'driver_data_state.dart';

@injectable
class DriverDataCubit extends Cubit<DriverDataState> {
  DriverDataCubit(this._firestoreService, this._prefs)
      : super(const DriverDataInitial());

  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;

  Future<void> saveDriverData({
    required String name,
    required String phone,
    required String licenseNumber,
    required String vehiclePlate,
    String? companyName,
    String? emergencyContact,
  }) async {
    emit(const DriverDataLoading());

    try {
      final driverId = const Uuid().v4();

      final driver = DriverModel(
        id: driverId,
        name: name,
        phone: phone,
        licenseNumber: licenseNumber,
        vehiclePlate: vehiclePlate,
        companyName: companyName,
        emergencyContact: emergencyContact,
        createdAt: DateTime.now(),
        statistics: {
          'awakePercentage': 0,
          'distractedPercentage': 0,
          'totalTrips': 0,
          'totalAlerts': 0,
        },
      );

      await _firestoreService.saveDriver(
        driverId: driverId,
        data: driver.toMap(),
      );

      // Save driver ID locally
      await _prefs.setString(AppConstants.prefDriverId, driverId);
      await _prefs.setString(AppConstants.prefDriverName, name);
      await _prefs.setString(AppConstants.prefDriverPhone, phone);
      await _prefs.setString(
        AppConstants.prefDriverLicenseNumber,
        licenseNumber,
      );
      await _prefs.setString(AppConstants.prefDriverVehiclePlate, vehiclePlate);
      await _prefs.setString(
        AppConstants.prefDriverCompanyName,
        companyName ?? '',
      );
      await _prefs.setString(
        AppConstants.prefDriverEmergencyContact,
        emergencyContact ?? '',
      );

      emit(DriverDataSaved(driver: driver));
    } catch (e) {
      emit(DriverDataError(message: e.toString()));
    }
  }

  bool get hasExistingDriver =>
      _prefs.containsKey(AppConstants.prefDriverId);

  String? get driverId =>
      _prefs.getString(AppConstants.prefDriverId);

  String? get driverName =>
      _prefs.getString(AppConstants.prefDriverName);
}
