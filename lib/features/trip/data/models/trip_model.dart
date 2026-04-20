import 'package:sav/features/trip/domain/entities/trip_entity.dart';

class TripModel extends TripEntity {
  const TripModel({
    required super.id,
    required super.driverId,
    required super.from,
    required super.to,
    super.fromPlaceId,
    super.toPlaceId,
    super.fromLatitude,
    super.fromLongitude,
    super.toLatitude,
    super.toLongitude,
    super.currentLatitude,
    super.currentLongitude,
    required super.status,
    required super.startTime,
    super.endTime,
    super.duration,
    super.distance,
    super.alerts,
    super.drowsinessAlerts,
    super.distractionAlerts,
    super.awakePercentage,
    super.durationSeconds,
  });

  factory TripModel.fromBackendMap(Map<String, dynamic> map) {
    final startTime = _toDateTime(map['start_time']) ?? DateTime.now();
    final endTime = _toDateTime(map['end_time']);
    final durationSeconds =
        _toInt(map['duration_seconds']) > 0 ? _toInt(map['duration_seconds']) :
            (endTime == null ? 0 : endTime.difference(startTime).inSeconds);

    return TripModel(
      id: _toString(map['id']),
      driverId: _toString(map['driver']),
      from: _toString(map['start_address']),
      to: _toString(map['destination_address']),
      fromLatitude: _toNullableDouble(map['start_latitude']),
      fromLongitude: _toNullableDouble(map['start_longitude']),
      toLatitude: _toNullableDouble(map['destination_latitude']) ??
          _toNullableDouble(map['end_latitude']),
      toLongitude: _toNullableDouble(map['destination_longitude']) ??
          _toNullableDouble(map['end_longitude']),
      currentLatitude: _toNullableDouble(map['current_latitude']),
      currentLongitude: _toNullableDouble(map['current_longitude']),
      status: _toString(map['status'], fallback: 'started'),
      startTime: startTime,
      endTime: endTime,
      duration: _toDurationLabel(
        durationSeconds: durationSeconds,
        minutes: _toNullableInt(map['duration_minutes']),
      ),
      distance: _toDistanceLabel(map['distance_km']),
      alerts: _toInt(map['alerts']),
      drowsinessAlerts: _toInt(map['drowsiness_alerts']),
      distractionAlerts: _toInt(map['distraction_alerts']),
      awakePercentage: _toNullableDouble(map['awake_percentage']),
      durationSeconds: durationSeconds,
    );
  }

  factory TripModel.fromHistoryMap(Map<String, dynamic> map) {
    final startTime = _toDateTime(map['start_time']) ?? DateTime.now();
    final endTime = _toDateTime(map['end_time']);
    final durationSeconds = _toInt(map['duration_seconds']);

    return TripModel(
      id: _toString(map['id']),
      driverId: _toString(map['driver']),
      from: _toString(map['start_address']),
      to: _toString(map['destination_address']),
      status: _toString(map['status'], fallback: 'finished'),
      startTime: startTime,
      endTime: endTime,
      duration: _toDurationLabel(durationSeconds: durationSeconds),
      distance: _toDistanceLabel(map['distance_km']),
      alerts: _toInt(map['alerts']),
      drowsinessAlerts: _toInt(map['drowsiness_alerts']),
      distractionAlerts: _toInt(map['distraction_alerts']),
      durationSeconds: durationSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'driver': driverId,
      'status': status,
      'start_address': from,
      'destination_address': to,
      'start_latitude': fromLatitude,
      'start_longitude': fromLongitude,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'end_latitude': toLatitude,
      'end_longitude': toLongitude,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      'duration_seconds': durationSeconds,
      'alerts': alerts,
      'drowsiness_alerts': drowsinessAlerts,
      'distraction_alerts': distractionAlerts,
      'awake_percentage': awakePercentage,
    };
  }

  static String _toString(dynamic value, {String fallback = ''}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static String _toDurationLabel({
    required int durationSeconds,
    int? minutes,
  }) {
    final resolvedSeconds = durationSeconds > 0
        ? durationSeconds
        : ((minutes ?? 0) * 60);

    if (resolvedSeconds <= 0) {
      return '';
    }

    final totalMinutes = (resolvedSeconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    if (hours > 0) {
      return '$hours h, $mins min';
    }

    return '$totalMinutes min';
  }

  static String _toDistanceLabel(dynamic value) {
    final km = _toNullableDouble(value);
    if (km == null || km <= 0) {
      return '';
    }

    return '${km.toStringAsFixed(1)} KM';
  }
}
