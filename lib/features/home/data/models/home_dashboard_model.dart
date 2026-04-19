import 'package:sav/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:sav/features/home/domain/entities/home_duty_level.dart';

class HomeDashboardModel extends HomeDashboardEntity {
  const HomeDashboardModel({
    required super.driverName,
    required super.totalTrips,
    required super.totalAlerts,
    required super.drowsinessAlerts,
    required super.distractionAlerts,
    required super.totalDurationMinutes,
    required super.awakePercentage,
    required super.distractedPercentage,
    required super.weekDuty,
    required super.monthDuty,
    required super.focusedMonth,
    required super.isOnline,
    required super.pendingSyncCount,
    super.isFromCache,
  });

  factory HomeDashboardModel.fromEntity(HomeDashboardEntity entity) {
    return HomeDashboardModel(
      driverName: entity.driverName,
      totalTrips: entity.totalTrips,
      totalAlerts: entity.totalAlerts,
      drowsinessAlerts: entity.drowsinessAlerts,
      distractionAlerts: entity.distractionAlerts,
      totalDurationMinutes: entity.totalDurationMinutes,
      awakePercentage: entity.awakePercentage,
      distractedPercentage: entity.distractedPercentage,
      weekDuty: entity.weekDuty,
      monthDuty: entity.monthDuty,
      focusedMonth: entity.focusedMonth,
      isOnline: entity.isOnline,
      pendingSyncCount: entity.pendingSyncCount,
      isFromCache: entity.isFromCache,
    );
  }

  factory HomeDashboardModel.fromMap(Map<String, dynamic> map) {
    final weekDutyRaw =
        (map['weekDuty'] as Map<dynamic, dynamic>?) ??
        const <dynamic, dynamic>{};
    final monthDutyRaw =
        (map['monthDuty'] as Map<dynamic, dynamic>?) ??
        const <dynamic, dynamic>{};

    return HomeDashboardModel(
      driverName: (map['driverName'] ?? 'Driver').toString(),
      totalTrips: _toInt(map['totalTrips']),
      totalAlerts: _toInt(map['totalAlerts']),
      drowsinessAlerts: _toInt(map['drowsinessAlerts']),
      distractionAlerts: _toInt(map['distractionAlerts']),
      totalDurationMinutes: _toInt(map['totalDurationMinutes']),
      awakePercentage: _toDouble(map['awakePercentage'], defaultValue: 100),
      distractedPercentage: _toDouble(
        map['distractedPercentage'],
        defaultValue: 0,
      ),
      weekDuty: weekDutyRaw.map(
        (dynamic key, dynamic value) =>
            MapEntry<int, HomeDutyLevel>(_toInt(key), _dutyFromString(value)),
      ),
      monthDuty: monthDutyRaw.map(
        (dynamic key, dynamic value) => MapEntry<DateTime, HomeDutyLevel>(
          DateTime.tryParse(key.toString()) ?? DateTime.now(),
          _dutyFromString(value),
        ),
      ),
      focusedMonth:
          DateTime.tryParse((map['focusedMonth'] ?? '').toString()) ??
          DateTime.now(),
      isOnline: _toBool(map['isOnline'], defaultValue: true),
      pendingSyncCount: _toInt(map['pendingSyncCount']),
      isFromCache: _toBool(map['isFromCache'], defaultValue: true),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'driverName': driverName,
      'totalTrips': totalTrips,
      'totalAlerts': totalAlerts,
      'drowsinessAlerts': drowsinessAlerts,
      'distractionAlerts': distractionAlerts,
      'totalDurationMinutes': totalDurationMinutes,
      'awakePercentage': awakePercentage,
      'distractedPercentage': distractedPercentage,
      'weekDuty': weekDuty.map(
        (int day, HomeDutyLevel duty) =>
            MapEntry<String, String>(day.toString(), duty.name),
      ),
      'monthDuty': monthDuty.map(
        (DateTime day, HomeDutyLevel duty) => MapEntry<String, String>(
          DateTime(day.year, day.month, day.day).toIso8601String(),
          duty.name,
        ),
      ),
      'focusedMonth': DateTime(
        focusedMonth.year,
        focusedMonth.month,
      ).toIso8601String(),
      'isOnline': isOnline,
      'pendingSyncCount': pendingSyncCount,
      'isFromCache': isFromCache,
    };
  }

  static HomeDutyLevel _dutyFromString(dynamic value) {
    final normalized = (value ?? '').toString().toLowerCase();
    switch (normalized) {
      case 'high':
        return HomeDutyLevel.high;
      case 'low':
        return HomeDutyLevel.low;
      default:
        return HomeDutyLevel.off;
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static double _toDouble(dynamic value, {required double defaultValue}) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse((value ?? '').toString()) ?? defaultValue;
  }

  static bool _toBool(dynamic value, {required bool defaultValue}) {
    if (value is bool) {
      return value;
    }

    final normalized = (value ?? '').toString().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }

    return defaultValue;
  }
}
