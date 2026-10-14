import '../entities/meeting_join_result.dart';
import '../repositories/meeting_repository.dart';

class JoinMeeting {
  final MeetingRepository repository;

  const JoinMeeting(this.repository);

  Future<MeetingJoinResult> call({
    String? meetingId,
    String? meetingLink,
    String? roomName,
  }) {
    return repository.joinMeeting(
      meetingId: meetingId,
      meetingLink: meetingLink,
      roomName: roomName,
    );
  }
}
