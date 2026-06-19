import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/core/services/alert_service.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/location_service.dart';
import 'package:sav/core/services/offline_cache_service.dart';
import 'package:sav/core/services/push_notification_service.dart';
import 'package:sav/core/services/local_telemetry_server.dart';
import 'package:sav/core/services/trip_live_updates_service.dart';
import 'package:sav/features/trip/data/models/trip_place_model.dart';
import 'package:sav/features/trip/domain/entities/esp_telemetry_log_entity.dart';
import 'package:sav/features/trip/domain/entities/esp_telemetry_stats_entity.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/entities/trip_event_entity.dart';
import 'package:sav/features/trip/domain/entities/alert_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';
import 'package:sav/features/trip/domain/usecases/load_esp_telemetry_stats_use_case.dart';
import 'package:sav/features/trip/domain/usecases/load_esp_telemetry_use_case.dart';
import 'package:sav/features/trip/domain/usecases/cancel_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/create_trip_alert_use_case.dart';
import 'package:sav/features/trip/domain/usecases/finish_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/load_current_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/load_trip_events_use_case.dart';
import 'package:sav/features/trip/domain/usecases/push_trip_location_use_case.dart';
import 'package:sav/features/trip/domain/usecases/resume_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/start_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/stop_trip_use_case.dart';
import 'package:sav/features/trip/domain/usecases/load_driver_trip_history_use_case.dart';
import 'package:sav/features/trip/domain/usecases/start_existing_trip_use_case.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'trip_state.dart';

@lazySingleton
class TripCubit extends Cubit<TripState> {
  TripCubit(
    this._startTripUseCase,
    this._startExistingTripUseCase,
    this._loadCurrentTripUseCase,
    this._loadDriverTripHistoryUseCase,
    this._pushTripLocationUseCase,
    this._stopTripUseCase,
    this._resumeTripUseCase,
    this._finishTripUseCase,
    this._cancelTripUseCase,
    this._loadTripEventsUseCase,
    this._createTripAlertUseCase,
    this._locationService,
    this._alertService,
    this._offlineCache,
    this._connectivity,
    this._localTelemetryServer,
  ) : super(const TripInitial()) {
    _connectivity.onConnectivityRestored = _onConnectivityRestored;
    _connectivity.onConnectivityLost = _onConnectivityLost;
    _fcmAlertSubscription = PushNotificationService.alertStream.listen(_onFcmAlert);
    _localTelemetrySubscription = _localTelemetryServer.telemetryStream.listen(_onLocalTelemetry);
  }

  final StartTripUseCase _startTripUseCase;
  final StartExistingTripUseCase _startExistingTripUseCase;
  final LoadCurrentTripUseCase _loadCurrentTripUseCase;
  final LoadDriverTripHistoryUseCase _loadDriverTripHistoryUseCase;
  final PushTripLocationUseCase _pushTripLocationUseCase;
  final StopTripUseCase _stopTripUseCase;
  final ResumeTripUseCase _resumeTripUseCase;
  final FinishTripUseCase _finishTripUseCase;
  final CancelTripUseCase _cancelTripUseCase;
  final LoadTripEventsUseCase _loadTripEventsUseCase;
  final CreateTripAlertUseCase _createTripAlertUseCase;
  final LocationService _locationService;
  final AlertService _alertService;
  final OfflineCacheService _offlineCache;
  final ConnectivityService _connectivity;
  final LocalTelemetryServer _localTelemetryServer;

  TripLiveUpdatesService? get _tripLiveUpdates =>
      GetIt.instance.isRegistered<TripLiveUpdatesService>()
      ? GetIt.instance<TripLiveUpdatesService>()
      : null;

  LoadEspTelemetryUseCase? get _loadEspTelemetryUseCase =>
      GetIt.instance.isRegistered<LoadEspTelemetryUseCase>()
      ? GetIt.instance<LoadEspTelemetryUseCase>()
      : null;

  LoadEspTelemetryStatsUseCase? get _loadEspTelemetryStatsUseCase =>
      GetIt.instance.isRegistered<LoadEspTelemetryStatsUseCase>()
      ? GetIt.instance<LoadEspTelemetryStatsUseCase>()
      : null;

  TripEntity? _activeTrip;
  Timer? _telemetryTimer;
  Timer? _telemetryStatsTimer;
  Timer? _locationUpdateTimer;
  StreamSubscription<Map<String, dynamic>>? _fcmAlertSubscription;
  StreamSubscription<Map<String, dynamic>>? _localTelemetrySubscription;
  bool _isPollingTelemetry = false;
  bool _isTransitioning = false;

  TripRepository get _tripRepository => GetIt.instance<TripRepository>();
  int? _lastAlertId;
  bool _isPollingAlerts = false;

  bool _isTelemetryReady = false;
  int? _lastTelemetryId;
  DateTime? _lastTelemetryAt;

  int _alertCount = 0;
  int _drowsinessAlerts = 0;
  int _distractionAlerts = 0;
  double _awakePercentage = 100.0;
  double _totalDistanceMeters = 0;
  Position? _lastPosition;
  DateTime? _lastAlertTime;

  TripEntity? get activeTrip => _activeTrip;

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
          await loadAssignedTrips();
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

        _tripLiveUpdates?.emit(
          type: TripLiveUpdateType.resumed,
          tripId: trip.tripIdOrZero,
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

          _tripLiveUpdates?.emit(
            type: TripLiveUpdateType.started,
            tripId: trip.tripIdOrZero,
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

  Future<void> loadAssignedTrips() async {
    emit(
      const TripLoading(
        title: 'Loading trips',
        message: 'Fetching your assigned trips.',
      ),
    );

    final result = await _loadDriverTripHistoryUseCase(status: 'created');
    result.fold(
      (failure) {
        emit(TripError(message: _mapFailureMessage(failure)));
      },
      (trips) {
        emit(TripAssignedLoaded(trips));
      },
    );
  }

  Future<void> startExistingTrip({
    required int tripId,
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
      final startLatitude = startPosition?.latitude;
      final startLongitude = startPosition?.longitude;

      if (startLatitude == null || startLongitude == null) {
        throw Exception(
          'Unable to determine starting location. Please enable GPS and try again.',
        );
      }

      final result = await _startExistingTripUseCase(
        tripId: tripId,
        latitude: startLatitude,
        longitude: startLongitude,
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

          _tripLiveUpdates?.emit(
            type: TripLiveUpdateType.started,
            tripId: trip.tripIdOrZero,
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
        _telemetryTimer?.cancel();
        _telemetryStatsTimer?.cancel();
        _tripLiveUpdates?.emit(
          type: TripLiveUpdateType.paused,
          tripId: updatedTrip.tripIdOrZero,
        );
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
        _startTelemetryLoop();
        _startTelemetryStatsLoop();
        unawaited(_localTelemetryServer.start());
        _tripLiveUpdates?.emit(
          type: TripLiveUpdateType.resumed,
          tripId: updatedTrip.tripIdOrZero,
        );
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

        _tripLiveUpdates?.emit(
          type: TripLiveUpdateType.cancelled,
          tripId: updatedTrip.tripIdOrZero,
        );
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

    Position? position;

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
        detectionStatus: _connectivity.isOnline
            ? DetectionStatus.initializing
            : DetectionStatus.offline,
        isAiReady: _isTelemetryReady,
        isOnline: _connectivity.isOnline,
        pendingSyncCount: _offlineCache.totalPendingCount,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    if (_activeTrip?.isStarted ?? false) {
      _startTelemetryLoop();
      _startTelemetryStatsLoop();
      unawaited(_localTelemetryServer.start());
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
    _alertCount = 0;
    _drowsinessAlerts = 0;
    _distractionAlerts = 0;
    _awakePercentage = 100.0;
    _totalDistanceMeters = 0;
    _lastPosition = null;
    _lastAlertTime = null;
    _isPollingTelemetry = false;
    _isTelemetryReady = false;
    _lastTelemetryId = null;
    _lastTelemetryAt = null;
    _isTransitioning = false;
    _lastAlertId = null;
    _isPollingAlerts = false;
  }

  void _startTelemetryLoop() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.detectionIntervalMs),
      (_) {
        _pollTelemetryLatest();
        _pollAlertsLatest();
      },
    );
  }

  void _startTelemetryStatsLoop() {
    _telemetryStatsTimer?.cancel();
    _telemetryStatsTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _pollTelemetryStats(),
    );
  }

  Future<void> _pollTelemetryLatest() async {
    if (_isPollingTelemetry ||
        _activeTrip == null ||
        !_activeTrip!.isStarted ||
        !_connectivity.isOnline) {
      if (!_connectivity.isOnline && _activeTrip != null) {
        _updateActiveState(
          detectionStatus: DetectionStatus.offline,
          isAiReady: false,
        );
      }
      return;
    }

    _isPollingTelemetry = true;

    try {
      final useCase = _loadEspTelemetryUseCase;
      if (useCase == null) {
        return;
      }

      final result = await useCase(
        page: 1,
        pageSize: 1,
        tripId: _activeTrip!.tripIdOrZero,
      );

      await result.fold(
        (failure) async {
          debugPrint('ESP telemetry fetch failed: ${failure.message}');
          _updateActiveState(
            detectionStatus: DetectionStatus.offline,
            isAiReady: false,
          );
        },
        (logs) async {
          if (logs.isEmpty) {
            _updateActiveState(
              detectionStatus: _isTelemetryReady
                  ? DetectionStatus.offline
                  : DetectionStatus.initializing,
              isAiReady: _isTelemetryReady,
            );
            return;
          }

          final latest = logs.first;
          _handleTelemetryUpdate(latest);
        },
      );
    } catch (error) {
      debugPrint('ESP telemetry poll failed: $error');
    } finally {
      _isPollingTelemetry = false;
    }
  }

  Future<void> _pollTelemetryStats() async {
    if (_activeTrip == null || !_activeTrip!.isStarted || !_connectivity.isOnline) {
      return;
    }

    final useCase = _loadEspTelemetryStatsUseCase;
    if (useCase == null) {
      return;
    }

    try {
      final result = await useCase(tripId: _activeTrip!.tripIdOrZero);
      result.fold(
        (failure) => debugPrint('ESP telemetry stats failed: ${failure.message}'),
        _applyTelemetryStats,
      );
    } catch (error) {
      debugPrint('ESP telemetry stats poll failed: $error');
    }
  }

  void _handleTelemetryUpdate(EspTelemetryLogEntity latest) {
    _isTelemetryReady = true;
    final eventTime = latest.eventTime;
    final now = DateTime.now();

    if (eventTime != null &&
        now.difference(eventTime) > AppConstants.espTelemetryStaleThreshold) {
      _updateActiveState(
        detectionStatus: DetectionStatus.offline,
        isAiReady: true,
      );
      return;
    }

    if (_lastTelemetryId != null && latest.id == _lastTelemetryId) {
      _updateActiveState(
        detectionStatus: _resolveTelemetryStatus(latest),
        isAiReady: true,
      );
      return;
    }

    if (eventTime != null && _lastTelemetryAt != null) {
      if (!eventTime.isAfter(_lastTelemetryAt!)) {
        _updateActiveState(
          detectionStatus: _resolveTelemetryStatus(latest),
          isAiReady: true,
        );
        return;
      }
    }

    _lastTelemetryId = latest.id;
    _lastTelemetryAt = eventTime ?? DateTime.now();

    if (!latest.hasDanger) {
      _updateActiveState(
        detectionStatus: DetectionStatus.safe,
        isAiReady: true,
      );
      return;
    }

    final canAlert =
        _lastAlertTime == null ||
        now.difference(_lastAlertTime!).inMilliseconds >=
            AppConstants.alertCooldownMs;

    if (!canAlert) {
      _updateActiveState(
        detectionStatus: _resolveTelemetryStatus(latest),
        isAiReady: true,
      );
      return;
    }

    _lastAlertTime = now;
    _alertCount++;

    final alertType = _mapTelemetryAlertType(latest);
    if (alertType == 'drowsiness' || alertType == 'eyes_closed') {
      _drowsinessAlerts++;
      _alertService.playDrowsinessAlert();
    } else {
      _distractionAlerts++;
      _alertService.playYawnWarning();
    }

    unawaited(_saveAlert(alertType));

    final activeState = _buildActiveState(
      detectionStatus: _resolveTelemetryStatus(latest),
      isAiReady: true,
    );

    emit(
      TripDangerAlert(
        alertType: alertType,
        confidence: latest.score,
        activeState: activeState,
      ),
    );
  }

  void _applyTelemetryStats(EspTelemetryStatsEntity stats) {
    if (stats.total <= 0) {
      return;
    }

    final safePercent = (stats.safeCount / stats.total) * 100;
    _awakePercentage = safePercent.clamp(0, 100).toDouble();
    _updateActiveState();
  }

  DetectionStatus _resolveTelemetryStatus(EspTelemetryLogEntity latest) {
    if (_activeTrip?.isStopped ?? false) {
      return DetectionStatus.offline;
    }

    if (!latest.faceDetected) {
      return DetectionStatus.offline;
    }

    if (latest.eyeAlert || latest.alert || latest.headDown) {
      return DetectionStatus.drowsy;
    }

    if (latest.yawn) {
      return DetectionStatus.yawning;
    }

    return DetectionStatus.safe;
  }

  String _mapTelemetryAlertType(EspTelemetryLogEntity latest) {
    if (!latest.faceDetected) {
      return 'no_face';
    }

    if (latest.eyeAlert) {
      return 'eyes_closed';
    }

    if (latest.headDown || latest.alert) {
      return 'drowsiness';
    }

    if (latest.yawn) {
      return 'yawning';
    }

    return 'drowsiness';
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
        _tripLiveUpdates?.emitProgress(tripId: tripId);
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
      var syncedAny = false;

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
        } else {
          syncedAny = true;
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
        } else {
          syncedAny = true;
        }
      }

      _updateActiveState(pendingSyncCount: _offlineCache.totalPendingCount);

      if (syncedAny) {
        _tripLiveUpdates?.emit(
          type: TripLiveUpdateType.synced,
          tripId: _activeTrip?.tripIdOrZero,
        );
      }
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
          _lastPosition?.latitude ??
          fallbackPosition?.latitude ??
          snapshot.latitude;
      final longitude =
          _lastPosition?.longitude ??
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

          _tripLiveUpdates?.emit(
            type: TripLiveUpdateType.finished,
            tripId: finishedTrip.tripIdOrZero,
          );
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
    final awake = _lastTelemetryAt != null
      ? _awakePercentage
      : (trip?.awakePercentage ?? 100.0);

    return TripEnded(
      duration: (trip?.duration ?? '').trim().isNotEmpty
          ? trip!.duration
          : fallbackDuration,
      distance: (trip?.distance ?? '').trim().isNotEmpty
          ? trip!.distance
          : fallbackDistance,
      alertCount: _alertCount,
      awakePercentage: awake,
      wasCancelled: wasCancelled,
    );
  }

  void _stopAllSubsystems() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _telemetryStatsTimer?.cancel();
    _telemetryStatsTimer = null;

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    _locationService.stopTracking();
    _alertService.stop();
    unawaited(_localTelemetryServer.stop());
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
      awakePercentage: _lastTelemetryAt != null
        ? _awakePercentage
        : (_activeTrip?.awakePercentage ?? 100.0),
      latitude: latitude ?? base?.latitude ?? _activeTrip?.currentLatitude,
      longitude: longitude ?? base?.longitude ?? _activeTrip?.currentLongitude,
      totalDistanceMeters: _totalDistanceMeters,
      isAiReady: isAiReady ?? base?.isAiReady ?? _isTelemetryReady,
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
    _telemetryTimer?.cancel();
    _telemetryStatsTimer?.cancel();
  }

  void onAppResumed() {
    if (_activeTrip == null) {
      return;
    }

    if (_activeTrip!.isStarted) {
      _startTelemetryLoop();
      _startTelemetryStatsLoop();
    }

    if (_connectivity.isOnline) {
      unawaited(_syncPendingData());
    }
  }

  @override
  Future<void> close() {
    _connectivity.onConnectivityRestored = null;
    _connectivity.onConnectivityLost = null;
    _fcmAlertSubscription?.cancel();
    _localTelemetrySubscription?.cancel();
    _stopAllSubsystems();
    return super.close();
  }

  // ─── FCM Alert Handler ──────────────────────────────────────────────────
  /// Called whenever an 'alert' or 'emergency' push notification arrives.
  /// Triggers the same TripDangerAlert flow as ESP telemetry, so the driver
  /// sees the red overlay + hears the alarm even when ESP hardware is absent.
  void _onFcmAlert(Map<String, dynamic> data) {
    if (_activeTrip == null) {
      return; // no active trip – ignore
    }

    final String rawAlertType = (data['alert_type'] ?? '').toString().trim();
    final double confidence =
        double.tryParse((data['confidence'] ?? '0.9').toString()) ?? 0.9;

    final String alertType = _normaliseFcmAlertType(rawAlertType);

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

    // Play the appropriate sound
    if (alertType == 'drowsiness' || alertType == 'eyes_closed') {
      _drowsinessAlerts++;
      _alertService.playDrowsinessAlert();
    } else {
      _distractionAlerts++;
      _alertService.playYawnWarning();
    }

    // Build & emit the danger alert state
    final activeState = _buildActiveState(
      detectionStatus: _alertTypeToDetectionStatus(alertType),
      isAiReady: true,
    );

    emit(
      TripDangerAlert(
        alertType: alertType,
        confidence: confidence,
        activeState: activeState,
      ),
    );
  }

  /// Normalises backend alert_type values to the alertType strings used
  /// by TripDangerAlert / the alert overlay.
  String _normaliseFcmAlertType(String raw) {
    switch (raw) {
      case 'sleep':
      case 'drowsy':
      case 'head_down':
        return 'drowsiness';
      case 'eyes_closed':
        return 'eyes_closed';
      case 'yawning':
        return 'yawning';
      case 'no_face':
        return 'no_face';
      default:
        return 'drowsiness'; // safe fallback
    }
  }

  DetectionStatus _alertTypeToDetectionStatus(String alertType) {
    switch (alertType) {
      case 'drowsiness':
      case 'eyes_closed':
        return DetectionStatus.drowsy;
      case 'yawning':
        return DetectionStatus.yawning;
      default:
        return DetectionStatus.drowsy;
    }
  }

  void _onLocalTelemetry(Map<String, dynamic> data) {
    if (_activeTrip == null) {
      return; // no active trip – ignore
    }

    final bool faceDetected = data['face_detected'] ?? true;
    final bool eyeAlert = data['eye_alert'] ?? false;
    final bool yawn = data['yawn'] ?? false;
    final bool headDown = data['head_down'] ?? false;
    final bool alert = data['alert'] ?? false;
    final double confidence =
        double.tryParse((data['score'] ?? '0.9').toString()) ?? 0.9;

    String? alertType;
    if (!faceDetected) {
      alertType = 'no_face';
    } else if (eyeAlert) {
      alertType = 'eyes_closed';
    } else if (headDown || alert) {
      alertType = 'drowsiness';
    } else if (yawn) {
      alertType = 'yawning';
    }

    if (alertType != null) {
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

      // Play the appropriate sound
      if (alertType == 'drowsiness' || alertType == 'eyes_closed') {
        _drowsinessAlerts++;
        _alertService.playDrowsinessAlert();
      } else {
        _distractionAlerts++;
        _alertService.playYawnWarning();
      }

      // Save/cache alert locally to sync later
      unawaited(_saveAlert(alertType));

      // Build & emit the danger alert state
      final activeState = _buildActiveState(
        detectionStatus: _alertTypeToDetectionStatus(alertType),
        isAiReady: true,
      );

      emit(
        TripDangerAlert(
          alertType: alertType,
          confidence: confidence,
          activeState: activeState,
        ),
      );
    } else {
      // Safe state update
      _updateActiveState(
        detectionStatus: DetectionStatus.safe,
        isAiReady: true,
      );
    }
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

    if (normalized.contains(
      'location updates are allowed only for active trips',
    )) {
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

  // ─── Alerts Polling & Acknowledgment ──────────────────────────────────────

  Future<void> _pollAlertsLatest() async {
    if (_isPollingAlerts ||
        _activeTrip == null ||
        !_activeTrip!.isStarted ||
        !_connectivity.isOnline) {
      return;
    }

    _isPollingAlerts = true;

    try {
      final result = await _tripRepository.loadTripAlerts(
        tripId: _activeTrip!.tripIdOrZero,
      );

      await result.fold(
        (failure) async {
          debugPrint('Trip alerts fetch failed: ${failure.message}');
        },
        (alerts) async {
          if (alerts.isEmpty) {
            return;
          }

          // Alerts are sorted by -created_at on the backend.
          final latest = alerts.first;

          if (_lastAlertId == null) {
            _lastAlertId = latest.id;
            return;
          }

          if (latest.id > _lastAlertId!) {
            _lastAlertId = latest.id;
            _handleBackendAlert(latest);
          }
        },
      );
    } catch (error) {
      debugPrint('Trip alerts poll failed: $error');
    } finally {
      _isPollingAlerts = false;
    }
  }

  void _handleBackendAlert(AlertEntity alert) {
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

    final alertType = _normaliseFcmAlertType(alert.alertType);
    if (alertType == 'drowsiness' || alertType == 'eyes_closed') {
      _drowsinessAlerts++;
      _alertService.playDrowsinessAlert();
    } else {
      _distractionAlerts++;
      _alertService.playYawnWarning();
    }

    final activeState = _buildActiveState(
      detectionStatus: _alertTypeToDetectionStatus(alertType),
      isAiReady: true,
    );

    emit(
      TripDangerAlert(
        alertType: alertType,
        confidence: 0.95,
        activeState: activeState,
      ),
    );
  }

  void acknowledgeAlert() {
    if (_activeTrip != null && state is TripDangerAlert) {
      _alertService.stop();
      _updateActiveState(
        detectionStatus: _activeTrip!.isStopped
            ? DetectionStatus.offline
            : DetectionStatus.safe,
        isAiReady: true,
      );
    }
  }
}
