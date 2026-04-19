import 'package:sav/features/home/domain/entities/home_trip_history_item_entity.dart';

class HomeTripHistoryItemModel extends HomeTripHistoryItemEntity {
  const HomeTripHistoryItemModel({
    required super.id,
    required super.status,
    required super.startTime,
    required super.durationSeconds,
    super.endTime,
    super.startAddress,
    super.destinationAddress,
    super.endAddress,
  });

  factory HomeTripHistoryItemModel.fromMap(Map<String, dynamic> map) {
    return HomeTripHistoryItemModel(
      id: _toInt(map['id']),
      status: (map['status'] ?? '').toString(),
      startTime:
          DateTime.tryParse((map['start_time'] ?? '').toString()) ??
          DateTime.now(),
      endTime: DateTime.tryParse((map['end_time'] ?? '').toString()),
      durationSeconds: _toInt(map['duration_seconds']),
      startAddress: (map['start_address'] ?? '').toString(),
      destinationAddress: (map['destination_address'] ?? '').toString(),
      endAddress: (map['end_address'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
