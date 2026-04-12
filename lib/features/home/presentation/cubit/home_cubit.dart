import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/backend_api_service.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/firestore_service.dart';
import 'package:sav/core/services/offline_cache_service.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  final FirestoreService _firestoreService;
  final ConnectivityService _connectivity;
  final OfflineCacheService _offlineCache;
  final SharedPreferences _prefs;
  final BackendApiService _backendApiService;
  final Map<String, Map<DateTime, DutyLevel>> _monthDutyCache =
      <String, Map<DateTime, DutyLevel>>{};

  HomeCubit(
    this._firestoreService,
    this._connectivity,
    this._offlineCache,
    this._prefs,
  )   : _backendApiService = BackendApiService(),
        super(const HomeInitial());

  /// Load dashboard stats and duty indicators for week/month.
  Future<void> loadDashboard() async {
    emit(const HomeLoading());

    final now = DateTime.now();
    final focusedMonth = DateTime(now.year, now.month);
    final localDriverName =
        _prefs.getString(AppConstants.prefDriverName) ?? 'Driver';

    try {
      final token = _prefs.getString(AppConstants.prefAccessToken);
      final driverId = _prefs.getString(AppConstants.prefDriverId);

      if (token == null || token.trim().isEmpty) {
        emit(_buildEmptyState(
          driverName: localDriverName,
          focusedMonth: focusedMonth,
        ));
        return;
      }

      final feed = await _backendApiService.fetchDriverFeed(accessToken: token);

      final profile = (feed['profile'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};

      final fullName =
          '${(profile['first_name'] ?? '').toString()} ${(profile['last_name'] ?? '').toString()}'
              .trim();
      final fallbackName =
          (profile['username'] ?? localDriverName).toString().trim();
      final driverName = fullName.isNotEmpty ? fullName : fallbackName;

      final profileId = profile['id'];
      if (profileId != null) {
        await _prefs.setString(AppConstants.prefDriverId, profileId.toString());
      } else if (driverId != null && driverId.isNotEmpty) {
        await _prefs.setString(AppConstants.prefDriverId, driverId);
      }
      await _prefs.setString(AppConstants.prefDriverName, driverName);

      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      final weekStart = _startOfWeekMonday(now);
      final weekEnd = weekStart.add(const Duration(days: 6));

      final monthHistory = await _backendApiService.fetchTripHistory(
        accessToken: token,
        startDate: monthStart,
        endDate: monthEnd,
      );
      final weekHistory = await _backendApiService.fetchTripHistory(
        accessToken: token,
        startDate: weekStart,
        endDate: weekEnd,
      );

      final monthDuty = _buildDutyByDate(monthHistory);
      _monthDutyCache[_monthKey(focusedMonth)] = monthDuty;
      final weekDuty = _buildWeekDuty(weekHistory);

      final todayTrips = weekHistory.where(
        (item) => _isSameDate(item.startTime, now),
      );
      final totalDurationMinutes = todayTrips
          .map((item) => (item.durationSeconds / 60.0).round())
          .fold<int>(0, (sum, minutes) => sum + minutes);

      final recentAlerts = (feed['recent_alerts'] as List<dynamic>? ??
              const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();

      final alertsToday = recentAlerts.where((alert) {
        final createdAt = DateTime.tryParse((alert['created_at'] ?? '').toString());
        return createdAt != null && _isSameDate(createdAt, now);
      }).length;

      final totalTripsToday = todayTrips.length;
      final totalAlertsToday = alertsToday;
      final distractedPercentage = totalTripsToday == 0
          ? 0.0
          : ((totalAlertsToday / (totalTripsToday * 4)) * 100).clamp(0, 95)
              .toDouble();
      final awakePercentage = (100 - distractedPercentage).clamp(5, 100).toDouble();

      if (isClosed) {
        return;
      }

      emit(
        HomeLoaded(
          driverName: driverName,
          totalTrips: totalTripsToday,
          totalAlerts: totalAlertsToday,
          drowsinessAlerts: totalAlertsToday ~/ 2,
          distractionAlerts: totalAlertsToday - (totalAlertsToday ~/ 2),
          totalDurationMinutes: totalDurationMinutes,
          awakePercentage: awakePercentage,
          distractedPercentage: distractedPercentage,
          weekActivity: weekDuty.map(
            (weekday, duty) => MapEntry(weekday, duty != DutyLevel.off),
          ),
          weekDuty: weekDuty,
          monthDuty: monthDuty,
          focusedMonth: focusedMonth,
          isOnline: _connectivity.isOnline,
          pendingSyncCount: _offlineCache.totalPendingCount,
        ),
      );
    } catch (_) {
      await _loadFallbackFromFirestore(
        focusedMonth: focusedMonth,
        localDriverName: localDriverName,
      );
    }
  }

  Future<void> loadDutyForMonth(DateTime month) async {
    final currentState = state;
    if (currentState is! HomeLoaded) {
      return;
    }

    final focusedMonth = DateTime(month.year, month.month);
    final cacheKey = _monthKey(focusedMonth);
    final cached = _monthDutyCache[cacheKey];
    if (cached != null) {
      emit(currentState.copyWith(monthDuty: cached, focusedMonth: focusedMonth));
      return;
    }

    final token = _prefs.getString(AppConstants.prefAccessToken);
    if (token == null || token.trim().isEmpty) {
      emit(currentState.copyWith(
        monthDuty: const <DateTime, DutyLevel>{},
        focusedMonth: focusedMonth,
      ));
      return;
    }

    try {
      final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
      final monthEnd = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
      final monthHistory = await _backendApiService.fetchTripHistory(
        accessToken: token,
        startDate: monthStart,
        endDate: monthEnd,
      );

      final duty = _buildDutyByDate(monthHistory);
      _monthDutyCache[cacheKey] = duty;

      if (!isClosed) {
        emit(currentState.copyWith(monthDuty: duty, focusedMonth: focusedMonth));
      }
    } catch (_) {
      if (!isClosed) {
        emit(currentState.copyWith(
          monthDuty: const <DateTime, DutyLevel>{},
          focusedMonth: focusedMonth,
        ));
      }
    }
  }

  Future<void> _loadFallbackFromFirestore({
    required DateTime focusedMonth,
    required String localDriverName,
  }) async {
    try {
      final driverId = _prefs.getString(AppConstants.prefDriverId);
      if (driverId == null || driverId.isEmpty) {
        if (!isClosed) {
          emit(_buildEmptyState(
            driverName: localDriverName,
            focusedMonth: focusedMonth,
          ));
        }
        return;
      }

      final stats = await _firestoreService.getTodayStatistics(driverId);
      final weekActivity = await _firestoreService.getWeekActivity(driverId);

      final weekDuty = <int, DutyLevel>{
        for (var i = DateTime.monday; i <= DateTime.sunday; i++)
          i: (weekActivity[i] ?? false) ? DutyLevel.low : DutyLevel.off,
      };

      if (!isClosed) {
        emit(
          HomeLoaded(
            driverName: localDriverName,
            totalTrips: stats['totalTrips'] as int? ?? 0,
            totalAlerts: stats['totalAlerts'] as int? ?? 0,
            drowsinessAlerts: stats['totalDrowsinessAlerts'] as int? ?? 0,
            distractionAlerts: stats['totalDistractionAlerts'] as int? ?? 0,
            totalDurationMinutes: stats['totalDurationMinutes'] as int? ?? 0,
            awakePercentage:
                (stats['awakePercentage'] as num?)?.toDouble() ?? 100.0,
            distractedPercentage: 0,
            weekActivity: weekActivity,
            weekDuty: weekDuty,
            monthDuty: const <DateTime, DutyLevel>{},
            focusedMonth: focusedMonth,
            isOnline: _connectivity.isOnline,
            pendingSyncCount: _offlineCache.totalPendingCount,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(HomeError('Failed to load dashboard: $e'));
      }
    }
  }

  HomeLoaded _buildEmptyState({
    required String driverName,
    required DateTime focusedMonth,
  }) {
    return HomeLoaded(
      driverName: driverName,
      totalTrips: 0,
      totalAlerts: 0,
      drowsinessAlerts: 0,
      distractionAlerts: 0,
      totalDurationMinutes: 0,
      awakePercentage: 100,
      distractedPercentage: 0,
      weekActivity: const <int, bool>{},
      weekDuty: const <int, DutyLevel>{},
      monthDuty: const <DateTime, DutyLevel>{},
      focusedMonth: focusedMonth,
      isOnline: _connectivity.isOnline,
      pendingSyncCount: _offlineCache.totalPendingCount,
    );
  }

  Map<DateTime, DutyLevel> _buildDutyByDate(
    List<BackendTripHistoryItem> history,
  ) {
    final counts = <DateTime, int>{};
    for (final item in history) {
      final day = DateTime(
        item.startTime.year,
        item.startTime.month,
        item.startTime.day,
      );
      counts[day] = (counts[day] ?? 0) + 1;
    }

    return counts.map(
      (day, count) => MapEntry(day, _dutyFromCount(count)),
    );
  }

  Map<int, DutyLevel> _buildWeekDuty(
    List<BackendTripHistoryItem> weekHistory,
  ) {
    final countsByWeekday = <int, int>{};
    for (final item in weekHistory) {
      countsByWeekday[item.startTime.weekday] =
          (countsByWeekday[item.startTime.weekday] ?? 0) + 1;
    }

    return <int, DutyLevel>{
      for (var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++)
        weekday: _dutyFromCount(countsByWeekday[weekday] ?? 0),
    };
  }

  DutyLevel _dutyFromCount(int count) {
    if (count >= 2) {
      return DutyLevel.high;
    }
    if (count == 1) {
      return DutyLevel.low;
    }
    return DutyLevel.off;
  }

  DateTime _startOfWeekMonday(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(
      Duration(days: date.weekday - DateTime.monday),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _monthKey(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}';
  }
}
