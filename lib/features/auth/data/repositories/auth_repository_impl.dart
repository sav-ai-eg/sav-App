import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sav/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sav/features/auth/data/params/login_params.dart';
import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';
import 'package:sav/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, AuthSessionEntity>> login({
    required LoginParams params,
  }) async {
    try {
      final session = await _remoteDataSource.login(params: params);
      return Right<Failure, AuthSessionEntity>(session);
    } on NoInternetException catch (exception) {
      return Left<Failure, AuthSessionEntity>(
        NetworkFailure(exception.message),
      );
    } on RequestTimeoutException catch (exception) {
      return Left<Failure, AuthSessionEntity>(
        NetworkFailure(exception.message),
      );
    } on AppException catch (exception) {
      return Left<Failure, AuthSessionEntity>(ApiFailure(exception.message));
    } catch (_) {
      return const Left<Failure, AuthSessionEntity>(
        ApiFailure('Unable to login right now. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSession({
    required AuthSessionEntity session,
  }) async {
    try {
      await _localDataSource.saveSession(session: session);
      return const Right<Failure, Unit>(unit);
    } on CacheException catch (exception) {
      return Left<Failure, Unit>(CacheFailure(exception.message));
    } catch (_) {
      return const Left<Failure, Unit>(
        CacheFailure('Unable to save auth session locally.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> clearSession() async {
    try {
      await _localDataSource.clearSession();
      return const Right<Failure, Unit>(unit);
    } on CacheException catch (exception) {
      return Left<Failure, Unit>(CacheFailure(exception.message));
    } catch (_) {
      return const Left<Failure, Unit>(
        CacheFailure('Unable to clear auth session locally.'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    final refreshToken = _localDataSource.getRefreshToken();

    try {
      if (refreshToken.isNotEmpty) {
        await _remoteDataSource.logout(refreshToken: refreshToken);
      }
    } on NoInternetException {
      // Allow local sign-out when network is unavailable.
    } on RequestTimeoutException {
      // Allow local sign-out when logout request times out.
    } on AppException {
      // Allow local sign-out even if backend logout fails.
    }

    return clearSession();
  }
}
