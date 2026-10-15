import '../entities/meeting_entity.dart';
import '../repositories/meeting_repository.dart';

class SearchMeetings {
  final MeetingRepository repository;

  const SearchMeetings(this.repository);

  Future<List<MeetingEntity>> call({
    required String query,
    String type = 'private',
  }) {
    return repository.searchMeetings(query: query, type: type);
  }
}
