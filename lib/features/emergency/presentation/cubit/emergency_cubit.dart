import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/firestore_service.dart';
import 'package:sav/core/services/location_service.dart';

part 'emergency_state.dart';

enum EmergencyType {
  medical,
  police,
  fire,
  fleetManager,
}

@injectable
class EmergencyCubit extends Cubit<EmergencyState> {
  EmergencyCubit(
    this._firestoreService,
    this._connectivity,
    this._locationService,
    this._prefs,
  ) : super(const EmergencyInitial());

  final FirestoreService _firestoreService;
  final ConnectivityService _connectivity;
  final LocationService _locationService;
  final SharedPreferences _prefs;
  EmergencyType? selectedType;

  void selectType(EmergencyType type) {
    selectedType = type;
    emit(EmergencyTypeSelected(type));
  }

  /// Get the phone number for a given emergency type.
  String _phoneForType(EmergencyType type) {
    switch (type) {
      case EmergencyType.medical:
        return AppConstants.emergencyAmbulance;
      case EmergencyType.police:
        return AppConstants.emergencyPolice;
      case EmergencyType.fire:
        return AppConstants.emergencyFire;
      case EmergencyType.fleetManager:
        final contact = _prefs.getString('emergencyContact');
        return contact ?? AppConstants.emergencyPolice;
    }
  }

  /// Place a phone call to the emergency number.
  Future<void> callEmergency(EmergencyType type) async {
    final phone = _phoneForType(type);
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('❌ Cannot launch phone dialer');
      }
    } catch (e) {
      debugPrint('❌ EmergencyCubit.callEmergency error: $e');
    }
  }

  /// Trigger full emergency: save to Firestore + call.
  Future<void> triggerEmergency() async {
    if (selectedType == null) return;

    emit(const EmergencyLoading());

    try {
      final driverId = _prefs.getString(AppConstants.prefDriverId);
      final driverName = _prefs.getString(AppConstants.prefDriverName);

      // Get current location for emergency
      final position = await _locationService.getCurrentPosition();

      final emergencyData = {
        'driverId': driverId,
        'driverName': driverName,
        'type': selectedType!.name,
        'status': 'active',
        'detectedAt': DateTime.now().toIso8601String(),
        if (position != null) 'latitude': position.latitude,
        if (position != null) 'longitude': position.longitude,
      };

      // Save to Firestore if online
      if (_connectivity.isOnline) {
        try {
          await _firestoreService.saveEmergency(data: {
            ...emergencyData,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('⚠️ Emergency save Firestore failed: $e');
        }
      }

      // Always attempt the call
      await callEmergency(selectedType!);

      emit(EmergencyTriggered(selectedType!));
    } catch (e) {
      emit(EmergencyError(e.toString()));
    }
  }
}
