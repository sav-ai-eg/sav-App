import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/services/backend_api_service.dart';
import 'package:sav/core/services/google_places_service.dart';
import 'package:sav/core/di/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  await getIt.init();
  if (!getIt.isRegistered<GooglePlacesService>()) {
    getIt.registerLazySingleton<GooglePlacesService>(GooglePlacesService.new);
  }
  if (!getIt.isRegistered<BackendApiService>()) {
    getIt.registerLazySingleton<BackendApiService>(BackendApiService.new);
  }
}
