import '../../domain/entities/meeting_entity.dart';
import '../../domain/entities/meeting_join_result.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../datasources/meeting_remote_datasource.dart';
import '../models/meeting_model.dart';

class MeetingRepositoryImpl implements MeetingRepository {
  final MeetingRemoteDataSource dataSource;

  const MeetingRepositoryImpl(this.dataSource);

  @override
  Future<MeetingEntity> createMeeting(MeetingEntity meeting) {
    final model = MeetingModel(
      name: meeting.name,
      description: meeting.description,
      category: meeting.category,
      accessType: meeting.accessType,
      meetingType: meeting.meetingType,
      scheduledStartTime: meeting.scheduledStartTime,
    );
    return dataSource.createMeeting(model);
  }

  @override
  Future<List<MeetingEntity>> getMeetings() {
    return dataSource.getMeetings();
  }

  @override
  Future<MeetingJoinResult> joinMeeting({
    String? meetingId,
    String? meetingLink,
  }) {
    return dataSource.joinMeeting(
      meetingId: meetingId,
      meetingLink: meetingLink,
    );
  }
}
