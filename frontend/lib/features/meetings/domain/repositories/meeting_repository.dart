import '../entities/meeting_entity.dart';

abstract class MeetingRepository {
  Future<void> createMeeting(MeetingEntity meeting);
}
