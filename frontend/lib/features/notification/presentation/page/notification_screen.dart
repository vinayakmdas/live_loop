import 'package:flutter/material.dart';
import 'package:frontend/core/appcolors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          "Notification Screen",
          style: TextStyle(color: AppColors.white),
        ),
      ),
    );
  }
}