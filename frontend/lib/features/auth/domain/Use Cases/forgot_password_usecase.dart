import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase({required this.repository});

  Future<String> call(String email) async {
    return await repository.forgotPassword(email);
  }
}
