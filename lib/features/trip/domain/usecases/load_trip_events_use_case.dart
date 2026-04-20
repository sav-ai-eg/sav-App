import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/trip_event_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@injectable
class LoadTripEventsUseCase {
  const LoadTripEventsUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, List<TripEventEntity>>> call({
    required int tripId,
  }) {
    return _repository.loadTripEvents(tripId: tripId);
  }
}
