import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/auth/presentation/pages/loginscreen.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/home/presentation/bloc/home_event.dart';
import 'package:frontend/features/home/presentation/bloc/home_state.dart';
import 'package:frontend/features/home/presentation/widget/homescren_widget.dart';

/// Home Screen using BLoC pattern for state management
class Homescreen extends StatefulWidget {
  final UserEntity? user;

  const Homescreen({super.key, this.user});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  HomeBloc? _localBloc;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initBloc();
      _initialized = true;
    }
  }

  void _initBloc() {
    final effectiveUser = _resolveUser();

    // Check if HomeBloc is already provided above in the widget tree
    try {
      final parentBloc = context.read<HomeBloc>();
      if (effectiveUser != null) {
        parentBloc.add(LoadHomeUser(user: effectiveUser));
      }
      return;
    } catch (_) {
      // No parent HomeBloc found; fall back to local instance
    }

    if (_localBloc == null) {
      _localBloc = HomeBloc(initialUser: effectiveUser);
      if (effectiveUser == null) {
        _localBloc!.add(LoadHomeUser());
      }
    } else if (effectiveUser != null) {
      _localBloc!.add(LoadHomeUser(user: effectiveUser));
    }
  }

  /// Resolves the authenticated user from constructor, route arguments, or AuthBloc
  UserEntity? _resolveUser() {
    if (widget.user != null) {
      return widget.user;
    }

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is UserEntity) {
      return routeArgs;
    }

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess) {
        return authState.user;
      } else if (authState is AuthAuthenticated) {
        return authState.user;
      }
    } catch (_) {}

    return null;
  }

  @override
  void dispose() {
    _localBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_localBloc != null) {
      return BlocProvider<HomeBloc>.value(
        value: _localBloc!,
        child: const _HomeScreenContent(),
      );
    }

    return const _HomeScreenContent();
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // 1. Loading state
        if (state is HomeLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: HomescrenWidget.appBar(userInitial: 'U'),
            body: HomescrenWidget.loadingView(),
          );
        }

        // 2. Unauthenticated / Not Logged In state
        if (!state.isLoggedIn) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: HomescrenWidget.appBar(userInitial: 'U'),
            body: HomescrenWidget.notLoggedInView(
              onLoginPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Loginscreen()),
                  (route) => false,
                );
              },
            ),
          );
        }

        // 3. Logged-in state displaying user's actual name dynamically
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: HomescrenWidget.appBar(
            userInitial: state.userInitial,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  HomescrenWidget.welcomeSection(userName: state.userName),
                  const SizedBox(height: 25),
                  HomescrenWidget.createMeetingButton(  context: context     ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}