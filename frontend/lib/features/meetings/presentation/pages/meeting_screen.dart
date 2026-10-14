import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/auth/presentation/pages/loginscreen.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/home/presentation/bloc/home_state.dart';
import 'package:frontend/features/home/presentation/widget/homescren_widget.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_event.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_state.dart';
import 'package:frontend/features/meetings/presentation/pages/create_meeting_page.dart';
import 'package:frontend/features/meetings/presentation/widgets/meeting_card.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MeetingBloc>().add(const LoadMeetingsEvent());
      }
    });
  }

  Future<void> _navigateToCreateMeeting() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateMeetingPage(),
      ),
    );
    if (result == true && mounted) {
      context.read<MeetingBloc>().add(const LoadMeetingsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) {
        if (homeState is HomeLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: HomescrenWidget.appBar(userInitial: 'U'),
            body: HomescrenWidget.loadingView(),
          );
        }

        if (!homeState.isLoggedIn) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: HomescrenWidget.appBar(userInitial: 'U'),
            body: HomescrenWidget.notLoggedInView(
              onLoginPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Loginscreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: HomescrenWidget.appBar(
            userInitial: homeState.userInitial,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with Title and Create Meeting Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Meetings',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'All your active spaces and groups',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _navigateToCreateMeeting,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'New',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Database-backed meeting list
                  Expanded(
                    child: BlocBuilder<MeetingBloc, MeetingState>(
                      builder: (context, meetingState) {
                        if (meetingState is MeetingLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }

                        if (meetingState is MeetingError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppColors.error,
                                    size: 44,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    meetingState.error.isNotEmpty
                                        ? meetingState.error
                                        : 'Could not load meetings',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: () {
                                      context.read<MeetingBloc>().add(
                                            const LoadMeetingsEvent(),
                                          );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.white,
                                      side: const BorderSide(
                                        color: AppColors.navigationBorder,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Try again'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final meetings = meetingState.meetings;

                        if (meetings.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: AppColors.navigationBackground,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.navigationBorder,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.video_call_outlined,
                                      size: 36,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No meetings yet',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Create a meeting space to get started.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _navigateToCreateMeeting,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Create your first meeting',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.navigationBackground,
                          onRefresh: () async {
                            context.read<MeetingBloc>().add(
                                  const LoadMeetingsEvent(),
                                );
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: meetings.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final meeting = meetings[index];

                              return MeetingCard(
                                meetingName: meeting.name,
                                description: meeting.description ?? '',
                                category: meeting.category ?? 'general',
                                accessType: meeting.accessType ?? 'invite_only',
                                meetingType: meeting.meetingType,
                                scheduledStartTime: meeting.scheduledStartTime,
                                onTap: () {
                                  // Detail / Join meeting navigation in future phase
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}