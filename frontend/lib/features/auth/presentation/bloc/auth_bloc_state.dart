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