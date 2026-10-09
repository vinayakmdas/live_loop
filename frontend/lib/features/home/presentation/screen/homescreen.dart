import 'package:flutter/material.dart';
import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

class Homescreen extends StatelessWidget {
  final UserEntity? user;

  const Homescreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title:  Row(
      children: [
        Image.asset("asset/icon.png", width: 42, height: 42),

        SizedBox(width: 0),

        Text(
          'Live Loop',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Spacer(),
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color.fromARGB(77, 66, 66, 66),
          child: Text("${user?.name[0].toUpperCase() ?? "U"}"),
        ),
      ],
    )
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome, ${user?.name ?? "User"}! 👋',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
 
            ],
          ),
        ),
      ),
    );
  }

}