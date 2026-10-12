import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';

class ClearSessionUseCase {
  final AuthRepository repository;

  ClearSessionUseCase({required this.repository});

  /// Removes the persisted session from local storage on logout.
  Future<void> call() async {
    await repository.clearSession();
  }
}
