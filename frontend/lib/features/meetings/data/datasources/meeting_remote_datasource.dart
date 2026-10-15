import 'package:frontend/core/constants/api_constant.dart';
import 'package:frontend/core/constants/api_service.dart';
import 'package:frontend/core/storage/tocken_storage.dart';
import '../../domain/entities/meeting_join_result.dart';
import '../models/meeting_model.dart';

abstract class MeetingRemoteDataSource {
  Future<MeetingModel> createMeeting(MeetingModel meeting);
  Future<List<MeetingModel>> getMeetings();
  Future<List<MeetingModel>> searchMeetings({
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
  Future<List<MeetingModel>> searchMeetings({
    required String query,
    String type = 'private',
  }) async {
    final token = sessionLocalDataSource?.getToken();
    final url = ApiConstants.searchMeetingsUrl(query, type: type);
    final response = await apiService.get(
      url,
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
    String? roomName,
    String? passcode,
  }) async {
    // 1. Local session token is strictly for authenticating the HTTP API request
    final authSessionToken = sessionLocalDataSource?.getToken();
    final endpoint = meetingId != null && meetingId.isNotEmpty
        ? ApiConstants.meetingJoinEndpoint(meetingId)
        : ApiConstants.joinMeetingEndpoint;

    final body = <String, dynamic>{
      if (meetingId != null && meetingId.isNotEmpty) 'meetingId': meetingId,
      if (meetingLink != null && meetingLink.isNotEmpty)
        'meetingLink': meetingLink,
      if (roomName != null && roomName.isNotEmpty)
        'roomName': roomName,
      if (passcode != null && passcode.isNotEmpty) ...{
        'passcode': passcode.trim(),
        'password': passcode.trim(),
      },
    };

    final response = await apiService.post(
      endpoint,
      body,
      token: authSessionToken,
    );

    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;

    final meetingData = data['meeting'] is Map<String, dynamic>
        ? data['meeting'] as Map<String, dynamic>
        : data;

    final meeting = MeetingModel.fromJson(meetingData);

    // 2. Extract and strictly validate the LiveKit participant token.
    // NEVER fall back to authSessionToken (app login JWT), which causes 'Invalid API key' in LiveKit.
    final roomToken = data['token']?.toString() ?? '';
    if (roomToken.isEmpty) {
      throw Exception(
        'Backend did not return a LiveKit participant token. Please verify LiveKit server configuration.',
      );
    }

    final effectiveRoomName = data['roomName']?.toString() ??
        (roomName != null && roomName.isNotEmpty ? roomName : meeting.name);
    final serverUrl = data['serverUrl']?.toString() ??
        'wss://live-loop-wdcidnza.livekit.cloud';

    return MeetingJoinResult(
      meeting: meeting,
      token: roomToken,
      roomName: effectiveRoomName,
      serverUrl: serverUrl,
    );
  }
}
