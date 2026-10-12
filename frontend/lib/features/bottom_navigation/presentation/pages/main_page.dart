import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/bottom_navigation/domain/usecases/get_navigation_items.dart';
import 'package:frontend/features/bottom_navigation/presentation/bloc/%20BottomNav/bottom_nav_bloc.dart';
import 'package:frontend/features/bottom_navigation/presentation/bloc/%20BottomNav/bottom_nav_state.dart';
import 'package:frontend/features/bottom_navigation/presentation/widget/custtom_bottom.dart';
import 'package:frontend/features/home/presentation/page/homescreen.dart';
import 'package:frontend/features/meetings/presentation/pages/meeting_Screen.dart';
import 'package:frontend/features/notification/presentation/page/notification_screen.dart';
import 'package:frontend/features/profile/presentation/page/profile_screen.dart';



class MainPage extends StatelessWidget {
  const MainPage({super.key});

  static const List<Widget> _pages = [
    Homescreen(),
           MeetingScreen(),
           NotificationScreen(),
           ProfileScreen(),

  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BottomNavBloc(
        getNavigationItems: const GetNavigationItems(),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<BottomNavBloc, BottomNavState>(
          builder: (context, state) {
            return IndexedStack(
              index: state.selectedIndex,
              children: _pages,
            );
          },
        ),
        bottomNavigationBar: const CustomBottomNav(),
      ),
    );
  }
}
