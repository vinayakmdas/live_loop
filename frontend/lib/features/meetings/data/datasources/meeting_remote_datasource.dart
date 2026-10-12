import 'package:frontend/core/constants/api_constant.dart';
import 'package:frontend/core/constants/api_service.dart';
import 'package:frontend/core/storage/tocken_storage.dart';
import '../../domain/entities/meeting_join_result.dart';
import '../models/meeting_model.dart';

abstract class MeetingRemoteDataSource {
  Future<MeetingModel> createMeeting(MeetingModel meeting);
  Future<List<MeetingModel>> getMeetings();
  Future<MeetingJoinResult> joinMeeting({String? meetingId, String? meetingLink});
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

  @override
  Future<MeetingJoinResult> joinMeeting({
    String? meetingId,
    String? meetingLink,
  }) async {
    final token = sessionLocalDataSource?.getToken();
    final endpoint = meetingId != null && meetingId.isNotEmpty
        ? ApiConstants.meetingJoinEndpoint(meetingId)
        : ApiConstants.joinMeetingEndpoint;

    final body = <String, dynamic>{
      if (meetingId != null && meetingId.isNotEmpty) 'meetingId': meetingId,
      if (meetingLink != null && meetingLink.isNotEmpty)
        'meetingLink': meetingLink,
    };

    final response = await apiService.post(
      endpoint,
      body,
      token: token,
    );

    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;

    final meetingData = data['meeting'] is Map<String, dynamic>
        ? data['meeting'] as Map<String, dynamic>
        : data;

    final meeting = MeetingModel.fromJson(meetingData);
    final roomToken = data['token']?.toString() ?? token ?? '';
    final roomName = data['roomName']?.toString() ?? meeting.name;
    final serverUrl = data['serverUrl']?.toString() ??
        'wss://live-loop-wdcidnza.livekit.cloud';

    return MeetingJoinResult(
      meeting: meeting,
      token: roomToken,
      roomName: roomName,
      serverUrl: serverUrl,
    );
  }
}
