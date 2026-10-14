import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/auth/presentation/pages/loginscreen.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/home/presentation/bloc/home_event.dart';
import 'package:frontend/features/home/presentation/bloc/home_state.dart';
import 'package:frontend/features/home/presentation/page/video_call_screen.dart';
import 'package:frontend/features/home/presentation/widget/homescren_widget.dart';
import 'package:frontend/features/home/presentation/widget/live_card_widget.dart';
import 'package:frontend/features/meetings/domain/entities/meeting_entity.dart';
import 'package:frontend/features/meetings/domain/entities/meeting_join_result.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_event.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_state.dart';

/// Home Screen using BLoC pattern for state management
class Homescreen extends StatefulWidget {
  final UserEntity? user;

  const Homescreen({super.key, this.user});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  HomeBloc? _localBloc;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initBloc();
      try {
        context.read<MeetingBloc>().add(const LoadMeetingsEvent());
      } catch (_) {}
      _initialized = true;
    }
  }

  void _initBloc() {
    final effectiveUser = _resolveUser();

    // Check if HomeBloc is already provided above in the widget tree
    try {
      final parentBloc = context.read<HomeBloc>();
      if (effectiveUser != null) {
        parentBloc.add(LoadHomeUser(user: effectiveUser));
      }
      return;
    } catch (_) {
      // No parent HomeBloc found; fall back to local instance
    }

    if (_localBloc == null) {
      _localBloc = HomeBloc(initialUser: effectiveUser);
      if (effectiveUser == null) {
        _localBloc!.add(LoadHomeUser());
      }
    } else if (effectiveUser != null) {
      _localBloc!.add(LoadHomeUser(user: effectiveUser));
    }
  }

  /// Resolves the authenticated user from constructor, route arguments, or AuthBloc
  UserEntity? _resolveUser() {
    if (widget.user != null) {
      return widget.user;
    }

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is UserEntity) {
      return routeArgs;
    }

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess) {
        return authState.user;
      } else if (authState is AuthAuthenticated) {
        return authState.user;
      }
    } catch (_) {}

    return null;
  }

  @override
  void dispose() {
    _localBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_localBloc != null) {
      return BlocProvider<HomeBloc>.value(
        value: _localBloc!,
        child: const _HomeScreenContent(),
      );
    }

    return const _HomeScreenContent();
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  String? _joiningMeetingId;

  String _formatStartTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Handles retrieving LiveKit participant token from backend and navigating to VideoCallScreen
  Future<void> _handleJoinMeeting([
    MeetingEntity? meeting,
    String? requestedRoom,
  ]) async {
    if (_joiningMeetingId != null) return;

    final targetId =
        meeting?.id ?? meeting?.meetingLink ?? requestedRoom ?? 'live_room';
    setState(() {
      _joiningMeetingId = targetId;
    });

    try {
      final meetingBloc = context.read<MeetingBloc>();
      final authBloc = context.read<AuthBloc>();

      // 1. Verify user is logged in (session token used for HTTP authorization)
      final prefs = await SharedPreferences.getInstance();
      String sessionToken =
          prefs.getString('session_access_token') ?? '';

      if (sessionToken.isEmpty) {
        final authState = authBloc.state;
        if (authState is AuthSuccess && authState.user.token != null) {
          sessionToken = authState.user.token!;
        } else if (authState is AuthAuthenticated &&
            authState.user.token != null) {
          sessionToken = authState.user.token!;
        }
      }

      if (sessionToken.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // 2. Determine target room name
      final String roomName = requestedRoom ??
          (meeting?.name.isNotEmpty == true
              ? meeting!.name
              : 'kerala-community');

      // 3. Request LiveKit participant token and server URL from backend
      final MeetingJoinResult? result = await meetingBloc.joinMeetingDirect(
        meetingId: meeting?.id,
        meetingLink: meeting?.meetingLink,
        roomName: roomName,
      );

      if (!mounted) return;

      if (result == null || result.token.isEmpty) {
        throw Exception(
          'LiveKit participant token was not received from server.',
        );
      }

      // Refresh meetings list so member counts update across the app
      meetingBloc.add(const LoadMeetingsEvent());

      // 4. Navigate to VideoCallScreen passing the LIVEKIT participant token (NOT the app login token)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            serverUrl: result.serverUrl,
            token: result.token,
            roomName: result.roomName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining meeting: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _joiningMeetingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, homeState) {
        // 1. Loading state
        if (homeState is HomeLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: HomescrenWidget.appBar(userInitial: 'U'),
            body: HomescrenWidget.loadingView(),
          );
        }

        // 2. Unauthenticated / Not Logged In state
        if (!homeState.isLoggedIn) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: HomescrenWidget.appBar(userInitial: 'U'),
            body: HomescrenWidget.notLoggedInView(
              onLoginPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Loginscreen()),
                  (route) => false,
                );
              },
            ),
          );
        }

        // 3. Logged-in state
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: HomescrenWidget.appBar(
            userInitial: homeState.userInitial,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.navigationBackground,
              onRefresh: () async {
                context.read<HomeBloc>().add(LoadHomeUser());
                context.read<MeetingBloc>().add(const LoadMeetingsEvent());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    HomescrenWidget.welcomeSection(userName: homeState.userName),
                    const SizedBox(height: 25),
                    HomescrenWidget.createMeetingButton(context: context),
                    const SizedBox(height: 28),

                    // Current Live Meetings Section
                    BlocBuilder<MeetingBloc, MeetingState>(
                      builder: (context, meetingState) {
                        final currentMeetings = meetingState.meetings
                            .where((m) => m.isCurrent)
                            .toList();

                        if (meetingState is MeetingLoading &&
                            meetingState.meetings.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }

                        // When no live meetings exist yet in the database, display the default live card
                        if (currentMeetings.isEmpty) {
                          return LiveNowCard(
                            title: 'Good conversations happen here.',
                            subtitle: 'Kerala Community meetup',
                            startTime: _formatStartTime(DateTime.now()),
                            memberCount: 1,
                            memberInitials: const ['J', 'S', 'M', 'A'],
                            isJoining: _joiningMeetingId != null,
                            onJoinPressed: () =>
                                _handleJoinMeeting(null, 'kerala-community'),
                          );
                        }

                        // Display active live meetings from backend
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final meeting in currentMeetings) ...[
                              LiveNowCard(
                                title: meeting.name,
                                subtitle: meeting.description?.isNotEmpty == true
                                    ? meeting.description!
                                    : '${meeting.category != null && meeting.category!.isNotEmpty ? meeting.category![0].toUpperCase() + meeting.category!.substring(1) : "General"} Meeting',
                                startTime: _formatStartTime(
                                  meeting.scheduledStartTime ?? meeting.createdAt,
                                ),
                                memberCount: meeting.memberCount ?? 1,
                                memberInitials: meeting.memberInitials.isNotEmpty
                                    ? meeting.memberInitials
                                    : [
                                        meeting.name.isNotEmpty
                                            ? meeting.name[0].toUpperCase()
                                            : 'M'
                                      ],
                                isJoining: _joiningMeetingId ==
                                    (meeting.id ??
                                        meeting.meetingLink ??
                                        meeting.name),
                                onJoinPressed: () =>
                                    _handleJoinMeeting(meeting),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}