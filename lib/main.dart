import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/offline_cache_service.dart';
import 'package:sav/core/util/routing/app_router.dart';
import 'package:sav/firebase_options.dart';
import 'package:sav/sav_app.dart';
void main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await Hive.initFlutter();
      await configureDependencies();
      await getIt<OfflineCacheService>().initialize();
      getIt<ConnectivityService>().initialize();
      await ScreenUtil.ensureScreenSize();
      runApp(SavApp(appRouter: AppRouter()));
    },
    (error, stack) 
    {
      debugPrint('Error: $error');
      debugPrint('Stack: $stack');
    },
  );
}   
