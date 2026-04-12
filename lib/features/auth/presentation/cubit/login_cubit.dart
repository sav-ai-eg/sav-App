import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/services/backend_api_service.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._apiService, this._prefs) : super(const LoginInitial());

  final BackendApiService _apiService;
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

    try {
      final session = await _apiService.login(
        username: normalizedUsername,
        password: password,
      );

      if (session.user.role.toLowerCase() != 'driver') {
        emit(const LoginFailure('Only driver accounts are allowed in this app.'));
        return;
      }

      await _prefs.setString(AppConstants.prefAccessToken, session.accessToken);
      await _prefs.setString(AppConstants.prefRefreshToken, session.refreshToken);
      await _prefs.setString(AppConstants.prefDriverId, session.user.id.toString());
      await _prefs.setString(AppConstants.prefDriverName, session.user.displayName);
      await _prefs.setString(AppConstants.prefDriverUsername, session.user.username);
      await _prefs.setString(AppConstants.prefDriverRole, session.user.role);

      emit(const LoginSuccess());
    } catch (error) {
      emit(LoginFailure(_mapLoginError(error)));
    }
  }

  String _mapLoginError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
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
