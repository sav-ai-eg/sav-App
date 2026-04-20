import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@injectable
class ResumeTripUseCase {
  const ResumeTripUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, TripEntity>> call({
    required int tripId,
    double? latitude,
    double? longitude,
    String? notes,
  }) {
    return _repository.resumeTrip(
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );
  }
}
