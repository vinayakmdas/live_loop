import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';

class GoogleSignInUseCase {
  final AuthRepository repository;

  const GoogleSignInUseCase(this.repository);

  Future<UserEntity> call() async {
    return await repository.signInWithGoogle();
  }
}
