import 'package:equatable/equatable.dart';

class EspTelemetryLogEntity extends Equatable {
  const EspTelemetryLogEntity({
    required this.id,
    required this.deviceUid,
    this.deviceId,
    this.driverId,
    this.tripId,
    this.faceDetected = true,
    this.eye = '',
    this.eyeClosedTime = 0.0,
    this.eyeAlert = false,
    this.yawn = false,
    this.headDown = false,
    this.alert = false,
    this.score = 0.0,
    this.capturedAt,
    this.createdAt,
  });

  final int id;
  final int? deviceId;
  final String deviceUid;
  final int? driverId;
  final int? tripId;
  final bool faceDetected;
  final String eye;
  final double eyeClosedTime;
  final bool eyeAlert;
  final bool yawn;
  final bool headDown;
  final bool alert;
  final double score;
  final DateTime? capturedAt;
  final DateTime? createdAt;

  DateTime? get eventTime => capturedAt ?? createdAt;

  bool get hasDanger =>
      alert || eyeAlert || yawn || headDown || !faceDetected;

  @override
  List<Object?> get props => <Object?>[
    id,
    deviceId,
    deviceUid,
    driverId,
    tripId,
    faceDetected,
    eye,
    eyeClosedTime,
    eyeAlert,
    yawn,
    headDown,
    alert,
    score,
    capturedAt,
    createdAt,
  ];
}
