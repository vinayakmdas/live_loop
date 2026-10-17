import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:frontend/core/storage/tocken_storage.dart';
import 'package:frontend/features/auth/data/model/user_model.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/check_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/clear_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/google_sign_in_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/login_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/register_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/save_session_usecase.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/home/domain/entities/chat_message.dart';

class MockGoogleSignInAccount implements GoogleSignInAccount {
  @override
  final String displayName;
  @override
  final String email;
  @override
  final String id;
  @override
  final String? photoUrl;
  @override
  final String? serverAuthCode;

  MockGoogleSignInAccount({
    required this.displayName,
    required this.email,
    required this.id,
    this.photoUrl,
    this.serverAuthCode,
  });

  @override
  Future<GoogleSignInAuthentication> get authentication =>
      Future.value(MockGoogleSignInAuthentication());

  @override
  Future<Map<String, String>> get authHeaders => Future.value({});

  @override
  Future<void> clearAuthCache() async {}
}

class MockGoogleSignInAuthentication implements GoogleSignInAuthentication {
  @override
  String? get accessToken => 'mock_google_access_token';

  @override
  String? get idToken => 'mock_google_id_token';

  @override
  String? get serverAuthCode => null;
}

class FakeAuthRepository implements AuthRepository {
  UserEntity? mockGoogleUser;
  bool shouldThrow = false;
  String errorMessage = 'Google Sign-In failed';

  @override
  Future<UserEntity> signInWithGoogle() async {
    if (shouldThrow) throw Exception(errorMessage);
    return mockGoogleUser ??
        const UserEntity(
          id: 'google_user_123',
          name: 'Jane Google',
          username: 'janeg',
          email: 'jane@google.com',
          profileImage: 'https://lh3.googleusercontent.com/a/fake_photo',
          token: 'jwt_mock_token',
          refreshToken: 'refresh_mock_token',
        );
  }

  @override
  Future<UserEntity> login(String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<UserEntity> register(String name, String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<void> saveSession(UserEntity user) async {}

  @override
  Future<UserEntity?> getSession() async => mockGoogleUser;

  @override
  Future<void> clearSession() async {}

  @override
  Future<String> forgotPassword(String email) async => 'Reset link sent';

  @override
  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async => 'Password reset successful';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Sign-In & Profile Management Tests', () {
    test('UserModel serializes and deserializes profileImage correctly', () {
      final json = {
        '_id': 'u101',
        'name': 'Google User',
        'username': 'google_user',
        'email': 'user@gmail.com',
        'profileImage': 'https://lh3.googleusercontent.com/avatar123',
      };

      final user = UserModel.fromJson(
        json,
        token: 'access_abc',
        refreshToken: 'refresh_xyz',
      );

      expect(user.id, 'u101');
      expect(user.name, 'Google User');
      expect(user.email, 'user@gmail.com');
      expect(user.profileImage, 'https://lh3.googleusercontent.com/avatar123');
      expect(user.token, 'access_abc');
      expect(user.refreshToken, 'refresh_xyz');

      final serialized = user.toJson();
      expect(serialized['profileImage'], 'https://lh3.googleusercontent.com/avatar123');
      expect(serialized['name'], 'Google User');
    });

    test('SessionLocalDataSource persists and restores profileImage across sessions', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SessionLocalDataSource(prefs: prefs);

      expect(storage.getSession(), isNull);

      const user = UserEntity(
        id: 'u202',
        name: 'Sarah Connor',
        username: 'sconnor',
        email: 'sarah@skynet.com',
        profileImage: 'https://images.example.com/sarah.jpg',
        token: 'token_123',
        refreshToken: 'refresh_456',
      );

      await storage.saveSession(user);

      final restored = storage.getSession();
      expect(restored, isNotNull);
      expect(restored!.id, 'u202');
      expect(restored.name, 'Sarah Connor');
      expect(restored.email, 'sarah@skynet.com');
      expect(restored.profileImage, 'https://images.example.com/sarah.jpg');
      expect(restored.token, 'token_123');
      expect(restored.refreshToken, 'refresh_456');

      // Clear session
      await storage.clearSession();
      expect(storage.getSession(), isNull);
    });

    test('GoogleSignInUseCase invokes repository.signInWithGoogle()', () async {
      final fakeRepo = FakeAuthRepository();
      final useCase = GoogleSignInUseCase(fakeRepo);

      final result = await useCase();
      expect(result.name, 'Jane Google');
      expect(result.email, 'jane@google.com');
      expect(result.profileImage, isNotNull);
    });

    test('AuthBloc handles GoogleSignInRequested successfully', () async {
      final fakeRepo = FakeAuthRepository();
      final googleSignInUseCase = GoogleSignInUseCase(fakeRepo);
      final saveSessionUseCase = SaveSessionUseCase(repository: fakeRepo);
      final checkSessionUseCase = CheckSessionUseCase(repository: fakeRepo);
      final clearSessionUseCase = ClearSessionUseCase(repository: fakeRepo);
      final loginUseCase = LoginUseCase(repository: fakeRepo);
      final registerUseCase = RegisterUseCase(repository: fakeRepo);

      final bloc = AuthBloc(
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
        googleSignInUseCase: googleSignInUseCase,
        checkSessionUseCase: checkSessionUseCase,
        saveSessionUseCase: saveSessionUseCase,
        clearSessionUseCase: clearSessionUseCase,
      );

      expect(bloc.state, isA<AuthInitial>());

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(GoogleSignInRequested());

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthSuccess>());

      final successState = states[1] as AuthSuccess;
      expect(successState.user.name, 'Jane Google');
      expect(successState.user.profileImage, isNotNull);

      await subscription.cancel();
      await bloc.close();
    });

    test('AuthBloc handles GoogleSignInRequested failure gracefully', () async {
      final fakeRepo = FakeAuthRepository()
        ..shouldThrow = true
        ..errorMessage = 'User cancelled Google Sign In';

      final googleSignInUseCase = GoogleSignInUseCase(fakeRepo);
      final saveSessionUseCase = SaveSessionUseCase(repository: fakeRepo);
      final checkSessionUseCase = CheckSessionUseCase(repository: fakeRepo);
      final clearSessionUseCase = ClearSessionUseCase(repository: fakeRepo);
      final loginUseCase = LoginUseCase(repository: fakeRepo);
      final registerUseCase = RegisterUseCase(repository: fakeRepo);

      final bloc = AuthBloc(
        loginUseCase: loginUseCase,
        registerUseCase: registerUseCase,
        googleSignInUseCase: googleSignInUseCase,
        checkSessionUseCase: checkSessionUseCase,
        saveSessionUseCase: saveSessionUseCase,
        clearSessionUseCase: clearSessionUseCase,
      );

      final states = <AuthState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(GoogleSignInRequested());

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthFailure>());

      final failureState = states[1] as AuthFailure;
      expect(failureState.message, contains('User cancelled Google Sign In'));

      await subscription.cancel();
      await bloc.close();
    });

    test('ChatMessage properly parses and formats senderProfileImage and senderInitial', () {
      final msgWithPic = ChatMessage.fromJson({
        'id': 'm1',
        'roomId': 'room_abc',
        'senderId': 'u1',
        'senderName': 'Alice Wonderland',
        'senderProfileImage': 'https://google.com/alice.png',
        'text': 'Hello call!',
        'timestamp': DateTime.now().toIso8601String(),
      });

      expect(msgWithPic.senderProfileImage, 'https://google.com/alice.png');
      expect(msgWithPic.senderInitial, 'A');
      expect(msgWithPic.toJson()['senderProfileImage'], 'https://google.com/alice.png');

      final msgWithoutPic = ChatMessage.fromJson({
        'id': 'm2',
        'roomId': 'room_abc',
        'senderId': 'u2',
        'senderName': 'Bob Marley',
        'text': 'One love',
        'timestamp': DateTime.now().toIso8601String(),
      });

      expect(msgWithoutPic.senderProfileImage, isNull);
      expect(msgWithoutPic.senderInitial, 'B');
    });
  });
}
