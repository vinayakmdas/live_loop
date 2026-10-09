import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/login_usecase.dart';
import 'package:frontend/features/auth/domain/Use%20Cases/register_usecase.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc/autbloc_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc/autbloc_state.dart';


class  AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
  }) : super(AuthInitial()) {

    on<LoginRequested>(_login);

    on<RegisterRequested>(_register);
  }

  Future<void> _login(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await loginUseCase(
        event.email,
        event.password,
      );

      emit(AuthSuccess(user));
    } catch (e) {
      emit(
        AuthFailure(
          e.toString(),
        ),
      );
    }
  }

  Future<void> _register(
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

      emit(AuthSuccess(user));
    } catch (e) {
      emit(
        AuthFailure(
          e.toString(),
        ),
      );
    }
  }
}