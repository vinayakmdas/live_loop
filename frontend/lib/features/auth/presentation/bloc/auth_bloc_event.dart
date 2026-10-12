abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({
    required this.email,
    required this.password,
  });
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
}

/// Fired on app start to check whether a valid local session exists.
class CheckSessionRequested extends AuthEvent {}

/// Fired when the user explicitly logs out.
class LogoutRequested extends AuthEvent {}