import 'package:equatable/equatable.dart';
import 'meeting_entity.dart';

class MeetingJoinResult extends Equatable {
  final MeetingEntity meeting;
  final String token;
  final String roomName;
  final String serverUrl;

  const MeetingJoinResult({
    required this.meeting,
    required this.token,
    required this.roomName,
    required this.serverUrl,
  });

  @override
  List<Object?> get props => [meeting, token, roomName, serverUrl];
}
