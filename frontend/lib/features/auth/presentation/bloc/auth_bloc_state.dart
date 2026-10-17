import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

abstract class AuthState {}

/// Initial state before any action is taken.
class AuthInitial extends AuthState {}

/// Loading state during async operations (login, register, session check).
class AuthLoading extends AuthState {}

/// Emitted after a successful login or register — user data is available.
class AuthSuccess extends AuthState {
  final UserEntity user;

  AuthSuccess(this.user);
}

/// Emitted when an authenticated session is restored from local storage.
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  AuthAuthenticated(this.user);
}

/// Emitted when no valid session is found, or after logout.
class AuthUnauthenticated extends AuthState {}

/// Emitted when any auth operation fails.
class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);
}

/// Emitted while sending the password reset email.
class ForgotPasswordLoading extends AuthState {}

/// Emitted when the password reset email request was accepted.
class ForgotPasswordSuccess extends AuthState {
  final String message;

  ForgotPasswordSuccess(this.message);
}

/// Emitted when requesting the password reset email fails.
class ForgotPasswordFailure extends AuthState {
  final String error;

  ForgotPasswordFailure(this.error);
}

/// Emitted while resetting the password.
class ResetPasswordLoading extends AuthState {}

/// Emitted when the password was successfully reset.
class ResetPasswordSuccess extends AuthState {
  final String message;

  ResetPasswordSuccess(this.message);
}

/// Emitted when resetting the password fails.
class ResetPasswordFailure extends AuthState {
  final String error;

  ResetPasswordFailure(this.error);
}