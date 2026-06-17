import 'package:sav/features/trip/data/models/trip_event_model.dart';
import 'package:sav/features/trip/data/models/trip_model.dart';
import 'package:sav/features/trip/data/models/esp_telemetry_log_model.dart';
import 'package:sav/features/trip/data/models/esp_telemetry_stats_model.dart';
import 'package:sav/features/trip/data/models/alert_model.dart';

abstract class TripRemoteDataSource {
  Future<TripModel> startTrip({
    required String startAddress,
    required String destinationAddress,
    required double startLatitude,
    required double startLongitude,
  });

  Future<TripModel?> loadCurrentTrip();

  Future<void> pushTripLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    String? notes,
  });

  Future<TripModel> stopTrip({
    required int tripId,
    double? latitude,
    double? longitude,
    String? notes,
  });

  Future<TripModel> resumeTrip({
    required int tripId,
    double? latitude,
    double? longitude,
    String? notes,
  });

  Future<TripModel> finishTrip({
    required int tripId,
    required double latitude,
    required double longitude,
    required String endAddress,
    String? notes,
  });

  Future<TripModel> cancelTrip({
    required int tripId,
    String? endAddress,
    double? latitude,
    double? longitude,
    String? notes,
  });

  Future<List<TripEventModel>> loadTripEvents({required int tripId});

  Future<List<TripModel>> loadDriverTripHistory({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 20,
    int maxPages = 3,
  });

  Future<void> createTripAlert({
    required int tripId,
    required String alertType,
  });

  Future<List<EspTelemetryLogModel>> loadEspTelemetry({
    int page = 1,
    int pageSize = 1,
    int? tripId,
    String? deviceUid,
    bool? alertOnly,
  });

  Future<EspTelemetryStatsModel> loadEspTelemetryStats({
    int? tripId,
    String? deviceUid,
  });

  Future<List<AlertModel>> loadTripAlerts({required int tripId});
}
