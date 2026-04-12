import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/util/extensions/navigation.dart';
import 'package:sav/core/util/routing/routes.dart';

part 'splash_state.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._prefs) : super(SplashInitial());

  final SharedPreferences _prefs;

  void handlePageNext(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        final hasSession = _hasValidSession();

        if (context.mounted) {
          if (hasSession) {
            context.pushAndRemoveUntilWithNamed(Routes.bottomNavView);
          } else {
            context.pushAndRemoveUntilWithNamed(Routes.loginView);
          }
        }
      }
    });
  }

  bool _hasValidSession() {
    final accessToken = _prefs.getString(AppConstants.prefAccessToken);
    final driverId = _prefs.getString(AppConstants.prefDriverId);

    if (accessToken == null || accessToken.trim().isEmpty) {
      return false;
    }

    if (driverId == null || driverId.trim().isEmpty) {
      return false;
    }

    return _isJwtNotExpired(accessToken);
  }

  bool _isJwtNotExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;

      final exp = payload['exp'];
      if (exp is! int) {
        return true;
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 1)));
    } catch (_) {
      return false;
    }
  }
}
