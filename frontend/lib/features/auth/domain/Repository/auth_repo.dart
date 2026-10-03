import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);

  Future<UserEntity> register(
    String name,
    String email,
    String password,
  );

}
