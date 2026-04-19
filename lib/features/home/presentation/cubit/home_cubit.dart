import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/home/domain/entities/home_dashboard_entity.dart';
import 'package:sav/features/home/domain/entities/home_duty_level.dart';
import 'package:sav/features/home/domain/usecases/load_home_dashboard_use_case.dart';
import 'package:sav/features/home/domain/usecases/load_home_duty_for_month_use_case.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._loadHomeDashboardUseCase, this._loadHomeDutyForMonthUseCase)
    : super(const HomeInitial());

  final LoadHomeDashboardUseCase _loadHomeDashboardUseCase;
  final LoadHomeDutyForMonthUseCase _loadHomeDutyForMonthUseCase;

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    final currentLoaded = state is HomeLoaded ? state as HomeLoaded : null;

    if (state is HomeLoading) {
      return;
    }

    if (currentLoaded != null && currentLoaded.isRefreshing && forceRefresh) {
      return;
    }

    if (currentLoaded != null && forceRefresh) {
      emit(currentLoaded.copyWith(isRefreshing: true, clearInfoMessage: true));
    } else {
      emit(const HomeLoading());
    }

    final result = await _loadHomeDashboardUseCase(now: DateTime.now());
    result.fold(
      (failure) {
        final message = _mapFailureMessage(failure);
        final previousState = currentLoaded;
        if (previousState != null) {
          emit(
            previousState.copyWith(isRefreshing: false, infoMessage: message),
          );
          return;
        }

        if (_isSessionFailure(message)) {
          emit(HomeEmpty(message));
          return;
        }

        emit(HomeError(message));
      },
      (dashboard) {
        emit(
          _toLoadedState(
            dashboard,
            infoMessage: dashboard.isFromCache
                ? 'Showing last synced dashboard data.'
                : null,
          ),
        );
      },
    );
  }

  Future<void> refreshDashboard() {
    return loadDashboard(forceRefresh: true);
  }

  Future<void> loadDutyForMonth(DateTime month) async {
    final currentState = state;
    if (currentState is! HomeLoaded || currentState.isMonthLoading) {
      return;
    }

    final focusedMonth = DateTime(month.year, month.month);
    if (_isSameMonth(currentState.focusedMonth, focusedMonth) &&
        currentState.monthDuty.isNotEmpty) {
      return;
    }

    final loadingState = currentState.copyWith(
      focusedMonth: focusedMonth,
      isMonthLoading: true,
      clearInfoMessage: true,
    );
    emit(loadingState);

    final result = await _loadHomeDutyForMonthUseCase(month: focusedMonth);
    result.fold(
      (failure) {
        emit(
          loadingState.copyWith(
            isMonthLoading: false,
            infoMessage: _mapFailureMessage(failure),
          ),
        );
      },
      (monthDuty) {
        emit(
          loadingState.copyWith(
            monthDuty: _mapMonthDuty(monthDuty),
            isMonthLoading: false,
            infoMessage: monthDuty.isEmpty
                ? 'No trip activity for this month.'
                : null,
          ),
        );
      },
    );
  }

  HomeLoaded _toLoadedState(
    HomeDashboardEntity dashboard, {
    String? infoMessage,
  }) {
    final weekDuty = _mapWeekDuty(dashboard.weekDuty);
    return HomeLoaded(
      driverName: dashboard.driverName,
      totalTrips: dashboard.totalTrips,
      totalAlerts: dashboard.totalAlerts,
      drowsinessAlerts: dashboard.drowsinessAlerts,
      distractionAlerts: dashboard.distractionAlerts,
      totalDurationMinutes: dashboard.totalDurationMinutes,
      awakePercentage: dashboard.awakePercentage,
      distractedPercentage: dashboard.distractedPercentage,
      weekActivity: dashboard.weekActivity,
      weekDuty: weekDuty,
      monthDuty: _mapMonthDuty(dashboard.monthDuty),
      focusedMonth: dashboard.focusedMonth,
      isOnline: dashboard.isOnline,
      pendingSyncCount: dashboard.pendingSyncCount,
      isFromCache: dashboard.isFromCache,
      isRefreshing: false,
      isMonthLoading: false,
      infoMessage: infoMessage,
    );
  }

  Map<int, DutyLevel> _mapWeekDuty(Map<int, HomeDutyLevel> source) {
    return source.map(
      (day, duty) => MapEntry<int, DutyLevel>(day, _mapDuty(duty)),
    );
  }

  Map<DateTime, DutyLevel> _mapMonthDuty(Map<DateTime, HomeDutyLevel> source) {
    return source.map(
      (day, duty) => MapEntry<DateTime, DutyLevel>(
        DateTime(day.year, day.month, day.day),
        _mapDuty(duty),
      ),
    );
  }

  DutyLevel _mapDuty(HomeDutyLevel level) {
    switch (level) {
      case HomeDutyLevel.high:
        return DutyLevel.high;
      case HomeDutyLevel.low:
        return DutyLevel.low;
      case HomeDutyLevel.off:
        return DutyLevel.off;
    }
  }

  bool _isSessionFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('session') ||
        normalized.contains('login again') ||
        normalized.contains('unauthorized');
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  String _mapFailureMessage(Failure failure) {
    final message = failure.message.trim();
    if (message.isEmpty) {
      return 'Unable to load dashboard right now. Please try again.';
    }

    final normalized = message.toLowerCase();
    if (normalized.contains('session') ||
        normalized.contains('unauthorized') ||
        normalized.contains('login again')) {
      return 'Session expired. Please login again.';
    }

    if (normalized.contains('no internet') ||
        normalized.contains('network') ||
        normalized.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (normalized.contains('timeout') || normalized.contains('timed out')) {
      return 'Connection timed out. Please try again.';
    }

    if (normalized.contains('forbidden') || normalized.contains('403')) {
      return 'You do not have permission to access this data.';
    }

    if (normalized.contains('not found') || normalized.contains('404')) {
      return 'No data found for the selected period.';
    }

    if (normalized.contains('server') || normalized.contains('500')) {
      return 'Server error while loading dashboard. Please try again shortly.';
    }

    return message;
  }
}
