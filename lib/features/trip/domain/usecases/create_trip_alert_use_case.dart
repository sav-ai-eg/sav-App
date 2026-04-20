import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@injectable
class CreateTripAlertUseCase {
  const CreateTripAlertUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, Unit>> call({
    required int tripId,
    required String alertType,
  }) {
    return _repository.createTripAlert(
      tripId: tripId,
      alertType: alertType,
    );
  }
}
