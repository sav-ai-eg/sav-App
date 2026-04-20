import 'package:sav/features/trip/domain/entities/trip_event_entity.dart';

class TripEventModel extends TripEventEntity {
  const TripEventModel({
    required super.id,
    required super.tripId,
    required super.eventType,
    required super.createdAt,
    super.actorId,
    super.actorUsername,
    super.previousStatus,
    super.newStatus,
    super.notes,
    super.latitude,
    super.longitude,
  });

  factory TripEventModel.fromMap(Map<String, dynamic> map) {
    return TripEventModel(
      id: _toInt(map['id']),
      tripId: _toInt(map['trip']),
      eventType: (map['event_type'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      actorId: _toNullableInt(map['actor']),
      actorUsername: (map['actor_username'] ?? '').toString().trim().isEmpty
          ? null
          : (map['actor_username'] ?? '').toString(),
      previousStatus: _toNullableString(map['previous_status']),
      newStatus: _toNullableString(map['new_status']),
      notes: _toNullableString(map['notes']),
      latitude: _toNullableDouble(map['latitude']),
      longitude: _toNullableDouble(map['longitude']),
    );
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

  static String? _toNullableString(dynamic value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
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
}
