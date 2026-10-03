import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';


class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({
    required this.repository,
  });

  Future<UserEntity> call(
    String email,
    String password,
  ) async {
    return await repository.login(
      email,
      password,
    );
  }
}