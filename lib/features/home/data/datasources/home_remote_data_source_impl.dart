import 'package:injectable/injectable.dart';
import 'package:sav/core/constants/api_endpoints.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/network/api_consumer.dart';
import 'package:sav/features/home/data/datasources/home_remote_data_source.dart';
import 'package:sav/features/home/data/models/home_alert_item_model.dart';
import 'package:sav/features/home/data/models/home_trip_history_item_model.dart';
import 'package:sav/features/home/data/params/home_trip_history_query_params.dart';

@Injectable(as: HomeRemoteDataSource)
class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl(this._apiConsumer);

  final ApiConsumer _apiConsumer;

  @override
  Future<Map<String, dynamic>> fetchDriverFeed() async {
    try {
      final response = await _apiConsumer.get(ApiEndpoints.authDriverFeed);
      if (_isSuccess(response.statusCode)) {
        return response.data;
      }

      throw ServerException(
        _extractErrorMessage(
          response.data,
          fallback: 'Failed to load home feed.',
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<List<HomeTripHistoryItemModel>> fetchTripHistory({
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 100,
    int maxPages = 6,
  }) async {
    final items = <HomeTripHistoryItemModel>[];

    var page = 1;
    while (page <= maxPages) {
      final query = HomeTripHistoryQueryParams(
        startDate: startDate,
        endDate: endDate,
        page: page,
        pageSize: pageSize,
      ).toMap();

      try {
        final response = await _apiConsumer.get(
          ApiEndpoints.authDriverTripsHistory,
          queryParameters: query,
        );

        if (!_isSuccess(response.statusCode)) {
          throw ServerException(
            _extractErrorMessage(
              response.data,
              fallback: 'Failed to load trip history.',
            ),
          );
        }

        final payload = response.data;
        final pageItems =
            (payload['results'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(HomeTripHistoryItemModel.fromMap)
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
  Future<List<HomeAlertItemModel>> fetchAlerts() async {
    try {
      final response = await _apiConsumer.get(ApiEndpoints.alerts);
      if (!_isSuccess(response.statusCode)) {
        throw ServerException(
          _extractErrorMessage(
            response.data,
            fallback: 'Failed to load alerts.',
          ),
        );
      }

      final raw = response.rawData;
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(HomeAlertItemModel.fromMap)
            .toList();
      }

      if (raw is Map && raw['results'] is List) {
        return (raw['results'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(HomeAlertItemModel.fromMap)
            .toList();
      }

      if (response.data['results'] is List) {
        return (response.data['results'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(HomeAlertItemModel.fromMap)
            .toList();
      }

      return const <HomeAlertItemModel>[];
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
}
