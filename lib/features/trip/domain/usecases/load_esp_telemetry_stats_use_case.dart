import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/esp_telemetry_stats_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

class LoadEspTelemetryStatsUseCase {
  const LoadEspTelemetryStatsUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, EspTelemetryStatsEntity>> call({
    int? tripId,
    String? deviceUid,
  }) {
    return _repository.loadEspTelemetryStats(
      tripId: tripId,
      deviceUid: deviceUid,
    );
  }
}
