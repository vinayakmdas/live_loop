import 'package:equatable/equatable.dart';

abstract class MeetingEvent extends Equatable {
  const MeetingEvent();

  @override
  List<Object?> get props => [];
}

class LoadMeetingsEvent extends MeetingEvent {
  const LoadMeetingsEvent();
}

class MeetingCategoryChanged extends MeetingEvent {
  final String category;
  const MeetingCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class MeetingAccessChanged extends MeetingEvent {
  final String accessType;
  const MeetingAccessChanged(this.accessType);

  @override
  List<Object?> get props => [accessType];
}

class MeetingTypeChanged extends MeetingEvent {
  final String meetingType;
  const MeetingTypeChanged(this.meetingType);

  @override
  List<Object?> get props => [meetingType];
}

class MeetingScheduleChanged extends MeetingEvent {
  final DateTime? scheduledStartTime;
  const MeetingScheduleChanged(this.scheduledStartTime);

  @override
  List<Object?> get props => [scheduledStartTime];
}

class MeetingSubmitted extends MeetingEvent {
  final String name;
  final String description;
  final String category;
  final String accessType;
  final String meetingType;
  final DateTime? scheduledStartTime;

  const MeetingSubmitted({
    required this.name,
    required this.description,
    required this.category,
    required this.accessType,
    this.meetingType = 'instant',
    this.scheduledStartTime,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        category,
        accessType,
        meetingType,
        scheduledStartTime,
      ];
}

class MeetingMessageCleared extends MeetingEvent {
  const MeetingMessageCleared();
}

class JoinMeetingRequested extends MeetingEvent {
  final String? meetingId;
  final String? meetingLink;
  final String? roomName;

  const JoinMeetingRequested({
    this.meetingId,
    this.meetingLink,
    this.roomName,
  });

  @override
  List<Object?> get props => [meetingId, meetingLink, roomName];
}

