import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';
import 'package:sav/features/auth/domain/repositories/auth_repository.dart';

class PersistAuthSessionUseCase {
  const PersistAuthSessionUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Either<Failure, Unit>> call({required AuthSessionEntity session}) {
    return _authRepository.saveSession(session: session);
  }
}
