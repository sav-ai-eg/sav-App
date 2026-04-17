import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/auth/data/params/login_params.dart';
import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';
import 'package:sav/features/auth/domain/usecases/login_use_case.dart';
import 'package:sav/features/auth/domain/usecases/persist_auth_session_use_case.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._loginUseCase, this._persistSessionUseCase)
      : super(const LoginInitial());

  final LoginUseCase _loginUseCase;
  final PersistAuthSessionUseCase _persistSessionUseCase;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (state is LoginSubmitting) {
      return;
    }

    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      emit(const LoginFailure('Please enter your username.'));
      return;
    }

    if (password.trim().isEmpty) {
      emit(const LoginFailure('Please enter your password.'));
      return;
    }

    emit(const LoginSubmitting());

    final result = await _loginUseCase(
      LoginParams(username: normalizedUsername, password: password),
    );

    await result.fold(
      (failure) async {
        emit(LoginFailure(_mapFailureMessage(failure)));
      },
      (session) async {
        if (session.user.role.toLowerCase() != 'driver') {
          emit(
            const LoginFailure('Only driver accounts are allowed in this app.'),
          );
          return;
        }

        final persistResult = await _persistSession(session);
        persistResult.fold(
          (persistFailure) => emit(LoginFailure(_mapFailureMessage(persistFailure))),
          (_) => emit(const LoginSuccess()),
        );
      },
    );
  }

  Future<Either<Failure, Unit>> _persistSession(AuthSessionEntity session) {
    return _persistSessionUseCase(session: session);
  }

  String _mapFailureMessage(Failure failure) {
    final message = failure.message.trim();
    if (message.isEmpty) {
      return 'Login failed. Please try again.';
    }

    final normalized = message.toLowerCase();
    if (normalized.contains('no active account') ||
        normalized.contains('invalid username or password') ||
        normalized.contains('invalid credentials')) {
      return 'Invalid username or password.';
    }

    return message;
  }
}
