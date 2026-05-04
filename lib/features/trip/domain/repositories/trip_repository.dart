import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/domain/entities/esp_telemetry_log_entity.dart';
import 'package:sav/features/trip/domain/entities/esp_telemetry_stats_entity.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/entities/trip_event_entity.dart';

abstract class TripRepository {
  Future<Either<Failure, TripEntity>> startTrip({
    required String startAddress,
    required String destinationAddress,
    required double startLatitude,
    required double startLongitude,
  });

  Future<Either<Failure, TripEntity?>> loadCurrentTrip();

  Future<Either<Failure, Unit>> pushTripLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    String? notes,
  });

  Future<Either<Failure, TripEntity>> stopTrip({
    required int tripId,
    double? latitude,
    double? longitude,
    String? notes,
  });

  Future<Either<Failure, TripEntity>> resumeTrip({
    required int tripId,
    double? latitude,
    double? longitude,
    String? notes,
  });

  Future<Either<Failure, TripEntity>> finishTrip({
    required int tripId,
    required double latitude,
    required double longitude,
    required String endAddress,
    String? notes,
  });

  Future<Either<Failure, TripEntity>> cancelTrip({
    required int tripId,
    String? endAddress,
    double? latitude,
    double? longitude,
    String? notes,
  });

  Future<Either<Failure, List<TripEventEntity>>> loadTripEvents({
    required int tripId,
  });

  Future<Either<Failure, List<TripEntity>>> loadDriverTripHistory({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 20,
    int maxPages = 3,
  });

  Future<Either<Failure, Unit>> createTripAlert({
    required int tripId,
    required String alertType,
  });

  Future<Either<Failure, List<EspTelemetryLogEntity>>> loadEspTelemetry({
    int page = 1,
    int pageSize = 1,
    int? tripId,
    String? deviceUid,
    bool? alertOnly,
  });

  Future<Either<Failure, EspTelemetryStatsEntity>> loadEspTelemetryStats({
    int? tripId,
    String? deviceUid,
  });
}
