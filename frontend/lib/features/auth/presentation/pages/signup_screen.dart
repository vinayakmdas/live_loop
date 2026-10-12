import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/auth/presentation/widget/signup_widget.dart';
import 'package:frontend/features/bottom_navigation/presentation/pages/main_page.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/home/presentation/bloc/home_event.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late final TextEditingController nameController;
  late final TextEditingController emailcontroller;
  late final TextEditingController passwordcontroller;
  late final TextEditingController confirmPasswordcontroller;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailcontroller = TextEditingController();
    passwordcontroller = TextEditingController();
    confirmPasswordcontroller = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailcontroller.dispose();
    passwordcontroller.dispose();
    confirmPasswordcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Update HomeBloc with newly registered user details
            try {
              context.read<HomeBloc>().add(LoadHomeUser(user: state.user));
            } catch (_) {}

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully!'),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 120, left: 25, right: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SignupWidget.appText(),
                const SizedBox(height: 30),
                SignupWidget.welcomeText(),
                const SizedBox(height: 45),
                SignupWidget.username(controller: nameController),
                const SizedBox(height: 30),
                SignupWidget.emailField(controller: emailcontroller),
                const SizedBox(height: 30),
                SignupWidget.passwordField(controller: passwordcontroller),
                const SizedBox(height: 30),
                SignupWidget.confirmPasswordField(
                  controller: confirmPasswordcontroller,
                ),
                const SizedBox(height: 30),
                SignupWidget.signupButton(
                  context: context,
                  nameController: nameController,
                  emailcontroller: emailcontroller,
                  passwordcontroller: passwordcontroller,
                  confirmPasswordcontroller: confirmPasswordcontroller,
                ),
                const SizedBox(height: 30),
                SignupWidget.orDivider(),
                const SizedBox(height: 30),
                SignupWidget.googleSignInButton(),
                const SizedBox(height: 30),
                SignupWidget.moveToSignup(context: context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

