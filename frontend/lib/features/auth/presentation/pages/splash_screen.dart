import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/theme/appcolors.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/auth/presentation/pages/loginscreen.dart';
import 'package:frontend/features/bottom_navigation/presentation/pages/main_page.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/home/presentation/bloc/home_event.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_event.dart';

/// A simple splash screen that checks local session on startup and routes
/// to either the Home (MainPage) or Login screen accordingly.
/// The visual design of this screen will be updated later.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch session check as soon as the screen is live.
    context.read<AuthBloc>().add(CheckSessionRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Restore user into HomeBloc so screens have access to user data.
          try {
            context.read<HomeBloc>().add(LoadHomeUser(user: state.user));
          } catch (_) {}

          // Preload meetings for authenticated user
          try {
            context.read<MeetingBloc>().add(const LoadMeetingsEvent());
          } catch (_) {}

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainPage()),
            (route) => false,
          );
        } else if (state is AuthUnauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Loginscreen()),
            (route) => false,
          );
        }
      },
      child: const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          // Simple placeholder — final design will be applied separately.
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
