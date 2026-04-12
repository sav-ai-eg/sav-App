// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sav/core/di/app_module.dart' as _i841;
import 'package:sav/core/services/alert_service.dart' as _i514;
import 'package:sav/core/services/camera_service.dart' as _i933;
import 'package:sav/core/services/connectivity_service.dart' as _i645;
import 'package:sav/core/services/firestore_service.dart' as _i526;
import 'package:sav/core/services/location_service.dart' as _i730;
import 'package:sav/core/services/offline_cache_service.dart' as _i46;
import 'package:sav/core/services/tflite_detection_service.dart' as _i149;
import 'package:sav/features/auth/presentation/cubit/driver_data_cubit.dart'
    as _i670;
import 'package:sav/features/emergency/presentation/cubit/emergency_cubit.dart'
    as _i809;
import 'package:sav/features/history/presentation/cubit/history_cubit.dart'
    as _i653;
import 'package:sav/features/home/presentation/cubit/home_cubit.dart' as _i635;
import 'package:sav/features/splash/presentation/cubit/splash_cubit.dart'
    as _i60;
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart' as _i801;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => appModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i514.AlertService>(() => _i514.AlertService());
    gh.lazySingleton<_i933.CameraService>(() => _i933.CameraService());
    gh.lazySingleton<_i645.ConnectivityService>(
      () => _i645.ConnectivityService(),
    );
    gh.lazySingleton<_i526.FirestoreService>(() => _i526.FirestoreService());
    gh.lazySingleton<_i730.LocationService>(() => _i730.LocationService());
    gh.lazySingleton<_i46.OfflineCacheService>(
      () => _i46.OfflineCacheService(),
    );
    gh.lazySingleton<_i149.TfliteDetectionService>(
      () => _i149.TfliteDetectionService(),
    );
    gh.factory<_i801.TripCubit>(
      () => _i801.TripCubit(
        gh<_i526.FirestoreService>(),
        gh<_i149.TfliteDetectionService>(),
        gh<_i933.CameraService>(),
        gh<_i730.LocationService>(),
        gh<_i514.AlertService>(),
        gh<_i46.OfflineCacheService>(),
        gh<_i645.ConnectivityService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i670.DriverDataCubit>(
      () => _i670.DriverDataCubit(
        gh<_i526.FirestoreService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i653.HistoryCubit>(
      () => _i653.HistoryCubit(
        gh<_i526.FirestoreService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i809.EmergencyCubit>(
      () => _i809.EmergencyCubit(
        gh<_i526.FirestoreService>(),
        gh<_i645.ConnectivityService>(),
        gh<_i730.LocationService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i60.SplashCubit>(
      () => _i60.SplashCubit(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i635.HomeCubit>(
      () => _i635.HomeCubit(
        gh<_i526.FirestoreService>(),
        gh<_i645.ConnectivityService>(),
        gh<_i46.OfflineCacheService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i841.AppModule {}
