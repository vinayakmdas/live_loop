import '../entities/meeting_entity.dart';
import '../repositories/meeting_repository.dart';

class CreateMeeting {
  final MeetingRepository repository;

  const CreateMeeting(this.repository);

  Future<MeetingEntity> call(MeetingEntity meeting) {
    return repository.createMeeting(meeting);
  }
}
