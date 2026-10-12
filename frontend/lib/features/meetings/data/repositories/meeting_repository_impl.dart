import '../../domain/entities/meeting_entity.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../datasources/meeting_remote_datasource.dart';
import '../models/meeting_model.dart';

class MeetingRepositoryImpl implements MeetingRepository {
  final MeetingRemoteDataSource dataSource;

  const MeetingRepositoryImpl(this.dataSource);

  @override
  Future<void> createMeeting(MeetingEntity meeting) {
    final model = MeetingModel(
      name: meeting.name,
      description: meeting.description,
      category: meeting.category,
      accessType: meeting.accessType,
    );
    return dataSource.createMeeting(model);
  }
}
