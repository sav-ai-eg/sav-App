import 'package:equatable/equatable.dart';

class TripEventEntity extends Equatable {
  const TripEventEntity({
    required this.id,
    required this.tripId,
    required this.eventType,
    required this.createdAt,
    this.actorId,
    this.actorUsername,
    this.previousStatus,
    this.newStatus,
    this.notes,
    this.latitude,
    this.longitude,
  });

  final int id;
  final int tripId;
  final String eventType;
  final DateTime createdAt;
  final int? actorId;
  final String? actorUsername;
  final String? previousStatus;
  final String? newStatus;
  final String? notes;
  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => <Object?>[
    id,
    tripId,
    eventType,
    createdAt,
    actorId,
    actorUsername,
    previousStatus,
    newStatus,
    notes,
    latitude,
    longitude,
  ];
}
