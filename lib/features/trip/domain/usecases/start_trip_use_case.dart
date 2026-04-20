import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@injectable
class StartTripUseCase {
  const StartTripUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, TripEntity>> call({
    required String startAddress,
    required String destinationAddress,
    required double startLatitude,
    required double startLongitude,
  }) {
    return _repository.startTrip(
      startAddress: startAddress,
      destinationAddress: destinationAddress,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
    );
  }
}
