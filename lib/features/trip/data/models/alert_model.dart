import 'package:sav/features/trip/domain/entities/alert_entity.dart';

class AlertModel extends AlertEntity {
  const AlertModel({
    required super.id,
    required super.driverId,
    required super.tripId,
    required super.alertType,
    required super.source,
    required super.sourceId,
    required super.createdAt,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: _toInt(map['id']),
      driverId: _toInt(map['driver']),
      tripId: _toInt(map['trip']),
      alertType: (map['alert_type'] ?? '').toString(),
      source: (map['source'] ?? '').toString(),
      sourceId: (map['source_id'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
