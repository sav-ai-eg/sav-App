part of 'trip_cubit.dart';

/// Detection status during an active trip.
enum DetectionStatus { safe, drowsy, yawning, offline, initializing }

abstract class TripState {
  const TripState();

  bool get hideBottomNav => false;
}

class TripInitial extends TripState {
  const TripInitial();
}

class TripLoading extends TripState {
  final String title;
  final String message;

  const TripLoading({
    this.title = 'Preparing your trip',
    this.message = 'Hold on while we get everything ready.',
  });
}

/// Main active trip state — contains all real-time data.
class TripActive extends TripState {
  final TripModel trip;
  final DetectionStatus detectionStatus;
  final int alertCount;
  final int drowsinessAlerts;
  final int distractionAlerts;
  final double awakePercentage;
  final double? latitude;
  final double? longitude;
  final double totalDistanceMeters;
  final bool isAiReady;
  final bool isCameraReady;
  final bool isOnline;
  final int pendingSyncCount;

  const TripActive({
    required this.trip,
    this.detectionStatus = DetectionStatus.initializing,
    this.alertCount = 0,
    this.drowsinessAlerts = 0,
    this.distractionAlerts = 0,
    this.awakePercentage = 100.0,
    this.latitude,
    this.longitude,
    this.totalDistanceMeters = 0,
    this.isAiReady = false,
    this.isCameraReady = false,
    this.isOnline = true,
    this.pendingSyncCount = 0,
  });

  TripActive copyWith({
    TripModel? trip,
    DetectionStatus? detectionStatus,
    int? alertCount,
    int? drowsinessAlerts,
    int? distractionAlerts,
    double? awakePercentage,
    double? latitude,
    double? longitude,
    double? totalDistanceMeters,
    bool? isAiReady,
    bool? isCameraReady,
    bool? isOnline,
    int? pendingSyncCount,
  }) {
    return TripActive(
      trip: trip ?? this.trip,
      detectionStatus: detectionStatus ?? this.detectionStatus,
      alertCount: alertCount ?? this.alertCount,
      drowsinessAlerts: drowsinessAlerts ?? this.drowsinessAlerts,
      distractionAlerts: distractionAlerts ?? this.distractionAlerts,
      awakePercentage: awakePercentage ?? this.awakePercentage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      isAiReady: isAiReady ?? this.isAiReady,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }

  String get formattedDistance {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.toInt()} m';
    }
    return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} KM';
  }

  @override
  bool get hideBottomNav => true;
}

/// Transient state emitted briefly when a danger alert occurs.
class TripDangerAlert extends TripState {
  final String alertType; // 'drowsiness' or 'yawn'
  final double confidence;
  final TripActive activeState; // the underlying active state

  const TripDangerAlert({
    required this.alertType,
    required this.confidence,
    required this.activeState,
  });

  @override
  bool get hideBottomNav => true;
}

class TripEnding extends TripState {
  final TripActive activeState;

  const TripEnding({required this.activeState});

  @override
  bool get hideBottomNav => true;
}

class TripEnded extends TripState {
  final String? duration;
  final String? distance;
  final int alertCount;
  final double awakePercentage;

  const TripEnded({
    this.duration,
    this.distance,
    this.alertCount = 0,
    this.awakePercentage = 100.0,
  });
}

class TripError extends TripState {
  final String message;
  final bool keepNavigationHidden;

  const TripError({required this.message, this.keepNavigationHidden = false});

  @override
  bool get hideBottomNav => keepNavigationHidden;
}

/// Emitted when permissions are needed before starting.
class TripPermissionNeeded extends TripState {
  final bool needsCamera;
  final bool needsLocation;
  const TripPermissionNeeded({
    this.needsCamera = false,
    this.needsLocation = false,
  });
}
