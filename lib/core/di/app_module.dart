import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Register third-party dependencies that can't be annotated directly.
@module
abstract class AppModule {
  @preResolve
  @singleton
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();
}
