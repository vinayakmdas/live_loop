import 'package:flutter/material.dart';
import 'package:frontend/core/appcolors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          "Profile Screen",
          style: TextStyle(color: AppColors.white),
        ),
      ),
    );
  }
}