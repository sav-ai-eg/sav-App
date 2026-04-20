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
  const HistoryEmpty({
    this.message = 'No history found yet. Start a new trip now!',
  });

  final String message;
}

class HistoryLoaded extends HistoryState {
  final List<TripHistoryModel> trips;
  final bool isFromCache;
  final DateTime? cachedAt;
  final String? noticeMessage;

  const HistoryLoaded({
    required this.trips,
    this.isFromCache = false,
    this.cachedAt,
    this.noticeMessage,
  });
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError({required this.message});
}
