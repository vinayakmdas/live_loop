import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

abstract class HomeEvent {}

/// Event to load user details into HomeBloc
class LoadHomeUser extends HomeEvent {
  final UserEntity? user;

  LoadHomeUser({this.user});
}

/// Event to update user details in HomeBloc
class UpdateHomeUser extends HomeEvent {
  final UserEntity user;

  UpdateHomeUser(this.user);
}

/// Event to clear user details on logout or unauthenticated state
class ClearHomeUser extends HomeEvent {}
