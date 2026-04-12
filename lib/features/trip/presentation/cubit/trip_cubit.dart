import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/alert_service.dart';
import 'package:sav/core/services/camera_service.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/firestore_service.dart';
import 'package:sav/core/services/location_service.dart';
import 'package:sav/core/services/offline_cache_service.dart';
import 'package:sav/core/services/tflite_detection_service.dart';
import 'package:sav/features/trip/data/models/trip_model.dart';
import 'package:sav/features/trip/data/models/trip_place_model.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'trip_state.dart';

@injectable
class TripCubit extends Cubit<TripState> {
  TripCubit(
    this._firestoreService,
    this._detectionService,
    this._cameraService,
    this._locationService,
    this._alertService,
    this._offlineCache,
    this._connectivity,
    this._prefs,
  ) : super(const TripInitial()) {
    _connectivity.onConnectivityRestored = _onConnectivityRestored;
    _connectivity.onConnectivityLost = _onConnectivityLost;
  }

  final FirestoreService _firestoreService;
  final TfliteDetectionService _detectionService;
  final CameraService _cameraService;
  final LocationService _locationService;
  final AlertService _alertService;
  final OfflineCacheService _offlineCache;
  final ConnectivityService _connectivity;
  final SharedPreferences _prefs;

  TripModel? _activeTrip;
  Timer? _detectionTimer;
  Timer? _locationUpdateTimer;
  bool _isDetecting = false;
  int _totalFrames = 0;
  int _safeFrames = 0;
  int _alertCount = 0;
  int _drowsinessAlerts = 0;
  int _distractionAlerts = 0;
  double _totalDistanceMeters = 0;
  Position? _lastPosition;
  DateTime? _lastAlertTime;

  TripModel? get activeTrip => _activeTrip;
  CameraService get cameraService => _cameraService;
  TripActive? get activeSnapshot =>
      _activeTrip == null ? null : _buildActiveState();

  Future<void> startTrip({
    required TripPlaceModel from,
    required TripPlaceModel to,
  }) async {
    if (_activeTrip != null || state is TripLoading || state is TripEnding) {
      return;
    }

    emit(
      const TripLoading(
        title: 'Preparing your trip',
        message: 'Preparing route and sensors.',
      ),
    );

    try {
      final driverId = _prefs.getString(AppConstants.prefDriverId);
      if (driverId == null || driverId.trim().isEmpty) {
        throw Exception(
          'Driver not found. Please login first.',
        );
      }

      final trip = TripModel(
        id: const Uuid().v4(),
        driverId: driverId,
        from: from.fullText,
        to: to.fullText,
        fromPlaceId: from.placeId,
        toPlaceId: to.placeId,
        fromLatitude: from.latitude,
        fromLongitude: from.longitude,
        toLatitude: to.latitude,
        toLongitude: to.longitude,
        status: 'active',
        startTime: DateTime.now(),
      );

      _activeTrip = trip;
      _resetCounters();

      await _persistTripStart(trip);
      await WakelockPlus.enable();
      await _initializeSubsystems();
    } catch (error) {
      _stopAllSubsystems();
      _activeTrip = null;
      _resetCounters();
      emit(TripError(message: _resolveErrorMessage(error)));
    }
  }

  Future<void> _persistTripStart(TripModel trip) async {
    final payload = trip.toMap();

    try {
      if (_connectivity.isOnline) {
        await _firestoreService.saveTrip(
          driverId: trip.driverId,
          tripId: trip.id,
          data: payload,
        );
        return;
      }
    } catch (_) {
      // Fall back to offline cache below.
    }

    await _offlineCache.cacheAlert({
      '_type': 'trip_start',
      'tripId': trip.id,
      'driverId': trip.driverId,
      ...payload,
    });
  }

  Future<void> _initializeSubsystems() async {
    if (_activeTrip == null) {
      return;
    }

    _emitLoadingStep('Starting camera...');
    final cameraReady = await _cameraService.initialize();

    _emitLoadingStep('Loading AI...');
    var aiReady = _detectionService.isInitialized;
    if (!aiReady && cameraReady) {
      aiReady = await _detectionService.initialize();
    }

    _emitLoadingStep('Getting location...');
    final initialPosition = await _locationService.getCurrentPosition();
    _lastPosition = initialPosition;

    if (_activeTrip == null) {
      return;
    }

    emit(
      TripActive(
        trip: _activeTrip!,
        detectionStatus: cameraReady && aiReady
            ? DetectionStatus.safe
            : DetectionStatus.offline,
        isAiReady: aiReady,
        isCameraReady: cameraReady,
        isOnline: _connectivity.isOnline,
        pendingSyncCount: _offlineCache.totalPendingCount,
        latitude: initialPosition?.latitude,
        longitude: initialPosition?.longitude,
      ),
    );

    if (cameraReady && aiReady) {
      _startDetectionLoop();
    }

    _startLocationTracking();
    _startLocationFirestoreUpdates();
  }

  void _emitLoadingStep(String message) {
    emit(TripLoading(title: 'Starting trip', message: message));
  }

  void _resetCounters() {
    _totalFrames = 0;
    _safeFrames = 0;
    _alertCount = 0;
    _drowsinessAlerts = 0;
    _distractionAlerts = 0;
    _totalDistanceMeters = 0;
    _lastPosition = null;
    _lastAlertTime = null;
    _isDetecting = false;
  }

  void _startDetectionLoop() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.detectionIntervalMs),
      (_) => _runDetection(),
    );
  }

  Future<void> _runDetection() async {
    if (_isDetecting ||
        _activeTrip == null ||
        !_cameraService.isInitialized ||
        !_detectionService.isInitialized) {
      return;
    }

    _isDetecting = true;

    try {
      final frame = await _cameraService.captureFrame();
      if (frame == null) {
        return;
      }

      final result = await _detectionService.detectFrame(frame);
      _totalFrames++;

      if (result == null) {
        return;
      }

      if (result.isDanger) {
        final now = DateTime.now();
        final canAlert =
            _lastAlertTime == null ||
            now.difference(_lastAlertTime!).inMilliseconds >=
                AppConstants.alertCooldownMs;

        if (!canAlert) {
          return;
        }

        _lastAlertTime = now;
        _alertCount++;

        if (result.isDrowsy) {
          _drowsinessAlerts++;
          _alertService.playDrowsinessAlert();
        } else if (result.isYawning) {
          _distractionAlerts++;
          _alertService.playYawnWarning();
        }

        await _saveAlert(result);

        final activeState = _buildActiveState(
          detectionStatus: result.isDrowsy
              ? DetectionStatus.drowsy
              : DetectionStatus.yawning,
          isAiReady: true,
          isCameraReady: true,
        );

        emit(
          TripDangerAlert(
            alertType: result.alertType,
            confidence: result.maxConfidence,
            activeState: activeState,
          ),
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (_activeTrip != null && state is TripDangerAlert) {
            _updateActiveState(
              detectionStatus: DetectionStatus.safe,
              isAiReady: true,
              isCameraReady: true,
            );
          }
        });

        return;
      }

      _safeFrames++;
      _updateActiveState(
        detectionStatus: DetectionStatus.safe,
        isAiReady: true,
        isCameraReady: true,
      );
    } catch (error) {
      debugPrint('Trip detection failed: $error');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _saveAlert(dynamic result) async {
    if (_activeTrip == null) {
      return;
    }

    final driverName =
        _prefs.getString(AppConstants.prefDriverName) ?? 'Unknown Driver';

    final alertData = {
      'type': result.alertType,
      'isDrowsy': result.isDrowsy,
      'isYawning': result.isYawning,
      'confidence': result.maxConfidence,
      'tripId': _activeTrip!.id,
      'driverId': _activeTrip!.driverId,
      'driverName': driverName,
      'detectedAt': DateTime.now().toIso8601String(),
      'source': 'on_device',
    };

    if (_connectivity.isOnline) {
      try {
        await _firestoreService.saveAlert(
          driverId: _activeTrip!.driverId,
          data: {...alertData, 'timestamp': FieldValue.serverTimestamp()},
        );

        await _firestoreService.incrementTripAlerts(
          driverId: _activeTrip!.driverId,
          tripId: _activeTrip!.id,
          alertType: result.alertType,
        );
        return;
      } catch (error) {
        debugPrint('Alert sync failed, caching locally: $error');
      }
    }

    await _offlineCache.cacheAlert(alertData);
    _updateActiveState(pendingSyncCount: _offlineCache.totalPendingCount);
  }

  void _startLocationTracking() {
    _locationService.startTracking(
      onUpdate: (position) {
        if (_activeTrip == null) {
          return;
        }

        if (_lastPosition != null) {
          final distance = _locationService.calculateDistance(
            _lastPosition!,
            position,
          );
          _totalDistanceMeters += distance;
        }

        _lastPosition = position;
        _updateActiveState(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      },
      distanceFilter: 10,
    );
  }

  void _startLocationFirestoreUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(
      AppConstants.tripLocationPushInterval,
      (_) => _pushLocation(),
    );
  }

  Future<void> _pushLocation() async {
    if (_activeTrip == null || _lastPosition == null) {
      return;
    }

    final locationData = {
      'driverId': _activeTrip!.driverId,
      'latitude': _lastPosition!.latitude,
      'longitude': _lastPosition!.longitude,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (_connectivity.isOnline) {
      try {
        await _locationService.updateDriverLocation(
          driverId: _activeTrip!.driverId,
          latitude: _lastPosition!.latitude,
          longitude: _lastPosition!.longitude,
        );
        return;
      } catch (error) {
        debugPrint('Location push failed, caching locally: $error');
      }
    }

    await _offlineCache.cacheLocation(locationData);
    _updateActiveState(pendingSyncCount: _offlineCache.totalPendingCount);
  }

  void _onConnectivityRestored() {
    _updateActiveState(
      isOnline: true,
      pendingSyncCount: _offlineCache.totalPendingCount,
    );
    _syncPendingData();
  }

  void _onConnectivityLost() {
    _updateActiveState(isOnline: false);
  }

  Future<void> _syncPendingData() async {
    if (!_connectivity.isOnline) {
      return;
    }

    try {
      final alerts = await _offlineCache.drainAlerts();
      for (final rawAlert in alerts) {
        final alert = Map<String, dynamic>.from(rawAlert);
        final driverId = alert['driverId'] as String?;
        if (driverId == null || driverId.trim().isEmpty) {
          continue;
        }

        final internalType = alert.remove('_type') as String?;
        final tripId = alert.remove('tripId') as String?;

        try {
          if (internalType == 'trip_start' && tripId != null) {
            await _firestoreService.saveTrip(
              driverId: driverId,
              tripId: tripId,
              data: alert,
            );
            continue;
          }

          if (internalType == 'trip_end' && tripId != null) {
            await _firestoreService.updateTrip(
              driverId: driverId,
              tripId: tripId,
              data: alert,
            );
            continue;
          }

          await _firestoreService.saveAlert(
            driverId: driverId,
            data: {
              ...alert,
              'timestamp': FieldValue.serverTimestamp(),
              'syncedFromCache': true,
            },
          );
        } catch (error) {
          if (internalType != null) {
            alert['_type'] = internalType;
          }
          if (tripId != null) {
            alert['tripId'] = tripId;
          }
          await _offlineCache.cacheAlert(alert);
          debugPrint('Pending sync item failed and was re-cached: $error');
        }
      }

      final locations = await _offlineCache.drainLocations();
      if (locations.isNotEmpty) {
        final latest = locations.last;
        final driverId = latest['driverId'] as String?;
        final latitude = (latest['latitude'] as num?)?.toDouble();
        final longitude = (latest['longitude'] as num?)?.toDouble();

        if (driverId != null && latitude != null && longitude != null) {
          try {
            await _locationService.updateDriverLocation(
              driverId: driverId,
              latitude: latitude,
              longitude: longitude,
            );
          } catch (error) {
            await _offlineCache.cacheLocation(latest);
            debugPrint(
              'Pending location sync failed and was re-cached: $error',
            );
          }
        }
      }

      _updateActiveState(pendingSyncCount: _offlineCache.totalPendingCount);
    } catch (error) {
      debugPrint('Pending sync failed: $error');
    }
  }

  Future<void> endTrip() async {
    if (_activeTrip == null || state is TripEnding) {
      return;
    }

    final snapshot = _buildActiveState();
    emit(TripEnding(activeState: snapshot));

    try {
      _stopAllSubsystems();

      final driverId = _prefs.getString(AppConstants.prefDriverId);
      if (driverId == null || driverId.trim().isEmpty) {
        throw Exception('Driver not found. Unable to complete the trip.');
      }

      final endTime = DateTime.now();
      final difference = endTime.difference(_activeTrip!.startTime);
      final duration = _formatDurationSummary(difference);
      final distance = _formatDistanceSummary(_totalDistanceMeters);
      final awakePercentage = _totalFrames > 0
          ? (_safeFrames / _totalFrames * 100)
          : 100.0;

      final tripEndData = {
        'status': 'completed',
        'endTime': Timestamp.fromDate(endTime),
        'duration': duration,
        'distance': distance,
        'alerts': _alertCount,
        'drowsinessAlerts': _drowsinessAlerts,
        'distractionAlerts': _distractionAlerts,
        'awakePercentage': awakePercentage,
        'detectionMethod': 'on_device',
        'date': DateFormat('dd MMM yyyy - h:mm a').format(endTime),
      };

      if (_connectivity.isOnline) {
        try {
          await _firestoreService.updateTrip(
            driverId: driverId,
            tripId: _activeTrip!.id,
            data: tripEndData,
          );

          await _firestoreService.updateTripAwakePercentage(
            driverId: driverId,
            tripId: _activeTrip!.id,
            percentage: awakePercentage,
          );

          await _firestoreService.updateDriverStatistics(
            driverId: driverId,
            stats: {
              'totalTrips': FieldValue.increment(1),
              'totalAlerts': FieldValue.increment(_alertCount),
              'awakePercentage': awakePercentage,
              'lastTripDate': Timestamp.fromDate(endTime),
            },
          );
        } catch (error) {
          await _offlineCache.cacheAlert({
            '_type': 'trip_end',
            'tripId': _activeTrip!.id,
            'driverId': driverId,
            ...tripEndData,
          });
          debugPrint('Trip completion sync failed, cached locally: $error');
        }
      } else {
        await _offlineCache.cacheAlert({
          '_type': 'trip_end',
          'tripId': _activeTrip!.id,
          'driverId': driverId,
          ...tripEndData,
        });
      }

      if (_connectivity.isOnline) {
        await _syncPendingData();
      }

      _activeTrip = null;

      emit(
        TripEnded(
          duration: duration,
          distance: distance,
          alertCount: _alertCount,
          awakePercentage: awakePercentage,
        ),
      );

      _resetCounters();
    } catch (error) {
      final fallbackState = activeSnapshot;
      if (fallbackState != null) {
        emit(fallbackState);
      }
      emit(
        TripError(
          message: _resolveErrorMessage(error),
          keepNavigationHidden: fallbackState != null,
        ),
      );
    }
  }

  void _stopAllSubsystems() {
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _locationService.stopTracking();
    _cameraService.dispose();
    _alertService.stop();
    WakelockPlus.disable();
  }

  void resetTrip() {
    _stopAllSubsystems();
    _activeTrip = null;
    _resetCounters();
    emit(const TripInitial());
  }

  void _updateActiveState({
    DetectionStatus? detectionStatus,
    bool? isAiReady,
    bool? isCameraReady,
    bool? isOnline,
    int? pendingSyncCount,
    double? latitude,
    double? longitude,
  }) {
    if (_activeTrip == null) {
      return;
    }

    emit(
      _buildActiveState(
        detectionStatus: detectionStatus,
        isAiReady: isAiReady,
        isCameraReady: isCameraReady,
        isOnline: isOnline,
        pendingSyncCount: pendingSyncCount,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  TripActive _buildActiveState({
    DetectionStatus? detectionStatus,
    bool? isAiReady,
    bool? isCameraReady,
    bool? isOnline,
    int? pendingSyncCount,
    double? latitude,
    double? longitude,
  }) {
    final current = state;
    final base = switch (current) {
      TripActive value => value,
      TripDangerAlert value => value.activeState,
      TripEnding value => value.activeState,
      _ => null,
    };

    return TripActive(
      trip: _activeTrip!,
      detectionStatus:
          detectionStatus ?? base?.detectionStatus ?? DetectionStatus.safe,
      alertCount: _alertCount,
      drowsinessAlerts: _drowsinessAlerts,
      distractionAlerts: _distractionAlerts,
      awakePercentage: _totalFrames > 0
          ? (_safeFrames / _totalFrames * 100)
          : 100.0,
      latitude: latitude ?? base?.latitude,
      longitude: longitude ?? base?.longitude,
      totalDistanceMeters: _totalDistanceMeters,
      isAiReady:
          isAiReady ?? base?.isAiReady ?? _detectionService.isInitialized,
      isCameraReady:
          isCameraReady ?? base?.isCameraReady ?? _cameraService.isInitialized,
      isOnline: isOnline ?? base?.isOnline ?? _connectivity.isOnline,
      pendingSyncCount:
          pendingSyncCount ??
          base?.pendingSyncCount ??
          _offlineCache.totalPendingCount,
    );
  }

  void onAppPaused() {
    _cameraService.pause();
    _detectionTimer?.cancel();
  }

  void onAppResumed() {
    if (_activeTrip == null) {
      return;
    }

    _cameraService.resume();
    if (_cameraService.isInitialized && _detectionService.isInitialized) {
      _startDetectionLoop();
    }
    if (_connectivity.isOnline) {
      _syncPendingData();
    }
  }

  @override
  Future<void> close() {
    _stopAllSubsystems();
    return super.close();
  }

  String _formatDurationSummary(Duration difference) {
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    if (hours > 0) {
      return '$hours h, $minutes min';
    }
    return '${difference.inMinutes} min';
  }

  String _formatDistanceSummary(double totalDistanceMeters) {
    final distanceKm = totalDistanceMeters / 1000;
    if (distanceKm >= 1) {
      return '${distanceKm.toStringAsFixed(1)} KM';
    }
    return '${totalDistanceMeters.toInt()} m';
  }

  String _resolveErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Something went wrong while handling the trip.';
    }
    return message;
  }
}
