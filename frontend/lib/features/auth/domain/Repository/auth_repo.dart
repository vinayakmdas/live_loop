import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);

  Future<UserEntity> register(
    String name,
    String email,
    String password,
  );

  /// Authenticates using Google Sign-In and returns the user entity.
  Future<UserEntity> signInWithGoogle();

  /// Saves the user session to local storage after successful login/register.
  Future<void> saveSession(UserEntity user);

  /// Returns the persisted [UserEntity] if a session exists, otherwise null.
  Future<UserEntity?> getSession();

  /// Clears the local session on logout.
  Future<void> clearSession();

  /// Requests a password reset link for the provided email.
  Future<String> forgotPassword(String email);

  /// Resets the user's password using a valid reset token.
  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
  });
}
