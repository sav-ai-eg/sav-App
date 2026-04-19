import 'package:equatable/equatable.dart';

class HomeAlertItemEntity extends Equatable {
  const HomeAlertItemEntity({
    required this.id,
    required this.alertType,
    required this.createdAt,
    this.tripId,
    this.message = '',
    this.resolved = false,
  });

  final int id;
  final String alertType;
  final DateTime createdAt;
  final int? tripId;
  final String message;
  final bool resolved;

  @override
  List<Object?> get props => <Object?>[
    id,
    alertType,
    createdAt,
    tripId,
    message,
    resolved,
  ];
}
