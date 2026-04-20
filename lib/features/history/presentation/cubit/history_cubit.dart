import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/history/data/models/trip_history_model.dart';
import 'package:sav/features/trip/domain/usecases/load_driver_trip_history_use_case.dart';

part 'history_state.dart';

@injectable
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._loadDriverTripHistoryUseCase)
    : super(const HistoryInitial());

  final LoadDriverTripHistoryUseCase _loadDriverTripHistoryUseCase;
  final List<TripHistoryModel> _allTrips = [];
  List<TripHistoryModel> _filteredTrips = [];
  String? _activeFilter;
  String _searchQuery = '';

  String? get activeFilter => _activeFilter;

  Future<void> loadHistory() async {
    emit(const HistoryLoading());

    final result = await _loadDriverTripHistoryUseCase(
      pageSize: 30,
      maxPages: 4,
    );

    result.fold(
      (failure) => emit(HistoryError(message: _mapFailureMessage(failure))),
      (trips) {
        _allTrips
          ..clear()
          ..addAll(trips.map(TripHistoryModel.fromTripEntity));

        if (_allTrips.isEmpty) {
          emit(
            const HistoryEmpty(
              message: 'No trips found yet. Start a trip to see history.',
            ),
          );
          return;
        }

        _applyFilters();
      },
    );
  }

  void searchByDate(String query) {
    _searchQuery = query.trim();
    _applyFilters();
  }

  void setFilter(String filter) {
    if (_activeFilter == filter) {
      _activeFilter = null;
    } else {
      _activeFilter = filter;
    }
    _applyFilters();
  }

  void _applyFilters() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final normalizedQuery = _searchQuery.toLowerCase();

    _filteredTrips = _allTrips.where((trip) {
      final matchesFilter = switch (_activeFilter) {
        'Last Week' =>
          trip.startTime != null && !trip.startTime!.isBefore(weekAgo),
        _ => true,
      };

      if (!matchesFilter) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final searchable = <String>[
        trip.date,
        trip.from,
        trip.to,
        trip.displayStatus,
      ].join(' ').toLowerCase();

      return searchable.contains(normalizedQuery);
    }).toList();

    if (_filteredTrips.isEmpty) {
      emit(
        const HistoryEmpty(
          message: 'No matching trips found for your current filters.',
        ),
      );
      return;
    }

    emit(HistoryLoaded(trips: _filteredTrips));
  }

  String _mapFailureMessage(Failure failure) {
    final message = failure.message.trim();
    if (message.isEmpty) {
      return 'Unable to load trip history right now. Please try again.';
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
      return 'No internet connection. Please check your network and retry.';
    }

    if (normalized.contains('timeout') || normalized.contains('timed out')) {
      return 'Connection timed out while loading history.';
    }

    if (normalized.contains('server') || normalized.contains('500')) {
      return 'Server error while loading history. Please try again shortly.';
    }

    return message;
  }
}
