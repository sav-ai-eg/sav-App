import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/firestore_service.dart';
import 'package:sav/features/history/data/models/trip_history_model.dart';

part 'history_state.dart';

@injectable
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._firestoreService, this._prefs)
      : super(const HistoryInitial());

  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;
  final List<TripHistoryModel> _allTrips = [];
  List<TripHistoryModel> _filteredTrips = [];
  String? _activeFilter;
  String _searchQuery = '';

  String? get activeFilter => _activeFilter;

  Future<void> loadHistory() async {
    emit(const HistoryLoading());

    try {
      final driverId = _prefs.getString(AppConstants.prefDriverId);

      if (driverId == null) {
        emit(const HistoryEmpty());
        return;
      }

      final snapshot = await _firestoreService.getTrips(driverId);

      _allTrips.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        _allTrips.add(TripHistoryModel.fromMap(data, doc.id));
      }

      if (_allTrips.isEmpty) {
        emit(const HistoryEmpty());
      } else {
        _filteredTrips = List.from(_allTrips);
        emit(HistoryLoaded(trips: _filteredTrips));
      }
    } catch (e) {
      emit(const HistoryEmpty());
    }
  }

  void searchByDate(String query) {
    _searchQuery = query;
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
    _filteredTrips = _allTrips.where((trip) {
      final matchesSearch = _searchQuery.isEmpty ||
          trip.date.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesSearch;
    }).toList();

    if (_filteredTrips.isEmpty) {
      emit(const HistoryEmpty());
    } else {
      emit(HistoryLoaded(trips: _filteredTrips));
    }
  }
}
