import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sav/core/constants/app_constants.dart';

class GoogleRouteStep {
  const GoogleRouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceText,
    required this.durationText,
    required this.startLocation,
    required this.endLocation,
    required this.polylinePoints,
    this.maneuver = '',
  });

  final String instruction;
  final int distanceMeters;
  final int durationSeconds;
  final String distanceText;
  final String durationText;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng> polylinePoints;
  final String maneuver;
}

class GoogleRouteData {
  const GoogleRouteData({
    required this.points,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceText,
    required this.durationText,
    this.bounds,
  });

  final List<LatLng> points;
  final List<GoogleRouteStep> steps;
  final int distanceMeters;
  final int durationSeconds;
  final String distanceText;
  final String durationText;
  final LatLngBounds? bounds;

  bool get hasPath => points.length >= 2;

  static const GoogleRouteData empty = GoogleRouteData(
    points: <LatLng>[],
    steps: <GoogleRouteStep>[],
    distanceMeters: 0,
    durationSeconds: 0,
    distanceText: '',
    durationText: '',
  );
}

class GoogleDirectionsService {
  GoogleDirectionsService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Map<String, GoogleRouteData> _routeCache = <String, GoogleRouteData>{};

  Future<GoogleRouteData> getDrivingRoute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    if (!AppConstants.hasGoogleMapsApiKey) {
      return GoogleRouteData.empty;
    }

    final cacheKey = _buildCacheKey(
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
    );

    final cached = _routeCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', <
      String,
      String
    >{
      'origin':
          '${originLatitude.toStringAsFixed(6)},${originLongitude.toStringAsFixed(6)}',
      'destination':
          '${destinationLatitude.toStringAsFixed(6)},${destinationLongitude.toStringAsFixed(6)}',
      'mode': 'driving',
      'alternatives': 'false',
      'departure_time': 'now',
      'traffic_model': 'best_guess',
      'units': 'metric',
      'language': 'en',
      'key': AppConstants.googleMapsApiKey,
    });

    final response = await _dio.getUri<dynamic>(uri);
    if (response.statusCode != 200) {
      throw Exception('Route request failed (${response.statusCode}).');
    }

    final payload = _toMap(response.data);
    final status = (payload['status'] ?? 'UNKNOWN_ERROR').toString();

    if (status == 'ZERO_RESULTS') {
      return GoogleRouteData.empty;
    }

    if (status != 'OK') {
      final message = (payload['error_message'] ?? 'Unable to load route.')
          .toString();
      throw Exception(message);
    }

    final routes = (payload['routes'] as List<dynamic>? ?? const <dynamic>[]);
    if (routes.isEmpty) {
      return GoogleRouteData.empty;
    }

    final firstRoute = _toMap(routes.first);
    final legs = (firstRoute['legs'] as List<dynamic>? ?? const <dynamic>[])
        .map(_toMap)
        .toList(growable: false);

    var totalDistanceMeters = 0;
    var totalDurationSeconds = 0;
    final parsedSteps = <GoogleRouteStep>[];

    for (final leg in legs) {
      totalDistanceMeters += _toInt(_toMap(leg['distance'])['value']);
      final durationInTraffic = _toInt(
        _toMap(leg['duration_in_traffic'])['value'],
      );
      final fallbackDuration = _toInt(_toMap(leg['duration'])['value']);
      totalDurationSeconds += durationInTraffic > 0
          ? durationInTraffic
          : fallbackDuration;

      final legSteps = (leg['steps'] as List<dynamic>? ?? const <dynamic>[])
          .map(_toMap)
          .map(_parseStep)
          .whereType<GoogleRouteStep>();

      parsedSteps.addAll(legSteps);
    }

    final polyline =
        _toMap(firstRoute['overview_polyline'])['points']?.toString() ?? '';
    final points = _decodePolyline(polyline);

    final bounds = _parseBounds(_toMap(firstRoute['bounds']));

    final routeData = GoogleRouteData(
      points: points,
      steps: parsedSteps,
      distanceMeters: totalDistanceMeters,
      durationSeconds: totalDurationSeconds,
      distanceText: _formatDistance(totalDistanceMeters),
      durationText: _formatDuration(totalDurationSeconds),
      bounds: bounds,
    );

    _routeCache[cacheKey] = routeData;
    return routeData;
  }

  GoogleRouteStep? _parseStep(Map<String, dynamic> stepMap) {
    final start = _parseLatLng(_toMap(stepMap['start_location']));
    final end = _parseLatLng(_toMap(stepMap['end_location']));

    if (start == null || end == null) {
      return null;
    }

    final maneuver = (stepMap['maneuver'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final rawInstruction =
        (stepMap['html_instructions'] ?? stepMap['instructions'] ?? '')
            .toString();

    final instruction = _sanitizeInstruction(rawInstruction);
    final distanceMeters = _toInt(_toMap(stepMap['distance'])['value']);
    final durationSeconds = _toInt(_toMap(stepMap['duration'])['value']);

    final distanceText = (_toMap(stepMap['distance'])['text'] ?? '')
        .toString()
        .trim();
    final durationText = (_toMap(stepMap['duration'])['text'] ?? '')
        .toString()
        .trim();

    final polylineEncoded = (_toMap(stepMap['polyline'])['points'] ?? '')
        .toString();
    var polylinePoints = _decodePolyline(polylineEncoded);
    if (polylinePoints.length < 2) {
      polylinePoints = <LatLng>[start, end];
    }

    return GoogleRouteStep(
      instruction: instruction.isNotEmpty
          ? instruction
          : _fallbackInstruction(maneuver),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      distanceText: distanceText.isNotEmpty
          ? distanceText
          : _formatDistance(distanceMeters),
      durationText: durationText.isNotEmpty
          ? durationText
          : _formatDuration(durationSeconds),
      startLocation: start,
      endLocation: end,
      polylinePoints: polylinePoints,
      maneuver: maneuver,
    );
  }

  String _buildCacheKey({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) {
    return '${originLatitude.toStringAsFixed(4)}_${originLongitude.toStringAsFixed(4)}_${destinationLatitude.toStringAsFixed(4)}_${destinationLongitude.toStringAsFixed(4)}';
  }

  Map<String, dynamic> _toMap(dynamic rawData) {
    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    if (rawData is String) {
      final body = rawData.trim();
      if (body.isEmpty) {
        return const <String, dynamic>{};
      }

      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return const <String, dynamic>{};
      }
    }

    return const <String, dynamic>{};
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  LatLng? _parseLatLng(Map<String, dynamic> locationMap) {
    if (locationMap.isEmpty) {
      return null;
    }

    final latitude = _toDouble(locationMap['lat']);
    final longitude = _toDouble(locationMap['lng']);
    if (latitude == null || longitude == null) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  String _sanitizeInstruction(String raw) {
    if (raw.trim().isEmpty) {
      return '';
    }

    var value = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
    const htmlEntities = <String, String>{
      '&nbsp;': ' ',
      '&amp;': '&',
      '&quot;': '"',
      '&#39;': "'",
      '&apos;': "'",
      '&lt;': '<',
      '&gt;': '>',
    };

    for (final entry in htmlEntities.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }

    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _fallbackInstruction(String maneuver) {
    if (maneuver.trim().isEmpty) {
      return 'Continue straight';
    }

    final words = maneuver
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          final normalized = part.trim().toLowerCase();
          if (normalized.isEmpty) {
            return normalized;
          }
          return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
        })
        .join(' ');

    if (words.isEmpty) {
      return 'Continue straight';
    }

    return words;
  }

  List<LatLng> _decodePolyline(String encoded) {
    if (encoded.isEmpty) {
      return const <LatLng>[];
    }

    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;

      while (true) {
        if (index >= encoded.length) {
          return points;
        }
        final code = encoded.codeUnitAt(index++) - 63;
        result |= (code & 0x1f) << shift;
        shift += 5;
        if (code < 0x20) {
          break;
        }
      }

      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      while (true) {
        if (index >= encoded.length) {
          return points;
        }
        final code = encoded.codeUnitAt(index++) - 63;
        result |= (code & 0x1f) << shift;
        shift += 5;
        if (code < 0x20) {
          break;
        }
      }

      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  LatLngBounds? _parseBounds(Map<String, dynamic> boundsMap) {
    if (boundsMap.isEmpty) {
      return null;
    }

    final southwest = _toMap(boundsMap['southwest']);
    final northeast = _toMap(boundsMap['northeast']);

    final southLat = _toDouble(southwest['lat']);
    final southLng = _toDouble(southwest['lng']);
    final northLat = _toDouble(northeast['lat']);
    final northLng = _toDouble(northeast['lng']);

    if (southLat == null ||
        southLng == null ||
        northLat == null ||
        northLng == null) {
      return null;
    }

    return LatLngBounds(
      southwest: LatLng(southLat, southLng),
      northeast: LatLng(northLat, northLng),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  String _formatDistance(int meters) {
    if (meters <= 0) {
      return '';
    }

    if (meters < 1000) {
      return '$meters m';
    }

    final km = meters / 1000;
    if (km >= 10) {
      return '${km.toStringAsFixed(0)} km';
    }

    return '${km.toStringAsFixed(1)} km';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '';
    }

    final totalMinutes = (seconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '$hours h ${minutes.toString().padLeft(2, '0')} min';
    }

    return '$totalMinutes min';
  }
}
