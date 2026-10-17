import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/appcolors.dart';
import 'package:frontend/core/utils/date_time_formatter.dart';
import 'package:frontend/features/meetings/domain/entities/meeting_entity.dart';

/// Reusable card widget for displaying an upcoming/scheduled meeting with live countdown timer.
class ComingUpCard extends StatefulWidget {
  final MeetingEntity? meeting;
  final String? title;
  final String? meetingName;
  final String? subtitle;
  final String? description;
  final DateTime? scheduledStartTime;
  final String? countdown;
  final String? scheduledDate;
  final String? startTime;
  final int? memberCount;
  final List<String>? memberInitials;
  final String? category;
  final VoidCallback? onTap;
  final VoidCallback? onJoinPressed;

  const ComingUpCard({
    super.key,
    this.meeting,
    this.title,
    this.meetingName,
    this.subtitle,
    this.description,
    this.scheduledStartTime,
    this.countdown,
    this.scheduledDate,
    this.startTime,
    this.memberCount,
    this.memberInitials,
    this.category,
    this.onTap,
    this.onJoinPressed,
  });

  /// Formats the remaining time countdown until [scheduledTime].
  ///
  /// Examples:
  /// - "Starts in 30 minutes"
  /// - "Starts in 2 hours"
  /// - "Starts tomorrow"
  /// - "Starts in 3 days"
  /// - "Starts now"
  static String formatCountdown(DateTime? scheduledTime, {DateTime? now}) =>
      DateTimeFormatter.formatCountdown(scheduledTime, now: now);

  /// Formats the scheduled date (e.g. "Tomorrow", "Today", "Oct 18, 2026")
  static String formatScheduledDate(DateTime? scheduledTime, {DateTime? now}) =>
      DateTimeFormatter.formatScheduledDate(scheduledTime, now: now);

  /// Formats the scheduled start time (e.g. "2:30 PM", "10:00 AM")
  static String formatScheduledTime(DateTime? scheduledTime) =>
      DateTimeFormatter.formatScheduledTime(scheduledTime);

  @override
  State<ComingUpCard> createState() => _ComingUpCardState();
}

class _ComingUpCardState extends State<ComingUpCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Update countdown every 30 seconds
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _effectiveName {
    if (widget.meetingName != null && widget.meetingName!.isNotEmpty) {
      return widget.meetingName!;
    }
    if (widget.title != null && widget.title!.isNotEmpty) {
      return widget.title!;
    }
    if (widget.meeting != null && widget.meeting!.name.isNotEmpty) {
      return widget.meeting!.name;
    }
    return 'Upcoming Meeting';
  }

  String get _effectiveDescription {
    if (widget.description != null && widget.description!.isNotEmpty) {
      return widget.description!;
    }
    if (widget.subtitle != null && widget.subtitle!.isNotEmpty) {
      return widget.subtitle!;
    }
    if (widget.meeting?.description != null &&
        widget.meeting!.description!.isNotEmpty) {
      return widget.meeting!.description!;
    }
    final cat = widget.category ?? widget.meeting?.category;
    if (cat != null && cat.isNotEmpty) {
      return '${cat[0].toUpperCase()}${cat.substring(1)} Meeting';
    }
    return 'Scheduled Meeting';
  }

  DateTime? get _effectiveScheduledTime =>
      widget.scheduledStartTime ?? widget.meeting?.scheduledStartTime;

  String get _effectiveCountdown {
    if (widget.countdown != null && widget.countdown!.isNotEmpty) {
      return widget.countdown!;
    }
    if (_effectiveScheduledTime != null) {
      return ComingUpCard.formatCountdown(_effectiveScheduledTime!);
    }
    return 'Scheduled';
  }

  String get _effectiveScheduledDate {
    if (widget.scheduledDate != null && widget.scheduledDate!.isNotEmpty) {
      return widget.scheduledDate!;
    }
    if (_effectiveScheduledTime != null) {
      return ComingUpCard.formatScheduledDate(_effectiveScheduledTime!);
    }
    return '';
  }

  String get _effectiveStartTime {
    if (widget.startTime != null && widget.startTime!.isNotEmpty) {
      return widget.startTime!;
    }
    if (_effectiveScheduledTime != null) {
      return ComingUpCard.formatScheduledTime(_effectiveScheduledTime!);
    }
    return '';
  }

  int get _effectiveMemberCount =>
      widget.memberCount ?? widget.meeting?.memberCount ?? 1;

  List<String> get _effectiveMemberInitials {
    if (widget.memberInitials != null && widget.memberInitials!.isNotEmpty) {
      return widget.memberInitials!;
    }
    if (widget.meeting != null && widget.meeting!.memberInitials.isNotEmpty) {
      return widget.meeting!.memberInitials;
    }
    final firstChar = _effectiveName.isNotEmpty
        ? _effectiveName.trim()[0].toUpperCase()
        : 'M';
    return [firstChar];
  }

  String get _memberCountText {
    if (_effectiveMemberCount <= 0) {
      return 'No participants yet';
    } else if (_effectiveMemberCount == 1) {
      return '1 person invited';
    } else {
      return '$_effectiveMemberCount people invited';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF344155),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: UPCOMING badge + Countdown pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 13,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'UPCOMING',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFFD4D0FF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _effectiveCountdown,
                      style: const TextStyle(
                        color: Color(0xFFD4D0FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Subtitle / Category
          Text(
            _effectiveDescription,
            style: const TextStyle(
              color: AppColors.inactiveText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Meeting Name
          Text(
            _effectiveName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Scheduled Date and Start Time details
          if (_effectiveScheduledDate.isNotEmpty ||
              _effectiveStartTime.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (_effectiveScheduledDate.isNotEmpty) ...[
                  const Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _effectiveScheduledDate,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (_effectiveScheduledDate.isNotEmpty &&
                    _effectiveStartTime.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (_effectiveStartTime.isNotEmpty) ...[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _effectiveStartTime,
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 18),

          // Bottom row: Member avatars & count + Details action
          Row(
            children: [
              _MemberAvatars(initials: _effectiveMemberInitials),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _memberCountText,
                  style: const TextStyle(
                    color: AppColors.inactiveText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onJoinPressed ?? widget.onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: BorderSide(
                    color: AppColors.navigationBorder.withValues(alpha: 0.9),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: AppColors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          : 34.0 + (visibleInitials.length - 1) * 22.0,
      height: 32,
      child: Stack(
        children: [
          for (int i = 0; i < visibleInitials.length; i++)
            Positioned(
              left: i * 22.0,
              top: 0,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 2,
                  ),
                ),
                child: Text(
                  visibleInitials[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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

/// Backwards compatibility alias
typedef ComingCard = ComingUpCard;

/// Extension on [ComingUpCard] providing instance-level formatters matching static APIs
extension ComingUpCardMethods on ComingUpCard {
  String formatCountdown([DateTime? time, DateTime? now]) =>
      DateTimeFormatter.formatCountdown(
        time ?? scheduledStartTime ?? meeting?.scheduledStartTime,
        now: now,
      );

  String formatScheduledDate([DateTime? time, DateTime? now]) =>
      DateTimeFormatter.formatScheduledDate(
        time ?? scheduledStartTime ?? meeting?.scheduledStartTime,
        now: now,
      );

  String formatScheduledTime([DateTime? time]) =>
      DateTimeFormatter.formatScheduledTime(
        time ?? scheduledStartTime ?? meeting?.scheduledStartTime,
      );
}

/// Extension on [MeetingEntity] providing direct access to formatted schedule values
extension MeetingEntityScheduleFormatting on MeetingEntity {
  String get countdown =>
      scheduledStartTime != null ? DateTimeFormatter.formatCountdown(scheduledStartTime) : '';
  String get scheduledDate =>
      scheduledStartTime != null ? DateTimeFormatter.formatScheduledDate(scheduledStartTime) : '';
  String get scheduledTime =>
      scheduledStartTime != null ? DateTimeFormatter.formatScheduledTime(scheduledStartTime) : '';

  String formatCountdown([DateTime? now]) =>
      DateTimeFormatter.formatCountdown(scheduledStartTime, now: now);
  String formatScheduledDate([DateTime? now]) =>
      DateTimeFormatter.formatScheduledDate(scheduledStartTime, now: now);
  String formatScheduledTime() =>
      DateTimeFormatter.formatScheduledTime(scheduledStartTime);
}
