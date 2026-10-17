import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/theme/appcolors.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/auth/presentation/widget/login_widget.dart';
import 'package:frontend/features/bottom_navigation/presentation/pages/main_page.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/home/presentation/bloc/home_event.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_event.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  late final TextEditingController emailcontroller;
  late final TextEditingController passwordcontroller;

  @override
  void initState() {
    super.initState();
    emailcontroller = TextEditingController();
    passwordcontroller = TextEditingController();
  }

  @override
  void dispose() {
    emailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Update HomeBloc with logged-in user details
            try {
              context.read<HomeBloc>().add(LoadHomeUser(user: state.user));
            } catch (_) {}

            // Load meetings with new authenticated session
            try {
              context.read<MeetingBloc>().add(const LoadMeetingsEvent());
            } catch (_) {}

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainPage(),
                settings: RouteSettings(arguments: state.user),
              ),
              (route) => false,
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 150, left: 25, right: 25),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoginWidget.appText(),
                const SizedBox(height: 30),
                LoginWidget.welcomeText(),
                const SizedBox(height: 45),
                LoginWidget.emailField(emailController: emailcontroller),
                const SizedBox(height: 30),
                LoginWidget.passwordField(passwordController: passwordcontroller),
                const SizedBox(height: 12),
                LoginWidget.forgotPasswordButton(context),
                const SizedBox(height: 24),
                LoginWidget.loginButton(emailcontroller, passwordcontroller, context),
                const SizedBox(height: 30),
                LoginWidget.orDivider(),
                const SizedBox(height: 30),
                LoginWidget.googleSignInButton(context),
                const SizedBox(height: 30),
                LoginWidget.moveToSignup(context: context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

