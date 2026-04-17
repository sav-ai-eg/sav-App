import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/auth/data/params/login_params.dart';
import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthSessionEntity>> login({
    required LoginParams params,
  });
}
