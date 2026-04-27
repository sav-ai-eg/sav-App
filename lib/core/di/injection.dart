import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/network/api_consumer.dart';
import 'package:sav/core/network/dio_api_consumer.dart';
import 'package:sav/core/services/backend_api_service.dart';
import 'package:sav/core/services/auth_session_storage.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/google_directions_service.dart';
import 'package:sav/core/services/google_places_service.dart';
import 'package:sav/core/services/offline_cache_service.dart';
import 'package:sav/core/services/trip_live_updates_service.dart';
import 'package:sav/core/services/trip_navigation_service.dart';
import 'package:sav/core/di/injection.config.dart';
import 'package:sav/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sav/features/auth/data/datasources/auth_local_data_source_impl.dart';
import 'package:sav/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sav/features/auth/data/datasources/auth_remote_data_source_impl.dart';
import 'package:sav/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sav/features/auth/domain/repositories/auth_repository.dart';
import 'package:sav/features/auth/domain/usecases/login_use_case.dart';
import 'package:sav/features/auth/domain/usecases/logout_use_case.dart';
import 'package:sav/features/auth/domain/usecases/persist_auth_session_use_case.dart';
import 'package:sav/features/auth/presentation/cubit/login_cubit.dart';
import 'package:sav/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:sav/features/home/data/datasources/home_local_data_source.dart';
import 'package:sav/features/home/data/datasources/home_local_data_source_impl.dart';
import 'package:sav/features/home/data/datasources/home_remote_data_source.dart';
import 'package:sav/features/home/data/datasources/home_remote_data_source_impl.dart';
import 'package:sav/features/home/data/repositories/home_repository_impl.dart';
import 'package:sav/features/home/domain/repositories/home_repository.dart';
import 'package:sav/features/home/domain/usecases/load_home_dashboard_use_case.dart';
import 'package:sav/features/home/domain/usecases/load_home_duty_for_month_use_case.dart';
import 'package:sav/features/home/presentation/cubit/home_cubit.dart';

final getIt = GetIt.instance;
@InjectableInit()
Future<void> configureDependencies() async {
  await getIt.init();
  if (!getIt.isRegistered<FlutterSecureStorage>()) {
    getIt.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
  }
  if (!getIt.isRegistered<AuthSessionStorage>()) {
    getIt.registerLazySingleton<AuthSessionStorage>(
      () => AuthSessionStorage(
        preferences: getIt<SharedPreferences>(),
        secureStorage: getIt<FlutterSecureStorage>(),
      ),
    );
  }
  if (!getIt.isRegistered<Dio>()) {
    getIt.registerLazySingleton<Dio>(
      () => Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          headers: const <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (int? status) => status != null && status < 500,
        ),
      ),
    );
  }
  if (getIt.isRegistered<ApiConsumer>()) {
    await getIt.unregister<ApiConsumer>();
  }
  getIt.registerLazySingleton<ApiConsumer>(
    () => DioApiConsumer(
      getIt<Dio>(),
      getIt<SharedPreferences>(),
      getIt<AuthSessionStorage>(),
    ),
  );
  if (!getIt.isRegistered<AuthRemoteDataSource>()) {
    getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt<ApiConsumer>()),
    );
  }

  if (!getIt.isRegistered<AuthLocalDataSource>()) {
    getIt.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(
        getIt<SharedPreferences>(),
        sessionStorage: getIt<AuthSessionStorage>(),
      ),
    );
  }
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        getIt<AuthRemoteDataSource>(),
        getIt<AuthLocalDataSource>(),
      ),
    );
  }

  if (!getIt.isRegistered<LoginUseCase>()) {
    getIt.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(getIt<AuthRepository>()),
    );
  }
  if (!getIt.isRegistered<PersistAuthSessionUseCase>()) {
    getIt.registerLazySingleton<PersistAuthSessionUseCase>(
      () => PersistAuthSessionUseCase(getIt<AuthRepository>()),
    );
  }
  if (!getIt.isRegistered<LogoutUseCase>()) {
    getIt.registerLazySingleton<LogoutUseCase>(
      () => LogoutUseCase(getIt<AuthRepository>()),
    );
  }

  if (!getIt.isRegistered<LoginCubit>()) {
    getIt.registerFactory<LoginCubit>(
      () =>
          LoginCubit(getIt<LoginUseCase>(), getIt<PersistAuthSessionUseCase>()),
    );
  }
  if (getIt.isRegistered<SplashCubit>()) {
    await getIt.unregister<SplashCubit>();
  }
  getIt.registerFactory<SplashCubit>(
    () => SplashCubit(getIt<SharedPreferences>(), getIt<AuthSessionStorage>()),
  );

  if (!getIt.isRegistered<GooglePlacesService>()) {
    getIt.registerLazySingleton<GooglePlacesService>(
      () => GooglePlacesService(dio: getIt<Dio>()),
    );
  }
  if (!getIt.isRegistered<GoogleDirectionsService>()) {
    getIt.registerLazySingleton<GoogleDirectionsService>(
      () => GoogleDirectionsService(dio: getIt<Dio>()),
    );
  }
  if (!getIt.isRegistered<TripNavigationService>()) {
    getIt.registerLazySingleton<TripNavigationService>(
      () => TripNavigationService(getIt<GoogleDirectionsService>()),
    );
  }

  if (!getIt.isRegistered<TripLiveUpdatesService>()) {
    getIt.registerLazySingleton<TripLiveUpdatesService>(
      TripLiveUpdatesService.new,
    );
  }

  if (!getIt.isRegistered<BackendApiService>()) {
    getIt.registerLazySingleton<BackendApiService>(
      () => BackendApiService(apiConsumer: getIt<ApiConsumer>()),
    );
  }
  if (!getIt.isRegistered<HomeRemoteDataSource>()) {
    getIt.registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(getIt<ApiConsumer>()),
    );
  }

  if (!getIt.isRegistered<HomeLocalDataSource>()) {
    getIt.registerLazySingleton<HomeLocalDataSource>(
      () => HomeLocalDataSourceImpl(getIt<SharedPreferences>()),
    );
  }
  if (!getIt.isRegistered<HomeRepository>()) {
    getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        getIt<HomeRemoteDataSource>(),
        getIt<HomeLocalDataSource>(),
        getIt<ConnectivityService>(),
        getIt<OfflineCacheService>(),
      ),
    );
  }
  if (!getIt.isRegistered<LoadHomeDashboardUseCase>()) {
    getIt.registerLazySingleton<LoadHomeDashboardUseCase>(
      () => LoadHomeDashboardUseCase(getIt<HomeRepository>()),
    );
  }
  if (!getIt.isRegistered<LoadHomeDutyForMonthUseCase>()) {
    getIt.registerLazySingleton<LoadHomeDutyForMonthUseCase>(
      () => LoadHomeDutyForMonthUseCase(getIt<HomeRepository>()),
    );
  }

  if (!getIt.isRegistered<HomeCubit>()) {
    getIt.registerFactory<HomeCubit>(
      () => HomeCubit(
        getIt<LoadHomeDashboardUseCase>(),
        getIt<LoadHomeDutyForMonthUseCase>(),
      ),
    );
  }
}
