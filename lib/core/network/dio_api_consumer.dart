import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/network/api_consumer.dart';
import 'package:sav/core/network/api_response.dart';

class DioApiConsumer implements ApiConsumer {
  DioApiConsumer(this._dio) {
    _dio.options = _dio.options.copyWith(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: _jsonHeaders,
      validateStatus: (int? status) => status != null && status < 500,
    );
  }

  final Dio _dio;

  static const Map<String, String> _jsonHeaders = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  @override
  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _mergeHeaders(headers)),
      );

      return _mapResponse(response);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  @override
  Future<ApiResponse> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(headers: _mergeHeaders(headers)),
      );

      return _mapResponse(response);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  @override
  Future<ApiResponse> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: body,
        queryParameters: queryParameters,
        options: Options(headers: _mergeHeaders(headers)),
      );

      return _mapResponse(response);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  ApiResponse _mapResponse(Response<dynamic> response) {
    return ApiResponse(
      statusCode: response.statusCode ?? 0,
      data: _toMap(response.data),
      rawData: response.data,
    );
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      final body = data.trim();
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

  Map<String, String> _mergeHeaders(Map<String, String>? customHeaders) {
    if (customHeaders == null || customHeaders.isEmpty) {
      return _jsonHeaders;
    }

    return <String, String>{..._jsonHeaders, ...customHeaders};
  }

  AppException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const RequestTimeoutException();
      case DioExceptionType.connectionError:
        return const NoInternetException();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 401 || statusCode == 403) {
          return const UnauthorizedException();
        }
        return const ServerException();
      case DioExceptionType.cancel:
        return const AppException('Request was cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const UnknownException();
    }
  }
}
