
import 'package:flutter/material.dart';
import 'package:frontend/core/appcolors.dart';

class LiveNowCard extends StatelessWidget {
  const LiveNowCard({
    super.key,
    this.onJoinPressed,
    this.startTime,
    this.remainingTime = '',
    this.memberCount = 1,
    this.title = 'Meeting Room',
    this.subtitle = 'Live Meeting',
    this.memberInitials = const [],
    this.isJoining = false,
  });

  final VoidCallback? onJoinPressed;
  final String? startTime;
  final String remainingTime;
  final int memberCount;
  final String title;
  final String subtitle;
  final List<String> memberInitials;
  final bool isJoining;

  String get _displayTime {
    if (startTime != null && startTime!.isNotEmpty) {
      return startTime!;
    }
    if (remainingTime.isNotEmpty) {
      return remainingTime;
    }
    return '';
  }

  String get _memberCountText {
    if (memberCount <= 0) {
      return 'Be the first to join';
    } else if (memberCount == 1) {
      return '1 person has joined the meeting';
    } else {
      return '$memberCount people have joined the meeting';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -180,
            left: 140,
            child: _DecorativeCircle(size: 420),
          ),
          const Positioned(
            top: -110,
            left: 245,
            child: _DecorativeCircle(size: 300),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: AppColors.liveGreen,
                            size: 12,
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'LIVE NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_displayTime.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Color(0xFFD9D5FF),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _displayTime,
                              style: const TextStyle(
                                color: Color(0xFFD9D5FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFD4D0FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    _MemberAvatars(
                      initials: memberInitials.isNotEmpty
                          ? memberInitials
                          : [
                              title.isNotEmpty
                                  ? title[0].toUpperCase()
                                  : 'M'
                            ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _memberCountText,
                        style: const TextStyle(
                          color: Color(0xFFD4D0FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isJoining ? null : onJoinPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Text(
                            'Join now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _MemberAvatars extends StatelessWidget {
  const _MemberAvatars({required this.initials});

  final List<String> initials;

  @override
  Widget build(BuildContext context) {
    final visibleInitials = initials.take(4).toList();

    return SizedBox(
      width: visibleInitials.isEmpty
          ? 0
          : 44.0 + (visibleInitials.length - 1) * 30.0,
      height: 40,
      child: Stack(
        children: [
          for (int i = 0; i < visibleInitials.length; i++)
            Positioned(
              left: i * 30.0,
              top: 1,
              child: Container(
                width: 39,
                height: 39,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF28356D),
                    width: 2,
                  ),
                ),
                child: Text(
                  visibleInitials[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
