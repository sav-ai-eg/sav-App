import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/google_directions_service.dart';

class TripNavigationSnapshot {
  const TripNavigationSnapshot({
    required this.routeData,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.currentInstruction,
    required this.nextInstruction,
    required this.currentManeuver,
    required this.distanceToManeuverMeters,
    required this.distanceToManeuverText,
    required this.remainingDistanceMeters,
    required this.remainingDurationSeconds,
    required this.remainingDistanceText,
    required this.remainingDurationText,
    required this.isOffRoute,
    required this.didReroute,
    required this.isApiKeyMissing,
  });

  final GoogleRouteData routeData;
  final int currentStepIndex;
  final int totalSteps;
  final String currentInstruction;
  final String nextInstruction;
  final String currentManeuver;
  final double distanceToManeuverMeters;
  final String distanceToManeuverText;
  final int remainingDistanceMeters;
  final int remainingDurationSeconds;
  final String remainingDistanceText;
  final String remainingDurationText;
  final bool isOffRoute;
  final bool didReroute;
  final bool isApiKeyMissing;

  bool get hasTurnGuidance => currentInstruction.trim().isNotEmpty;
}

class TripNavigationService {
  TripNavigationService(this._directionsService);

  static const double _offRouteThresholdMeters = 95;
  static const double _stepArrivalThresholdMeters = 28;
  static const Duration _minRerouteInterval = Duration(seconds: 12);

  final GoogleDirectionsService _directionsService;
  final FlutterTts _tts = FlutterTts();

  GoogleRouteData? _route;
  LatLng? _destination;
  int _currentStepIndex = 0;
  DateTime? _lastRouteUpdateAt;

  int _lastAnnouncedStepIndex = -1;
  String _lastAnnouncementBucket = '';

  bool _voiceEnabled = true;
  bool _ttsConfigured = false;

  void setVoiceEnabled(bool enabled) {
    _voiceEnabled = enabled;
    if (!enabled) {
      _safelyStopTts();
    }
  }

  Future<void> resetSession({bool stopVoice = true}) async {
    _route = null;
    _destination = null;
    _currentStepIndex = 0;
    _lastRouteUpdateAt = null;
    _lastAnnouncedStepIndex = -1;
    _lastAnnouncementBucket = '';

    if (stopVoice) {
      await _safelyStopTts();
    }
  }

  Future<TripNavigationSnapshot> updateNavigation({
    required LatLng currentPosition,
    required LatLng destination,
    required bool isOnline,
    bool forceReroute = false,
  }) async {
    if (!AppConstants.hasGoogleMapsApiKey) {
      await resetSession();
      return TripNavigationSnapshot(
        routeData: GoogleRouteData.empty,
        currentStepIndex: 0,
        totalSteps: 0,
        currentInstruction: '',
        nextInstruction: '',
        currentManeuver: '',
        distanceToManeuverMeters: 0,
        distanceToManeuverText: '',
        remainingDistanceMeters: 0,
        remainingDurationSeconds: 0,
        remainingDistanceText: '',
        remainingDurationText: '',
        isOffRoute: false,
        didReroute: false,
        isApiKeyMissing: true,
      );
    }

    final destinationChanged =
        _destination == null ||
        _distanceBetween(_destination!, destination) > 30;

    if (destinationChanged) {
      _destination = destination;
      _route = null;
      _currentStepIndex = 0;
      _lastAnnouncedStepIndex = -1;
      _lastAnnouncementBucket = '';
    }

    var route = _route;
    var isOffRoute = false;
    var didReroute = false;

    if (route != null && route.hasPath) {
      isOffRoute =
          _distanceToPolyline(currentPosition, route.points) >
          _offRouteThresholdMeters;
    }

    final shouldReroute =
        isOnline &&
        (forceReroute ||
            destinationChanged ||
            route == null ||
            !route.hasPath ||
            (isOffRoute && _canReroute()));

    if (shouldReroute) {
      didReroute = await _fetchRoute(
        currentPosition: currentPosition,
        destination: destination,
      );
      route = _route;

      if (didReroute) {
        isOffRoute = false;
      }
    }

    if (route == null || !route.hasPath || route.steps.isEmpty) {
      return TripNavigationSnapshot(
        routeData: route ?? GoogleRouteData.empty,
        currentStepIndex: 0,
        totalSteps: route?.steps.length ?? 0,
        currentInstruction: '',
        nextInstruction: '',
        currentManeuver: '',
        distanceToManeuverMeters: 0,
        distanceToManeuverText: '',
        remainingDistanceMeters: route?.distanceMeters ?? 0,
        remainingDurationSeconds: route?.durationSeconds ?? 0,
        remainingDistanceText: route?.distanceText ?? '',
        remainingDurationText: route?.durationText ?? '',
        isOffRoute: isOffRoute,
        didReroute: didReroute,
        isApiKeyMissing: false,
      );
    }

    _currentStepIndex = _resolveCurrentStepIndex(
      currentPosition,
      route.steps,
      _currentStepIndex,
    );

    if (_currentStepIndex >= route.steps.length) {
      _currentStepIndex = route.steps.length - 1;
    }

    var activeStep = route.steps[_currentStepIndex];
    var distanceToTurn = _distanceBetween(
      currentPosition,
      activeStep.endLocation,
    );

    if (distanceToTurn <= _stepArrivalThresholdMeters &&
        _currentStepIndex < route.steps.length - 1) {
      _currentStepIndex += 1;
      activeStep = route.steps[_currentStepIndex];
      distanceToTurn = _distanceBetween(
        currentPosition,
        activeStep.endLocation,
      );
      _lastAnnouncedStepIndex = -1;
      _lastAnnouncementBucket = '';
    }

    final nextInstruction = _currentStepIndex + 1 < route.steps.length
        ? route.steps[_currentStepIndex + 1].instruction
        : '';

    final remaining = _calculateRemainingMetrics(
      steps: route.steps,
      currentStepIndex: _currentStepIndex,
      distanceToCurrentStepMeters: distanceToTurn,
    );

    await _announceIfNeeded(
      instruction: activeStep.instruction,
      distanceMeters: distanceToTurn,
      stepIndex: _currentStepIndex,
      didReroute: didReroute,
    );

    return TripNavigationSnapshot(
      routeData: route,
      currentStepIndex: _currentStepIndex,
      totalSteps: route.steps.length,
      currentInstruction: activeStep.instruction,
      nextInstruction: nextInstruction,
      currentManeuver: activeStep.maneuver,
      distanceToManeuverMeters: distanceToTurn,
      distanceToManeuverText: _formatDistance(distanceToTurn.round()),
      remainingDistanceMeters: remaining.remainingDistanceMeters,
      remainingDurationSeconds: remaining.remainingDurationSeconds,
      remainingDistanceText: _formatDistance(remaining.remainingDistanceMeters),
      remainingDurationText: _formatDuration(
        remaining.remainingDurationSeconds,
      ),
      isOffRoute: isOffRoute,
      didReroute: didReroute,
      isApiKeyMissing: false,
    );
  }

  Future<bool> _fetchRoute({
    required LatLng currentPosition,
    required LatLng destination,
  }) async {
    final previousRoute = _route;

    try {
      final route = await _directionsService.getDrivingRoute(
        originLatitude: currentPosition.latitude,
        originLongitude: currentPosition.longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
      );

      _lastRouteUpdateAt = DateTime.now();

      if (route.hasPath) {
        _route = route;
        _currentStepIndex = 0;
        _lastAnnouncedStepIndex = -1;
        _lastAnnouncementBucket = '';
        return true;
      }

      if (previousRoute == null || !previousRoute.hasPath) {
        _route = null;
      }

      return false;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Trip navigation reroute failed: $error');
      }
      return false;
    }
  }

  bool _canReroute() {
    final lastUpdate = _lastRouteUpdateAt;
    if (lastUpdate == null) {
      return true;
    }

    return DateTime.now().difference(lastUpdate) >= _minRerouteInterval;
  }

  int _resolveCurrentStepIndex(
    LatLng currentPosition,
    List<GoogleRouteStep> steps,
    int preferredIndex,
  ) {
    if (steps.isEmpty) {
      return 0;
    }

    final safePreferred = preferredIndex < 0
        ? 0
        : preferredIndex >= steps.length
        ? steps.length - 1
        : preferredIndex;

    final start = math.max(0, safePreferred - 1);
    var bestIndex = safePreferred;
    var bestDistance = double.infinity;

    for (var index = start; index < steps.length; index++) {
      final distance = _distanceToStep(currentPosition, steps[index]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }

      if (index > safePreferred + 5 && bestDistance < 25) {
        break;
      }
    }

    return bestIndex;
  }

  ({int remainingDistanceMeters, int remainingDurationSeconds})
  _calculateRemainingMetrics({
    required List<GoogleRouteStep> steps,
    required int currentStepIndex,
    required double distanceToCurrentStepMeters,
  }) {
    if (steps.isEmpty) {
      return (remainingDistanceMeters: 0, remainingDurationSeconds: 0);
    }

    final activeStep = steps[currentStepIndex];

    var remainingDistance = math.max(0, distanceToCurrentStepMeters.round());

    var remainingDuration = 0;
    if (activeStep.distanceMeters > 0 && activeStep.durationSeconds > 0) {
      final ratio = (distanceToCurrentStepMeters / activeStep.distanceMeters)
          .clamp(0.0, 1.0);
      remainingDuration = (activeStep.durationSeconds * ratio).round();
    } else {
      remainingDuration = activeStep.durationSeconds;
    }

    for (var index = currentStepIndex + 1; index < steps.length; index++) {
      remainingDistance += steps[index].distanceMeters;
      remainingDuration += steps[index].durationSeconds;
    }

    return (
      remainingDistanceMeters: remainingDistance,
      remainingDurationSeconds: remainingDuration,
    );
  }

  double _distanceToStep(LatLng point, GoogleRouteStep step) {
    final points = step.polylinePoints.length >= 2
        ? step.polylinePoints
        : <LatLng>[step.startLocation, step.endLocation];

    return _distanceToPolyline(point, points);
  }

  double _distanceToPolyline(LatLng point, List<LatLng> polyline) {
    if (polyline.isEmpty) {
      return double.infinity;
    }

    var minDistance = double.infinity;

    for (final routePoint in polyline) {
      final distance = _distanceBetween(point, routePoint);
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  double _distanceBetween(LatLng first, LatLng second) {
    return Geolocator.distanceBetween(
      first.latitude,
      first.longitude,
      second.latitude,
      second.longitude,
    );
  }

  Future<void> _announceIfNeeded({
    required String instruction,
    required double distanceMeters,
    required int stepIndex,
    required bool didReroute,
  }) async {
    if (!_voiceEnabled || instruction.trim().isEmpty) {
      return;
    }

    if (didReroute) {
      await _speak('Route updated.');
    }

    if (_lastAnnouncedStepIndex != stepIndex) {
      _lastAnnouncedStepIndex = stepIndex;
      _lastAnnouncementBucket = '';
    }

    final bucket = _announcementBucket(distanceMeters);
    if (bucket.isEmpty || bucket == _lastAnnouncementBucket) {
      return;
    }

    _lastAnnouncementBucket = bucket;

    final roundedDistance = math.max(0, distanceMeters.round());
    final speechText = switch (bucket) {
      'prepare' =>
        'Continue for ${_formatDistance(roundedDistance)}, then $instruction',
      'soon' => 'In ${_formatDistance(roundedDistance)}, $instruction',
      'now' => 'Now, $instruction',
      _ => '',
    };

    if (speechText.isNotEmpty) {
      await _speak(speechText);
    }
  }

  String _announcementBucket(double distanceMeters) {
    if (distanceMeters <= 35) {
      return 'now';
    }

    if (distanceMeters <= 110) {
      return 'soon';
    }

    if (distanceMeters <= 280) {
      return 'prepare';
    }

    return '';
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    try {
      await _configureTtsIfNeeded();
      await _tts.stop();
      await _tts.speak(text);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Trip navigation voice failed: $error');
      }
    }
  }

  Future<void> _safelyStopTts() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Keep trip flow resilient when TTS is unavailable.
    }
  }

  Future<void> _configureTtsIfNeeded() async {
    if (_ttsConfigured) {
      return;
    }

    _ttsConfigured = true;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.46);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      // Some devices/kernels might not support TTS options consistently.
    }
  }

  String _formatDistance(int meters) {
    if (meters <= 0) {
      return '';
    }

    if (meters < 1000) {
      return '$meters m';
    }

    final kilometers = meters / 1000;
    if (kilometers >= 10) {
      return '${kilometers.toStringAsFixed(0)} km';
    }

    return '${kilometers.toStringAsFixed(1)} km';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '';
    }

    final totalMinutes = (seconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '$hours h ${minutes.toString().padLeft(2, '0')} min';
    }

    return '$totalMinutes min';
  }
}
