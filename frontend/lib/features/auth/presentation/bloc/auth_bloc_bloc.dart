import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/check_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/clear_session_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/forgot_password_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/google_sign_in_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/login_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/register_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/reset_password_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/save_session_usecase.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GoogleSignInUseCase googleSignInUseCase;
  final CheckSessionUseCase checkSessionUseCase;
  final SaveSessionUseCase saveSessionUseCase;
  final ClearSessionUseCase clearSessionUseCase;
  final ForgotPasswordUseCase? forgotPasswordUseCase;
  final ResetPasswordUseCase? resetPasswordUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.googleSignInUseCase,
    required this.checkSessionUseCase,
    required this.saveSessionUseCase,
    required this.clearSessionUseCase,
    this.forgotPasswordUseCase,
    this.resetPasswordUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<CheckSessionRequested>(_onCheckSession);
    on<LogoutRequested>(_onLogout);
    on<SessionExpiredRequested>(_onSessionExpired);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final user = await loginUseCase(event.email, event.password);
      await saveSessionUseCase(user);
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await registerUseCase(
        event.name,
        event.email,
        event.password,
      );
      await saveSessionUseCase(user);
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onGoogleSignIn(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await googleSignInUseCase();
      await saveSessionUseCase(user);
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onCheckSession(
    CheckSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await checkSessionUseCase();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await clearSessionUseCase();
    emit(AuthUnauthenticated());
  }

  Future<void> _onSessionExpired(
    SessionExpiredRequested event,
    Emitter<AuthState> emit,
  ) async {
    await clearSessionUseCase();
    emit(AuthUnauthenticated());
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(ForgotPasswordLoading());
    try {
      if (forgotPasswordUseCase == null) {
        throw 'Forgot password service is unavailable';
      }
      final message = await forgotPasswordUseCase!(event.email);
      emit(ForgotPasswordSuccess(message));
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString()));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(ResetPasswordLoading());
    try {
      if (resetPasswordUseCase == null) {
        throw 'Reset password service is unavailable';
      }
      final message = await resetPasswordUseCase!(
        resetToken: event.resetToken,
        newPassword: event.newPassword,
      );
      emit(ResetPasswordSuccess(message));
    } catch (e) {
      emit(ResetPasswordFailure(e.toString()));
    }
  }
}
