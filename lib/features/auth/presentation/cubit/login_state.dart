part of 'login_cubit.dart';

abstract class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginSubmitting extends LoginState {
  const LoginSubmitting();
}

class LoginSuccess extends LoginState {
  const LoginSuccess();
}

class LoginFailure extends LoginState {
  const LoginFailure(this.message);

  final String message;
}
