import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:sav/features/trip/domain/entities/esp_telemetry_log_entity.dart';
import 'package:sav/features/trip/domain/entities/esp_telemetry_stats_entity.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/domain/entities/trip_event_entity.dart';
import 'package:sav/features/trip/domain/repositories/trip_repository.dart';

@Injectable(as: TripRepository)
class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl(this._remoteDataSource);

  final TripRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, TripEntity>> startTrip({
    required String startAddress,
    required String destinationAddress,
    required double startLatitude,
    required double startLongitude,
  }) async {
    try {
      final trip = await _remoteDataSource.startTrip(
        startAddress: startAddress,
        destinationAddress: destinationAddress,
        startLatitude: startLatitude,
        startLongitude: startLongitude,
      );

      return Right<Failure, TripEntity>(trip);
    } on AppException catch (exception) {
      return Left<Failure, TripEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, TripEntity>(
        ApiFailure('Unable to start trip right now. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, TripEntity?>> loadCurrentTrip() async {
    try {
      final trip = await _remoteDataSource.loadCurrentTrip();
      return Right<Failure, TripEntity?>(trip);
    } on AppException catch (exception) {
      return Left<Failure, TripEntity?>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, TripEntity?>(
        ApiFailure('Unable to load current trip right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> pushTripLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      await _remoteDataSource.pushTripLocation(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
      return const Right<Failure, Unit>(unit);
    } on AppException catch (exception) {
      return Left<Failure, Unit>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, Unit>(
        ApiFailure('Unable to sync location update right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, TripEntity>> stopTrip({
    required int tripId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final trip = await _remoteDataSource.stopTrip(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );

      return Right<Failure, TripEntity>(trip);
    } on AppException catch (exception) {
      return Left<Failure, TripEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, TripEntity>(
        ApiFailure('Unable to pause trip right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, TripEntity>> resumeTrip({
    required int tripId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final trip = await _remoteDataSource.resumeTrip(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );

      return Right<Failure, TripEntity>(trip);
    } on AppException catch (exception) {
      return Left<Failure, TripEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, TripEntity>(
        ApiFailure('Unable to resume trip right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, TripEntity>> finishTrip({
    required int tripId,
    required double latitude,
    required double longitude,
    required String endAddress,
    String? notes,
  }) async {
    try {
      final trip = await _remoteDataSource.finishTrip(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
        endAddress: endAddress,
        notes: notes,
      );

      return Right<Failure, TripEntity>(trip);
    } on AppException catch (exception) {
      return Left<Failure, TripEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, TripEntity>(
        ApiFailure('Unable to finish trip right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, TripEntity>> cancelTrip({
    required int tripId,
    String? endAddress,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final trip = await _remoteDataSource.cancelTrip(
        tripId: tripId,
        endAddress: endAddress,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );

      return Right<Failure, TripEntity>(trip);
    } on AppException catch (exception) {
      return Left<Failure, TripEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, TripEntity>(
        ApiFailure('Unable to cancel trip right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<TripEventEntity>>> loadTripEvents({
    required int tripId,
  }) async {
    try {
      final events = await _remoteDataSource.loadTripEvents(tripId: tripId);
      return Right<Failure, List<TripEventEntity>>(events);
    } on AppException catch (exception) {
      return Left<Failure, List<TripEventEntity>>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, List<TripEventEntity>>(
        ApiFailure('Unable to load trip timeline right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<TripEntity>>> loadDriverTripHistory({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 20,
    int maxPages = 3,
  }) async {
    try {
      final items = await _remoteDataSource.loadDriverTripHistory(
        status: status,
        startDate: startDate,
        endDate: endDate,
        pageSize: pageSize,
        maxPages: maxPages,
      );

      return Right<Failure, List<TripEntity>>(items);
    } on AppException catch (exception) {
      return Left<Failure, List<TripEntity>>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, List<TripEntity>>(
        ApiFailure('Unable to load trip history right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> createTripAlert({
    required int tripId,
    required String alertType,
  }) async {
    try {
      await _remoteDataSource.createTripAlert(
        tripId: tripId,
        alertType: _normalizeAlertType(alertType),
      );
      return const Right<Failure, Unit>(unit);
    } on AppException catch (exception) {
      return Left<Failure, Unit>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, Unit>(
        ApiFailure('Unable to sync trip alert right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<EspTelemetryLogEntity>>> loadEspTelemetry({
    int page = 1,
    int pageSize = 1,
    int? tripId,
    String? deviceUid,
    bool? alertOnly,
  }) async {
    try {
      final logs = await _remoteDataSource.loadEspTelemetry(
        page: page,
        pageSize: pageSize,
        tripId: tripId,
        deviceUid: deviceUid,
        alertOnly: alertOnly,
      );
      return Right<Failure, List<EspTelemetryLogEntity>>(logs);
    } on AppException catch (exception) {
      return Left<Failure, List<EspTelemetryLogEntity>>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, List<EspTelemetryLogEntity>>(
        ApiFailure('Unable to load ESP telemetry right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, EspTelemetryStatsEntity>> loadEspTelemetryStats({
    int? tripId,
    String? deviceUid,
  }) async {
    try {
      final stats = await _remoteDataSource.loadEspTelemetryStats(
        tripId: tripId,
        deviceUid: deviceUid,
      );
      return Right<Failure, EspTelemetryStatsEntity>(stats);
    } on AppException catch (exception) {
      return Left<Failure, EspTelemetryStatsEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, EspTelemetryStatsEntity>(
        ApiFailure('Unable to load ESP telemetry stats right now.'),
      );
    }
  }

  Failure _mapFailure(AppException exception) {
    if (exception is UnauthorizedException) {
      return const ApiFailure('Session expired. Please login again.');
    }

    if (exception is NoInternetException) {
      return const NetworkFailure(
        'No internet connection. Please check your network and try again.',
      );
    }

    if (exception is RequestTimeoutException) {
      return const NetworkFailure(
        'Connection timed out. Please try again.',
      );
    }

    if (exception is CacheException) {
      return CacheFailure(exception.message);
    }

    return ApiFailure(exception.message);
  }

  String _normalizeAlertType(String rawAlertType) {
    final normalized = rawAlertType.trim().toLowerCase();

    switch (normalized) {
      case 'drowsiness':
      case 'drowsy':
      case 'sleep':
        return 'drowsy';
      case 'yawn':
      case 'yawning':
        return 'yawning';
      case 'eyes_closed':
      case 'no_face':
        return normalized;
      default:
        return 'no_face';
    }
  }
}
