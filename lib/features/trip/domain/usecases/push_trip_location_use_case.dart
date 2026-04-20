import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@injectable
class PushTripLocationUseCase {
  const PushTripLocationUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, Unit>> call({
    required int tripId,
    required double latitude,
    required double longitude,
    String? notes,
  }) {
    return _repository.pushTripLocation(
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );
  }
}
