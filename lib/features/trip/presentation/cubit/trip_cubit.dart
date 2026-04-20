import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/core/services/alert_service.dart';
import 'package:sav/core/services/camera_service.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/location_service.dart';
import 'package:sav/core/services/offline_cache_service.dart';
import 'package:sav/core/services/tflite_detection_service.dart';
import 'package:sav/features/trip/data/models/trip_place_model.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/entities/trip_event_entity.dart';
import 'package:sav/features/trip/domain/usecases/cancel_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/create_trip_alert_use_case.dart';
import 'package:sav/features/trip/domain/usecases/finish_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/load_current_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/load_trip_events_use_case.dart';
import 'package:sav/features/trip/domain/usecases/push_trip_location_use_case.dart';
import 'package:sav/features/trip/domain/usecases/resume_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/start_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/stop_trip_use_case.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'trip_state.dart';

@injectable
class TripCubit extends Cubit<TripState> {
  TripCubit(
    this._startTripUseCase,
    this._loadCurrentTripUseCase,
    this._pushTripLocationUseCase,
    this._stopTripUseCase,
    this._resumeTripUseCase,
    this._finishTripUseCase,
    this._cancelTripUseCase,
    this._loadTripEventsUseCase,
    this._createTripAlertUseCase,
    this._detectionService,
    this._cameraService,
    this._locationService,
    this._alertService,
    this._offlineCache,
    this._connectivity,
  ) : super(const TripInitial()) {
    _connectivity.onConnectivityRestored = _onConnectivityRestored;
    _connectivity.onConnectivityLost = _onConnectivityLost;
  }

  final StartTripUseCase _startTripUseCase;
  final LoadCurrentTripUseCase _loadCurrentTripUseCase;
  final PushTripLocationUseCase _pushTripLocationUseCase;
  final StopTripUseCase _stopTripUseCase;
  final ResumeTripUseCase _resumeTripUseCase;
  final FinishTripUseCase _finishTripUseCase;
  final CancelTripUseCase _cancelTripUseCase;
  final LoadTripEventsUseCase _loadTripEventsUseCase;
  final CreateTripAlertUseCase _createTripAlertUseCase;

  final TfliteDetectionService _detectionService;
  final CameraService _cameraService;
  final LocationService _locationService;
  final AlertService _alertService;
  final OfflineCacheService _offlineCache;
  final ConnectivityService _connectivity;

  TripEntity? _activeTrip;
  Timer? _detectionTimer;
  Timer? _locationUpdateTimer;
  bool _isDetecting = false;
  bool _isTransitioning = false;

  int _totalFrames = 0;
  int _safeFrames = 0;
  int _alertCount = 0;
  int _drowsinessAlerts = 0;
  int _distractionAlerts = 0;
  double _totalDistanceMeters = 0;
  Position? _lastPosition;
  DateTime? _lastAlertTime;

  TripEntity? get activeTrip => _activeTrip;
  CameraService get cameraService => _cameraService;

  TripActive? get activeSnapshot =>
      _activeTrip == null ? null : _buildActiveState();

  Future<void> restoreCurrentTrip() async {
    if (_activeTrip != null || state is TripLoading || state is TripEnding) {
      return;
    }

    final result = await _loadCurrentTripUseCase();
    await result.fold(
      (failure) async {
        final message = _mapFailureMessage(failure);
        if (_isSessionFailure(message)) {
          emit(TripError(message: message));
        }
      },
      (trip) async {
        if (trip == null) {
          return;
        }

        _activeTrip = trip;
        _resetCounters();

        await WakelockPlus.enable();
        emit(
          const TripLoading(
            title: 'Resuming trip',
            message: 'Restoring your active trip session.',
          ),
        );

        await _initializeSubsystems(
          initialLatitude: trip.currentLatitude ?? trip.fromLatitude,
          initialLongitude: trip.currentLongitude ?? trip.fromLongitude,
        );
      },
    );
  }

  Future<void> startTrip({
    required TripPlaceModel from,
    required TripPlaceModel to,
  }) async {
    if (_activeTrip != null ||
        state is TripLoading ||
        state is TripEnding ||
        _isTransitioning) {
      return;
    }

    if (!_connectivity.isOnline) {
      emit(
        const TripError(
          message: 'Internet connection is required to start a trip.',
        ),
      );
      return;
    }

    emit(
      const TripLoading(
        title: 'Preparing your trip',
        message: 'Checking location and trip session.',
      ),
    );

    try {
      final startPosition = await _locationService.getCurrentPosition();
      final startLatitude = from.latitude ?? startPosition?.latitude;
      final startLongitude = from.longitude ?? startPosition?.longitude;

      if (startLatitude == null || startLongitude == null) {
        throw Exception(
          'Unable to determine starting location. Please enable GPS and try again.',
        );
      }

      final result = await _startTripUseCase(
        startAddress: from.fullText,
        destinationAddress: to.fullText,
        startLatitude: startLatitude,
        startLongitude: startLongitude,
      );

      await result.fold(
        (failure) async {
          final message = _mapFailureMessage(failure);
          if (_isActiveTripConflict(message)) {
            await restoreCurrentTrip();
                emit(
                  const TripError(
                    message:
                        'You already have an active trip. Finish or cancel it before starting a new one.',
                    keepNavigationHidden: true,
                  ),
                );
            return;
          }

          emit(TripError(message: message));
        },
        (trip) async {
          _activeTrip = trip;
          _resetCounters();
          _lastPosition = startPosition;

          await WakelockPlus.enable();
          await _initializeSubsystems(
            initialLatitude: startLatitude,
            initialLongitude: startLongitude,
          );
        },
      );
    } catch (error) {
      _stopAllSubsystems();
      _activeTrip = null;
      _resetCounters();
      emit(TripError(message: _resolveErrorMessage(error)));
    }
  }

  Future<void> pauseTrip({String? notes}) async {
    final trip = _activeTrip;
    if (trip == null || !trip.isStarted || _isTransitioning) {
      return;
    }

    if (!_connectivity.isOnline) {
      _emitActionError('Internet connection is required to pause the trip.');
      return;
    }

    final snapshot = _buildActiveState(isActionInProgress: true);
    emit(snapshot);

    _isTransitioning = true;
    final result = await _stopTripUseCase(
      tripId: trip.tripIdOrZero,
      latitude: _lastPosition?.latitude ?? snapshot.latitude,
      longitude: _lastPosition?.longitude ?? snapshot.longitude,
      notes: notes,
    );
    _isTransitioning = false;

    result.fold(
      (failure) {
        _emitActionError(_mapFailureMessage(failure));
        _updateActiveState(isActionInProgress: false);
      },
      (updatedTrip) {
        _activeTrip = updatedTrip;
        _detectionTimer?.cancel();
        _updateActiveState(
          detectionStatus: DetectionStatus.offline,
          isActionInProgress: false,
        );
      },
    );
  }

  Future<void> resumeTrip({String? notes}) async {
    final trip = _activeTrip;
    if (trip == null || !trip.isStopped || _isTransitioning) {
      return;
    }

    if (!_connectivity.isOnline) {
      _emitActionError('Internet connection is required to resume the trip.');
      return;
    }

    final snapshot = _buildActiveState(isActionInProgress: true);
    emit(snapshot);

    _isTransitioning = true;
    final result = await _resumeTripUseCase(
      tripId: trip.tripIdOrZero,
      latitude: _lastPosition?.latitude ?? snapshot.latitude,
      longitude: _lastPosition?.longitude ?? snapshot.longitude,
      notes: notes,
    );
    _isTransitioning = false;

    result.fold(
      (failure) {
        _emitActionError(_mapFailureMessage(failure));
        _updateActiveState(isActionInProgress: false);
      },
      (updatedTrip) {
        _activeTrip = updatedTrip;
        if (_cameraService.isInitialized && _detectionService.isInitialized) {
          _startDetectionLoop();
        }
        _updateActiveState(
          detectionStatus: DetectionStatus.safe,
          isActionInProgress: false,
        );
      },
    );
  }

  Future<void> cancelTrip({String? notes}) async {
    final trip = _activeTrip;
    if (trip == null || _isTransitioning) {
      return;
    }

    if (!_connectivity.isOnline) {
      _emitActionError('Internet connection is required to cancel the trip.');
      return;
    }

    final snapshot = _buildActiveState(isActionInProgress: true);
    emit(snapshot);

    _isTransitioning = true;
    final result = await _cancelTripUseCase(
      tripId: trip.tripIdOrZero,
      endAddress: trip.to,
      latitude: _lastPosition?.latitude ?? snapshot.latitude,
      longitude: _lastPosition?.longitude ?? snapshot.longitude,
      notes: notes,
    );
    _isTransitioning = false;

    result.fold(
      (failure) {
        _emitActionError(_mapFailureMessage(failure));
        _updateActiveState(isActionInProgress: false);
      },
      (updatedTrip) {
        _activeTrip = updatedTrip;
        _stopAllSubsystems();
        final summary = _buildEndedState(wasCancelled: true);
        _activeTrip = null;
        _resetCounters();
        emit(summary);
      },
    );
  }

  Future<List<TripEventEntity>> loadActiveTripEvents() async {
    final tripId = _activeTrip?.tripIdOrZero ?? 0;
    if (tripId <= 0) {
      return const <TripEventEntity>[];
    }

    final result = await _loadTripEventsUseCase(tripId: tripId);
    return result.fold(
      (failure) => throw Exception(_mapFailureMessage(failure)),
      (events) => events,
    );
  }

  Future<void> _initializeSubsystems({
    double? initialLatitude,
    double? initialLongitude,
  }) async {
    if (_activeTrip == null) {
      return;
    }

    var cameraReady = false;
    var aiReady = false;
    Position? position;

    try {
      _emitLoadingStep('Starting camera...');
      cameraReady = await _cameraService.initialize();
    } catch (error) {
      debugPrint('Trip camera init failed: $error');
      cameraReady = false;
    }

    try {
      _emitLoadingStep('Loading AI...');
      aiReady = _detectionService.isInitialized;
      if (!aiReady && cameraReady) {
        aiReady = await _detectionService.initialize();
      }
    } catch (error) {
      debugPrint('Trip AI init failed: $error');
      aiReady = false;
    }

    try {
      _emitLoadingStep('Getting location...');
      position = await _locationService.getCurrentPosition();
      _lastPosition = position;
    } catch (error) {
      debugPrint('Trip location init failed: $error');
    }

    if (_activeTrip == null) {
      return;
    }

    final latitude =
        position?.latitude ??
        initialLatitude ??
        _activeTrip!.currentLatitude ??
        _activeTrip!.fromLatitude;
    final longitude =
        position?.longitude ??
        initialLongitude ??
        _activeTrip!.currentLongitude ??
        _activeTrip!.fromLongitude;

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
        latitude: latitude,
        longitude: longitude,
      ),
    );

    if (cameraReady && aiReady && (_activeTrip?.isStarted ?? false)) {
      _startDetectionLoop();
    }

    _startLocationTracking();
    _startLocationBackendUpdates();

    if (_connectivity.isOnline) {
      unawaited(_syncPendingData());
    }
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
    _isTransitioning = false;
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
        !_activeTrip!.isStarted ||
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

        await _saveAlert(result.alertType);

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

        Future<void>.delayed(const Duration(seconds: 3), () {
          if (_activeTrip != null && state is TripDangerAlert) {
            _updateActiveState(
              detectionStatus: _activeTrip!.isStopped
                  ? DetectionStatus.offline
                  : DetectionStatus.safe,
              isAiReady: true,
              isCameraReady: true,
            );
          }
        });

        return;
      }

      _safeFrames++;
      _updateActiveState(
        detectionStatus: _activeTrip!.isStopped
            ? DetectionStatus.offline
            : DetectionStatus.safe,
        isAiReady: true,
        isCameraReady: true,
      );
    } catch (error) {
      debugPrint('Trip detection failed: $error');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _saveAlert(String alertType) async {
    final tripId = _activeTrip?.tripIdOrZero ?? 0;
    if (tripId <= 0) {
      return;
    }

    if (_connectivity.isOnline) {
      final result = await _createTripAlertUseCase(
        tripId: tripId,
        alertType: alertType,
      );
      final isSynced = result.fold((_) => false, (_) => true);
      if (isSynced) {
        return;
      }
    }

    await _offlineCache.cacheAlert(<String, dynamic>{
      '_type': 'trip_alert',
      'tripId': tripId,
      'alertType': alertType,
      'detectedAt': DateTime.now().toIso8601String(),
    });

    _updateActiveState(pendingSyncCount: _offlineCache.totalPendingCount);
  }

  void _startLocationTracking() {
    _locationService.startTracking(
      onUpdate: (position) {
        if (_activeTrip == null) {
          return;
        }

        if (_lastPosition != null && (_activeTrip?.isStarted ?? false)) {
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

  void _startLocationBackendUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(
      AppConstants.tripLocationPushInterval,
      (_) => _pushLocation(),
    );
  }

  Future<void> _pushLocation() async {
    final trip = _activeTrip;
    if (trip == null || _lastPosition == null || !trip.isActive) {
      return;
    }

    final tripId = trip.tripIdOrZero;
    if (tripId <= 0) {
      return;
    }

    final latitude = _lastPosition!.latitude;
    final longitude = _lastPosition!.longitude;

    if (_connectivity.isOnline) {
      final result = await _pushTripLocationUseCase(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
      );

      final synced = result.fold((_) => false, (_) => true);
      if (synced) {
        return;
      }
    }

    await _offlineCache.cacheLocation(<String, dynamic>{
      'tripId': tripId,
      'latitude': latitude,
      'longitude': longitude,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    _updateActiveState(pendingSyncCount: _offlineCache.totalPendingCount);
  }

  void _onConnectivityRestored() {
    _updateActiveState(
      isOnline: true,
      pendingSyncCount: _offlineCache.totalPendingCount,
    );
    unawaited(_syncPendingData());
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
        final item = Map<String, dynamic>.from(rawAlert);
        final type = (item['_type'] ?? '').toString();

        if (type != 'trip_alert') {
          continue;
        }

        final tripId = _toInt(item['tripId']);
        final alertType = (item['alertType'] ?? '').toString().trim();
        if (tripId <= 0 || alertType.isEmpty) {
          continue;
        }

        final result = await _createTripAlertUseCase(
          tripId: tripId,
          alertType: alertType,
        );

        final synced = result.fold((_) => false, (_) => true);
        if (!synced) {
          await _offlineCache.cacheAlert(item);
        }
      }

      final locations = await _offlineCache.drainLocations();
      for (final rawLocation in locations) {
        final item = Map<String, dynamic>.from(rawLocation);

        final tripId = _toInt(item['tripId']);
        final latitude = _toDouble(item['latitude']);
        final longitude = _toDouble(item['longitude']);
        final notes = (item['notes'] ?? '').toString().trim();

        if (tripId <= 0 || latitude == null || longitude == null) {
          continue;
        }

        final result = await _pushTripLocationUseCase(
          tripId: tripId,
          latitude: latitude,
          longitude: longitude,
          notes: notes.isEmpty ? null : notes,
        );

        final synced = result.fold((_) => false, (_) => true);
        if (!synced) {
          await _offlineCache.cacheLocation(item);
        }
      }

      _updateActiveState(pendingSyncCount: _offlineCache.totalPendingCount);
    } catch (error) {
      debugPrint('Pending sync failed: $error');
    }
  }

  Future<void> endTrip() async {
    final trip = _activeTrip;
    if (trip == null || state is TripEnding || _isTransitioning) {
      return;
    }

    if (!_connectivity.isOnline) {
      _emitActionError('Internet connection is required to finish the trip.');
      return;
    }

    final snapshot = _buildActiveState();
    emit(TripEnding(activeState: snapshot));

    _isTransitioning = true;

    try {
      final fallbackPosition = await _locationService.getCurrentPosition();
      final latitude =
          _lastPosition?.latitude ?? fallbackPosition?.latitude ?? snapshot.latitude;
      final longitude = _lastPosition?.longitude ??
          fallbackPosition?.longitude ??
          snapshot.longitude;

      if (latitude == null || longitude == null) {
        throw Exception('Unable to get final location. Please try again.');
      }

      final result = await _finishTripUseCase(
        tripId: trip.tripIdOrZero,
        latitude: latitude,
        longitude: longitude,
        endAddress: trip.to,
      );

      await result.fold(
        (failure) async {
          emit(snapshot);
          _emitActionError(_mapFailureMessage(failure));
        },
        (finishedTrip) async {
          _activeTrip = finishedTrip;
          if (_connectivity.isOnline) {
            await _syncPendingData();
          }

          _stopAllSubsystems();
          final summary = _buildEndedState(wasCancelled: false);
          _activeTrip = null;
          _resetCounters();
          emit(summary);
        },
      );
    } catch (error) {
      emit(snapshot);
      _emitActionError(_resolveErrorMessage(error));
    } finally {
      _isTransitioning = false;
    }
  }

  TripEnded _buildEndedState({required bool wasCancelled}) {
    final trip = _activeTrip;

    final fallbackDuration = _formatDurationSummary(
      (trip?.endTime ?? DateTime.now()).difference(
        trip?.startTime ?? DateTime.now(),
      ),
    );

    final fallbackDistance = _formatDistanceSummary(_totalDistanceMeters);
    final awake = _totalFrames > 0
        ? (_safeFrames / _totalFrames * 100)
        : (trip?.awakePercentage ?? 100.0);

    return TripEnded(
      duration:
          (trip?.duration ?? '').trim().isNotEmpty ? trip!.duration : fallbackDuration,
      distance:
          (trip?.distance ?? '').trim().isNotEmpty ? trip!.distance : fallbackDistance,
      alertCount: _alertCount,
      awakePercentage: awake,
      wasCancelled: wasCancelled,
    );
  }

  void _stopAllSubsystems() {
    _detectionTimer?.cancel();
    _detectionTimer = null;

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    _locationService.stopTracking();
    _cameraService.dispose();
    _alertService.stop();
    unawaited(WakelockPlus.disable());
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
    bool? isActionInProgress,
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
        isActionInProgress: isActionInProgress,
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
    bool? isActionInProgress,
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
          : (_activeTrip?.awakePercentage ?? 100.0),
      latitude: latitude ?? base?.latitude ?? _activeTrip?.currentLatitude,
      longitude: longitude ?? base?.longitude ?? _activeTrip?.currentLongitude,
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
      isActionInProgress:
          isActionInProgress ?? base?.isActionInProgress ?? false,
    );
  }

  void _emitActionError(String message) {
    final snapshot = activeSnapshot;
    if (snapshot == null) {
      emit(TripError(message: message));
      return;
    }

    emit(TripError(message: message, keepNavigationHidden: true));
    emit(snapshot.copyWith(isActionInProgress: false));
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
    if (_activeTrip!.isStarted &&
        _cameraService.isInitialized &&
        _detectionService.isInitialized) {
      _startDetectionLoop();
    }

    if (_connectivity.isOnline) {
      unawaited(_syncPendingData());
    }
  }

  @override
  Future<void> close() {
    _connectivity.onConnectivityRestored = null;
    _connectivity.onConnectivityLost = null;
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

  bool _isSessionFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('session') ||
        normalized.contains('login again') ||
        normalized.contains('unauthorized') ||
        normalized.contains('token');
  }

  bool _isActiveTripConflict(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('already has an active trip') ||
        normalized.contains('active trip');
  }

  String _mapFailureMessage(Failure failure) {
    final message = failure.message.trim();
    if (message.isEmpty) {
      return 'Unable to process trip request right now. Please try again.';
    }

    final normalized = message.toLowerCase();

    if (_isSessionFailure(normalized)) {
      return 'Session expired. Please login again.';
    }

    if (normalized.contains('no internet') ||
        normalized.contains('network') ||
        normalized.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (normalized.contains('timeout') || normalized.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }

    if (normalized.contains('already has an active trip')) {
      return 'You already have an active trip. Resume, finish, or cancel it first.';
    }

    if (normalized.contains('only started trips can be stopped')) {
      return 'Only active trips can be paused.';
    }

    if (normalized.contains('only stopped trips can be resumed')) {
      return 'Only paused trips can be resumed.';
    }

    if (normalized.contains('only active trips can be finished')) {
      return 'Only active or paused trips can be finished.';
    }

    if (normalized.contains('location updates are allowed only for active trips')) {
      return 'Location updates are allowed only while the trip is active.';
    }

    if (normalized.contains('latitude and longitude are required')) {
      return 'A valid GPS location is required for this action.';
    }

    if (normalized.contains('forbidden') || normalized.contains('access')) {
      return 'You do not have permission to perform this action.';
    }

    if (normalized.contains('not found')) {
      return 'Trip session was not found. Please refresh and try again.';
    }

    if (normalized.contains('server') || normalized.contains('500')) {
      return 'Server error while handling trip request. Please try again shortly.';
    }

    return message;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
