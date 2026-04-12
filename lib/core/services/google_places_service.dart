import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/features/trip/data/models/trip_place_model.dart';

class GooglePlacesService {
  GooglePlacesService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, List<TripPlaceModel>> _autocompleteCache = {};
  final Map<String, TripPlaceModel> _detailsCache = {};

  Future<List<TripPlaceModel>> autocomplete({
    required String query,
    required String sessionToken,
    double? latitude,
    double? longitude,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < AppConstants.placesQueryMinLength ||
        AppConstants.googleMapsKey.trim().isEmpty) {
      return const [];
    }

    final cacheKey =
        '${normalizedQuery.toLowerCase()}_${latitude?.toStringAsFixed(3)}_${longitude?.toStringAsFixed(3)}';
    final cached = _autocompleteCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final parameters = <String, String>{
      'input': normalizedQuery,
      'key': AppConstants.googleMapsKey,
      'sessiontoken': sessionToken,
      'language': 'en',
      'types': 'geocode',
    };

    if (latitude != null && longitude != null) {
      parameters['location'] = '$latitude,$longitude';
      parameters['radius'] = '50000';
      parameters['strictbounds'] = 'false';
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      parameters,
    );

    final response = await _client.get(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception('Places search failed (${response.statusCode}).');
    }

    final status = data['status'] as String? ?? 'UNKNOWN_ERROR';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      final message =
          data['error_message'] as String? ?? 'Unable to load suggestions.';
      throw Exception(message);
    }

    final predictions = (data['predictions'] as List<dynamic>? ?? const [])
        .take(AppConstants.placesSuggestionsLimit)
        .map(
          (item) =>
              TripPlaceModel.fromAutocomplete(item as Map<String, dynamic>),
        )
        .where(
          (item) => item.placeId.isNotEmpty && item.title.trim().isNotEmpty,
        )
        .toList(growable: false);

    _autocompleteCache[cacheKey] = predictions;
    return predictions;
  }

  Future<TripPlaceModel> getPlaceDetails({
    required TripPlaceModel place,
    required String sessionToken,
  }) async {
    if (place.placeId.isEmpty || AppConstants.googleMapsKey.trim().isEmpty) {
      return place;
    }

    final cached = _detailsCache[place.placeId];
    if (cached != null) {
      return cached;
    }

    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': place.placeId,
          'key': AppConstants.googleMapsKey,
          'sessiontoken': sessionToken,
          'language': 'en',
          'fields': 'place_id,name,formatted_address,geometry/location',
        });

    final response = await _client.get(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception('Place details failed (${response.statusCode}).');
    }

    final status = data['status'] as String? ?? 'UNKNOWN_ERROR';
    if (status != 'OK') {
      final message =
          data['error_message'] as String? ?? 'Unable to load place details.';
      throw Exception(message);
    }

    final result = data['result'] as Map<String, dynamic>? ?? const {};
    final geometry = result['geometry'] as Map<String, dynamic>? ?? const {};
    final location = geometry['location'] as Map<String, dynamic>? ?? const {};

    final details = place.copyWith(
      title: result['name'] as String? ?? place.title,
      subtitle: result['formatted_address'] as String? ?? place.subtitle,
      latitude: (location['lat'] as num?)?.toDouble(),
      longitude: (location['lng'] as num?)?.toDouble(),
    );

    _detailsCache[place.placeId] = details;
    return details;
  }

  void dispose() {
    _client.close();
  }
}
