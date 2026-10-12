import '../entities/meeting_entity.dart';
import '../entities/meeting_join_result.dart';

abstract class MeetingRepository {
  Future<MeetingEntity> createMeeting(MeetingEntity meeting);
  Future<List<MeetingEntity>> getMeetings();
  Future<MeetingJoinResult> joinMeeting({String? meetingId, String? meetingLink});
}
