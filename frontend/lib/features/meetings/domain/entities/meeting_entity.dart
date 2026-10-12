import 'package:equatable/equatable.dart';

class MeetingEntity extends Equatable {
  final String name;
  final String description;
  final String category;
  final String accessType;

  const MeetingEntity({
    required this.name,
    required this.description,
    required this.category,
    required this.accessType,
  });

  @override
  List<Object?> get props => [name, description, category, accessType];
}
