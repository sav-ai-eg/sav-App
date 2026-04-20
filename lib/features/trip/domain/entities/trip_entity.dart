import 'package:equatable/equatable.dart';

class TripEntity extends Equatable {
  const TripEntity({
    required this.id,
    required this.driverId,
    required this.from,
    required this.to,
    this.fromPlaceId,
    this.toPlaceId,
    this.fromLatitude,
    this.fromLongitude,
    this.toLatitude,
    this.toLongitude,
    this.currentLatitude,
    this.currentLongitude,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration,
    this.distance,
    this.alerts = 0,
    this.drowsinessAlerts = 0,
    this.distractionAlerts = 0,
    this.awakePercentage,
    this.durationSeconds = 0,
  });

  final String id;
  final String driverId;
  final String from;
  final String to;
  final String? fromPlaceId;
  final String? toPlaceId;
  final double? fromLatitude;
  final double? fromLongitude;
  final double? toLatitude;
  final double? toLongitude;
  final double? currentLatitude;
  final double? currentLongitude;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final String? duration;
  final String? distance;
  final int alerts;
  final int drowsinessAlerts;
  final int distractionAlerts;
  final double? awakePercentage;
  final int durationSeconds;

  String get normalizedStatus => status.trim().toLowerCase();

  bool get isStarted => normalizedStatus == 'started';

  bool get isStopped => normalizedStatus == 'stopped';

  bool get isFinished => normalizedStatus == 'finished';

  bool get isCancelled => normalizedStatus == 'cancelled';

  bool get isActive => isStarted || isStopped;

  int get tripIdOrZero => int.tryParse(id) ?? 0;

  TripEntity copyWith({
    String? id,
    String? driverId,
    String? from,
    String? to,
    String? fromPlaceId,
    String? toPlaceId,
    double? fromLatitude,
    double? fromLongitude,
    double? toLatitude,
    double? toLongitude,
    double? currentLatitude,
    double? currentLongitude,
    String? status,
    DateTime? startTime,
    DateTime? endTime,
    String? duration,
    String? distance,
    int? alerts,
    int? drowsinessAlerts,
    int? distractionAlerts,
    double? awakePercentage,
    int? durationSeconds,
  }) {
    return TripEntity(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      from: from ?? this.from,
      to: to ?? this.to,
      fromPlaceId: fromPlaceId ?? this.fromPlaceId,
      toPlaceId: toPlaceId ?? this.toPlaceId,
      fromLatitude: fromLatitude ?? this.fromLatitude,
      fromLongitude: fromLongitude ?? this.fromLongitude,
      toLatitude: toLatitude ?? this.toLatitude,
      toLongitude: toLongitude ?? this.toLongitude,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      alerts: alerts ?? this.alerts,
      drowsinessAlerts: drowsinessAlerts ?? this.drowsinessAlerts,
      distractionAlerts: distractionAlerts ?? this.distractionAlerts,
      awakePercentage: awakePercentage ?? this.awakePercentage,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    driverId,
    from,
    to,
    fromPlaceId,
    toPlaceId,
    fromLatitude,
    fromLongitude,
    toLatitude,
    toLongitude,
    currentLatitude,
    currentLongitude,
    status,
    startTime,
    endTime,
    duration,
    distance,
    alerts,
    drowsinessAlerts,
    distractionAlerts,
    awakePercentage,
    durationSeconds,
  ];
}
