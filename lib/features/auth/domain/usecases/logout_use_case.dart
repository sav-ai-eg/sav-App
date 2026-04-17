import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Either<Failure, Unit>> call() {
    return _authRepository.logout();
  }
}
