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

class MeetingPasswordChanged extends MeetingEvent {
  final String password;
  const MeetingPasswordChanged(this.password);

  @override
  List<Object?> get props => [password];
}

class SearchPrivateMeetingsEvent extends MeetingEvent {
  final String query;
  const SearchPrivateMeetingsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class MeetingSubmitted extends MeetingEvent {
  final String name;
  final String description;
  final String category;
  final String accessType;
  final String? password;
  final String meetingType;
  final DateTime? scheduledStartTime;

  const MeetingSubmitted({
    required this.name,
    required this.description,
    required this.category,
    this.accessType = 'public',
    this.password,
    this.meetingType = 'instant',
    this.scheduledStartTime,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        category,
        accessType,
        password,
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
  final String? passcode;

  const JoinMeetingRequested({
    this.meetingId,
    this.meetingLink,
    this.roomName,
    this.passcode,
  });

  @override
  List<Object?> get props => [meetingId, meetingLink, roomName, passcode];
}

