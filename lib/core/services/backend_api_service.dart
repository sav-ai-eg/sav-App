import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/features/auth/data/models/auth_session_model.dart';

class BackendApiService {
  BackendApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _requestTimeout = Duration(seconds: 20);

  Future<AuthSessionModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            _buildUri('/api/auth/login/'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'username': username,
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      final payload = _decodeMap(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final session = AuthSessionModel.fromMap(payload);
        if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
          throw Exception('Login response is missing token data.');
        }
        return session;
      }

      throw Exception(
        _extractLoginErrorMessage(
          payload: payload,
          statusCode: response.statusCode,
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Login request timed out while connecting to ${AppConstants.apiBaseUrl}.',
      );
    } on SocketException {
      throw Exception(
        'Cannot connect to ${AppConstants.apiBaseUrl}. Check network and backend URL.',
      );
    } on http.ClientException {
      throw Exception(
        'Unable to reach ${AppConstants.apiBaseUrl}. Please verify backend URL.',
      );
    }
  }

  Future<Map<String, dynamic>> fetchDriverFeed({
    required String accessToken,
  }) async {
    final response = await _client
        .get(
          _buildUri('/api/auth/driver/feed/'),
          headers: _authHeaders(accessToken),
        )
        .timeout(_requestTimeout);

    final payload = _decodeMap(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    throw Exception(
      _extractErrorMessage(payload, fallback: 'Failed to load driver feed.'),
    );
  }

  Future<List<BackendTripHistoryItem>> fetchTripHistory({
    required String accessToken,
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 100,
    int maxPages = 6,
  }) async {
    final List<BackendTripHistoryItem> items = [];

    var page = 1;
    while (page <= maxPages) {
      final query = <String, String>{
        'page': '$page',
        'page_size': '$pageSize',
      };
      if (startDate != null) {
        query['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        query['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      final response = await _client
          .get(
            _buildUri('/api/auth/driver/trips/history/', queryParameters: query),
            headers: _authHeaders(accessToken),
          )
          .timeout(_requestTimeout);

      final payload = _decodeMap(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _extractErrorMessage(payload, fallback: 'Failed to load trip history.'),
        );
      }

      final pageItems =
          (payload['results'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(BackendTripHistoryItem.fromMap)
              .toList();
      items.addAll(pageItems);

      final numPages = _toInt(payload['num_pages'], defaultValue: 1);
      if (page >= numPages || pageItems.isEmpty) {
        break;
      }

      page += 1;
    }

    return items;
  }

  Uri _buildUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final base = Uri.parse(AppConstants.apiBaseUrl);
    final normalizedPath = _joinPaths(base.path, path);

    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: normalizedPath,
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  String _joinPaths(String basePath, String childPath) {
    final cleanBase = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final cleanChild = childPath.startsWith('/')
        ? childPath
        : '/$childPath';

    final joined = '$cleanBase$cleanChild';
    return joined.isEmpty ? '/' : joined;
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return const <String, dynamic>{};
    }

    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore invalid JSON and return empty map below.
    }

    return const <String, dynamic>{};
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

  String _extractLoginErrorMessage({
    required Map<String, dynamic> payload,
    required int statusCode,
  }) {
    final backendMessage = _extractErrorMessage(payload, fallback: '');
    final normalized = backendMessage.toLowerCase();

    if (statusCode == 429) {
      return 'Too many login attempts. Please try again shortly.';
    }

    if (statusCode >= 500) {
      return 'Server error while logging in. Please try again later.';
    }

    if (normalized.contains('no active account found') ||
        normalized.contains('invalid credentials') ||
        normalized.contains('invalid username or password') ||
        (statusCode == 401 && normalized.contains('credentials'))) {
      return 'Invalid username or password.';
    }

    if (normalized.contains('inactive')) {
      return 'This account is inactive. Please contact support.';
    }

    if (backendMessage.isNotEmpty) {
      return backendMessage;
    }

    return 'Unable to login right now. Please try again.';
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

  int _toInt(dynamic value, {required int defaultValue}) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? defaultValue;
  }

  Map<String, String> _authHeaders(String accessToken) {
    return <String, String>{
      ..._jsonHeaders,
      'Authorization': 'Bearer $accessToken',
    };
  }

  static const Map<String, String> _jsonHeaders = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class BackendTripHistoryItem {
  const BackendTripHistoryItem({
    required this.id,
    required this.status,
    required this.startTime,
    required this.durationSeconds,
    this.endTime,
    this.startAddress = '',
    this.destinationAddress = '',
    this.endAddress = '',
  });

  final int id;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final String startAddress;
  final String destinationAddress;
  final String endAddress;

  factory BackendTripHistoryItem.fromMap(Map<String, dynamic> map) {
    return BackendTripHistoryItem(
      id: _toInt(map['id']),
      status: (map['status'] ?? '').toString(),
      startTime: DateTime.tryParse((map['start_time'] ?? '').toString()) ??
          DateTime.now(),
      endTime: DateTime.tryParse((map['end_time'] ?? '').toString()),
      durationSeconds: _toInt(map['duration_seconds']),
      startAddress: (map['start_address'] ?? '').toString(),
      destinationAddress: (map['destination_address'] ?? '').toString(),
      endAddress: (map['end_address'] ?? '').toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
