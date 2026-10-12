import '../../domain/entities/meeting_entity.dart';

class MeetingModel extends MeetingEntity {
  const MeetingModel({
    super.id,
    required super.name,
    super.description,
    super.category,
    super.accessType,
    super.meetingType = 'instant',
    super.scheduledStartTime,
    super.meetingLink,
    super.status,
    super.memberCount,
    super.memberInitials = const [],
    super.createdAt,
    super.updatedAt,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      accessType: (json['accessType'] ?? '').toString(),
      meetingType:
          (json['meetingType'] ?? json['scheduleType'] ?? 'instant').toString(),
      scheduledStartTime: (json['scheduledStartTime'] ??
                  json['scheduledDate'] ??
                  json['startTime']) !=
              null
          ? DateTime.tryParse((json['scheduledStartTime'] ??
                  json['scheduledDate'] ??
                  json['startTime'])
              .toString())
          : null,
      meetingLink: json['meetingLink']?.toString(),
      status: json['status']?.toString(),
      memberCount: json['memberCount'] is int
          ? json['memberCount'] as int
          : (json['members'] is List ? (json['members'] as List).length : 0),
      memberInitials: json['memberInitials'] is List
          ? (json['memberInitials'] as List).map((e) => e.toString()).toList()
          : const [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description ?? '',
        'category': category?.toLowerCase() ?? '',
        'accessType': accessType ?? 'invite_only',
        'meetingType': meetingType,
        if (scheduledStartTime != null)
          'scheduledStartTime': scheduledStartTime!.toUtc().toIso8601String(),
      };
}
