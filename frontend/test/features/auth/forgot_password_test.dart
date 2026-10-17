import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/domain/Repository/auth_repo.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/check_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/clear_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/forgot_password_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/google_sign_in_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/login_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/register_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/reset_password_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/save_session_usecase.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:frontend/features/auth/presentation/pages/reset_password_screen.dart';

class MockAuthRepository implements AuthRepository {
  bool shouldThrow = false;
  String? lastEmail;
  String? lastToken;
  String? lastNewPassword;

  @override
  Future<String> forgotPassword(String email) async {
    lastEmail = email;
    if (shouldThrow) throw Exception('Unable to process request');
    return 'If that email exists in our system, a password reset link has been sent.';
  }

  @override
  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    lastToken = resetToken;
    lastNewPassword = newPassword;
    if (shouldThrow) throw Exception('Reset token is invalid or has expired');
    return 'Password reset successful. Please log in with your new password.';
  }

  @override
  Future<UserEntity> login(String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<UserEntity> register(String name, String email, String password) async =>
      throw UnimplementedError();

  @override
  Future<UserEntity> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> saveSession(UserEntity user) async {}

  @override
  Future<UserEntity?> getSession() async => null;

  @override
  Future<void> clearSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockRepo;
  late ForgotPasswordUseCase forgotPasswordUseCase;
  late ResetPasswordUseCase resetPasswordUseCase;
  late AuthBloc authBloc;

  setUp(() {
    mockRepo = MockAuthRepository();
    forgotPasswordUseCase = ForgotPasswordUseCase(repository: mockRepo);
    resetPasswordUseCase = ResetPasswordUseCase(repository: mockRepo);

    authBloc = AuthBloc(
      loginUseCase: LoginUseCase(repository: mockRepo),
      registerUseCase: RegisterUseCase(repository: mockRepo),
      googleSignInUseCase: GoogleSignInUseCase(mockRepo),
      checkSessionUseCase: CheckSessionUseCase(repository: mockRepo),
      saveSessionUseCase: SaveSessionUseCase(repository: mockRepo),
      clearSessionUseCase: ClearSessionUseCase(repository: mockRepo),
      forgotPasswordUseCase: forgotPasswordUseCase,
      resetPasswordUseCase: resetPasswordUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('Forgot & Reset Password Unit Tests', () {
    test('ForgotPasswordUseCase invokes repository and returns generic message', () async {
      final message = await forgotPasswordUseCase('user@example.com');
      expect(mockRepo.lastEmail, 'user@example.com');
      expect(message, contains('password reset link has been sent'));
    });

    test('ResetPasswordUseCase invokes repository with token and password', () async {
      final message = await resetPasswordUseCase(
        resetToken: 'token123',
        newPassword: 'newSecretPassword123',
      );
      expect(mockRepo.lastToken, 'token123');
      expect(mockRepo.lastNewPassword, 'newSecretPassword123');
      expect(message, contains('Password reset successful'));
    });

    test('AuthBloc emits [ForgotPasswordLoading, ForgotPasswordSuccess] on success', () async {
      final states = <AuthState>[];
      final subscription = authBloc.stream.listen(states.add);

      authBloc.add(ForgotPasswordRequested(email: 'test@example.com'));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], isA<ForgotPasswordLoading>());
      expect(states[1], isA<ForgotPasswordSuccess>());
      expect((states[1] as ForgotPasswordSuccess).message, contains('reset link'));

      await subscription.cancel();
    });

    test('AuthBloc emits [ForgotPasswordLoading, ForgotPasswordFailure] on error', () async {
      mockRepo.shouldThrow = true;
      final states = <AuthState>[];
      final subscription = authBloc.stream.listen(states.add);

      authBloc.add(ForgotPasswordRequested(email: 'test@example.com'));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], isA<ForgotPasswordLoading>());
      expect(states[1], isA<ForgotPasswordFailure>());

      await subscription.cancel();
    });

    test('AuthBloc emits [ResetPasswordLoading, ResetPasswordSuccess] on success', () async {
      final states = <AuthState>[];
      final subscription = authBloc.stream.listen(states.add);

      authBloc.add(ResetPasswordRequested(
        resetToken: 'test_token',
        newPassword: 'myNewPassword123',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], isA<ResetPasswordLoading>());
      expect(states[1], isA<ResetPasswordSuccess>());

      await subscription.cancel();
    });

    test('AuthBloc emits [ResetPasswordLoading, ResetPasswordFailure] on error', () async {
      mockRepo.shouldThrow = true;
      final states = <AuthState>[];
      final subscription = authBloc.stream.listen(states.add);

      authBloc.add(ResetPasswordRequested(
        resetToken: 'bad_token',
        newPassword: 'password123',
      ));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.length, 2);
      expect(states[0], isA<ResetPasswordLoading>());
      expect(states[1], isA<ResetPasswordFailure>());

      await subscription.cancel();
    });
  });

  group('Forgot & Reset Password Widget Tests', () {
    testWidgets('ForgotPasswordScreen renders input and submits request', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const ForgotPasswordScreen(),
          ),
        ),
      );

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);

      // Attempt submit without email (validation check)
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump();
      expect(find.text('Please enter your email address'), findsOneWidget);

      // Enter valid email and submit
      await tester.enterText(find.byType(TextFormField).first, 'valid@example.com');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pump(); // Tap frame
      await tester.runAsync(() async {
        await authBloc.stream.firstWhere((s) => s is ForgotPasswordSuccess);
      });
      await tester.pump(); // Rebuild with new state

      expect(mockRepo.lastEmail, 'valid@example.com');
      expect(find.text('Check Your Email'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen validates matching password and length', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const ResetPasswordScreen(initialToken: 'valid_prefilled_token'),
          ),
        ),
      );

      expect(find.text('Create New Password'), findsOneWidget);
      expect(find.text('valid_prefilled_token'), findsOneWidget);

      // Enter short password
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), '123'); // short new password
      await tester.enterText(fields.at(2), '123456'); // mismatch confirm password
      await tester.tap(find.text('Reset Password'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters long'), findsOneWidget);

      // Enter matching valid password
      await tester.enterText(fields.at(1), 'secret123');
      await tester.enterText(fields.at(2), 'secret123');
      await tester.tap(find.text('Reset Password'));
      await tester.pump();
      await tester.runAsync(() async {
        await authBloc.stream.firstWhere((s) => s is ResetPasswordSuccess);
      });
      await tester.pump();

      expect(mockRepo.lastToken, 'valid_prefilled_token');
      expect(mockRepo.lastNewPassword, 'secret123');
      expect(find.text('Password Reset Successful'), findsOneWidget);
    });
  });
}
