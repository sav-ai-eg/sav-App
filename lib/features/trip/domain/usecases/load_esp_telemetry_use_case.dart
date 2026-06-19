import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/esp_telemetry_log_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

class LoadEspTelemetryUseCase {
  const LoadEspTelemetryUseCase(this._repository);

  final TripRepository _repository;

  Future<Either<Failure, List<EspTelemetryLogEntity>>> call({
    int page = 1,
    int pageSize = 1,
    int? tripId,
    String? deviceUid,
    bool? alertOnly,
  }) {
    return _repository.loadEspTelemetry(
      page: page,
      pageSize: pageSize,
      tripId: tripId,
      deviceUid: deviceUid,
      alertOnly: alertOnly,
    );
  }
}
