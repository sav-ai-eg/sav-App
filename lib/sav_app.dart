import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/util/routing/app_router.dart';
import 'core/util/routing/routes.dart';

class SavApp extends StatefulWidget {
  final AppRouter appRouter;
  const SavApp({super.key, required this.appRouter});
  static GlobalKey<NavigatorState> appNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<SavApp> createState() => _SavAppState();
}

class _SavAppState extends State<SavApp> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      splitScreenMode: true,
      designSize: const Size(430, 932),
      child: MaterialApp(
        title: AppConstants.appName,
        navigatorKey: SavApp.appNavigatorKey,
        debugShowCheckedModeBanner: false,
        onGenerateRoute: widget.appRouter.generateRoute,
        initialRoute: Routes.splashView,
        scrollBehavior: const _SavScrollBehavior(),
        theme: ThemeData(
          textTheme: GoogleFonts.interTextTheme(),
          scaffoldBackgroundColor: AppColors.scaffoldColor,
          primaryColor: AppColors.primaryColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor,
            primary: AppColors.primaryColor,
            secondary: AppColors.secondaryColor,
          ),
        ),
      ),
    );
  }
}

class _SavScrollBehavior extends MaterialScrollBehavior {
  const _SavScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
