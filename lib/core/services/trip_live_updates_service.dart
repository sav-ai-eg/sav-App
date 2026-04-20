import 'dart:async';

enum TripLiveUpdateType {
  started,
  paused,
  resumed,
  cancelled,
  finished,
  synced,
  progress,
}

class TripLiveUpdateEvent {
  const TripLiveUpdateEvent({
    required this.type,
    required this.occurredAt,
    this.tripId,
    this.shouldRefreshHistory = true,
  });

  final TripLiveUpdateType type;
  final DateTime occurredAt;
  final int? tripId;
  final bool shouldRefreshHistory;
}

class TripLiveUpdatesService {
  final StreamController<TripLiveUpdateEvent> _controller =
      StreamController<TripLiveUpdateEvent>.broadcast();

  DateTime? _lastProgressSignalAt;

  Stream<TripLiveUpdateEvent> get stream => _controller.stream;

  void emit({
    required TripLiveUpdateType type,
    int? tripId,
    bool shouldRefreshHistory = true,
  }) {
    if (_controller.isClosed) {
      return;
    }

    _controller.add(
      TripLiveUpdateEvent(
        type: type,
        occurredAt: DateTime.now(),
        tripId: tripId,
        shouldRefreshHistory: shouldRefreshHistory,
      ),
    );
  }

  void emitProgress({int? tripId}) {
    final now = DateTime.now();
    final lastSignal = _lastProgressSignalAt;

    if (lastSignal != null &&
        now.difference(lastSignal) < const Duration(seconds: 12)) {
      return;
    }

    _lastProgressSignalAt = now;
    emit(
      type: TripLiveUpdateType.progress,
      tripId: tripId,
      shouldRefreshHistory: true,
    );
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
