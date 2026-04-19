import 'package:sav/features/home/domain/entities/home_alert_item_entity.dart';

class HomeAlertItemModel extends HomeAlertItemEntity {
  const HomeAlertItemModel({
    required super.id,
    required super.alertType,
    required super.createdAt,
    super.tripId,
    super.message,
    super.resolved,
  });

  factory HomeAlertItemModel.fromMap(Map<String, dynamic> map) {
    return HomeAlertItemModel(
      id: _toInt(map['id']),
      alertType: (map['alert_type'] ?? map['type'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(
            (map['created_at'] ?? map['timestamp'] ?? '').toString(),
          ) ??
          DateTime.now(),
      tripId: _toNullableInt(map['trip'] ?? map['trip_id']),
      message: (map['message'] ?? '').toString(),
      resolved: _toBool(map['resolved']),
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

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    final normalized = (value ?? '').toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}
