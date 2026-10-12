import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';

class SaveSessionUseCase {
  final AuthRepository repository;

  SaveSessionUseCase({required this.repository});

  /// Persists the [UserEntity] to local storage.
  Future<void> call(UserEntity user) async {
    await repository.saveSession(user);
  }
}
