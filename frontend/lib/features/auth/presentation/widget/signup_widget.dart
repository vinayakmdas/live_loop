import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_event.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
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

      SizedBox(width: 0),

      Text(
        'Live Loop',
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ],
  );
}   


  static Widget welcomeText() {

  return Column(
crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Create your account',
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
  
      SizedBox(height: 6),
  
      Text(
"Start your permanent meeting space",   
     style: TextStyle(
          fontSize: 15,
          color: Colors.grey,
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
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Username',
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: const Icon(
          Icons.person,
          color: Colors.grey,
        ),
        filled: true,
        fillColor: const Color(0xFF171A24),
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
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Email',
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: Colors.grey,
        ),
        filled: true,
        fillColor: const Color(0xFF171A24),
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
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Password',
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Colors.grey,
        ),
        filled: true,
        fillColor: const Color(0xFF171A24),
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
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: 'Confirm Password',
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Colors.grey,
        ),
        filled: true,
        fillColor: const Color(0xFF171A24),
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
  required  TextEditingController passwordcontroller,
  required TextEditingController confirmPasswordcontroller,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      
     onPressed: () {
      if(passwordcontroller.text.trim()==confirmPasswordcontroller.text.trim()){
        log("1");
        context.read<AuthBloc>().add(
          RegisterRequested(
            name: nameController.text.trim(),
            email: emailcontroller.text.trim(),
            password: passwordcontroller.text.trim(),
          ),
        );
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
      }
     },

      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Create Account',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}


static Widget orDivider() {
  return Row(
    children: [
      const Expanded(
        child: Divider(
          color: Colors.grey,
          thickness: 1,
        ),
      ),

      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          'OR',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      const Expanded(
        child: Divider(
          color: Colors.grey,
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
        backgroundColor: const Color(0xFF171A24),
        foregroundColor: Colors.white,
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
              color: Colors.white,
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
      Text(
        "Already have an account?",
        style: TextStyle(
          color: Colors.grey,
          fontSize: 15,
        ),
      ),

      SizedBox(width: 5),

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
        child: Text(
          'Sign in',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}
}