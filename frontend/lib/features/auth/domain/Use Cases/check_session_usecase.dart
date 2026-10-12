import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';

class CheckSessionUseCase {
  final AuthRepository repository;

  CheckSessionUseCase({required this.repository});

  /// Returns the saved [UserEntity] or null if no valid session exists.
  Future<UserEntity?> call() async {
    return await repository.getSession();
  }
}
