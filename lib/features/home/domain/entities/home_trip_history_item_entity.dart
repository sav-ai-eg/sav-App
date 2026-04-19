import 'package:equatable/equatable.dart';

class HomeTripHistoryItemEntity extends Equatable {
  const HomeTripHistoryItemEntity({
    required this.id,
    required this.status,
    required this.startTime,
    required this.durationSeconds,
    this.endTime,
    this.startAddress = '',
    this.destinationAddress = '',
    this.endAddress = '',
  });

  final int id;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final String startAddress;
  final String destinationAddress;
  final String endAddress;

  @override
  List<Object?> get props => <Object?>[
    id,
    status,
    startTime,
    endTime,
    durationSeconds,
    startAddress,
    destinationAddress,
    endAddress,
  ];
}
