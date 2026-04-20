import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@injectable
class LoadCurrentTripUseCase {
  const LoadCurrentTripUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, TripEntity?>> call() {
    return _repository.loadCurrentTrip();
  }
}
