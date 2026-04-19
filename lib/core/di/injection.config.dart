// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:sav/core/di/app_module.dart' as _i1050;
import 'package:sav/core/network/api_consumer.dart' as _i741;
import 'package:sav/core/network/dio_api_consumer.dart' as _i541;
import 'package:sav/core/services/alert_service.dart' as _i5;
import 'package:sav/core/services/camera_service.dart' as _i155;
import 'package:sav/core/services/connectivity_service.dart' as _i441;
import 'package:sav/core/services/firestore_service.dart' as _i811;
import 'package:sav/core/services/location_service.dart' as _i176;
import 'package:sav/core/services/offline_cache_service.dart' as _i789;
import 'package:sav/core/services/tflite_detection_service.dart' as _i813;
import 'package:sav/features/auth/presentation/cubit/driver_data_cubit.dart'
    as _i497;
import 'package:sav/features/emergency/presentation/cubit/emergency_cubit.dart'
    as _i116;
import 'package:sav/features/history/presentation/cubit/history_cubit.dart'
    as _i249;
import 'package:sav/features/home/data/datasources/home_local_data_source.dart'
    as _i123;
import 'package:sav/features/home/data/datasources/home_local_data_source_impl.dart'
    as _i361;
import 'package:sav/features/home/data/datasources/home_remote_data_source.dart'
    as _i799;
import 'package:sav/features/home/data/datasources/home_remote_data_source_impl.dart'
    as _i442;
import 'package:sav/features/home/data/repositories/home_repository_impl.dart'
    as _i540;
import 'package:sav/features/home/domain/repositories/home_repository.dart'
    as _i68;
import 'package:sav/features/home/domain/usecases/load_home_dashboard_use_case.dart'
    as _i193;
import 'package:sav/features/home/domain/usecases/load_home_duty_for_month_use_case.dart'
    as _i1068;
import 'package:sav/features/home/presentation/cubit/home_cubit.dart' as _i727;
import 'package:sav/features/splash/presentation/cubit/splash_cubit.dart'
    as _i265;
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart' as _i138;
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
    gh.lazySingleton<_i361.Dio>(() => appModule.dio);
    gh.lazySingleton<_i5.AlertService>(() => _i5.AlertService());
    gh.lazySingleton<_i155.CameraService>(() => _i155.CameraService());
    gh.lazySingleton<_i441.ConnectivityService>(
      () => _i441.ConnectivityService(),
    );
    gh.lazySingleton<_i811.FirestoreService>(() => _i811.FirestoreService());
    gh.lazySingleton<_i176.LocationService>(() => _i176.LocationService());
    gh.lazySingleton<_i789.OfflineCacheService>(
      () => _i789.OfflineCacheService(),
    );
    gh.lazySingleton<_i813.TfliteDetectionService>(
      () => _i813.TfliteDetectionService(),
    );
    gh.factory<_i116.EmergencyCubit>(
      () => _i116.EmergencyCubit(
        gh<_i811.FirestoreService>(),
        gh<_i441.ConnectivityService>(),
        gh<_i176.LocationService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i497.DriverDataCubit>(
      () => _i497.DriverDataCubit(
        gh<_i811.FirestoreService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i249.HistoryCubit>(
      () => _i249.HistoryCubit(
        gh<_i811.FirestoreService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i265.SplashCubit>(
      () => _i265.SplashCubit(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i123.HomeLocalDataSource>(
      () => _i361.HomeLocalDataSourceImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i741.ApiConsumer>(
      () =>
          _i541.DioApiConsumer(gh<_i361.Dio>(), gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i138.TripCubit>(
      () => _i138.TripCubit(
        gh<_i811.FirestoreService>(),
        gh<_i813.TfliteDetectionService>(),
        gh<_i155.CameraService>(),
        gh<_i176.LocationService>(),
        gh<_i5.AlertService>(),
        gh<_i789.OfflineCacheService>(),
        gh<_i441.ConnectivityService>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i799.HomeRemoteDataSource>(
      () => _i442.HomeRemoteDataSourceImpl(gh<_i741.ApiConsumer>()),
    );
    gh.factory<_i68.HomeRepository>(
      () => _i540.HomeRepositoryImpl(
        gh<_i799.HomeRemoteDataSource>(),
        gh<_i123.HomeLocalDataSource>(),
        gh<_i441.ConnectivityService>(),
        gh<_i789.OfflineCacheService>(),
      ),
    );
    gh.factory<_i193.LoadHomeDashboardUseCase>(
      () => _i193.LoadHomeDashboardUseCase(gh<_i68.HomeRepository>()),
    );
    gh.factory<_i1068.LoadHomeDutyForMonthUseCase>(
      () => _i1068.LoadHomeDutyForMonthUseCase(gh<_i68.HomeRepository>()),
    );
    gh.factory<_i727.HomeCubit>(
      () => _i727.HomeCubit(
        gh<_i193.LoadHomeDashboardUseCase>(),
        gh<_i1068.LoadHomeDutyForMonthUseCase>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i1050.AppModule {}
