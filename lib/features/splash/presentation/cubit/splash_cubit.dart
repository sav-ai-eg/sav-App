import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/services/auth_session_storage.dart';
import 'package:sav/core/util/extensions/navigation.dart';
import 'package:sav/core/util/routing/routes.dart';

part 'splash_state.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(
    SharedPreferences preferences, [
    AuthSessionStorage? authSessionStorage,
  ]) : _authSessionStorage =
           authSessionStorage ?? AuthSessionStorage(preferences: preferences),
       super(SplashInitial());

  final AuthSessionStorage _authSessionStorage;

  void handlePageNext(BuildContext context) {
    _handlePageNext(context);
  }

  Future<void> _handlePageNext(BuildContext context) async {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!context.mounted) {
      return;
    }

    final hasSession = await _authSessionStorage.hasValidSession();
    if (!context.mounted) {
      return;
    }

    context.pushAndRemoveUntilWithNamed(
      hasSession ? Routes.bottomNavView : Routes.loginView,
    );
  }
}
