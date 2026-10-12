import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/home/presentation/bloc/home_event.dart';
import 'package:frontend/features/home/presentation/bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({UserEntity? initialUser})
      : super(initialUser != null
            ? HomeLoaded(user: initialUser)
            : const HomeInitial()) {
    on<LoadHomeUser>(_onLoadHomeUser);
    on<UpdateHomeUser>(_onUpdateHomeUser);
    on<ClearHomeUser>(_onClearHomeUser);
  }

  void _onLoadHomeUser(LoadHomeUser event, Emitter<HomeState> emit) {
    if (event.user != null) {
      emit(HomeLoaded(user: event.user!));
    } else if (state.user != null) {
      emit(HomeLoaded(user: state.user!));
    } else {
      emit(const HomeUnauthenticated());
    }
  }

  void _onUpdateHomeUser(UpdateHomeUser event, Emitter<HomeState> emit) {
    emit(HomeLoaded(user: event.user));
  }

  void _onClearHomeUser(ClearHomeUser event, Emitter<HomeState> emit) {
    emit(const HomeUnauthenticated());
  }
}
