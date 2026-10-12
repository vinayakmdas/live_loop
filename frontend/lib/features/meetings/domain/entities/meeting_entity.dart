import 'package:equatable/equatable.dart';

class MeetingEntity extends Equatable {
  final String? id;
  final String name;
  final String? description;
  final String? category;
  final String? accessType;
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

  /// True if the meeting is currently live (active instant meeting or scheduled meeting that has started)
  bool get isCurrent {
    if (status?.toLowerCase() == 'archived') return false;
    if (isInstant) return true;
    if (isScheduled && scheduledStartTime != null) {
      final now = DateTime.now();
      final localStart = scheduledStartTime!.toLocal();
      final diff = now.difference(localStart);
      return diff.inHours >= 0 && diff.inHours < 6;
    }
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        accessType,
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
