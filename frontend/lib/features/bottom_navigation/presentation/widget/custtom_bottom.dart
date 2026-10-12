import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/bottom_navigation/presentation/bloc/%20BottomNav/bottom_nav_bloc.dart';
import 'package:frontend/features/bottom_navigation/presentation/bloc/%20BottomNav/bottom_nav_event.dart';
import 'package:frontend/features/bottom_navigation/presentation/bloc/%20BottomNav/bottom_nav_state.dart';



class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavBloc, BottomNavState>(
      builder: (context, state) {
        return SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            height: 54,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.navigationBackground,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.navigationBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: state.items.map((item) {
                final isSelected =
                    state.selectedIndex == item.index;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 1,
                    ),
                    child: Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          context.read<BottomNavBloc>().add(
                                BottomNavTabChanged(item.index),
                              );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 180,
                          ),
                          curve: Curves.easeInOut,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.selectedBackground
                                : AppColors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.selectedText
                                  : AppColors.inactiveText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}