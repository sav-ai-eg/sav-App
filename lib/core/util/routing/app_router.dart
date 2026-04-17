import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/util/routing/routes.dart';
import 'package:sav/features/auth/presentation/cubit/login_cubit.dart';
import 'package:sav/features/auth/presentation/views/login_view.dart';
import 'package:sav/features/common/bottom_nav/presentation/cubit/bottom_nav_cubit.dart';
import 'package:sav/features/common/bottom_nav/presentation/views/bottom_nav_view.dart';
import 'package:sav/features/emergency/presentation/views/emergency_view.dart';
import 'package:sav/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:sav/features/splash/presentation/views/splash_view.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splashView:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<SplashCubit>(),
            child: const SplashView(),
          ),
        );

      case Routes.loginView:
      case Routes.driverDataView:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<LoginCubit>(),
            child: const LoginView(),
          ),
        );

      case Routes.bottomNavView:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => BottomNavCubit(),
            child: const BottomNavView(),
          ),
        );

      case Routes.emergencyView:
        return MaterialPageRoute(
          builder: (_) => const EmergencyView(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
