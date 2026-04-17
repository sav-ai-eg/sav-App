import 'package:equatable/equatable.dart';
import 'package:sav/features/auth/domain/entities/auth_user_entity.dart';

class AuthSessionEntity extends Equatable {
  const AuthSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUserEntity user;

  @override
  List<Object?> get props => <Object?>[accessToken, refreshToken, user];
}
