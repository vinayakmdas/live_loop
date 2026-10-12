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
    this.createdAt,
    this.updatedAt,
  });

  bool get isInstant => meetingType.toLowerCase() == 'instant';
  bool get isScheduled =>
      meetingType.toLowerCase() == 'scheduled' ||
      meetingType.toLowerCase() == 'later';

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
        createdAt,
        updatedAt,
      ];
}
