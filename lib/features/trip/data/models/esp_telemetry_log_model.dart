import 'package:sav/features/trip/domain/entities/esp_telemetry_log_entity.dart';

class EspTelemetryLogModel extends EspTelemetryLogEntity {
  const EspTelemetryLogModel({
    required super.id,
    required super.deviceUid,
    super.deviceId,
    super.driverId,
    super.tripId,
    super.faceDetected,
    super.eye,
    super.eyeClosedTime,
    super.eyeAlert,
    super.yawn,
    super.headDown,
    super.alert,
    super.score,
    super.capturedAt,
    super.createdAt,
  });

  factory EspTelemetryLogModel.fromMap(Map<String, dynamic> map) {
    return EspTelemetryLogModel(
      id: _toInt(map['id']),
      deviceId: _toNullableInt(map['device']),
      deviceUid: _toString(map['device_uid']),
      driverId: _toNullableInt(map['driver']),
      tripId: _toNullableInt(map['trip']),
      faceDetected: _toBool(map['face_detected'], defaultValue: true),
      eye: _toString(map['eye']),
      eyeClosedTime: _toDouble(map['eye_closed_time']),
      eyeAlert: _toBool(map['eye_alert']),
      yawn: _toBool(map['yawn']),
      headDown: _toBool(map['head_down']),
      alert: _toBool(map['alert']),
      score: _toDouble(map['score']),
      capturedAt: _toDateTime(map['captured_at']),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  static String _toString(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text;
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
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse((value ?? '').toString()) ?? 0.0;
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) {
      return value;
    }
    final text = (value ?? '').toString().toLowerCase().trim();
    if (text == 'true' || text == '1') {
      return true;
    }
    if (text == 'false' || text == '0' || text.isEmpty) {
      return false;
    }
    return defaultValue;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
