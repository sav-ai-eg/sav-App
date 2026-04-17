import 'package:sav/features/auth/data/models/auth_session_model.dart';
import 'package:sav/features/auth/data/params/login_params.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> login({required LoginParams params});
}
