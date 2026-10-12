import '../models/meeting_model.dart';

abstract class MeetingRemoteDataSource {
  Future<void> createMeeting(MeetingModel meeting);
}

/// Temporary local implementation. Replace this with HTTP/API logic later.
class MeetingRemoteDataSourceImpl implements MeetingRemoteDataSource {
  @override
  Future<void> createMeeting(MeetingModel meeting) async {
    // Backend is not connected yet. This intentionally simulates a successful
    // request so you can build and test the UI independently.
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
