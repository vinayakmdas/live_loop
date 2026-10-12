import 'package:frontend/core/storage/tocken_storage.dart';
import 'package:frontend/features/auth/data/Data%20Sources/auth_datasource.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SessionLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

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
    await localDataSource.clearSession();
  }
}
