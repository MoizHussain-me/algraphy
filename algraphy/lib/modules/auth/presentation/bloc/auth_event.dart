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

class ClientSignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String companyName;
  final String industry;
  final String servicesNeeded;

  ClientSignupRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.companyName,
    required this.industry,
    required this.servicesNeeded,
  });
}

class ChangePasswordRequested extends AuthEvent {
  final String newPassword;
  ChangePasswordRequested(this.newPassword);
}

class LogoutRequested extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}
