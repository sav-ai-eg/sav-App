import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:sav/core/constants/api_endpoints.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/network/api_consumer.dart';
import 'package:sav/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:sav/features/trip/data/models/trip_event_model.dart';
import 'package:sav/features/trip/data/models/trip_model.dart';

@Injectable(as: TripRemoteDataSource)
class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  TripRemoteDataSourceImpl(this._apiConsumer);

  final ApiConsumer _apiConsumer;

  @override
  Future<TripModel> startTrip({
    required String startAddress,
    required String destinationAddress,
    required double startLatitude,
    required double startLongitude,
  }) async {
    try {
      final response = await _apiConsumer.post(
        ApiEndpoints.tripsStart,
        body: <String, dynamic>{
          'start_address': startAddress,
          'destination_address': destinationAddress,
          'start_latitude': _formatCoordinate(startLatitude),
          'start_longitude': _formatCoordinate(startLongitude),
        },
      );

      if (_isSuccess(response.statusCode)) {
        return TripModel.fromBackendMap(response.data);
      }

      throw ServerException(
        _extractErrorMessage(
          response.data,
          fallback: 'Unable to start trip right now.',
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<TripModel?> loadCurrentTrip() async {
    try {
      final response = await _apiConsumer.get(ApiEndpoints.tripsCurrent);
      if (response.statusCode == 404) {
        return null;
      }

      if (_isSuccess(response.statusCode)) {
        return TripModel.fromBackendMap(response.data);
      }

      throw ServerException(
        _extractErrorMessage(
          response.data,
          fallback: 'Unable to load current trip.',
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<void> pushTripLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final response = await _apiConsumer.post(
        ApiEndpoints.tripLocation(tripId),
        body: <String, dynamic>{
          'latitude': _formatCoordinate(latitude),
          'longitude': _formatCoordinate(longitude),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );

      if (_isSuccess(response.statusCode)) {
        return;
      }

      throw ServerException(
        _extractErrorMessage(
          response.data,
          fallback: 'Unable to sync trip location.',
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<TripModel> stopTrip({
    required int tripId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    return _transitionTrip(
      path: ApiEndpoints.tripStop(tripId),
      fallbackMessage: 'Unable to pause this trip right now.',
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );
  }

  @override
  Future<TripModel> resumeTrip({
    required int tripId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    return _transitionTrip(
      path: ApiEndpoints.tripResume(tripId),
      fallbackMessage: 'Unable to resume this trip right now.',
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );
  }

  @override
  Future<TripModel> finishTrip({
    required int tripId,
    required double latitude,
    required double longitude,
    required String endAddress,
    String? notes,
  }) async {
    return _transitionTrip(
      path: ApiEndpoints.tripFinish(tripId),
      fallbackMessage: 'Unable to finish this trip right now.',
      latitude: latitude,
      longitude: longitude,
      endAddress: endAddress,
      notes: notes,
    );
  }

  @override
  Future<TripModel> cancelTrip({
    required int tripId,
    String? endAddress,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    return _transitionTrip(
      path: ApiEndpoints.tripCancel(tripId),
      fallbackMessage: 'Unable to cancel this trip right now.',
      latitude: latitude,
      longitude: longitude,
      endAddress: endAddress,
      notes: notes,
    );
  }

  @override
  Future<List<TripEventModel>> loadTripEvents({required int tripId}) async {
    try {
      final response = await _apiConsumer.get(ApiEndpoints.tripEvents(tripId));
      if (!_isSuccess(response.statusCode)) {
        throw ServerException(
          _extractErrorMessage(
            response.data,
            fallback: 'Unable to load trip timeline right now.',
          ),
        );
      }

      final raw = response.rawData;
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(TripEventModel.fromMap)
            .toList();
      }

      if (response.data['results'] is List) {
        return (response.data['results'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(TripEventModel.fromMap)
            .toList();
      }

      return const <TripEventModel>[];
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<List<TripModel>> loadDriverTripHistory({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 20,
    int maxPages = 3,
  }) async {
    final items = <TripModel>[];

    var page = 1;
    while (page <= maxPages) {
      final query = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (status != null && status.trim().isNotEmpty) {
        query['status'] = status.trim().toLowerCase();
      }

      if (startDate != null) {
        query['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }

      if (endDate != null) {
        query['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      try {
        final response = await _apiConsumer.get(
          ApiEndpoints.authDriverTripsHistory,
          queryParameters: query,
        );

        if (!_isSuccess(response.statusCode)) {
          throw ServerException(
            _extractErrorMessage(
              response.data,
              fallback: 'Unable to load trip history right now.',
            ),
          );
        }

        final payload = response.data;
        final pageItems =
            (payload['results'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(TripModel.fromHistoryMap)
                .toList();

        items.addAll(pageItems);

        final numPages = _toInt(payload['num_pages'], defaultValue: 1);
        if (page >= numPages || pageItems.isEmpty) {
          break;
        }

        page += 1;
      } on AppException {
        rethrow;
      } catch (_) {
        throw const UnknownException();
      }
    }

    return items;
  }

  @override
  Future<void> createTripAlert({
    required int tripId,
    required String alertType,
  }) async {
    try {
      final response = await _apiConsumer.post(
        ApiEndpoints.alerts,
        body: <String, dynamic>{
          'trip': tripId,
          'alert_type': alertType,
        },
      );

      if (_isSuccess(response.statusCode)) {
        return;
      }

      throw ServerException(
        _extractErrorMessage(
          response.data,
          fallback: 'Unable to sync alert to server.',
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  Future<TripModel> _transitionTrip({
    required String path,
    required String fallbackMessage,
    double? latitude,
    double? longitude,
    String? endAddress,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        if (latitude != null) 'latitude': _formatCoordinate(latitude),
        if (longitude != null) 'longitude': _formatCoordinate(longitude),
        if (endAddress != null && endAddress.trim().isNotEmpty)
          'end_address': endAddress.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      final response = await _apiConsumer.post(path, body: body);
      if (_isSuccess(response.statusCode)) {
        return TripModel.fromBackendMap(response.data);
      }

      throw ServerException(
        _extractErrorMessage(response.data, fallback: fallbackMessage),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  bool _isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  int _toInt(dynamic value, {required int defaultValue}) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? defaultValue;
  }

  String _extractErrorMessage(
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    final detail = _readMessage(payload['detail']);
    if (detail != null) {
      return detail;
    }

    for (final key in const <String>['non_field_errors', 'message', 'error']) {
      final message = _readMessage(payload[key]);
      if (message != null) {
        return message;
      }
    }

    for (final entry in payload.entries) {
      if (entry.key == 'detail') {
        continue;
      }

      final nestedMessage = _readMessage(entry.value);
      if (nestedMessage != null) {
        return nestedMessage;
      }
    }

    return fallback;
  }

  String? _readMessage(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final message = value.trim();
      return message.isEmpty ? null : message;
    }

    if (value is List) {
      for (final item in value) {
        final message = _readMessage(item);
        if (message != null) {
          return message;
        }
      }
      return null;
    }

    if (value is Map) {
      for (final entry in value.entries) {
        final message = _readMessage(entry.value);
        if (message != null) {
          return message;
        }
      }
      return null;
    }

    return null;
  }

  String _formatCoordinate(double value) {
    return value.toStringAsFixed(6);
  }
}
