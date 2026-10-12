import 'package:equatable/equatable.dart';
import '../../domain/entities/meeting_entity.dart';
import '../../domain/entities/meeting_join_result.dart';

enum MeetingStatus { initial, submitting, success, failure }

class MeetingState extends Equatable {
  final List<MeetingEntity> meetings;
  final String category;
  final String accessType;
  final String meetingType; // 'instant' or 'scheduled'
  final DateTime? scheduledStartTime;
  final MeetingStatus status;
  final String message;
  final MeetingJoinResult? joinResult;
  final bool isJoining;

  const MeetingState({
    this.meetings = const [],
    this.category = '',
    this.accessType = 'invite_only',
    this.meetingType = 'instant',
    this.scheduledStartTime,
    this.status = MeetingStatus.initial,
    this.message = '',
    this.joinResult,
    this.isJoining = false,
  });

  bool get isInstant => meetingType == 'instant';
  bool get isScheduled => meetingType == 'scheduled';

  MeetingState copyWith({
    List<MeetingEntity>? meetings,
    String? category,
    String? accessType,
    String? meetingType,
    DateTime? scheduledStartTime,
    bool clearScheduledStartTime = false,
    MeetingStatus? status,
    String? message,
    MeetingJoinResult? joinResult,
    bool? isJoining,
  }) {
    return MeetingState(
      meetings: meetings ?? this.meetings,
      category: category ?? this.category,
      accessType: accessType ?? this.accessType,
      meetingType: meetingType ?? this.meetingType,
      scheduledStartTime: clearScheduledStartTime
          ? null
          : (scheduledStartTime ?? this.scheduledStartTime),
      status: status ?? this.status,
      message: message ?? this.message,
      joinResult: joinResult ?? this.joinResult,
      isJoining: isJoining ?? this.isJoining,
    );
  }

  @override
  List<Object?> get props => [
        meetings,
        category,
        accessType,
        meetingType,
        scheduledStartTime,
        status,
        message,
        joinResult,
        isJoining,
      ];
}

class MeetingLoading extends MeetingState {
  const MeetingLoading({
    super.meetings,
    super.category,
    super.accessType,
    super.meetingType,
    super.scheduledStartTime,
    super.status = MeetingStatus.initial,
    super.message,
  });
}

class MeetingLoaded extends MeetingState {
  const MeetingLoaded({
    required super.meetings,
    super.category,
    super.accessType,
    super.meetingType,
    super.scheduledStartTime,
    super.status = MeetingStatus.initial,
    super.message,
  });
}

class MeetingError extends MeetingState {
  final String error;

  const MeetingError({
    required this.error,
    super.meetings,
    super.category,
    super.accessType,
    super.meetingType,
    super.scheduledStartTime,
    super.status = MeetingStatus.failure,
    super.message,
  });

  @override
  List<Object?> get props => [error, ...super.props];
}

class MeetingJoined extends MeetingState {
  const MeetingJoined({
    required MeetingJoinResult joinResult,
    super.meetings,
    super.category,
    super.accessType,
    super.meetingType,
    super.scheduledStartTime,
    super.status = MeetingStatus.success,
    super.message,
  }) : super(joinResult: joinResult, isJoining: false);
}

