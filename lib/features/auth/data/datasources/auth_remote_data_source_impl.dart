import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/network/api_consumer.dart';
import 'package:sav/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sav/features/auth/data/models/auth_session_model.dart';
import 'package:sav/features/auth/data/params/login_params.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._apiConsumer);

  final ApiConsumer _apiConsumer;

  @override
  Future<AuthSessionModel> login({required LoginParams params}) async {
    try {
      final response = await _apiConsumer.post(
        '/api/auth/login/',
        body: params.toJson(),
      );

      final payload = response.data;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final session = AuthSessionModel.fromMap(payload);
        if (session.accessToken.isEmpty || session.refreshToken.isEmpty) {
          throw const ServerException('Login response is missing token data.');
        }
        return session;
      }

      throw ServerException(
        _extractLoginErrorMessage(
          payload: payload,
          statusCode: response.statusCode,
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
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
