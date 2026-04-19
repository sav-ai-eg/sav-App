import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/offline_cache_service.dart';
import 'package:sav/features/home/data/datasources/home_local_data_source.dart';
import 'package:sav/features/home/data/datasources/home_remote_data_source.dart';
import 'package:sav/features/home/data/models/home_alert_item_model.dart';
import 'package:sav/features/home/data/models/home_dashboard_model.dart';
import 'package:sav/features/home/domain/entities/home_alert_item_entity.dart';
import 'package:sav/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:sav/features/home/domain/entities/home_duty_level.dart';
import 'package:sav/features/home/domain/entities/home_trip_history_item_entity.dart';
import 'package:sav/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivityService,
    this._offlineCacheService,
  );

  final HomeRemoteDataSource _remoteDataSource;
  final HomeLocalDataSource _localDataSource;
  final ConnectivityService _connectivityService;
  final OfflineCacheService _offlineCacheService;

  @override
  Future<Either<Failure, HomeDashboardEntity>> loadDashboard({
    required DateTime now,
  }) async {
    try {
      final focusedMonth = DateTime(now.year, now.month);
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);
      final weekStart = _startOfWeekMonday(now);
      final weekEnd = weekStart.add(const Duration(days: 6));

      final feedFuture = _remoteDataSource.fetchDriverFeed();
      final monthHistoryFuture = _remoteDataSource.fetchTripHistory(
        startDate: monthStart,
        endDate: monthEnd,
      );
      final weekHistoryFuture = _remoteDataSource.fetchTripHistory(
        startDate: weekStart,
        endDate: weekEnd,
      );

      final feed = await feedFuture;
      final monthHistory = await monthHistoryFuture;
      final weekHistory = await weekHistoryFuture;

      List<HomeAlertItemEntity> alerts;
      try {
        alerts = await _remoteDataSource.fetchAlerts();
      } on AppException {
        alerts = _alertsFromFeed(feed);
      } catch (_) {
        alerts = _alertsFromFeed(feed);
      }

      if (alerts.isEmpty) {
        alerts = _alertsFromFeed(feed);
      }

      final dashboard = _buildDashboardEntity(
        now: now,
        focusedMonth: focusedMonth,
        feed: feed,
        monthHistory: monthHistory,
        weekHistory: weekHistory,
        alerts: alerts,
      );

      await _localDataSource.cacheDashboard(
        dashboard: HomeDashboardModel.fromEntity(dashboard),
      );

      return Right<Failure, HomeDashboardEntity>(dashboard);
    } on UnauthorizedException catch (_) {
      return const Left<Failure, HomeDashboardEntity>(
        ApiFailure('Your session expired. Please login again.'),
      );
    } on NoInternetException catch (_) {
      return _loadCachedOrFailure(
        const NetworkFailure(
          'No internet connection. Please check your network and try again.',
        ),
      );
    } on RequestTimeoutException catch (_) {
      return _loadCachedOrFailure(
        const NetworkFailure(
          'Connection timed out while loading home data. Please try again.',
        ),
      );
    } on CacheException catch (exception) {
      return Left<Failure, HomeDashboardEntity>(
        CacheFailure(exception.message),
      );
    } on AppException catch (exception) {
      return _loadCachedOrFailure(ApiFailure(exception.message));
    } catch (_) {
      return _loadCachedOrFailure(
        const ApiFailure(
          'Unable to load dashboard right now. Please try again.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, HomeDutyLevel>>> loadDutyForMonth({
    required DateTime month,
  }) async {
    final focusedMonth = DateTime(month.year, month.month);
    final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final monthEnd = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);

    try {
      final monthHistory = await _remoteDataSource.fetchTripHistory(
        startDate: monthStart,
        endDate: monthEnd,
      );

      return Right<Failure, Map<DateTime, HomeDutyLevel>>(
        _buildDutyByDate(monthHistory),
      );
    } on NoInternetException {
      final cached = _localDataSource.getCachedDashboard();
      if (cached != null && _isSameMonth(cached.focusedMonth, focusedMonth)) {
        return Right<Failure, Map<DateTime, HomeDutyLevel>>(cached.monthDuty);
      }

      return const Left<Failure, Map<DateTime, HomeDutyLevel>>(
        NetworkFailure(
          'No internet connection. Unable to update this month data now.',
        ),
      );
    } on RequestTimeoutException {
      return const Left<Failure, Map<DateTime, HomeDutyLevel>>(
        NetworkFailure('Request timed out while loading month duty.'),
      );
    } on AppException catch (exception) {
      return Left<Failure, Map<DateTime, HomeDutyLevel>>(
        ApiFailure(exception.message),
      );
    } catch (_) {
      return const Left<Failure, Map<DateTime, HomeDutyLevel>>(
        ApiFailure('Unable to load duty data for this month.'),
      );
    }
  }

  Future<Either<Failure, HomeDashboardEntity>> _loadCachedOrFailure(
    Failure failure,
  ) async {
    try {
      final cached = _localDataSource.getCachedDashboard();
      if (cached != null) {
        final cachedEntity = cached.copyWith(
          isFromCache: true,
          isOnline: _connectivityService.isOnline,
          pendingSyncCount: _offlineCacheService.totalPendingCount,
        );

        return Right<Failure, HomeDashboardEntity>(cachedEntity);
      }

      return Left<Failure, HomeDashboardEntity>(failure);
    } catch (_) {
      return Left<Failure, HomeDashboardEntity>(failure);
    }
  }

  HomeDashboardEntity _buildDashboardEntity({
    required DateTime now,
    required DateTime focusedMonth,
    required Map<String, dynamic> feed,
    required List<HomeTripHistoryItemEntity> monthHistory,
    required List<HomeTripHistoryItemEntity> weekHistory,
    required List<HomeAlertItemEntity> alerts,
  }) {
    final driverName = _extractDriverName(feed);

    final monthDuty = _buildDutyByDate(monthHistory);
    final weekDuty = _buildWeekDuty(weekHistory);

    final todayTrips = weekHistory.where(
      (HomeTripHistoryItemEntity item) => _isSameDate(item.startTime, now),
    );

    final totalDurationMinutes = todayTrips.fold<int>(
      0,
      (int total, HomeTripHistoryItemEntity item) =>
          total + _resolveTripDurationMinutes(item, now),
    );

    final todayAlerts = alerts.where(
      (HomeAlertItemEntity alert) => _isSameDate(alert.createdAt, now),
    );

    final alertSplit = _splitAlerts(todayAlerts);
    final totalAlertsToday = alertSplit.total;
    final totalTripsToday = todayTrips.length;

    final distractedPercentage = totalTripsToday == 0
        ? (totalAlertsToday > 0 ? 95.0 : 0.0)
        : ((totalAlertsToday / (totalTripsToday * 4)) * 100)
              .clamp(0, 95)
              .toDouble();
    final awakePercentage = (100 - distractedPercentage)
        .clamp(5, 100)
        .toDouble();

    return HomeDashboardEntity(
      driverName: driverName,
      totalTrips: totalTripsToday,
      totalAlerts: totalAlertsToday,
      drowsinessAlerts: alertSplit.drowsiness,
      distractionAlerts: alertSplit.distraction,
      totalDurationMinutes: totalDurationMinutes,
      awakePercentage: awakePercentage,
      distractedPercentage: distractedPercentage,
      weekDuty: weekDuty,
      monthDuty: monthDuty,
      focusedMonth: focusedMonth,
      isOnline: _connectivityService.isOnline,
      pendingSyncCount: _offlineCacheService.totalPendingCount,
      isFromCache: false,
    );
  }

  String _extractDriverName(Map<String, dynamic> feed) {
    final profile =
        (feed['profile'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    final first = (profile['first_name'] ?? '').toString().trim();
    final last = (profile['last_name'] ?? '').toString().trim();
    final fullName = '$first $last'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final username = (profile['username'] ?? '').toString().trim();
    if (username.isNotEmpty) {
      return username;
    }

    return 'Driver';
  }

  List<HomeAlertItemEntity> _alertsFromFeed(Map<String, dynamic> feed) {
    return (feed['recent_alerts'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(HomeAlertItemModel.fromMap)
        .toList();
  }

  Map<DateTime, HomeDutyLevel> _buildDutyByDate(
    List<HomeTripHistoryItemEntity> history,
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
      (DateTime day, int count) =>
          MapEntry<DateTime, HomeDutyLevel>(day, _dutyFromCount(count)),
    );
  }

  Map<int, HomeDutyLevel> _buildWeekDuty(
    List<HomeTripHistoryItemEntity> weekHistory,
  ) {
    final countsByWeekday = <int, int>{};

    for (final item in weekHistory) {
      countsByWeekday[item.startTime.weekday] =
          (countsByWeekday[item.startTime.weekday] ?? 0) + 1;
    }

    return <int, HomeDutyLevel>{
      for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
        weekday: _dutyFromCount(countsByWeekday[weekday] ?? 0),
    };
  }

  HomeDutyLevel _dutyFromCount(int count) {
    if (count >= 2) {
      return HomeDutyLevel.high;
    }

    if (count == 1) {
      return HomeDutyLevel.low;
    }

    return HomeDutyLevel.off;
  }

  DateTime _startOfWeekMonday(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  int _resolveTripDurationMinutes(
    HomeTripHistoryItemEntity item,
    DateTime now,
  ) {
    if (item.durationSeconds > 0) {
      return (item.durationSeconds / 60.0).round();
    }

    if (item.endTime != null) {
      return item.endTime!.difference(item.startTime).inMinutes.clamp(0, 1440);
    }

    final normalizedStatus = item.status.trim().toLowerCase();
    if (normalizedStatus == 'started' ||
        normalizedStatus == 'stopped' ||
        normalizedStatus == 'active') {
      return now.difference(item.startTime).inMinutes.clamp(0, 1440);
    }

    return 0;
  }

  _AlertSplit _splitAlerts(Iterable<HomeAlertItemEntity> alerts) {
    var drowsiness = 0;
    var distraction = 0;

    for (final alert in alerts) {
      final normalized = _normalizeAlertType(alert.alertType);
      if (_isDrowsinessAlert(normalized)) {
        drowsiness += 1;
      } else {
        distraction += 1;
      }
    }

    final total = drowsiness + distraction;
    if (total == 0) {
      return const _AlertSplit(total: 0, drowsiness: 0, distraction: 0);
    }

    return _AlertSplit(
      total: total,
      drowsiness: drowsiness,
      distraction: distraction,
    );
  }

  bool _isDrowsinessAlert(String normalizedType) {
    return normalizedType == 'drowsy' ||
        normalizedType == 'drowsiness' ||
        normalizedType == 'sleep' ||
        normalizedType == 'eyes_closed';
  }

  String _normalizeAlertType(String rawType) {
    final type = rawType.trim().toLowerCase();

    if (type == 'yawn') {
      return 'yawning';
    }

    if (type == 'phone') {
      return 'phone_usage';
    }

    return type;
  }
}

class _AlertSplit {
  const _AlertSplit({
    required this.total,
    required this.drowsiness,
    required this.distraction,
  });

  final int total;
  final int drowsiness;
  final int distraction;
}
