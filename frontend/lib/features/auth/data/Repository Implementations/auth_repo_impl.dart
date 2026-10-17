import 'package:frontend/core/storage/tocken_storage.dart';
import 'package:frontend/features/auth/data/Data%20Sources/auth_datasource.dart';
import 'package:frontend/features/auth/data/services/google_auth_service.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SessionLocalDataSource localDataSource;
  final GoogleAuthService googleAuthService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    GoogleAuthService? googleAuthService,
  }) : googleAuthService = googleAuthService ?? GoogleAuthService();

  @override
  Future<UserEntity> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }

  @override
  Future<UserEntity> register(
    String name,
    String email,
    String password,
  ) async {
    return await remoteDataSource.register(name, email, password);
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final account = await googleAuthService.signIn();
    if (account == null) {
      throw Exception('Google sign-in was cancelled');
    }

    String? idToken;
    try {
      final auth = await account.authentication;
      idToken = auth.idToken;
    } catch (_) {}

    final user = await remoteDataSource.googleSignIn(
      email: account.email,
      name: account.displayName ?? account.email.split('@')[0],
      profileImage: account.photoUrl,
      googleId: account.id,
      idToken: idToken,
    );

    await saveSession(user);
    return user;
  }

  @override
  Future<void> saveSession(UserEntity user) async {
    await localDataSource.saveSession(user);
  }

  @override
  Future<UserEntity?> getSession() async {
    return localDataSource.getSession();
  }

  @override
  Future<void> clearSession() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {}
    try {
      await googleAuthService.signOut();
    } catch (_) {}
    await localDataSource.clearSession();
  }

  @override
  Future<String> forgotPassword(String email) async {
    return remoteDataSource.forgotPassword(email);
  }

  @override
  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    return remoteDataSource.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }
}
