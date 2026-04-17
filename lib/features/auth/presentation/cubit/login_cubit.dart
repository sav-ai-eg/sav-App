import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/auth/data/params/login_params.dart';
import 'package:sav/features/auth/domain/entities/auth_session_entity.dart';
import 'package:sav/features/auth/domain/usecases/login_use_case.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._loginUseCase, this._prefs) : super(const LoginInitial());

  final LoginUseCase _loginUseCase;
  final SharedPreferences _prefs;

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

        await _persistSession(session);
        emit(const LoginSuccess());
      },
    );
  }

  Future<void> _persistSession(AuthSessionEntity session) async {
    await _prefs.setString(AppConstants.prefAccessToken, session.accessToken);
    await _prefs.setString(AppConstants.prefRefreshToken, session.refreshToken);
    await _prefs.setString(AppConstants.prefDriverId, session.user.id.toString());
    await _prefs.setString(AppConstants.prefDriverName, session.user.displayName);
    await _prefs.setString(AppConstants.prefDriverUsername, session.user.username);
    await _prefs.setString(AppConstants.prefDriverRole, session.user.role);
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
