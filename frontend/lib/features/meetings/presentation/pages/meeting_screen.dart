import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:frontend/core/appcolors.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/auth/presentation/pages/loginscreen.dart';
import 'package:frontend/features/home/presentation/bloc/home_bloc.dart';
import 'package:frontend/features/home/presentation/bloc/home_state.dart';
import 'package:frontend/features/home/presentation/page/video_call_screen.dart';
import 'package:frontend/features/home/presentation/widget/homescren_widget.dart';
import 'package:frontend/features/meetings/domain/entities/meeting_entity.dart';
import 'package:frontend/features/meetings/domain/entities/meeting_join_result.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_bloc.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_event.dart';
import 'package:frontend/features/meetings/presentation/bloc/meeting_state.dart';
import 'package:frontend/features/meetings/presentation/pages/create_meeting_page.dart';
import 'package:frontend/features/meetings/presentation/widgets/meeting_card.dart';
import 'package:frontend/features/meetings/presentation/widgets/meeting_passcode_dialog.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  String? _joiningMeetingId;
  int _selectedTabIndex = 0; // 0: Public Rooms, 1: Private Rooms
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MeetingBloc>().add(const LoadMeetingsEvent());
        // Load initial user's private rooms
        context.read<MeetingBloc>().add(const SearchPrivateMeetingsEvent(''));
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      context.read<MeetingBloc>().add(SearchPrivateMeetingsEvent(_searchController.text.trim()));
    }
  }

  Future<void> _handleJoinMeeting(MeetingEntity meeting, {String? enteredPasscode}) async {
    if (_joiningMeetingId != null) return;

    // Check future scheduled availability
    if (meeting.isScheduled && meeting.scheduledStartTime != null) {
      if (DateTime.now().isBefore(meeting.scheduledStartTime!.toLocal())) {
        final localTime = meeting.scheduledStartTime!.toLocal();
        final hour = localTime.hour == 0
            ? 12
            : (localTime.hour > 12 ? localTime.hour - 12 : localTime.hour);
        final minute = localTime.minute.toString().padLeft(2, '0');
        final period = localTime.hour >= 12 ? 'PM' : 'AM';
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final formatted = '${months[localTime.month - 1]} ${localTime.day}, ${localTime.year} at $hour:$minute $period';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This room is scheduled for $formatted and will automatically become available then.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    String? passcode = enteredPasscode;
    if (meeting.isPrivate && (passcode == null || passcode.trim().isEmpty)) {
      passcode = await showMeetingPasscodeDialog(
        context,
        meetingName: meeting.name,
      );
      if (!mounted) return;
      if (passcode == null || passcode.trim().isEmpty) {
        return;
      }
    }

    setState(() {
      _joiningMeetingId = meeting.id ?? meeting.meetingLink ?? meeting.name;
    });

    try {
      final meetingBloc = context.read<MeetingBloc>();
      final MeetingJoinResult? result = await meetingBloc.joinMeetingDirect(
        meetingId: meeting.id,
        meetingLink: meeting.meetingLink,
        roomName: meeting.name.isNotEmpty ? meeting.name : 'live_room',
        passcode: passcode,
      );

      if (!mounted) return;

      if (result == null || result.token.isEmpty) {
        throw Exception(
          'LiveKit participant token was not received from server.',
        );
      }

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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            serverUrl: result.serverUrl,
            token: result.token,
            roomName: result.roomName,
            userName: currentUser?.name,
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('[MeetingScreen Join Error] $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceAll('Exception: ', '')),
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
                  // Top Title & New Meeting button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meeting Rooms',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Public rooms & search private spaces',
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

                  const SizedBox(height: 18),

                  // Room Type Segment Tabs: Public Rooms vs Private Rooms
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.navigationBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.navigationBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            label: 'Public Rooms',
                            icon: Icons.public,
                            selected: _selectedTabIndex == 0,
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 0;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            label: 'Private Rooms',
                            icon: Icons.lock_outline,
                            selected: _selectedTabIndex == 1,
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 1;
                              });
                              if (_searchController.text.trim().isNotEmpty) {
                                context.read<MeetingBloc>().add(
                                  SearchPrivateMeetingsEvent(_searchController.text.trim()),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab Content
                  Expanded(
                    child: _selectedTabIndex == 0
                        ? _buildPublicRoomsTab()
                        : _buildPrivateRoomsTab(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tab 1: Public Rooms List (visible to everyone)
  Widget _buildPublicRoomsTab() {
    return BlocBuilder<MeetingBloc, MeetingState>(
      builder: (context, meetingState) {
        if (meetingState is MeetingLoading && meetingState.meetings.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (meetingState is MeetingError && meetingState.meetings.isEmpty) {
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
                        : 'Could not load public meetings',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      context.read<MeetingBloc>().add(const LoadMeetingsEvent());
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

        // Filter to ensure only public rooms appear in this list
        final publicMeetings = meetingState.meetings
            .where((m) => m.isPublic)
            .toList();

        if (publicMeetings.isEmpty) {
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
                      Icons.meeting_room_outlined,
                      size: 36,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No rooms available yet',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No public rooms have been created yet.',
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
                      'Create a Public Room',
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
            context.read<MeetingBloc>().add(const LoadMeetingsEvent());
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: publicMeetings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final meeting = publicMeetings[index];

              return MeetingCard(
                meetingName: meeting.name,
                description: meeting.description ?? '',
                category: meeting.category ?? 'general',
                accessType: meeting.accessType ?? 'public',
                joinCode: meeting.joinCode,
                meetingType: meeting.meetingType,
                scheduledStartTime: meeting.scheduledStartTime,
                onTap: () => _handleJoinMeeting(meeting),
              );
            },
          ),
        );
      },
    );
  }

  /// Tab 2: Private Rooms Search & Join Interface
  Widget _buildPrivateRoomsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar for private rooms
        Container(
          decoration: BoxDecoration(
            color: AppColors.navigationBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.navigationBorder),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search private room (e.g. Maths Class)...',
              hintStyle: const TextStyle(
                color: AppColors.hintText,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.grey,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        context.read<MeetingBloc>().add(const SearchPrivateMeetingsEvent(''));
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
            onChanged: (query) {
              setState(() {});
              context.read<MeetingBloc>().add(SearchPrivateMeetingsEvent(query.trim()));
            },
            onSubmitted: (query) {
              context.read<MeetingBloc>().add(SearchPrivateMeetingsEvent(query.trim()));
            },
          ),
        ),

        const SizedBox(height: 14),

        // Private search results or helper instructions
        Expanded(
          child: BlocBuilder<MeetingBloc, MeetingState>(
            builder: (context, meetingState) {
              if (meetingState.isSearchingPrivate) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              final results = meetingState.privateSearchResults;
              final query = _searchController.text.trim();

              if (query.isNotEmpty) {
                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.navigationBackground,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.navigationBorder),
                            ),
                            child: const Icon(
                              Icons.meeting_room_outlined,
                              size: 32,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No rooms available yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No private room found matching "$query".',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Render matching private rooms
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final meeting = results[index];
                    return _PrivateRoomCard(
                      meeting: meeting,
                      isJoining: _joiningMeetingId == (meeting.id ?? meeting.meetingLink ?? meeting.name),
                      onJoin: () => _handleJoinMeeting(meeting),
                    );
                  },
                );
              }

              // Empty search state: Informative guide + user's created private rooms if any
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.navigationBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.navigationBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.lock_outline,
                              color: AppColors.warning,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Private Rooms are Protected',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Private rooms do not appear in the public list. Type the exact or partial room name (e.g. Maths Class) to search for it, and enter the room password to join.',
                                  style: TextStyle(
                                    color: AppColors.inactiveText,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (results.isEmpty) ...[
                      const SizedBox(height: 36),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.navigationBackground,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.navigationBorder,
                                ),
                              ),
                              child: const Icon(
                                Icons.meeting_room_outlined,
                                size: 30,
                                color: AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No rooms available yet',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Search for a private room by name above.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 22),
                      const Text(
                        'Your Private Rooms',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final room in results) ...[
                        _PrivateRoomCard(
                          meeting: room,
                          isJoining: _joiningMeetingId == (room.id ?? room.meetingLink ?? room.name),
                          onJoin: () => _handleJoinMeeting(room),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectedBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primary : AppColors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.grey,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivateRoomCard extends StatelessWidget {
  final MeetingEntity meeting;
  final bool isJoining;
  final VoidCallback onJoin;

  const _PrivateRoomCard({
    required this.meeting,
    required this.isJoining,
    required this.onJoin,
  });

  String _formatSchedule(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = dt.toLocal();
    final hour = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${months[local.month - 1]} ${local.day} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isScheduled = meeting.isScheduled && meeting.scheduledStartTime != null;
    final isAvailable = meeting.isAvailableNow;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navigationBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navigationBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meeting.description != null && meeting.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meeting.description!,
                        style: const TextStyle(
                          color: AppColors.inactiveText,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isJoining ? null : onJoin,
                icon: isJoining
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.key, size: 14),
                label: Text(
                  isJoining ? 'Joining...' : 'Join',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 11, color: AppColors.warning),
                    SizedBox(width: 4),
                    Text(
                      'Private Room',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (meeting.category != null && meeting.category!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.navigationBorder),
                  ),
                  child: Text(
                    meeting.category![0].toUpperCase() + meeting.category!.substring(1),
                    style: const TextStyle(
                      color: AppColors.inactiveText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (isScheduled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.navigationBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAvailable ? Icons.fiber_manual_record : Icons.access_time,
                        size: 11,
                        color: isAvailable ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAvailable
                            ? 'Live Now'
                            : 'Starts ${_formatSchedule(meeting.scheduledStartTime!)}',
                        style: TextStyle(
                          color: isAvailable ? AppColors.success : AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, size: 11, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Live Now',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (meeting.password != null && meeting.password!.isNotEmpty)
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: meeting.password!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password "${meeting.password}" copied!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.key, size: 11, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Password: ${meeting.password}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy, size: 11, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}