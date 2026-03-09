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

class TalentLoginRequested extends AuthEvent {
  final String email;
  final String password;

  TalentLoginRequested(this.email, this.password);
}

class TalentSignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String userType;
  final String talentType;

  TalentSignupRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.userType,
    required this.talentType,
  });
}

class ChangePasswordRequested extends AuthEvent {
  final String newPassword;
  ChangePasswordRequested(this.newPassword);
}

class LogoutRequested extends AuthEvent {}

class DeleteAccountRequested extends AuthEvent {}
