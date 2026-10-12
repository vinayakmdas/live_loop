import 'package:equatable/equatable.dart';

abstract class MeetingEvent extends Equatable {
  const MeetingEvent();

  @override
  List<Object?> get props => [];
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

class MeetingSubmitted extends MeetingEvent {
  final String name;
  final String description;
  final String category;
  final String accessType;

  const MeetingSubmitted({
    required this.name,
    required this.description,
    required this.category,
    required this.accessType,
  });

  @override
  List<Object?> get props => [name, description, category, accessType];
}

class MeetingMessageCleared extends MeetingEvent {
  const MeetingMessageCleared();
}
