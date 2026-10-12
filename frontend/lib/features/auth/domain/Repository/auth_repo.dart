import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);

  Future<UserEntity> register(
    String name,
    String email,
    String password,
  );

  /// Saves the user session to local storage after successful login/register.
  Future<void> saveSession(UserEntity user);

  /// Returns the persisted [UserEntity] if a session exists, otherwise null.
  Future<UserEntity?> getSession();

  /// Clears the local session on logout.
  Future<void> clearSession();
}
