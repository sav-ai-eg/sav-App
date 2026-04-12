part of 'history_cubit.dart';

abstract class HistoryState {
  const HistoryState();
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}

class HistoryLoaded extends HistoryState {
  final List<TripHistoryModel> trips;
  const HistoryLoaded({required this.trips});
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError({required this.message});
}
