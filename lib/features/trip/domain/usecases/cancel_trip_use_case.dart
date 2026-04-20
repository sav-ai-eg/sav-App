import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@injectable
class CancelTripUseCase {
  const CancelTripUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, TripEntity>> call({
    required int tripId,
    String? endAddress,
    double? latitude,
    double? longitude,
    String? notes,
  }) {
    return _repository.cancelTrip(
      tripId: tripId,
      endAddress: endAddress,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );
  }
}
