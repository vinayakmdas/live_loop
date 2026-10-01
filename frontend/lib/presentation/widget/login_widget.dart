import 'package:flutter/material.dart';
import 'package:frontend/core/appcolors.dart';

class LoginWidget {
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
        'Welcome back',
        style: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
  
      SizedBox(height: 6),
  
      Text(
"Sign in to continue to Live Loop",        style: TextStyle(
          fontSize: 15,
          color: Colors.grey,
        ),
      ),
    ],
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
static Widget loginButton({
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Sign In',
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
}
