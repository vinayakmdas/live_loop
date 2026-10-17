import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/theme/appcolors.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_event.dart';
import 'package:frontend/features/meetings/presentation/pages/create_meeting_page.dart';

/// Reusable UI components for the Home screen following MVC architecture
class HomescrenWidget {
  /// Complete AppBar for the Home screen with app branding and user avatar
  static PreferredSizeWidget appBar({
    required String userInitial,
    String? profileImageUrl,
    VoidCallback? onProfileTap,
  }) {
    final hasImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Row(
        children: [
          Image.asset('asset/icon.png', width: 42, height: 42),
          const SizedBox(width: 8),
          const Text(
            'Live Loop',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.avatarBackground,
              backgroundImage: hasImage ? NetworkImage(profileImageUrl) : null,
              child: hasImage
                  ? null
                  : Text(
                      userInitial,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Welcome greeting section displaying dynamic user name and subtitle
  static Widget welcomeSection({required String userName}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome, $userName! 👋',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Stay connected with your meetings',
          style: TextStyle(fontSize: 15, color: AppColors.grey),
        ),
      ],
    );
  }

  /// Loading state widget
  static Widget loadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primaryGradientStart),
          SizedBox(height: 16),
          Text(
            'Loading user profile...',
            style: TextStyle(color: AppColors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Fallback view when user is not logged in
  static Widget notLoggedInView({required VoidCallback onLoginPressed}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'You are not signed in',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign in to access your meetings and profile',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onLoginPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGradientStart,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable gradient button to create meetings
  static Widget createMeetingButton({required BuildContext context}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateMeetingPage()),
            );
            if (result == true && context.mounted) {
              context.read<MeetingBloc>().add(const LoadMeetingsEvent());
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: AppColors.white),
                SizedBox(width: 4),
                Text(
                  'Create Meeting',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Search bar for the Home screen matching modern dark styling
  static Widget searchBar({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    VoidCallback? onClear,
    String hintText = 'Search meetings by name or category...',
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navigationBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navigationBorder),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.hintText, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.grey, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.grey,
                    size: 18,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Alias for naming consistency
typedef HomeScreenWidget = HomescrenWidget;
