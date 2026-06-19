import 'package:sav/features/trip/domain/entities/esp_telemetry_stats_entity.dart';

class EspTelemetryStatsModel extends EspTelemetryStatsEntity {
  const EspTelemetryStatsModel({
    required super.total,
    required super.alertsTrue,
    required super.eyesClosed,
    required super.yawn,
    required super.headDown,
    required super.noFace,
  });

  factory EspTelemetryStatsModel.fromMap(Map<String, dynamic> map) {
    return EspTelemetryStatsModel(
      total: _toInt(map['total']),
      alertsTrue: _toInt(map['alerts_true']),
      eyesClosed: _toInt(map['eyes_closed']),
      yawn: _toInt(map['yawn']),
      headDown: _toInt(map['head_down']),
      noFace: _toInt(map['no_face']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
