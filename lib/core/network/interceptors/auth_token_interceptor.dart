import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/constants/api_endpoints.dart';

class AuthRequestOptionsKeys {
  static const String requiresAuth = 'requiresAuth';
  static const String hasRetried = 'hasRetried';
}

class AuthTokenInterceptor extends QueuedInterceptor {
  AuthTokenInterceptor({
    required Dio requestDio,
    required Dio refreshDio,
    required SharedPreferences prefs,
  })  : _requestDio = requestDio,
        _refreshDio = refreshDio,
        _prefs = prefs;

  final Dio _requestDio;
  final Dio _refreshDio;
  final SharedPreferences _prefs;

  Future<String?>? _refreshFuture;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final requiresAuth = options.extra[AuthRequestOptionsKeys.requiresAuth] != false;

    if (requiresAuth && !_hasAuthorizationHeader(options.headers)) {
      final accessToken = _prefs.getString(AppConstants.prefAccessToken)?.trim() ?? '';
      if (accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final statusCode = response.statusCode ?? 0;
    if (statusCode != 401 && statusCode != 403) {
      handler.next(response);
      return;
    }

    final requestOptions = response.requestOptions;
    final requiresAuth =
        requestOptions.extra[AuthRequestOptionsKeys.requiresAuth] != false;
    final hasRetried = requestOptions.extra[AuthRequestOptionsKeys.hasRetried] == true;

    if (!requiresAuth || hasRetried || _isRefreshRequest(requestOptions.path)) {
      handler.next(response);
      return;
    }

    final refreshedAccessToken = await _refreshAccessToken();
    if (refreshedAccessToken == null || refreshedAccessToken.isEmpty) {
      await _clearAuthSession();
      handler.next(response);
      return;
    }

    requestOptions.headers['Authorization'] = 'Bearer $refreshedAccessToken';
    requestOptions.extra[AuthRequestOptionsKeys.hasRetried] = true;

    try {
      final retriedResponse = await _requestDio.fetch<dynamic>(requestOptions);
      handler.resolve(retriedResponse);
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  bool _hasAuthorizationHeader(Map<String, dynamic> headers) {
    for (final key in headers.keys) {
      if (key.toString().toLowerCase() == 'authorization') {
        return true;
      }
    }
    return false;
  }

  bool _isRefreshRequest(String path) {
    return path.contains(ApiEndpoints.authRefresh);
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    final completer = Completer<String?>();
    _refreshFuture = completer.future;

    try {
      final refreshToken = _prefs.getString(AppConstants.prefRefreshToken)?.trim() ?? '';
      if (refreshToken.isEmpty) {
        completer.complete(null);
        return completer.future;
      }

      final response = await _refreshDio.post<dynamic>(
        ApiEndpoints.authRefresh,
        data: <String, dynamic>{'refresh': refreshToken},
        options: Options(
          headers: const <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          extra: <String, dynamic>{
            AuthRequestOptionsKeys.requiresAuth: false,
          },
        ),
      );

      final statusCode = response.statusCode ?? 0;
      final data = _toMap(response.data);

      if (statusCode < 200 || statusCode >= 300) {
        completer.complete(null);
        return completer.future;
      }

      final newAccessToken = (data['access'] ?? '').toString().trim();
      if (newAccessToken.isEmpty) {
        completer.complete(null);
        return completer.future;
      }

      await _prefs.setString(AppConstants.prefAccessToken, newAccessToken);

      final newRefreshToken = (data['refresh'] ?? '').toString().trim();
      if (newRefreshToken.isNotEmpty) {
        await _prefs.setString(AppConstants.prefRefreshToken, newRefreshToken);
      }

      completer.complete(newAccessToken);
      return completer.future;
    } catch (_) {
      completer.complete(null);
      return completer.future;
    } finally {
      _refreshFuture = null;
    }
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return const <String, dynamic>{};
  }

  Future<void> _clearAuthSession() async {
    await Future.wait(<Future<bool>>[
      _prefs.remove(AppConstants.prefAccessToken),
      _prefs.remove(AppConstants.prefRefreshToken),
      _prefs.remove(AppConstants.prefDriverId),
      _prefs.remove(AppConstants.prefDriverName),
      _prefs.remove(AppConstants.prefDriverUsername),
      _prefs.remove(AppConstants.prefDriverRole),
    ]);
  }
}
