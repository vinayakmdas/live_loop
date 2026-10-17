import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase({required this.repository});

  Future<String> call({
    required String resetToken,
    required String newPassword,
  }) async {
    return await repository.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }
}
