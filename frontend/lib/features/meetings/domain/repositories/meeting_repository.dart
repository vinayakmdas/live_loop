import '../entities/meeting_entity.dart';
import '../entities/meeting_join_result.dart';

abstract class MeetingRepository {
  Future<MeetingEntity> createMeeting(MeetingEntity meeting);
  Future<List<MeetingEntity>> getMeetings();
  Future<List<MeetingEntity>> searchMeetings({
    required String query,
    String type = 'private',
  });
  Future<MeetingJoinResult> joinMeeting({
    String? meetingId,
    String? meetingLink,
    String? roomName,
    String? passcode,
  });
}
