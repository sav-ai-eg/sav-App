import 'package:equatable/equatable.dart';

class AlertEntity extends Equatable {
  const AlertEntity({
    required this.id,
    required this.driverId,
    required this.tripId,
    required this.alertType,
    required this.source,
    required this.sourceId,
    required this.createdAt,
  });

  final int id;
  final int driverId;
  final int tripId;
  final String alertType;
  final String source;
  final String sourceId;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
        id,
        driverId,
        tripId,
        alertType,
        source,
        sourceId,
        createdAt,
      ];
}
