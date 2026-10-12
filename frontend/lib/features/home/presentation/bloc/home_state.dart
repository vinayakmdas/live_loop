import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

abstract class HomeState {
  final UserEntity? user;

  const HomeState({this.user});

  /// Dynamic user display name, safely falls back to 'User'
  String get userName {
    if (user == null) return 'User';
    final trimmed = user!.name.trim();
    return trimmed.isNotEmpty ? trimmed : 'User';
  }

  /// Single uppercase initial for profile avatar, safe from index error
  String get userInitial {
    final name = userName;
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  /// Safe email getter
  String get userEmail => user?.email ?? '';

  /// Safe username getter
  String get username => user?.username ?? '';

  /// Authentication check
  bool get isLoggedIn => user != null;
}

class HomeInitial extends HomeState {
  const HomeInitial({super.user});
}

class HomeLoading extends HomeState {
  const HomeLoading({super.user});
}

class HomeLoaded extends HomeState {
  const HomeLoaded({required UserEntity user}) : super(user: user);
}

class HomeUnauthenticated extends HomeState {
  const HomeUnauthenticated() : super(user: null);
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message, super.user});
}
