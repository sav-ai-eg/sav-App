import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:sav/features/home/domain/entities/home_duty_level.dart';
import 'package:sav/features/home/domain/repositories/home_repository.dart';
import 'package:sav/features/home/domain/usecases/load_home_dashboard_use_case.dart';
import 'package:sav/features/home/domain/usecases/load_home_duty_for_month_use_case.dart';
import 'package:sav/features/home/presentation/cubit/home_cubit.dart';

void main() {
  group('HomeCubit', () {
    late _FakeHomeRepository repository;
    late HomeCubit cubit;

    setUp(() {
      repository = _FakeHomeRepository();
      cubit = HomeCubit(
        LoadHomeDashboardUseCase(repository),
        LoadHomeDutyForMonthUseCase(repository),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('emits loading then loaded when dashboard request succeeds', () async {
      repository.dashboardResult = Right<Failure, HomeDashboardEntity>(
        _dashboardSample(totalTrips: 3),
      );

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          isA<HomeLoading>(),
          predicate<HomeState>(
            (state) => state is HomeLoaded && state.totalTrips == 3,
          ),
        ]),
      );

      await cubit.loadDashboard();
    });

    test('emits empty state when session failure happens without cached UI state', () async {
      repository.dashboardResult = const Left<Failure, HomeDashboardEntity>(
        ApiFailure('session expired, login again'),
      );

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          isA<HomeLoading>(),
          predicate<HomeState>(
            (state) =>
                state is HomeEmpty &&
                state.message.toLowerCase().contains('session expired'),
          ),
        ]),
      );

      await cubit.loadDashboard();
    });

    test('refresh keeps old data and surfaces info message on failure', () async {
      repository.dashboardResult = Right<Failure, HomeDashboardEntity>(
        _dashboardSample(totalTrips: 5),
      );
      await cubit.loadDashboard();

      repository.dashboardResult = const Left<Failure, HomeDashboardEntity>(
        NetworkFailure('No internet connection.'),
      );

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          predicate<HomeState>(
            (state) => state is HomeLoaded && state.isRefreshing,
          ),
          predicate<HomeState>(
            (state) =>
                state is HomeLoaded &&
                !state.isRefreshing &&
                state.totalTrips == 5 &&
                (state.infoMessage ?? '').toLowerCase().contains('no internet'),
          ),
        ]),
      );

      await cubit.refreshDashboard();
    });

    test('loadDutyForMonth updates month duty map on success', () async {
      final now = DateTime(2026, 4, 19);
      repository.dashboardResult = Right<Failure, HomeDashboardEntity>(
        _dashboardSample(focusedMonth: DateTime(now.year, now.month)),
      );
      await cubit.loadDashboard();

      final nextMonth = DateTime(now.year, now.month + 1);
      final nextMonthDuty = <DateTime, HomeDutyLevel>{
        DateTime(nextMonth.year, nextMonth.month, 3): HomeDutyLevel.high,
      };
      repository.dutyResult = Right<Failure, Map<DateTime, HomeDutyLevel>>(
        nextMonthDuty,
      );

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          predicate<HomeState>(
            (state) =>
                state is HomeLoaded &&
                state.isMonthLoading &&
                state.focusedMonth.year == nextMonth.year &&
                state.focusedMonth.month == nextMonth.month,
          ),
          predicate<HomeState>(
            (state) =>
                state is HomeLoaded &&
                !state.isMonthLoading &&
                state.monthDuty[DateTime(nextMonth.year, nextMonth.month, 3)] ==
                    DutyLevel.high,
          ),
        ]),
      );

      await cubit.loadDutyForMonth(nextMonth);
    });

    test('loadDutyForMonth keeps state and shows message on failure', () async {
      final now = DateTime(2026, 4, 19);
      repository.dashboardResult = Right<Failure, HomeDashboardEntity>(
        _dashboardSample(focusedMonth: DateTime(now.year, now.month)),
      );
      await cubit.loadDashboard();

      final nextMonth = DateTime(now.year, now.month + 1);
      repository.dutyResult = const Left<Failure, Map<DateTime, HomeDutyLevel>>(
        NetworkFailure('Request timed out while loading month duty.'),
      );

      expectLater(
        cubit.stream,
        emitsInOrder(<dynamic>[
          predicate<HomeState>(
            (state) => state is HomeLoaded && state.isMonthLoading,
          ),
          predicate<HomeState>(
            (state) =>
                state is HomeLoaded &&
                !state.isMonthLoading &&
                (state.infoMessage ?? '').toLowerCase().contains('timed out'),
          ),
        ]),
      );

      await cubit.loadDutyForMonth(nextMonth);
    });
  });
}

class _FakeHomeRepository implements HomeRepository {
  Either<Failure, HomeDashboardEntity> dashboardResult =
      Right<Failure, HomeDashboardEntity>(_dashboardSample());
  Either<Failure, Map<DateTime, HomeDutyLevel>> dutyResult =
      const Right<Failure, Map<DateTime, HomeDutyLevel>>(
        <DateTime, HomeDutyLevel>{},
      );

  @override
  Future<Either<Failure, HomeDashboardEntity>> loadDashboard({
    required DateTime now,
  }) async {
    return dashboardResult;
  }

  @override
  Future<Either<Failure, Map<DateTime, HomeDutyLevel>>> loadDutyForMonth({
    required DateTime month,
  }) async {
    return dutyResult;
  }
}

HomeDashboardEntity _dashboardSample({
  int totalTrips = 1,
  DateTime? focusedMonth,
}) {
  final month = focusedMonth ?? DateTime(2026, 4);

  return HomeDashboardEntity(
    driverName: 'Ahmed Driver',
    totalTrips: totalTrips,
    totalAlerts: 2,
    drowsinessAlerts: 1,
    distractionAlerts: 1,
    totalDurationMinutes: 45,
    awakePercentage: 88,
    distractedPercentage: 12,
    weekDuty: const <int, HomeDutyLevel>{
      DateTime.monday: HomeDutyLevel.low,
      DateTime.tuesday: HomeDutyLevel.high,
    },
    monthDuty: <DateTime, HomeDutyLevel>{
      DateTime(month.year, month.month, 1): HomeDutyLevel.low,
    },
    focusedMonth: DateTime(month.year, month.month),
    isOnline: true,
    pendingSyncCount: 0,
    isFromCache: false,
  );
}
