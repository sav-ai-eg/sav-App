import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sav/features/auth/data/params/login_params.dart';
import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';
import 'package:sav/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

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
}
