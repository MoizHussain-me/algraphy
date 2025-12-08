abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  RegisterRequested(this.name, this.email, this.password);
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested(this.email, this.password);
}


class ChangePasswordRequested extends AuthEvent {
  final String newPassword;
  ChangePasswordRequested(this.newPassword);
}

class LogoutRequested extends AuthEvent {}
