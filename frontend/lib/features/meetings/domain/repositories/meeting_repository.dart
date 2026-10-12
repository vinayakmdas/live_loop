import '../entities/meeting_entity.dart';

abstract class MeetingRepository {
  Future<MeetingEntity> createMeeting(MeetingEntity meeting);
  Future<List<MeetingEntity>> getMeetings();
}
