import 'package:flutter/material.dart';
import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/auth/presentation/widget/login_widget.dart';


class Loginscreen extends StatelessWidget {
  const Loginscreen({super.key});

  @override
  Widget build(BuildContext context) {
   final  TextEditingController emailcontroller = TextEditingController();
    final TextEditingController passwordcontroller = TextEditingController();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.only(top: 200, left: 25,right: 25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoginWidget.appText(),
              SizedBox(height: 30),
              LoginWidget.welcomeText(),
               SizedBox(height: 45),
               
              LoginWidget.emailField(emailController: emailcontroller),
               SizedBox(height: 30),
              LoginWidget.passwordField(passwordController: passwordcontroller),
                 SizedBox(height: 30),
              LoginWidget.loginButton(emailcontroller, passwordcontroller, context),
           SizedBox(height: 30),
              LoginWidget.orDivider(),
              SizedBox(height: 30,),
              LoginWidget.googleSignInButton(),
              SizedBox(height: 30,),
              LoginWidget.moveToSignup(context: context)
            ],
          )
        ),
      ),
    );
  }
}
