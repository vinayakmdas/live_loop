import 'package:equatable/equatable.dart';

class MeetingEntity extends Equatable {
  final String? id;
  final String name;
  final String? description;
  final String? category;
  final String? accessType;
  final String? joinCode;
  final String? password;
  final bool? isAvailable;
  final String meetingType;
  final DateTime? scheduledStartTime;
  final String? meetingLink;
  final String? status;
  final int? memberCount;
  final List<String> memberInitials;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MeetingEntity({
    this.id,
    required this.name,
    this.description,
    this.category,
    this.accessType,
    this.joinCode,
    this.password,
    this.isAvailable,
    this.meetingType = 'instant',
    this.scheduledStartTime,
    this.meetingLink,
    this.status,
    this.memberCount,
    this.memberInitials = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isInstant => meetingType.toLowerCase() == 'instant';
  bool get isScheduled =>
      meetingType.toLowerCase() == 'scheduled' ||
      meetingType.toLowerCase() == 'later';

  bool get isPrivate => accessType?.toLowerCase() == 'private';
  bool get isPublic =>
      accessType?.toLowerCase() == 'public' ||
      accessType?.toLowerCase() == 'anyone_with_link' ||
      accessType == null ||
      accessType!.isEmpty;

  /// True if the meeting is currently live and available to join
  bool get isAvailableNow {
    if (isAvailable != null) return isAvailable!;
    if (isInstant) return true;
    if (scheduledStartTime == null) return true;
    return DateTime.now().isAfter(scheduledStartTime!.toLocal());
  }

  /// True if the meeting is currently live (active instant meeting or scheduled meeting that has started).
  /// Private rooms do NOT appear in the public live feed.
  /// Does not display completed, cancelled, or archived meetings.
  bool get isCurrent {
    if (!isPublic) return false;
    final s = status?.toLowerCase();
    if (s == 'archived' || s == 'completed' || s == 'cancelled') return false;

    final now = DateTime.now();

    // If scheduled for the future, it has NOT started yet -> definitely NOT current!
    if (scheduledStartTime != null && now.isBefore(scheduledStartTime!.toLocal())) {
      return false;
    }

    if (isInstant && scheduledStartTime == null) return true;

    if (scheduledStartTime != null) {
      final localStart = scheduledStartTime!.toLocal();
      if (now.isBefore(localStart)) return false;
      final diff = now.difference(localStart);
      return !diff.isNegative && diff.inHours < 6;
    }

    return isInstant;
  }

  /// True if the meeting is a scheduled public meeting that has not started yet.
  /// Shows only scheduled public meetings that have not started yet.
  /// Does not display current, completed, cancelled, or private meetings in this section.
  bool get isUpcoming {
    if (!isPublic) return false;
    final s = status?.toLowerCase();
    if (s == 'archived' || s == 'completed' || s == 'cancelled') return false;
    if (scheduledStartTime == null) return false;
    return DateTime.now().isBefore(scheduledStartTime!.toLocal());
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        accessType,
        joinCode,
        password,
        isAvailable,
        meetingType,
        scheduledStartTime,
        meetingLink,
        status,
        memberCount,
        memberInitials,
        createdAt,
        updatedAt,
      ];
}
