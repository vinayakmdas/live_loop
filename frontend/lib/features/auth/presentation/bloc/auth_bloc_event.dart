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

/// Fired when user initiates Google Sign-In.
class GoogleSignInRequested extends AuthEvent {}

/// Fired on app start to check whether a valid local session exists.
class CheckSessionRequested extends AuthEvent {}

/// Fired when the user explicitly logs out.
class LogoutRequested extends AuthEvent {}

/// Fired when the session has expired and refresh token is invalid or revoked.
class SessionExpiredRequested extends AuthEvent {}

/// Fired when user requests a password reset link.
class ForgotPasswordRequested extends AuthEvent {
  final String email;

  ForgotPasswordRequested({required this.email});
}

/// Fired when user submits a new password with their reset token.
class ResetPasswordRequested extends AuthEvent {
  final String resetToken;
  final String newPassword;

  ResetPasswordRequested({
    required this.resetToken,
    required this.newPassword,
  });
}