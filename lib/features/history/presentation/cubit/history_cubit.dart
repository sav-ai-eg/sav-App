import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/offline_cache_service.dart';
import 'package:sav/features/history/data/models/trip_history_model.dart';
import 'package:sav/features/trip/domain/usecases/load_driver_trip_history_use_case.dart';

part 'history_state.dart';

@injectable
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(
    this._loadDriverTripHistoryUseCase,
    this._offlineCacheService,
    this._connectivityService,
  ) : super(const HistoryInitial());

  final LoadDriverTripHistoryUseCase _loadDriverTripHistoryUseCase;
  final OfflineCacheService _offlineCacheService;
  final ConnectivityService _connectivityService;

  final List<TripHistoryModel> _allTrips = [];
  List<TripHistoryModel> _filteredTrips = [];

  String? _activeFilter;
  String _searchQuery = '';
  bool _isFromCache = false;
  DateTime? _cachedAt;
  String? _noticeMessage;

  String? get activeFilter => _activeFilter;

  Future<void> loadHistory() async {
    emit(const HistoryLoading());

    final cachedTrips = _readCachedTrips();

    if (!_connectivityService.isOnline) {
      if (cachedTrips.isEmpty) {
        emit(
          const HistoryError(
            message: 'No internet connection and no cached history available.',
          ),
        );
        return;
      }

      _setTrips(
        cachedTrips,
        isFromCache: true,
        cachedAt: _offlineCacheService.readCachedTripHistoryAt(),
        noticeMessage: 'You are offline. Showing last synced trip history.',
      );
      return;
    }

    final result = await _loadDriverTripHistoryUseCase(
      pageSize: 30,
      maxPages: 4,
    );

    result.fold(
      (failure) {
        if (cachedTrips.isNotEmpty) {
          _setTrips(
            cachedTrips,
            isFromCache: true,
            cachedAt: _offlineCacheService.readCachedTripHistoryAt(),
            noticeMessage:
                'Live history is temporarily unavailable. Showing cached data.',
          );
          return;
        }

        emit(HistoryError(message: _mapFailureMessage(failure)));
      },
      (trips) {
        final items = trips
            .map(TripHistoryModel.fromTripEntity)
            .toList(growable: false);

        if (items.isEmpty) {
          unawaited(_offlineCacheService.clearCachedTripHistory());
          emit(
            const HistoryEmpty(
              message: 'No trips found yet. Start a trip to see history.',
            ),
          );
          return;
        }

        _setTrips(items, isFromCache: false);
        unawaited(
          _offlineCacheService.cacheTripHistory(
            items.map((item) => item.toCacheMap()).toList(growable: false),
          ),
        );
      },
    );
  }

  void searchByDate(String query) {
    _searchQuery = query.trim();
    _applyFilters();
  }

  void setFilter(String? filter) {
    final normalized = filter?.trim();

    if (normalized == null || normalized.isEmpty) {
      _activeFilter = null;
      _applyFilters();
      return;
    }

    if (_activeFilter == normalized) {
      _activeFilter = null;
    } else {
      _activeFilter = normalized;
    }

    _applyFilters();
  }

  void _setTrips(
    List<TripHistoryModel> trips, {
    required bool isFromCache,
    DateTime? cachedAt,
    String? noticeMessage,
  }) {
    _allTrips
      ..clear()
      ..addAll(trips);

    _isFromCache = isFromCache;
    _cachedAt = cachedAt;
    _noticeMessage = noticeMessage;

    _applyFilters();
  }

  List<TripHistoryModel> _readCachedTrips() {
    final rawItems = _offlineCacheService.readCachedTripHistory();
    if (rawItems.isEmpty) {
      return const <TripHistoryModel>[];
    }

    return rawItems
        .map(TripHistoryModel.fromCacheMap)
        .where((trip) => trip.from.trim().isNotEmpty || trip.to.trim().isNotEmpty)
        .toList(growable: false);
  }

  void _applyFilters() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final normalizedQuery = _searchQuery.toLowerCase();

    _filteredTrips = _allTrips.where((trip) {
      final normalizedStatus = (trip.status ?? '').trim().toLowerCase();

      final matchesFilter = switch (_activeFilter) {
        'Last Week' =>
          trip.startTime != null && !trip.startTime!.isBefore(weekAgo),
        'Last Month' =>
          trip.startTime != null && !trip.startTime!.isBefore(monthAgo),
        'Finished' => normalizedStatus == 'finished',
        'Cancelled' => normalizedStatus == 'cancelled',
        'With Alerts' => trip.alerts > 0,
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
        HistoryEmpty(
          message: _resolveEmptyMessage(),
        ),
      );
      return;
    }

    emit(
      HistoryLoaded(
        trips: _filteredTrips,
        isFromCache: _isFromCache,
        cachedAt: _cachedAt,
        noticeMessage: _noticeMessage,
      ),
    );
  }

  String _resolveEmptyMessage() {
    if (_activeFilter != null && _searchQuery.isNotEmpty) {
      return 'No trips match your current search and filter.';
    }

    if (_activeFilter != null) {
      return 'No trips found for "$_activeFilter" yet.';
    }

    if (_searchQuery.isNotEmpty) {
      return 'No trips found for "$_searchQuery".';
    }

    return 'No trips found yet. Start a trip to see history.';
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
