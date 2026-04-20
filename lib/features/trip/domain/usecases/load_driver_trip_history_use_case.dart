import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@injectable
class LoadDriverTripHistoryUseCase {
  const LoadDriverTripHistoryUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, List<TripEntity>>> call({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 20,
    int maxPages = 3,
  }) {
    return _repository.loadDriverTripHistory(
      status: status,
      startDate: startDate,
      endDate: endDate,
      pageSize: pageSize,
      maxPages: maxPages,
    );
  }
}
