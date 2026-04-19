part of 'home_cubit.dart';

enum DutyLevel { off, low, high }

abstract class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading({this.showSkeleton = true});

  final bool showSkeleton;
}

class HomeLoaded extends HomeState {
  final String driverName;
  final int totalTrips;
  final int totalAlerts;
  final int drowsinessAlerts;
  final int distractionAlerts;
  final int totalDurationMinutes;
  final double awakePercentage;
  final double distractedPercentage;
  final Map<int, bool> weekActivity; // weekday (1=Mon..7=Sun) → hadTrip
  final Map<int, DutyLevel> weekDuty;
  final Map<DateTime, DutyLevel> monthDuty;
  final DateTime focusedMonth;
  final bool isOnline;
  final int pendingSyncCount;
  final bool isFromCache;
  final bool isRefreshing;
  final bool isMonthLoading;
  final String? infoMessage;

  const HomeLoaded({
    required this.driverName,
    required this.totalTrips,
    required this.totalAlerts,
    required this.drowsinessAlerts,
    required this.distractionAlerts,
    required this.totalDurationMinutes,
    required this.awakePercentage,
    required this.distractedPercentage,
    required this.weekActivity,
    required this.weekDuty,
    required this.monthDuty,
    required this.focusedMonth,
    this.isOnline = true,
    this.pendingSyncCount = 0,
    this.isFromCache = false,
    this.isRefreshing = false,
    this.isMonthLoading = false,
    this.infoMessage,
  });

  DutyLevel dutyForDate(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return monthDuty[normalized] ?? DutyLevel.off;
  }

  HomeLoaded copyWith({
    String? driverName,
    int? totalTrips,
    int? totalAlerts,
    int? drowsinessAlerts,
    int? distractionAlerts,
    int? totalDurationMinutes,
    double? awakePercentage,
    double? distractedPercentage,
    Map<int, bool>? weekActivity,
    Map<int, DutyLevel>? weekDuty,
    Map<DateTime, DutyLevel>? monthDuty,
    DateTime? focusedMonth,
    bool? isOnline,
    int? pendingSyncCount,
    bool? isFromCache,
    bool? isRefreshing,
    bool? isMonthLoading,
    String? infoMessage,
    bool clearInfoMessage = false,
  }) {
    return HomeLoaded(
      driverName: driverName ?? this.driverName,
      totalTrips: totalTrips ?? this.totalTrips,
      totalAlerts: totalAlerts ?? this.totalAlerts,
      drowsinessAlerts: drowsinessAlerts ?? this.drowsinessAlerts,
      distractionAlerts: distractionAlerts ?? this.distractionAlerts,
      totalDurationMinutes: totalDurationMinutes ?? this.totalDurationMinutes,
      awakePercentage: awakePercentage ?? this.awakePercentage,
      distractedPercentage: distractedPercentage ?? this.distractedPercentage,
      weekActivity: weekActivity ?? this.weekActivity,
      weekDuty: weekDuty ?? this.weekDuty,
      monthDuty: monthDuty ?? this.monthDuty,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      isOnline: isOnline ?? this.isOnline,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      isFromCache: isFromCache ?? this.isFromCache,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isMonthLoading: isMonthLoading ?? this.isMonthLoading,
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
    );
  }

  String get formattedDuration {
    if (totalDurationMinutes < 60) return '$totalDurationMinutes min';
    final h = totalDurationMinutes ~/ 60;
    final m = totalDurationMinutes % 60;
    return '${h}h ${m}m';
  }
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
}

class HomeEmpty extends HomeState {
  const HomeEmpty(this.message);

  final String message;
}
