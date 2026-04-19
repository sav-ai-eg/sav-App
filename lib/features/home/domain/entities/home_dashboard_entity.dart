import 'package:equatable/equatable.dart';
import 'package:sav/features/home/domain/entities/home_duty_level.dart';

class HomeDashboardEntity extends Equatable {
  const HomeDashboardEntity({
    required this.driverName,
    required this.totalTrips,
    required this.totalAlerts,
    required this.drowsinessAlerts,
    required this.distractionAlerts,
    required this.totalDurationMinutes,
    required this.awakePercentage,
    required this.distractedPercentage,
    required this.weekDuty,
    required this.monthDuty,
    required this.focusedMonth,
    required this.isOnline,
    required this.pendingSyncCount,
    this.isFromCache = false,
  });

  final String driverName;
  final int totalTrips;
  final int totalAlerts;
  final int drowsinessAlerts;
  final int distractionAlerts;
  final int totalDurationMinutes;
  final double awakePercentage;
  final double distractedPercentage;
  final Map<int, HomeDutyLevel> weekDuty;
  final Map<DateTime, HomeDutyLevel> monthDuty;
  final DateTime focusedMonth;
  final bool isOnline;
  final int pendingSyncCount;
  final bool isFromCache;

  Map<int, bool> get weekActivity => weekDuty.map(
    (int day, HomeDutyLevel duty) =>
        MapEntry<int, bool>(day, duty != HomeDutyLevel.off),
  );

  String get formattedDuration {
    if (totalDurationMinutes < 60) {
      return '$totalDurationMinutes min';
    }

    final h = totalDurationMinutes ~/ 60;
    final m = totalDurationMinutes % 60;
    return '${h}h ${m}m';
  }

  HomeDashboardEntity copyWith({
    String? driverName,
    int? totalTrips,
    int? totalAlerts,
    int? drowsinessAlerts,
    int? distractionAlerts,
    int? totalDurationMinutes,
    double? awakePercentage,
    double? distractedPercentage,
    Map<int, HomeDutyLevel>? weekDuty,
    Map<DateTime, HomeDutyLevel>? monthDuty,
    DateTime? focusedMonth,
    bool? isOnline,
    int? pendingSyncCount,
    bool? isFromCache,
  }) {
    return HomeDashboardEntity(
      driverName: driverName ?? this.driverName,
      totalTrips: totalTrips ?? this.totalTrips,
      totalAlerts: totalAlerts ?? this.totalAlerts,
      drowsinessAlerts: drowsinessAlerts ?? this.drowsinessAlerts,
      distractionAlerts: distractionAlerts ?? this.distractionAlerts,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      awakePercentage: awakePercentage ?? this.awakePercentage,
      distractedPercentage: distractedPercentage ?? this.distractedPercentage,
      weekDuty: weekDuty ?? this.weekDuty,
      monthDuty: monthDuty ?? this.monthDuty,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    driverName,
    totalTrips,
    totalAlerts,
    drowsinessAlerts,
    distractionAlerts,
    totalDurationMinutes,
    awakePercentage,
    distractedPercentage,
    weekDuty,
    monthDuty,
    focusedMonth,
    isOnline,
    pendingSyncCount,
    isFromCache,
  ];
}
