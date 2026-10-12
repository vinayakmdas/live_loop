import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_event.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/auth/presentation/pages/loginscreen.dart';

class SignupWidget {
  static Widget appText() {
    return Row(
      children: [
        Image.asset(
          "asset/icon.png",
          width: 42,
          height: 42,
        ),
        const SizedBox(width: 0),
        const Text(
          'Live Loop',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  static Widget welcomeText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your account',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: 6),
        Text(
          "Start your permanent meeting space",
          style: TextStyle(
            fontSize: 15,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  static Widget username({
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      style: const TextStyle(
        color: AppColors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Username',
        hintStyle: const TextStyle(
          color: AppColors.hintText,
        ),
        prefixIcon: const Icon(
          Icons.person,
          color: AppColors.iconColor,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static Widget emailField({
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        color: AppColors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Email',
        hintStyle: const TextStyle(
          color: AppColors.hintText,
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: AppColors.iconColor,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static Widget passwordField({
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(
        color: AppColors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: const TextStyle(
          color: AppColors.hintText,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppColors.iconColor,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static Widget confirmPasswordField({
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(
        color: AppColors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Confirm Password',
        hintStyle: const TextStyle(
          color: AppColors.hintText,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppColors.iconColor,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static Widget signupButton({
    required BuildContext context,
    required TextEditingController nameController,
    required TextEditingController emailcontroller,
    required TextEditingController passwordcontroller,
    required TextEditingController confirmPasswordcontroller,
  }) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    final name = nameController.text.trim();
                    final email = emailcontroller.text.trim();
                    final password = passwordcontroller.text.trim();
                    final confirmPassword =
                        confirmPasswordcontroller.text.trim();

                    if (name.isEmpty ||
                        email.isEmpty ||
                        password.isEmpty ||
                        confirmPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }

                    if (password != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    if (password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password must be at least 6 characters'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(
                          RegisterRequested(
                            name: name,
                            email: email,
                            password: password,
                          ),
                        );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primaryDisabled,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  static Widget orDivider() {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.divider,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  static Widget googleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          // Google sign-in
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Image.asset(
                'asset/google.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget moveToSignup({
    required BuildContext context,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account?",
          style: TextStyle(
            color: AppColors.grey,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const Loginscreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.15, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOut;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(
                    CurveTween(curve: curve),
                  );

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: const Text(
            'Sign in',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}