import 'package:frontend/core/constants/api_constant.dart';
import 'package:frontend/core/constants/api_service.dart';
import 'package:frontend/core/storage/tocken_storage.dart';
import '../models/meeting_model.dart';

abstract class MeetingRemoteDataSource {
  Future<MeetingModel> createMeeting(MeetingModel meeting);
  Future<List<MeetingModel>> getMeetings();
}

class MeetingRemoteDataSourceImpl implements MeetingRemoteDataSource {
  final ApiService apiService;
  final SessionLocalDataSource? sessionLocalDataSource;

  MeetingRemoteDataSourceImpl({
    required this.apiService,
    this.sessionLocalDataSource,
  });

  @override
  Future<MeetingModel> createMeeting(MeetingModel meeting) async {
    final token = sessionLocalDataSource?.getToken();
    final response = await apiService.post(
      ApiConstants.meetingsEndpoint,
      meeting.toJson(),
      token: token,
    );

    final dynamic meetingData = response['data'] != null && response['data']['meeting'] != null
        ? response['data']['meeting']
        : response['meeting'] ?? response['data'];

    if (meetingData is Map<String, dynamic>) {
      return MeetingModel.fromJson(meetingData);
    }
    throw 'Invalid response received while creating meeting.';
  }

  @override
  Future<List<MeetingModel>> getMeetings() async {
    final token = sessionLocalDataSource?.getToken();
    final response = await apiService.get(
      ApiConstants.meetingsEndpoint,
      token: token,
    );

    final dynamic meetingsList = response['data'] != null && response['data']['meetings'] != null
        ? response['data']['meetings']
        : response['meetings'] ?? response['data'];

    if (meetingsList is List) {
      return meetingsList
          .map((item) => MeetingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
