import '../entities/meeting_entity.dart';
import '../repositories/meeting_repository.dart';

class GetMeetings {
  final MeetingRepository repository;

  const GetMeetings(this.repository);

  Future<List<MeetingEntity>> call() {
    return repository.getMeetings();
  }
}
