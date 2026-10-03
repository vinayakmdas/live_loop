import 'package:flutter/material.dart';
import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/auth/presentation/widget/signup_widget.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailcontroller = TextEditingController();
    final TextEditingController passwordcontroller = TextEditingController();
    final TextEditingController confirmPasswordcontroller =
        TextEditingController();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 200, left: 25, right: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SignupWidget.appText(),
              const SizedBox(height: 30),
              SignupWidget.welcomeText(),
              SizedBox(height: 45),
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
    );
  }
}
