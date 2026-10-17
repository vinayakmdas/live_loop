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
import 'package:frontend/core/utils/date_time_formatter.dart';
import 'package:frontend/features/home/presentation/widget/coming_card_widget.dart';
import 'package:frontend/features/home/presentation/widget/homescren_widget.dart';
import 'package:frontend/features/home/presentation/widget/live_card_widget.dart';
import 'package:frontend/features/meetings/domain/entities/meeting_entity.dart';
import 'package:frontend/features/meetings/domain/entities/meeting_join_result.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_event.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_state.dart';
import 'package:frontend/features/meetings/presentation/widgets/meeting_card.dart';
import 'package:frontend/features/meetings/presentation/widgets/meeting_passcode_dialog.dart';

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
  void initState() {
    super.initState();
    if (widget.user != null) {
      _localBloc = HomeBloc(initialUser: widget.user);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initBloc();
      try {
        context.read<MeetingBloc>().add(const LoadMeetingsEvent());
      } catch (_) {}
      _initialized = true;
      if (mounted) setState(() {});
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    String? passcode,
  ]) async {
    if (_joiningMeetingId != null) return;

    if (meeting != null && !meeting.isAvailableNow) {
      final formattedTime = _formatStartTime(meeting.scheduledStartTime);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This meeting is scheduled for $formattedTime and has not started yet.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    // Prompt for code if joining a private meeting without existing access
    String? effectivePasscode = passcode;
    if (meeting != null && meeting.isPrivate && (effectivePasscode == null || effectivePasscode.isEmpty)) {
      if (meeting.joinCode != null && meeting.joinCode!.isNotEmpty) {
        effectivePasscode = meeting.joinCode;
      } else {
        effectivePasscode = await showMeetingPasscodeDialog(
          context,
          meetingName: meeting.name,
        );
        if (!mounted) return;
        if (effectivePasscode == null || effectivePasscode.trim().isEmpty) {
          // User cancelled entering code
          return;
        }
      }
    }

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
              : 'live_room');

      // 3. Request LiveKit participant token and server URL from backend
      final MeetingJoinResult? result = await meetingBloc.joinMeetingDirect(
        meetingId: meeting?.id,
        meetingLink: meeting?.meetingLink,
        roomName: roomName,
        passcode: effectivePasscode,
      );

      if (!mounted) return;

      if (result == null || result.token.isEmpty) {
        throw Exception(
          'LiveKit participant token was not received from server.',
        );
      }

      // Refresh meetings list so member counts update across the app
      meetingBloc.add(const LoadMeetingsEvent());

      UserEntity? currentUser;
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthSuccess) {
          currentUser = authState.user;
        } else if (authState is AuthAuthenticated) {
          currentUser = authState.user;
        }
      } catch (_) {}

      // 4. Navigate to VideoCallScreen passing the LIVEKIT participant token (NOT the app login token)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            serverUrl: result.serverUrl,
            token: result.token,
            roomName: result.roomName,
            userName: currentUser?.name,
            userProfileImage: currentUser?.profileImage,
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('[Homescreen JoinMeeting Error] $e\n$stack');
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
            profileImageUrl: homeState.profileImage,
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
                    const SizedBox(height: 20),

                    // Search bar for meetings
                    HomescrenWidget.searchBar(
                      controller: _searchController,
                      onChanged: (query) {
                        setState(() {
                          _searchQuery = query.trim();
                        });
                        if (_searchQuery.isNotEmpty) {
                          try {
                            context
                                .read<MeetingBloc>()
                                .add(SearchPrivateMeetingsEvent(_searchQuery));
                          } catch (_) {}
                        }
                      },
                      onClear: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        try {
                          context
                              .read<MeetingBloc>()
                              .add(const SearchPrivateMeetingsEvent(''));
                        } catch (_) {}
                      },
                    ),
                    const SizedBox(height: 18),

                    HomescrenWidget.createMeetingButton(context: context),
                    const SizedBox(height: 28),

                    // Current Live Meetings Section
                    Builder(
                      builder: (context) {
                        MeetingBloc? meetingBloc;
                        try {
                          meetingBloc = context.read<MeetingBloc>();
                        } catch (_) {}

                        if (meetingBloc == null) {
                          return const SizedBox.shrink();
                        }

                        return BlocBuilder<MeetingBloc, MeetingState>(
                          bloc: meetingBloc,
                          builder: (context, meetingState) {
                        final isSearching = _searchQuery.isNotEmpty;
                        final queryLower = _searchQuery.toLowerCase();

                        bool matchesSearch(MeetingEntity m) {
                          if (!isSearching) return true;
                          final nameMatch =
                              m.name.toLowerCase().contains(queryLower);
                          final descMatch = (m.description ?? '')
                              .toLowerCase()
                              .contains(queryLower);
                          final catMatch = (m.category ?? '')
                              .toLowerCase()
                              .contains(queryLower);
                          final codeMatch = (m.joinCode ?? '')
                              .toLowerCase()
                              .contains(queryLower);
                          return nameMatch ||
                              descMatch ||
                              catMatch ||
                              codeMatch;
                        }

                        final currentMeetings = meetingState.meetings
                            .where((m) => m.isCurrent && matchesSearch(m))
                            .toList();

                        final upcomingMeetings = meetingState.meetings
                            .where((m) => m.isUpcoming && matchesSearch(m))
                            .toList()
                          ..sort((a, b) {
                            if (a.scheduledStartTime == null) return 1;
                            if (b.scheduledStartTime == null) return -1;
                            return a.scheduledStartTime!
                                .compareTo(b.scheduledStartTime!);
                          });

                        final privateResults = isSearching
                            ? meetingState.privateSearchResults
                                .where(matchesSearch)
                                .toList()
                            : <MeetingEntity>[];

                        final totalMatches = currentMeetings.length +
                            upcomingMeetings.length +
                            privateResults.length;

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

                        if (meetingState is MeetingError &&
                            meetingState.meetings.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 32,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF344155),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 44,
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Could not load meetings',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  meetingState.message.isNotEmpty
                                      ? meetingState.message
                                      : 'Please check your connection and try again.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context
                                        .read<MeetingBloc>()
                                        .add(const LoadMeetingsEvent());
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Try Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Search Empty State: when user entered a search query and no meetings match
                        if (isSearching && totalMatches == 0) {
                          return _buildSearchEmptyState(_searchQuery);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Results summary bar when user is searching
                            if (isSearching) ...[
                              _buildSearchHeader(totalMatches),
                              const SizedBox(height: 18),
                            ],

                            // 1. Current Live Meetings Section
                            if (!isSearching || currentMeetings.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.sensors_rounded,
                                    color: AppColors.success,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isSearching
                                        ? 'Current Meetings (${currentMeetings.length})'
                                        : 'Current Meetings',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              if (currentMeetings.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 36,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.navigationBackground,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.navigationBorder,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.meeting_room_outlined,
                                          size: 32,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No rooms available yet',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Active public rooms will appear here once created.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                for (final meeting in currentMeetings) ...[
                                  LiveNowCard(
                                    title: meeting.name,
                                    subtitle: meeting.description?.isNotEmpty ==
                                            true
                                        ? meeting.description!
                                        : '${meeting.category != null && meeting.category!.isNotEmpty ? meeting.category![0].toUpperCase() + meeting.category!.substring(1) : "General"} Meeting',
                                    startTime: _formatStartTime(
                                      meeting.scheduledStartTime ??
                                          meeting.createdAt,
                                    ),
                                    memberCount: meeting.memberCount ?? 1,
                                    memberInitials:
                                        meeting.memberInitials.isNotEmpty
                                            ? meeting.memberInitials
                                            : [
                                                meeting.name.isNotEmpty
                                                    ? meeting.name[0]
                                                        .toUpperCase()
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
                              const SizedBox(height: 30),
                            ],

                            // 2. Upcoming Meetings Section
                            if (!isSearching || upcomingMeetings.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: AppColors.warning,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isSearching
                                        ? 'Upcoming Meetings (${upcomingMeetings.length})'
                                        : 'Upcoming Meetings',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              if (upcomingMeetings.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFF344155),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.warning
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 26,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No upcoming meetings',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Public meetings scheduled for later will appear here automatically with a live countdown.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                for (final meeting in upcomingMeetings) ...[
                                  ComingUpCard(
                                    meeting: meeting,
                                    onTap: () {
                                      final countdown =
                                          DateTimeFormatter.formatCountdown(
                                        meeting.scheduledStartTime,
                                      );
                                      final scheduledDate =
                                          DateTimeFormatter.formatScheduledDate(
                                        meeting.scheduledStartTime,
                                      );
                                      final scheduledTime =
                                          DateTimeFormatter.formatScheduledTime(
                                        meeting.scheduledStartTime,
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time_rounded,
                                                color: AppColors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '${meeting.name} is scheduled for $scheduledDate at $scheduledTime ($countdown).',
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: AppColors.primary,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    },
                                    onJoinPressed: () =>
                                        _handleJoinMeeting(meeting),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                            ],

                            // 3. Private Rooms Search Results (when searching)
                            if (isSearching && privateResults.isNotEmpty) ...[
                              const SizedBox(height: 30),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Private Rooms (${privateResults.length})',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              for (final meeting in privateResults) ...[
                                MeetingCard(
                                  meetingName: meeting.name,
                                  description: meeting.description ?? '',
                                  category: meeting.category ?? 'general',
                                  accessType: meeting.accessType ?? 'private',
                                  joinCode: meeting.joinCode,
                                  meetingType: meeting.meetingType,
                                  scheduledStartTime: meeting.scheduledStartTime,
                                  onTap: () => _handleJoinMeeting(meeting),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ],
                        );
                      },
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

  Widget _buildSearchHeader(int count) {
    return Row(
      children: [
        const Icon(Icons.search, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Results for "$_searchQuery"',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$count found',
            style: const TextStyle(
              color: Color(0xFFD4D0FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
            });
            try {
              context.read<MeetingBloc>().add(const SearchPrivateMeetingsEvent(''));
            } catch (_) {}
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Clear',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchEmptyState(String query) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF344155),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No meetings found for "$query"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check your spelling or try searching for another meeting name, category, or join code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              try {
                context.read<MeetingBloc>().add(const SearchPrivateMeetingsEvent(''));
              } catch (_) {}
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear Search'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.navigationBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}