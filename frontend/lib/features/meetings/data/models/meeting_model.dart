import '../../domain/entities/meeting_entity.dart';

class MeetingModel extends MeetingEntity {
  const MeetingModel({
    required super.name,
    required super.description,
    required super.category,
    required super.accessType,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'category': category,
        'accessType': accessType,
      };
}
