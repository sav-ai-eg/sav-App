import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@injectable
class FinishTripUseCase {
  const FinishTripUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, TripEntity>> call({
    required int tripId,
    required double latitude,
    required double longitude,
    required String endAddress,
    String? notes,
  }) {
    return _repository.finishTrip(
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      endAddress: endAddress,
      notes: notes,
    );
  }
}
